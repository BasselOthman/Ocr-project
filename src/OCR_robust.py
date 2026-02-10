import os
import re
import cv2
import numpy as np
import pandas as pd
from doctr.io import DocumentFile
from doctr.models import ocr_predictor
import sys
import math
import json
import difflib
import easyocr
from pdf2image import convert_from_path

# ================= PATH CONFIGURATION =================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INPUT_DIR = os.path.join(BASE_DIR, "input")
OUTPUT_DIR = os.path.join(BASE_DIR, "output")
LOGS_DIR = os.path.join(BASE_DIR, "logs")

# Ensure directories exist
os.makedirs(INPUT_DIR, exist_ok=True)
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(LOGS_DIR, exist_ok=True)

DEBUG_FILE = os.path.join(LOGS_DIR, "debug_info.txt")

# ================= PATIENT MANAGEMENT =================

class PatientManager:
    """
    Manages synthetic Patient IDs based on normalized patient names.
    Persists data to patient_registry.json.
    """
    def __init__(self, registry_path=None):
        if registry_path is None:
            self.registry_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "config", "patient_registry.json")
        else:
            self.registry_path = registry_path
            
        self.patient_map = self.load_registry() # { "normalized_name": "ID" }
        self.next_id = self.calculate_next_id()

    def load_registry(self):    
        if os.path.exists(self.registry_path):
            try:
                with open(self.registry_path, "r", encoding="utf-8") as f:
                    return json.load(f)
            except Exception as e:
                print(f"Warning: Could not load registry: {e}")
                return {}
        return {}

    def save_registry(self):
        try:
            os.makedirs(os.path.dirname(self.registry_path), exist_ok=True)
            print(f"DEBUG: Attempting to save registry to {self.registry_path}")
            with open(self.registry_path, "w", encoding="utf-8") as f:
                json.dump(self.patient_map, f, indent=4)
            print(f"Registry saved to {self.registry_path}")
        except Exception as e:
            print(f"Error saving registry: {e}")

    def calculate_next_id(self):
        if not self.patient_map:
            return 10001
        
        # dynamic max finding
        ids = [int(v) for v in self.patient_map.values() if v.isdigit()]
        if ids:
            return max(ids) + 1
        return 10001

    def normalize_name(self, name):
        """
        Normalizes a name for consistent matching.
        """
        if not name or not isinstance(name, str):
            return "UNKNOWN"
        
        # Remove common titles and keywords like "Patient"
        name = re.sub(r'\b(mr|mrs|ms|dr|prof|miss|patient|name)\b\.?', '', name, flags=re.IGNORECASE)
        # Remove anything that is not a letter (English or Arabic) or space
        # \u0600-\u06FF covers standard Arabic
        name = re.sub(r'[^\w\s\u0600-\u06FF]', '', name)
        # Normalize whitespace
        name = " ".join(name.split()).upper()
        return name

    def get_or_create_id(self, raw_name):
        """
        Returns an existing ID or creates a new one for the given name.
        """
        normalized = self.normalize_name(raw_name)
        
        if normalized == "UNKNOWN" or not normalized:
            return "UNKNOWN", "UNKNOWN"

        if normalized in self.patient_map:
            return self.patient_map[normalized], normalized
        
        # Create new ID
        new_id = str(self.next_id)
        self.patient_map[normalized] = new_id
        self.next_id += 1
        
        # Auto-save on creation (optional, but safer)
        self.save_registry()
        
        return new_id, normalized


# ================= REUSABLE HELPERS (From v1) =================
def normalize_arabic_digits(text):
    return text.translate(str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789"))

def fix_spacing(text):
    words = text.split(" ")
    new_words = []
    buffer = []
    for w in words:
        if not w: continue
        if len(w) == 1:
            buffer.append(w)
        else:
            if len(buffer) > 1:
                new_words.append("".join(buffer))
                buffer = []
            elif len(buffer) == 1:
                new_words.append(buffer[0])
                buffer = []
            new_words.append(w)
    if len(buffer) > 1:
        new_words.append("".join(buffer))
    elif len(buffer) == 1:
        new_words.append(buffer[0])
    return " ".join(new_words)

def cleanup_name(name):
    # Remove "x10..." scientific notation noise
    name = re.sub(r'\s*x10.*', '', name, flags=re.IGNORECASE)
    
    # Remove trailing numbers, percentages, or value-like debris
    # e.g. "Neutrophils 46.6 %" -> "Neutrophils"
    name = re.sub(r'\s+[\d\.,]+[%]?\s*$', '', name)
    
    if "HBs" in name and "Ag" in name: return "HBsAg"
    if "HCV" in name and "Ab" in name: return "HCVAb"
    if "Free" in name and "T" in name and "1" in name: return "Free T4"
        
    name = name.replace("H B s A g", "HBsAg")
    name = name.replace("H C V A b", "HCVAb")
    return name.strip()

def standardize_name(name):
    name = re.sub(r'\(.*?\)', '', name).strip()
    
    # Mapping for common test names
    mapping = {
        "HAEMOGLOBIN": "HGB",
        "HB": "HGB",
        "HEMATOCRIT": "HCT",
        "PCV": "HCT",
        "RBC": "RBC",
        "WBC": "WBC",
        "PLATELET": "PLT",
        "MCV": "MCV",
        "MCH": "MCH",
        "MCHC": "MCHC",
        "RDW": "RDW",
        "NEUTROPHIL": "NEUT",
        "LYMPHOCYTE": "LYMPH",
        "MONOCYTE": "MONO",
        "EOSINOPHIL": "EO",
        "BASOPHIL": "BASO",
        "GLUCOSE": "GLU",
        "SUGAR": "GLU",
        "UREA": "UREA",
        "CREATININE": "CREAT",
        "SGPT": "ALT",
        "ALT": "ALT",
        "SGOT": "AST",
        "AST": "AST",
        "BILIRUBIN": "BIL",
        "CHOLESTEROL": "CHOL",
        "TRIGLYCERIDE": "TRIG",
        "HDL": "HDL",
        "LDL": "LDL",
        "TSH": "TSH",
        "T3": "T3",
        "T4": "T4",
        "VITAMIN D": "VITD",
        "FERRITIN": "FERRITIN",
        "CALCIUM": "CA",
        "MAGNESIUM": "MG",
        "PHOSPHORUS": "PHOS",
        "PROTEIN": "TP",
        "ALBUMIN": "ALB",
        "GLOBULIN": "GLOB",
        "ALK": "ALP",
        "PHOSPHATASE": "ALP",
        "BILIRUBIN": "BIL",
        "DIRECT": "DBIL",
        # New additions
        "CRP": "CRP",
        "A1C": "HBA1C",
        "HBA1C": "HBA1C",
        "SODIUM": "NA",
        "NA": "NA",
        "POTASSIUM": "K",
        "K": "K",
        "LIPASE": "LIPASE",
        "AMYLASE": "AMYLASE",
        "URIC": "URIC"
    }
    
    upper_name = name.upper()
    
    # Sort keys by length descending to ensure specific matches are found first
    # e.g. Match "HBA1C" before "HB"
    sorted_keys = sorted(mapping.keys(), key=len, reverse=True)
    
    for key in sorted_keys:
        val = mapping[key]
        if key in upper_name:
            return val
            
    return name.upper()

def get_flag(value, ref_range):
    if not ref_range or not value: return "Unknown"
    
    # Simple check for Positive/Negative
    if "negative" in value.lower() or "non-reactive" in value.lower():
        return "NEGATIVE"
    if "positive" in value.lower() or "reactive" in value.lower():
        return "POSITIVE"
        
    try:
        val_float = float(re.search(r'\d+(\.\d+)?', value).group())
        # Parse range "X - Y"
        range_nums = re.findall(r'\d+(\.\d+)?', ref_range)
        if len(range_nums) >= 2:
            low = float(range_nums[0][0] if isinstance(range_nums[0], tuple) else range_nums[0])
            high = float(range_nums[-1][0] if isinstance(range_nums[-1], tuple) else range_nums[-1])
            if val_float < low: return "Low"
            if val_float > high: return "High"
            return "Normal"
    except:
        pass
    return "Normal"

def calculate_confidence(ocr_conf, unit, ref_range, value):
    score = 0.4 * ocr_conf
    if unit: score += 0.2
    if ref_range: score += 0.2
    if value: score += 0.2
    return round(score * 100, 2)

# ================= ROBUST LOGIC =================

class RobustOCR:
    def __init__(self):
        # Configuration
        self.column_anchors = {} # { 'Test Name': x_center, 'Result': x_center ... }
        self.median_line_height = 0.0
        self.test_mappings = self.load_test_mappings()

    def load_test_mappings(self):
        try:
            mapping_path = os.path.join(os.path.dirname(__file__), "config", "test_mapping.json")
            with open(mapping_path, "r", encoding="utf-8") as f:
                return json.load(f).get("mappings", {})
        except Exception as e:
            print(f"Warning: Could not load test mappings: {e}")
            return {}

    def get_test_code(self, ocr_name):
        norm_name = ocr_name.lower().strip()
        # Direct match
        if norm_name in self.test_mappings:
            return self.test_mappings[norm_name]
            
        # Fuzzy match
        # get_close_matches returns a list, we take the best one if score is good
        matches = difflib.get_close_matches(norm_name, self.test_mappings.keys(), n=1, cutoff=0.7)
        if matches:
            best_match = matches[0]
            print(f"Fuzzy Match: '{ocr_name}' -> '{best_match}' ({self.test_mappings[best_match]})")
            return self.test_mappings[best_match]
            
        return None

    def get_reliability_level(self, confidence_score):
        if confidence_score >= 85: return "HIGH"
        if confidence_score >= 60: return "MEDIUM"
        return "LOW"

    def is_mostly_symbols(self, text):
        if not text: return False
        clean_text = text.replace(" ", "")
        if not clean_text: return False
        
        # Valid alphanum (English + Arabic)
        valid_chars = re.findall(r'[a-zA-Z0-9\u0600-\u06FF]', clean_text)
        ratio = len(valid_chars) / len(clean_text)
        
        if ratio < 0.5:
            print(f"DEBUG: Rejected '{text}' as noise (Symbol Density: {ratio:.2f})")
            return True
            
        # Punctuation Density Check
        punct_chars = re.findall(r'[^\w\s\u0600-\u06FF]', text)
        punct_ratio = len(punct_chars) / len(text)
        if punct_ratio > 0.4:
            print(f"DEBUG: Rejected '{text}' as noise (Punct Density: {punct_ratio:.2f})")
            return True
            
        return False

    def is_noise(self, test_name):
        """
        Returns True if the test name looks like noise.
        """
        if not test_name: return True
        test_name = test_name.strip()
        
        # 0. MUST contain at least some letters (e.g. ":-:33" is noise)
        # Search for at least 2 alphabetic characters (English OR Arabic)
        if len(re.findall(r'[a-zA-Z\u0600-\u06FF]', test_name)) < 2:
            # print(f"DEBUG: Rejected '{test_name}' (Not enough letters)") 
            return True
            
        # 0.5 Symbol/Punct Density Check
        if self.is_mostly_symbols(test_name):
            return True
            
        # 0.6 Repeating Characters (e.g. "III", "...")
        if re.search(r'(.)\1{2,}', test_name): # 3 repeated chars
            print(f"DEBUG: Rejected '{test_name}' (Repeating Chars)")
            return True
            
        # 0.7 Garbage Charset (Only numbers + I/l/:/|/!)
        if re.match(r'^[0-9Iil|!:.\-]+$', test_name):
            print(f"DEBUG: Rejected '{test_name}' (Garbage Charset)")
            return True
            
        # 1. Purely numeric or numeric with special chars
        if re.match(r'^[\d\W]+$', test_name): return True
        
        # 2. IDs like U2199
        if re.match(r'^[A-Z][\d-]+$', test_name, re.IGNORECASE): return True
            
        # 3. Leaked Headers/Metadata (Explicit blacklists)
        noise_keywords = [
            "TEST", "NAME", "RESULT", "UNIT", "RANGE", "VALUE", "OBSERVED", 
            "REFERENCE", "REVIEWED", "PAGE", "SIGNATURE", "VERIFIED", "NOTES", "COMMENTS"
        ]
        if any(k in test_name.upper() for k in noise_keywords):
            return True
        
        # 4. Check for "Ratio of X of Y" artifacts (e.g. "of :1")
        if re.search(r'\bof\b\s*[:\d]', test_name, re.IGNORECASE):
             return True
            
        return False

    # Patterns to ignore if found in the "Test Name" column
    METADATA_BLACKLIST = [
        r"patient.*id", r"patient.*name", r"file.*no", r"sample.*id",
        r"reviewed.*by", r"page.*\d", r"signature", r"comment",
        r"report.*date", r"collection.*date",
        r"referred.*by", r"created.*date", r"lab.*id",
        r"reporting.*date", r"sex", r"age",
        r"doctor", r"consultant", r"cdc.*according", r"recommendation"
    ]



    def preprocess_image(self, img, page_num):
        """
        Applies simple preprocessing.
        Disabled manual deskewing as it can interfere with Doctr's orientation detection.
        """
        return img, False

        
    def find_header_row(self, pages):
        """
        Scans pages to find the main table header.
        Keywords: Test Name, Result, Unit, Reference Range
        Fuzzy match: (test|investigation).*(name), (result|value), (unit), (refer.*range)
        Returns: (page_idx, row_geometry, column_map)
        """
        header_patterns = {
            "Test Name": (r"(test|investigation).*(name|parameter)", r"test|name"),
            "Value": (r"(result|value|observed)", r"result|value|observed"),
            "Unit": (r"(unit)", r"unit"),
            "Reference Range": (r"(refer.*range|normal.*values)", r"refer|range|normal")
        }
        
        for p_idx, page in enumerate(pages):
            # Group words into rough lines first to check for header
            words = [w for b in page.blocks for l in b.lines for w in l.words]
            words.sort(key=lambda w: (w.geometry[0][1], w.geometry[0][0]))
            
            if not words: continue
            
            # Simple line grouping
            lines = []
            if words:
                current_line = [words[0]]
                for w in words[1:]:
                    # If vertical distance < 1.5% of page (tuned)
                    if abs(w.geometry[0][1] - current_line[-1].geometry[0][1]) < 0.015:
                        current_line.append(w)

                    else:
                        lines.append(current_line)
                        current_line = [w]
                lines.append(current_line)
            
            for line_words in lines:
                line_text = " ".join([w.value.lower() for w in line_words])
                score = 0
                cols_found = {}
                
                for key, (line_pat, anchor_pat) in header_patterns.items():
                    match = re.search(line_pat, line_text)
                    if match:
                        score += 1
                        # Find anchor...
                        for w in line_words:
                            if re.search(anchor_pat, w.value.lower()):
                                center_x = (w.geometry[0][0] + w.geometry[1][0]) / 2
                                cols_found[key] = center_x
                                break

                if score >= 2: # At least 2 matches
                    print(f"Header found on Page {p_idx+1}: {line_text}")
                    # Calculate bounding box of the header line
                    max_y = max([w.geometry[1][1] for w in line_words])
                    return p_idx, max_y, cols_found
                    
        print("Warning: No clear header found. Using default structure.")
        return 0, 0.15, {"Test Name": 0.1, "Value": 0.4, "Unit": 0.6, "Reference Range": 0.8}

    def calculate_adaptive_threshold(self, pages):
        """
        Calculates median text height for adaptive row grouping.
        """
        heights = []
        for page in pages:
            for b in page.blocks:
                for l in b.lines:
                    for w in l.words:
                        h = w.geometry[1][1] - w.geometry[0][1]
                        heights.append(h)
        
        if not heights: return 0.015
        median = np.median(heights)
        adaptive = median * 0.7 
        print(f"Adaptive Row Threshold: {adaptive:.4f} (Median Height: {median:.4f})")
        return max(0.005, min(0.02, adaptive)) # Safety clamp

    def get_column_ranges(self, anchors):
        # Define ranges centered on anchors with ± tolerance
        # If we have Test Name at 0.1 and Result at 0.5
        # Range for Test Name could be 0 to 0.4
        # Range for Result could be 0.4 to 0.6
        # Using simple midpoint split logic or fixed width
        
        ranges = {}
        sorted_cols = sorted(anchors.items(), key=lambda x: x[1])
        
        for i, (name, center) in enumerate(sorted_cols):
            # Start is midpoint from prev col, or 0
            if i == 0:
                start = 0.0
            else:
                prev_center = sorted_cols[i-1][1]
                start = (prev_center + center) / 2
                
            # End is midpoint to next col, or 1.0
            if i == len(sorted_cols) - 1:
                end = 1.0
            else:
                next_center = sorted_cols[i+1][1]
                end = (center + next_center) / 2
                
            ranges[name] = (start, end)
            
        return ranges

    def extract_patient_name(self, image_path, header_bottom, doc=None):
        """
        Uses EasyOCR (Arabic+English) to extract name.
        Fallback to doc (Doctr) if available.
        """
        # --- Shared Regex Patterns ---
        patt_chars = r"[A-Za-z\s\.\u0600-\u06FF]+"
        searches = [
            # 1. Full Anchor with lookahead keywords
            r"(?:Patient\s*Name|Name)\s*[:\-\.]?\s*(?:\d+[\d:]*\s+)?(" + patt_chars + r"?)\s+(?:ID|Ref|Date|Sex|Age|File|Lab|Coll|Auth|Print|Test|Res|Unit|Visit)",
            # 2. Arabic "Name" (Ism | Al-Ism)
            r"(?:الاسم|اسم المريض)\s*[:\-\.]?\s*(" + patt_chars + r"?)\s+(?:ID|Ref|Date|Sex|Age|File|Lab|Coll|Visit)",
            # 3. Just "Patient Name: Name" (No lookahead enforcement if EOL)
            r"(?:Patient\s*Name|Name)\s*[:\-\.]?\s*(" + patt_chars + r")",
            # Honorifics
            r"(?:Mr\.|Mrs\.|Ms\.|Miss|السيد|السيدة)\s*(" + patt_chars + r")"
        ]

        # --- 1. Try EasyOCR ---
        print(f"DEBUG: Running EasyOCR on {image_path} for name extraction...")
        try:
            reader = easyocr.Reader(['ar', 'en'], gpu=False) # GPU=False for safety on user machine
            
            img = cv2.imread(image_path)
            h, w, _ = img.shape
            crop_h = int(h * 0.33)
            crop_img = img[0:crop_h, 0:w]
            
            results = reader.readtext(crop_img, detail=0, paragraph=True)
            full_text = " ".join(results)
            # print("DEBUG: EasyOCR Raw Header Text:\n" + full_text)
            print(f"DEBUG: Full Text Repr: {repr(full_text)}")
            
            with open(DEBUG_FILE, "a", encoding="utf-8") as f:
                f.write(f"\n--- EasyOCR Extraction for {os.path.basename(image_path)} ---\n")
                f.write(full_text + "\n------------------------------------------------\n")
            
            for i, pattern in enumerate(searches):
                match = re.search(pattern, full_text, re.IGNORECASE)
                if match:
                    extracted = match.group(1).strip()
                    extracted_clean = re.sub(r'[^\w\s\u0600-\u06FF\.]', '', extracted).strip()
                    if len(extracted_clean) > 2:
                        print(f"Found Patient Name (EasyOCR - Pat {i}): {extracted_clean}")
                        return extracted_clean
            
        except Exception as e:
            print(f"Error in EasyOCR name extraction: {e}")

        # --- 2. Fallback to Doctr ---
        if doc:
            print("DEBUG: EasyOCR failed key match. Trying Doctr fallback...")
            try:
                # Aggregate text from Page 0 top 30%
                doctr_text = []
                for page in doc.pages[:1]: # Check first page only
                    for b in page.blocks:
                        if b.geometry[1][1] < 0.35: # Upper part
                             for l in b.lines:
                                 doctr_text.append(" ".join([w.value for w in l.words]))
                
                full_doctr_text = " ".join(doctr_text)
                print(f"DEBUG: Doctr Fallback Text: {full_doctr_text[:100]}...") 

                with open(DEBUG_FILE, "a", encoding="utf-8") as f:
                     f.write(f"\n--- Doctr Fallback Extraction for {os.path.basename(image_path)} ---\n")
                     f.write(full_doctr_text + "\n------------------------------------------------\n")

                for i, pattern in enumerate(searches):
                    match = re.search(pattern, full_doctr_text, re.IGNORECASE)
                    if match:
                        extracted = match.group(1).strip()
                        extracted_clean = re.sub(r'[^\w\s\u0600-\u06FF\.]', '', extracted).strip()
                        if len(extracted_clean) > 2:
                            print(f"Found Patient Name (Doctr - Pat {i}): {extracted_clean}")
                            return extracted_clean

            except Exception as e:
                print(f"Error in Doctr fallback: {e}")

        print("DEBUG: No regex match for patient name (EasyOCR + Doctr).")    
        return None


    def process_document(self, file_path_or_images, patient_manager=None):
        if isinstance(file_path_or_images, str) and file_path_or_images.lower().endswith('.pdf'):
            print(f"Processing PDF: {file_path_or_images}")
            images = convert_from_path(file_path_or_images, poppler_path=r"D:\Release-25.07.0-0\poppler-25.07.0\Library\bin")
            # Save tmp images for doctr
            image_paths = []
            for i, img in enumerate(images):
                path = os.path.join(LOGS_DIR, f"temp_page_{i}.png")
                
                # Check for skew correction 
                open_cv_image = np.array(img) 
                open_cv_image = open_cv_image[:, :, ::-1].copy() # RGB to BGR
                
                processed_img, was_corrected = self.preprocess_image(open_cv_image, i)
                cv2.imwrite(path, processed_img)
                image_paths.append(path)
        elif isinstance(file_path_or_images, list):
             image_paths = file_path_or_images
        else:
             print("Invalid input")
             return [], None

        model = ocr_predictor(pretrained=True, detect_orientation=True)
        doc = model(DocumentFile.from_images(image_paths))
        
        # Header/Config Analysis
        start_page, header_bottom, anchors = self.find_header_row(doc.pages)
        col_ranges = self.get_column_ranges(anchors)
        row_threshold = self.calculate_adaptive_threshold(doc.pages)
        
        # Extract Patient Name from Page 0 (Using EasyOCR on the image)
        first_page_img = image_paths[0]
        raw_patient_name = self.extract_patient_name(first_page_img, header_bottom if start_page == 0 else 0.3, doc)

        
        if not raw_patient_name:
            print("Warning: Could not extract patient name automatically.")
            raw_patient_name = "Unknown Patient"
            
        # Get ID
        patient_id, normalized_name = "UNKNOWN", "UNKNOWN"
        if patient_manager:
            patient_id, normalized_name = patient_manager.get_or_create_id(raw_patient_name)
            print(f"Assigned ID {patient_id} to '{raw_patient_name}'")

        results = []
        
        for p_idx, page in enumerate(doc.pages):
            if p_idx < start_page: continue
            
            words = [w for b in page.blocks for l in b.lines for w in l.words]
            words_below = [w for w in words if w.geometry[0][1] > header_bottom]
            words_below.sort(key=lambda w: (w.geometry[0][1], w.geometry[0][0]))
            
            rows = []
            if words_below:
                current_row = [words_below[0]]
                for w in words_below[1:]:
                    if abs(w.geometry[0][1] - current_row[-1].geometry[0][1]) < row_threshold:
                        current_row.append(w)
                    else:
                        rows.append(current_row)
                        current_row = [w]
                rows.append(current_row)
            
            for row in rows:
                row_cols = {"Test Name": [], "Value": [], "Unit": [], "Reference Range": []}
                row_text_full = " ".join([w.value for w in row])
                
                # Check Footers
                if "signature" in row_text_full.lower() or "professor" in row_text_full.lower():
                     break # Stop processing page on footer
                
                # Geometry Assignment
                for w in row:
                    center_x = (w.geometry[0][0] + w.geometry[1][0]) / 2
                    assigned = False
                    for col_name, (c_start, c_end) in col_ranges.items():
                        if c_start <= center_x <= c_end:
                            row_cols[col_name].append(w.value)
                            assigned = True
                            break
                
                # Extract Text
                name_text = fix_spacing(" ".join(row_cols["Test Name"]))
                val_text = " ".join(row_cols["Value"])
                unit_text = " ".join(row_cols["Unit"])
                ref_text = " ".join(row_cols["Reference Range"])
                
                # BASE ENTRY
                entry = {
                    "Patient_ID": patient_id,
                    "Patient_Name_Normalized": normalized_name,
                    "Test_Code": None,
                    "Test_Name_OCR": name_text,
                    "Value": val_text,
                    "Unit": unit_text,
                    "Reference_Range": ref_text,
                    "Value_Type": None,
                    "Row_Type": "NOISE",
                    "Reliability_Level": "LOW",
                    "Source_Page": f"Page {p_idx+1}"
                }
                
                # Classification Logic
                if not name_text:
                    continue # Skip empty names
                
                clean_name = cleanup_name(name_text)
                
                # --- AGGRESSIVE NOISE FILTERING ---
                if self.is_noise(clean_name):
                    # print(f"Skipping noise row: {clean_name}") 
                    continue
                # ----------------------------------
                
                norm_name = standardize_name(clean_name)
                entry["Test_Name_OCR"] = clean_name # Keep the cleaner version
                entry["Test_Code"] = norm_name if norm_name != clean_name.upper() else clean_name.upper()
                
                # If standardiz_name returned the input upper-cased (no mapping),
                # check if we should keep it. 
                # Ideally we keep it as "UNKNOWN" code but display the name? 
                # User wants "test names full, codes short".
                # My logic: Test_Code = norm_name. 
                pass

                # Check Metadata Metadata
                is_metadata = False
                for pattern in self.METADATA_BLACKLIST:
                    if re.search(pattern, clean_name, re.IGNORECASE):
                        is_metadata = True
                        break
                
                if is_metadata:
                    entry["Row_Type"] = "METADATA"
                    continue # Skip metadata rows in final output

                # Data Validation
                is_valid_val = re.search(r'\d+|negative|positive|reactive', val_text, re.I)
                
                if is_valid_val:
                    entry["Row_Type"] = "DATA"
                    # Canonical Mapping
                    test_code = self.get_test_code(norm_name)
                    entry["Test_Code"] = test_code
                    
                    # Value Type
                    if "%" in unit_text or "%" in val_text:
                        entry["Value_Type"] = "PERCENT" 
                    elif test_code in ["NEUT", "LYMPH", "MONO", "EO", "BASO"] and not "%" in unit_text:
                         entry["Value_Type"] = "ABSOLUTE"
                    else:
                         entry["Value_Type"] = "PRIMARY"
                    
                    # Reliability
                    val_confidences = [w.confidence for w in row if w.value in val_text.split()]
                    avg_conf = sum(val_confidences)/len(val_confidences) if val_confidences else 0.9
                    
                    entry["Reliability_Level"] = self.get_reliability_level(round(avg_conf * 100, 2))
                    
                    results.append(entry)
        
        return results, (patient_id, normalized_name)


if __name__ == "__main__":
    
    # Initialize Patient Manager
    patient_manager = PatientManager()
    
    # Collect PDF files
    if len(sys.argv) > 1:
        target_file = sys.argv[1]
        if os.path.exists(target_file):
            # If full path given
            pdf_files = [os.path.basename(target_file)]
            # Ensure input dir matches or we adjust logic (script assumes INPUT_DIR)
            # Simplest: assume user passes filename in input dir or we just use the name
        elif os.path.exists(os.path.join(INPUT_DIR, target_file)):
            pdf_files = [target_file]
        else:
            print(f"File {target_file} not found.")
            sys.exit(1)
    else:
        pdf_files = [f for f in os.listdir(INPUT_DIR) if f.lower().endswith(".pdf")]
    
    if not pdf_files:
        print(f"No PDF files found in {INPUT_DIR}")
        sys.exit(0)
        
    print(f"Found {len(pdf_files)} PDFs to process.")
    
    ocr = RobustOCR()
    
    master_results = []
    patient_registry = [] # List of tuples/dicts
    
    for pdf_file in pdf_files:
        full_path = os.path.join(INPUT_DIR, pdf_file)
        print(f"\n--- Processing {pdf_file} ---")
        
        # Process and collect results
        file_results, patient_info = ocr.process_document(full_path, patient_manager)
        
        if file_results:
            master_results.extend(file_results)
            
        patient_registry.append({
            "Patient_ID": patient_info[0],
            "Patient_Name_Normalized": patient_info[1],
            "Source_File": pdf_file
        })
        
    # Export to Master Excel
    output_path = os.path.join(OUTPUT_DIR, "Master_Lab_Results.xlsx")
    
    print(f"\nGeneratng Master Excel at {output_path}...")
    
    try:
        with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
            # Sheet 1: Patients
            df_patients = pd.DataFrame(patient_registry).drop_duplicates(subset=["Patient_ID"])
            df_patients.to_excel(writer, sheet_name="Patients", index=False)
            
            # Sheet 2: Results
            if master_results:
                df_results = pd.DataFrame(master_results)
                # Reorder columns for clarity
                cols = ["Patient_ID", "Patient_Name_Normalized", "Test_Name_OCR", "Value", "Unit", "Reference_Range", "Value_Type", "Reliability_Level", "Source_Page"]
                # Filter to only existing cols just in case
                cols = [c for c in cols if c in df_results.columns]
                df_results = df_results[cols]
                
                df_results.to_excel(writer, sheet_name="Results", index=False)
            else:
                pd.DataFrame(["No Data Found"]).to_excel(writer, sheet_name="Results")
                
        print("Success! Master Excel created.")

        # ================= JSON EXPORT (FLUTTER) =================
        json_output_path = os.path.join(OUTPUT_DIR, "Master_Lab_Results.json")
        print(f"Generating Master JSON at {json_output_path}...")

        # Structure data for Flutter (Hierarchical: Patient -> Results)
        # Use camelCase for keys to match standard Dart/Flutter models
        
        json_data = {
            "metadata": {
                "exportDate": pd.Timestamp.now().isoformat(),
                "totalPatients": 0,
                "totalTests": len(master_results)
            },
            "patients": []
        }

        # Group by Patient_ID
        patients_dict = {}
        for p in patient_registry:
            pid = p["Patient_ID"]
            if pid not in patients_dict:
                patients_dict[pid] = {
                    "id": pid,
                    "name": p["Patient_Name_Normalized"],
                    "sourceFiles": [],
                    "results": []
                }
            if p["Source_File"] not in patients_dict[pid]["sourceFiles"]:
                patients_dict[pid]["sourceFiles"].append(p["Source_File"])

        # Add results to patients
        for res in master_results:
            pid = res["Patient_ID"]
            if pid in patients_dict:
                test_entry = {
                    "testName": res["Test_Name_OCR"],
                    "testCode": res["Test_Code"],
                    "value": res["Value"],
                    "unit": res["Unit"],
                    "referenceRange": res["Reference_Range"],
                    "type": res["Value_Type"],
                    "reliability": res["Reliability_Level"],
                    "page": res["Source_Page"]
                }
                patients_dict[pid]["results"].append(test_entry)

        json_data["patients"] = list(patients_dict.values())
        json_data["metadata"]["totalPatients"] = len(json_data["patients"])

        with open(json_output_path, "w", encoding="utf-8") as f:
            json.dump(json_data, f, indent=2, ensure_ascii=False)
        
        print("Success! Master JSON created.")
        
    except Exception as e:
        print(f"Error saving Export: {e}")
