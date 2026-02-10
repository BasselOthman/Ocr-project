# OCR Project Guide

## 📂 Project Structure

We have organized your project to make it easier to manage:

*   **`input/`**: 📥 **Drop your PDF files here.** The script looks here automatically.
*   **`output/`**: 📤 **Results go here.** Your Excel files (`Robust_LabResults.xlsx`) will be saved here.
*   **`src/`**: ⚙️ **The Code.** Contains `OCR_robust.py` (the main brain) and other utilities.
*   **`logs/`**: 📝 **Debug Info.** Text files like `debug_info.txt` that show what the script is "thinking".
*   **`docs/`**: 📚 **Documentation.** Guides and checklists.
*   **`archive/`**: 📦 **Old Stuff.** Backups and previous tests.

---

## 🚀 How to Run

1.  Place your PDF (e.g., `Bassel_results.pdf`) inside the **`input/`** folder.
2.  Open your terminal in the main folder.
3.  Run the script:
    ```bash
    .\doctr_env\Scripts\python.exe src\OCR_robust.py
    ```
4.  Check **`output/`** for your Excel file!

---

## 🧠 Code Explanation (`OCR_robust.py`)

Here is a simplified plain-English explanation of what the code does:

### 1. Setup & Config
The script starts by looking for the `input`, `output`, and `logs` folders relative to where the script is located.

### 2. Helpers (The Cleanup Crew)
*   **`fix_spacing(text)`**: OCR often sees "H e m o g l o b i n" as separate letters. This function stitches them back into "Hemoglobin".
*   **`cleanup_name(name)`**: Removes noise like random numbers or "x10" chunks that get stuck to test names.

### 3. The `RobustOCR` Class (The Brain)
*   **`process_document()`**: The main manager. It loads the PDF, converts pages to images, and runs the following steps:
    1.  **`find_header_row()`**: It looks at the page to find keywords like "Test Name", "Result", "Unit". This tells it where the table columns are.
    2.  **`calculate_adaptive_threshold()`**: Checks how tall the text is to decide how to group words into lines.
    3.  **Extraction Loop**: It goes through every line *below* the header:
        *   It sees which column each word falls into (Name column? Value column?).
        *   It pieces the text together.
        *   It valiates the data (Is the value a number? Is the name a real test?).
    4.  **`get_flag()`**: Checks if the result is High/Low/Normal based on the reference range.

### 4. Export
Finally, it takes all the valid results and saves them into an Excel file in the `output/` folder.
