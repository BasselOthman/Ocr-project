from pdf2image import convert_from_path
from doctr.io import DocumentFile
from doctr.models import ocr_predictor
from doctr.utils.visualization import visualize_page
import pandas as pd
import cv2
import matplotlib.pyplot as plt
import re
import os

# ================= CONFIG =================
pdf_path = r"D:\Grad Project\OCR\Tests-results-60724507178.pdf"
poppler_path = r"D:\Release-25.07.0-0\poppler-25.07.0\Library\bin"
output_folder = os.path.join(os.path.dirname(os.path.abspath(__file__)), "output")
os.makedirs(output_folder, exist_ok=True)

# ================= LOG FILES =================
log_no_name = os.path.join(output_folder, "skipped_no_test_name.txt")
log_failed_val = os.path.join(output_folder, "skipped_failed_validation.txt")
log_attached = os.path.join(output_folder, "attached_lines.txt")
log_debug = os.path.join(output_folder, "processed_lines_debug.txt")

for log in [log_no_name, log_failed_val, log_attached, log_debug]:
    with open(log, "w", encoding="utf-8") as f:
        f.write(f"--- Log Start: {log} ---\n")

# ================= UTILITIES =================
test_name_map = {
    "SGPT (ALT)": "ALT",
    "SGOT (AST)": "AST",
    "Random Blood Glucose": "RBG",
    "Haemoglobin (EDTA Blood)": "Haemoglobin",
    "Haemoglobin A1C": "HbA1c",
}

def standardize_name(name):
    return test_name_map.get(name.strip(), name.strip())

def normalize_arabic_digits(text):
    return text.translate(str.maketrans("٠١٢٣٤٥٦٧٨٩", "0123456789"))

def fix_spacing(text):
    # Fix "H e m o g l o b i n" -> "Hemoglobin"
    # Logic: Merge consecutive single-character words.
    # "I am a boy" -> "I", "am", "a", "boy" (Preserves "I", "a")
    # "H B s A g" -> "HBsAg"
    # "F r e e" -> "Free"
    
    words = text.split(" ")
    new_words = []
    buffer = []

    for w in words:
        if not w: # Handle multiple spaces resulting in empty strings
            continue
            
        if len(w) == 1:
            buffer.append(w)
        else:
            # Buffer has single chars.
            if len(buffer) > 1:
                # Merge them
                new_words.append("".join(buffer))
                buffer = []
            elif len(buffer) == 1:
                # Just one single char, keep it as is (e.g. "Vitamin A")
                new_words.append(buffer[0])
                buffer = []
            
            new_words.append(w)
    
    if len(buffer) > 1:
        new_words.append("".join(buffer))
    elif len(buffer) == 1:
        new_words.append(buffer[0])
        
    return " ".join(new_words)

def cleanup_name(name):
    # Remove "x10..." garbage if it attached to name
    name = re.sub(r'\s*x10.*', '', name, flags=re.IGNORECASE)
    # Remove trailing digits that are likely parts of values (e.g. "Neutrophils 3")
    # But preserve names like "T4" or "HbA1c" (digit attached to letter is fine)
    # Digit separated by space at the end -> remove
    name = re.sub(r'\s+\d+(\.\d+)?$', '', name)
    
    # Specific Fixes for HBsAg, HCV, Free T4
    if "HBs" in name and "Ag" in name:
        return "HBsAg"
    if "HCV" in name and "Ab" in name:
         return "HCVAb"
    if "Free" in name and "T" in name and "1" in name:
        return "Free T4"
        
    # Also handle spaced variants if they occur
    name = name.replace("H B s A g", "HBsAg")
    name = name.replace("H C V A b", "HCVAb")
    
    return name.strip()

def calculate_confidence(ocr_conf, unit, ref_range, value):
    score = 0.4 * ocr_conf
    if unit:
        score += 0.3
    if ref_range:
        score += 0.15
    if re.search(r'\d', value) or value.lower() in ["positive", "negative", "reactive", "non-reactive"]:
        score += 0.15
    return round(score * 100, 2)

def get_flag(value, ref_range):
    v = value.lower()
    r = ref_range.lower()

    if v in ["negative", "non-reactive"]:
        return "NEGATIVE"
    if v in ["positive", "reactive"]:
        return "POSITIVE"

    try:
        val = float(re.findall(r"[\d\.]+", value)[0])
        if "<" in r:
            return "Normal" if val < float(re.findall(r"[\d\.]+", r)[0]) else "High"
        if ">" in r:
            return "Normal" if val > float(re.findall(r"[\d\.]+", r)[0]) else "Low"

        nums = re.findall(r"[\d\.]+", r)
        if len(nums) >= 2:
            low, high = map(float, nums[:2])
            if val < low: return "Low"
            if val > high: return "High"
            return "Normal"
    except:
        pass

    return "Unknown"

# ================= FILTERS =================
def detect_section(text):
    sections = {
        "complete blood picture": "CBC",
        "diabetic profile": "Diabetic Profile",
        "liver function tests": "LFT",
        "kidney function tests": "KFT",
        "thyroid function tests": "TFT",
        "hepatitis markers": "Hepatitis"
    }
    t = text.lower()
    for k, v in sections.items():
        if k in t:
            return v
    return None

def is_ignore_zone(text):
    ignores = [
        "assay method", "patient name", "registered", "collected",
        "authenticated", "printed", "visit number", "scan me",
        "dr.", "professor", "faculty", "university",
        "comment", "test name", "result", "reference range",
        "percent values", "absolute values", "follow up"
    ]
    return any(k in text.lower() for k in ignores)

def is_valid_test_line(text):
    text = normalize_arabic_digits(text)
    return (
        re.search(r'\d+\.?\d*', text)
        and (re.search(r'(mg/dL|g/dL|%|U/L|UIL|pg|fl|x10|Millions|Thousands|cmm)', text, re.I)
             or re.search(r'\d+\.?\d*\s*-\s*\d+\.?\d*', text))
    ) or re.search(r'(positive|negative|reactive|non-reactive)', text, re.I)

def is_interpretation_line(text):
    return text.lower().startswith(("normal:", "prediabetes:", "diabetes:"))

# ================= EXTRACTION =================
def extract_test_from_row(row):
    raw_row_text = " ".join(l["text"] for l in row)
    row_text = normalize_arabic_digits(fix_spacing(raw_row_text))

    confidences = [
        w["confidence"]
        for l in row for w in l.get("words", [])
        if "confidence" in w
    ]
    avg_conf = sum(confidences) / len(confidences) if confidences else 0.5

    value_match = re.search(r'(<|>)?\s*\d+\.?\d*|Negative|Positive|Reactive|Non-Reactive', row_text, re.I)
    if not value_match:
        return None
    value = value_match.group()

    range_match = re.search(r'(\d+\.?\d*\s*-\s*\d+\.?\d*|<\s*\d+\.?\d*|>\s*\d+\.?\d*)', row_text)
    ref_range = range_match.group() if range_match else ""

    unit_match = re.search(r'(mg/dL|g/dL|%|U/L|UIL|pg|fl|x10\^?\d+/L|Millions\s*/\s*cmm|Thousands\s*/\s*cmm|ulu/mL|uIU/mL|u/mL)', row_text, re.I)
    unit = unit_match.group() if unit_match else ""

    temp = row_text
    for x in [value, ref_range, unit]:
        temp = temp.replace(x, " ")

    name_match = re.search(r'[A-Za-z\u0600-\u06FF][A-Za-z0-9\u0600-\u06FF()\- ]{3,}', temp)
    if not name_match:
        with open(log_debug, "a", encoding="utf-8") as f:
            f.write(f"     -> Failed Name Match in: '{temp}'\n")
        return None

    raw_name = name_match.group()
    # Apply cleanup
    cleaned_name = cleanup_name(raw_name)

    test_name = standardize_name(cleaned_name)

    return {
        "Test Name": test_name,
        "Value": value.strip(),
        "Unit": unit.strip(),
        "Reference Range": ref_range.strip(),
        "Flag": get_flag(value, ref_range),
        "Confidence_Score": calculate_confidence(avg_conf, unit, ref_range, value)
    }

# ================= OCR PIPELINE =================
print("[1/2] Converting PDF")
pages = convert_from_path(pdf_path, poppler_path=poppler_path)
images = []

for i, p in enumerate(pages):
    path = os.path.join(output_folder, f"page_{i+1}.png")
    p.save(path, "PNG")
    images.append(path)

print("[2/2] OCR")
model = ocr_predictor(pretrained=True)
all_results = []

for idx, img_path in enumerate(images, start=1):
    img = cv2.imread(img_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, img = cv2.threshold(gray, 150, 255, cv2.THRESH_BINARY)
    cv2.imwrite(img_path, img)

    doc = DocumentFile.from_images([img_path])
    page = model(doc).export()["pages"][0]

    lines = []
    for block in page["blocks"]:
        for line in block["lines"]:
            # Calculate vertical center
            y = (line["geometry"][0][1] + line["geometry"][1][1]) / 2
            # Calculate horizontal start (for sorting within row)
            x = line["geometry"][0][0]
            lines.append({
                "text": " ".join(w["value"] for w in line["words"]),
                "y": y,
                "x": x,
                "words": line["words"]
            })

    # Sort primarily by Y (vertical position)
    lines.sort(key=lambda x: x["y"])

    # Group into rows
    rows = []
    if lines:
        # Start the first row with the first line
        current_row = [lines[0]]
        # Use simple clustering: if next line is close vertically, it's the same row
        for line in lines[1:]:
            # Threshold: 1.5% of page height seems reasonable for standard docs
            if abs(line["y"] - current_row[-1]["y"]) < 0.015:
                current_row.append(line)
            else:
                # Finish current row: sort it horizontally (left to right)
                rows.append(sorted(current_row, key=lambda l: l["x"]))
                current_row = [line]
        # Append the last row
        rows.append(sorted(current_row, key=lambda l: l["x"]))

    current_section = None
    current_test = None

    for row in rows:
        row_text = " ".join(l["text"] for l in row)

        section = detect_section(row_text)
        if section:
            current_section = section
            current_test = None
            continue

        # Apply spacing fix to the row analysis text too
        row_text_clean = fix_spacing(row_text)

        with open(log_debug, "a", encoding="utf-8") as f:
            f.write(f"Page {idx} | Row: {row_text_clean} | Raw: {row_text}\n")

        if is_ignore_zone(row_text_clean):
            with open(log_debug, "a", encoding="utf-8") as f:
                f.write("   -> IGNORED (Zone)\n")
            continue

        # Try to extract as a new test first (Prioritize explicitly named tests)
        extracted_test = None
        if is_valid_test_line(row_text_clean):
            extracted_test = extract_test_from_row(row)
        
        if extracted_test:
            extracted_test["Section"] = current_section or "Unknown"
            extracted_test["Page"] = idx
            extracted_test["Extraction_Status"] = "OK"
            all_results.append(extracted_test)
            current_test = extracted_test
            with open(log_debug, "a", encoding="utf-8") as f:
                f.write(f"   -> EXTRACTED: {extracted_test['Test Name']}\n")
            continue
        
        # If not a named test, check if it's a CBC continuation (Absolute values lines)
        if current_test and current_test["Unit"] == "%" and "x10" in row_text:
            match = re.search(r'(\d+\.?\d*)\s*(x10\^?\d+/L)', row_text, re.I)
            if match:
                current_test["Absolute Value"] = match.group(1)
                current_test["Absolute Unit"] = match.group(2)
                current_test["Extraction_Status"] = "CBC_CONTINUATION"
                with open(log_debug, "a", encoding="utf-8") as f:
                    f.write("   -> CBC_CONTINUATION\n")
            continue

        if is_interpretation_line(row_text_clean) and current_test:
            current_test["Reference Range"] += f"; {row_text}"
            current_test["Extraction_Status"] = "ATTACHED_LINE"
            with open(log_debug, "a", encoding="utf-8") as f:
                f.write("   -> ATTACHED_LINE\n")
        
        else:
            with open(log_debug, "a", encoding="utf-8") as f:
                f.write("   -> SKIPPED (Not Valid Test or Zone)\n")

# ================= EXPORT =================
df = pd.DataFrame(all_results)
df.to_excel(os.path.join(output_folder, "LabResults_Extracted_v2.xlsx"), index=False)

print("✅ DONE — Check Excel and logs")
