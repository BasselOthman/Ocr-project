from pdf2image import convert_from_path
from doctr.io import DocumentFile
from doctr.models import ocr_predictor
from doctr.utils.visualization import visualize_page
import pandas as pd
import cv2
import matplotlib.pyplot as plt
import re
import os

# config
pdf_path = r"D:\Grad Project\OCR\Tests-results-60724507178.pdf"   # path to PDF
poppler_path = r"D:\Release-25.07.0-0\poppler-25.07.0\Library\bin"   #popplr path
output_folder = r"D:\Grad Project\OCR\output"   # output folder
os.makedirs(output_folder, exist_ok=True)
# --- DATA STRUCTURES ---
all_results = []

# --- STANDARDIZATION MAPPING (Step 8) ---
test_name_map = {
    "SGPT (ALT)": "ALT",
    "SGPT": "ALT",
    "ALT": "ALT",
    "SGOT (AST)": "AST",
    "SGOT": "AST",
    "AST": "AST",
    "Random Blood Glucose": "RBG",
    "Haemoglobin (EDTA Blood)": "Haemoglobin",
    "Haemoglobin A1C": "HbA1c",
}

def standardize_name(name):
    clean_name = name.strip()
    return test_name_map.get(clean_name, clean_name)

def get_flag(value, ref_range):
    # Very basic parsing for demo purposes
    try:
        val = float(re.findall(r"[\d\.]+", value)[0])
        refs = re.findall(r"[\d\.]+", ref_range)
        if len(refs) == 2:
            low, high = float(refs[0]), float(refs[1])
            if val < low: return "Low"
            if val > high: return "High"
            return "Normal"
    except:
        pass
    return "Unknown"


# 1
print("[1/5] Converting PDF to images")
pages = convert_from_path(pdf_path, poppler_path=poppler_path)
image_paths = []

for i, page in enumerate(pages):
    image_file = os.path.join(output_folder, f"page_{i+1}.png")
    page.save(image_file, "PNG")
    image_paths.append(image_file)

print(f"Converted {len(image_paths)} pages successfully.")

# 2
print("[2/5] Running OCR model.")
model = ocr_predictor(pretrained=True)
all_text = ""

for idx, img_path in enumerate(image_paths, start=1):
    print(f"Processing page {idx}/{len(image_paths)}...")

    # preprocessing for better accurasy
    img = cv2.imread(img_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, thresh = cv2.threshold(gray, 150, 255, cv2.THRESH_BINARY)
    cv2.imwrite(img_path, thresh)

    # loading image to doctr
    doc = DocumentFile.from_images([img_path])
    result = model(doc)

    # Use exported dictionary (not Page object)
    exported = result.export()  # dictionary representation
    page_export = exported["pages"][0]  # the first page as dict

    # visualization
    fig = visualize_page(page_export, img)  # ✅ now valid call
    plt.title(f"OCR Visualization - Page {idx}")
    # plt.show()

    #saving visualization to pc
    output_vis_path = os.path.join(output_folder, f"annotated_page_{idx}.png")
    fig.savefig(output_vis_path)
    plt.close(fig)

    # text extraction
    page_text = " ".join([
        word["value"]
        for block in page_export["blocks"]
        for line in block["lines"]
        for word in line["words"]
    ])
    all_text += page_text + "\n"

    # --- PROCESS PAGE TEXT IMMEDIATELY (Step 3-6) ---
    print(f"   > Extracting data from Page {idx}...")
    
    # Clean text (Step 7)
    curr_text = page_text
    curr_text = re.sub(r"Scan me!.*", "", curr_text, flags=re.IGNORECASE)
    curr_text = re.sub(r"\s+", " ", curr_text)
    curr_text = re.sub(r"Dr\..*?(University|Faculty).*?(?=$|PATIENT)", "", curr_text, flags=re.IGNORECASE)
    curr_text = re.sub(r"(PATIENT NAME|Registered|Collected|Authenticated|Printed).*?(?=Test Name|Complete Blood Picture|Diabetic Profile)", "", curr_text, flags=re.IGNORECASE)

    # Regex Extraction (Step 6)
    pattern = r"([A-Za-z][A-Za-z()/%\s-]*?)\s+([<>]?\d*\.?\d+|Negative|Positive)\s*([a-zA-Zµ/%]+)?\s*([0-9.<>=\-– :a-zA-Z]{1,50})?"
    matches = re.findall(pattern, curr_text)

    for test, result, unit, ref in matches:
        test = test.strip()
        result = result.strip()
        unit = unit.strip()
        ref = ref_range = ref.strip()

        # Filtering noise
        if len(test) < 2 or any(w in test.lower() for w in ["patient", "registered", "collected", "method", "scan", "comment"]):
            continue

        # Standardize Name (Step 8)
        std_name = standardize_name(test)

        # Flagging (Step 10)
        flag = get_flag(result, ref_range)

        all_results.append({
            "Test Name": std_name,
            "Value": result,
            "Unit": unit,
            "Reference Range": ref_range,
            "Flag": flag,
            "Page": idx
        })

print("[3/5] OCR completed successfully!")





# --- EXPORT TO EXCEL (Step 12) ---
if all_results:
    df = pd.DataFrame(all_results)
    # Reorder columns as requested
    df = df[["Test Name", "Value", "Unit", "Reference Range", "Flag", "Page"]]
    
    output_excel = os.path.join(output_folder, "LabResults_Extracted.xlsx")
    df.to_excel(output_excel, index=False)
    print(f"[5/5] ✅ Extracted {len(df)} valid lab tests across {len(image_paths)} pages.")
    print(f"Saved to: {output_excel}")
else:
    print("⚠️ No valid test results extracted.")

print("\nCompleted successfully.")
