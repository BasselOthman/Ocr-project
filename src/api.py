import os
from flask import Flask, request, jsonify # type: ignore
from werkzeug.utils import secure_filename # type: ignore
import pandas as pd # type: ignore
from OCR_robust import RobustOCR, PatientManager

app = Flask(__name__)

# --- Configuration ---
UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "input")
OUTPUT_FOLDER = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "output")
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max upload

# Initialize OCR and Patient Manager once
ocr = RobustOCR()
patient_manager = PatientManager()

@app.route('/upload_report', methods=['POST'])
def upload_report():
    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400
        
    if file:
        filename = secure_filename(file.filename)
        # Ensure unique filename to avoid overwrites
        base, ext = os.path.splitext(filename)
        import time
        unique_filename = f"{base}_{int(time.time())}{ext}"
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
        file.save(filepath)
        
        try:
            # Process the image
            print(f"Processing upload: {filepath}")
            # Note: OCR_robust expects a file path or list of paths
            file_results, patient_info = ocr.process_document(filepath, patient_manager)
            
            if not file_results:
                 return jsonify({
                    "message": "Processed but no data extracted.",
                    "patient_id": patient_info[0] if patient_info else "UNKNOWN",
                    "patient_name": patient_info[1] if patient_info else "UNKNOWN"
                }), 200

            # Append to Excel (reusing logic from main block of OCR_robust.py but cleaner)
            output_path = os.path.join(OUTPUT_FOLDER, "Master_Lab_Results.xlsx")
            
            new_df = pd.DataFrame(file_results)
            
            if os.path.exists(output_path):
                try:
                    existing_df = pd.read_excel(output_path)
                    final_df = pd.concat([existing_df, new_df], ignore_index=True)
                except Exception as e:
                    print(f"Error reading existing Excel: {e}")
                    final_df = new_df
            else:
                final_df = new_df
                
            # Save updated Excel
            with pd.ExcelWriter(output_path, engine='openpyxl') as writer:
                # Add patient sheet if possible (simplified here to just results)
                final_df.to_excel(writer, sheet_name="All_Results", index=False)
                
            return jsonify({
                "message": "Success",
                "patient_id": patient_info[0],
                "patient_name": patient_info[1],
                "extracted_count": len(file_results),
                "excel_path": output_path
            }), 200
            
        except Exception as e:
            print(f"Error processing file: {e}")
            return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "running"}), 200

if __name__ == '__main__':
    # Run on 0.0.0.0 to be accessible from other devices on the network
    app.run(host='0.0.0.0', port=5000, debug=True)
