import os
import uuid

import pandas as pd  # type: ignore
from flask import Flask, jsonify, request, send_from_directory  # type: ignore
from werkzeug.utils import secure_filename  # type: ignore

from firebase_service import FirebaseService
from llm_pipeline import generate_clinical_explanation, generate_explanation
from OCR_robust import PatientManager, RobustOCR
from predict_pipeline import get_pipeline

app = Flask(__name__)

# --- Configuration ---
UPLOAD_FOLDER = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "input"
)
OUTPUT_FOLDER = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "output"
)
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

app.config["UPLOAD_FOLDER"] = UPLOAD_FOLDER
app.config["MAX_CONTENT_LENGTH"] = 16 * 1024 * 1024  # 16MB max upload

# Init OCR & Patient Sync & Firebase
ocr = RobustOCR()
patient_manager = PatientManager()
firebase = FirebaseService()
ml_pipeline = get_pipeline()


@app.route("/upload_report", methods=["POST"])
def upload_report():
    if "file" not in request.files:
        return jsonify({"error": "No file part"}), 400

    file = request.files["file"]
    user_id = request.form.get("user_id", "UNKNOWN_USER")
    user_name = request.form.get("user_name", "")

    print(f"--- INCOMING UPLOAD REQUEST ---")
    print(f"Received user_id from Flutter: {user_id}")
    print(f"-------------------------------")

    if file.filename == "":
        return jsonify({"error": "No selected file"}), 400

    if file:
        filename = secure_filename(file.filename)
        # Unique filename
        base, ext = os.path.splitext(filename)
        import time

        unique_filename = f"{base}_{int(time.time())}{ext}"
        filepath = os.path.join(app.config["UPLOAD_FOLDER"], unique_filename)
        file.save(filepath)

        try:
            # Process the image
            print(f"Processing upload: {filepath}")
            # Note: OCR_robust expects a file path or list
            file_results, patient_info = ocr.process_document(filepath, patient_manager)

            if not file_results:
                return (
                    jsonify(
                        {
                            "message": "Processed but no data extracted.",
                            "patient_id": (
                                patient_info[0] if patient_info else "UNKNOWN"
                            ),
                            "patient_name": (
                                patient_info[1] if patient_info else "UNKNOWN"
                            ),
                        }
                    ),
                    200,
                )

            # --- DYNAMIC FLAG CALCULATION ---
            # Using the robust flagging from OCR_robust.py which handles ranges and percentages properly.
            # We only fallback to dynamic calculation if no flag was set.
            import re

            def extract_num(s):
                m = re.search(r"[-+]?\d*\.\d+|\d+", str(s).replace(",", ""))
                return float(m.group()) if m else None

            for res in file_results:
                if (
                    res.get("Flag") in [None, "", "-", "Unknown", "UNKNOWN"]
                    and res.get("Value")
                    and res.get("Reference_Range")
                ):
                    val = extract_num(res.get("Value"))
                    ref_str = str(res.get("Reference_Range"))
                    if val is not None and "-" in ref_str:
                        parts = ref_str.split("-")
                        if len(parts) == 2:
                            ref_min = extract_num(parts[0])
                            ref_max = extract_num(parts[1])
                            if ref_min is not None and ref_max is not None:
                                if val < ref_min:
                                    res["Flag"] = "Low"
                                elif val > ref_max:
                                    res["Flag"] = "High"
                                else:
                                    res["Flag"] = "Normal"

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

            # Firebase Upload
            patient_name = (
                user_name
                if user_name
                else (patient_info[1] if patient_info else "Unknown")
            )

            # If Flutter sent a Firebase user_id, use it. Otherwise fallback to the synthetic OCR patient_id
            final_patient_id = (
                user_id
                if user_id != "UNKNOWN_USER"
                else (patient_info[0] if patient_info else "UNKNOWN")
            )

            report_id = str(uuid.uuid4())[:8]

            # --- PREVIOUS REPORT & COMPARISON ---
            prior_report = firebase.get_previous_report(final_patient_id)
            comparison = None
            if prior_report and "results" in prior_report:
                comparison = {
                    "previous_report_id": prior_report.get("id"),
                    "previous_report_date": (
                        str(prior_report.get("createdAt"))
                        if prior_report.get("createdAt")
                        else None
                    ),
                    "deltas": {},
                }
                prev_results = prior_report["results"]
                for res in file_results:
                    key = res.get("Test_Code") or res.get("Test_Name_OCR")
                    if not key:
                        continue
                    sanitized_key = key.replace("/", "_").replace(".", "_")
                    if sanitized_key in prev_results:
                        try:
                            prev_val_str = prev_results[sanitized_key].get("value", "")
                            curr_val_str = res.get("Value", "")

                            prev_val = extract_num(prev_val_str)
                            curr_val = extract_num(curr_val_str)

                            if prev_val is not None and curr_val is not None:
                                delta = curr_val - prev_val
                                pct = (delta / prev_val) * 100 if prev_val != 0 else 0
                                comparison["deltas"][sanitized_key] = {
                                    "prev_val": prev_val,
                                    "curr_val": curr_val,
                                    "delta": delta,
                                    "percent_change": pct,
                                    "unit": res.get("Unit", ""),
                                }
                        except Exception as e:
                            print(f"Error comparing values for {key}: {e}")

            # --- TOP CONCERNS ---
            top_concerns = []
            for res in file_results:
                flag = res.get("Flag", "Normal")
                if flag not in ["Normal", "Unknown", "-", ""]:
                    test_name = res.get("Test_Code") or res.get(
                        "Test_Name_OCR", "Unknown"
                    )
                    severity = (
                        "Critical"
                        if "Critical" in str(flag)
                        else ("High" if "High" in str(flag) else "Moderate")
                    )
                    top_concerns.append(
                        {
                            "test": test_name,
                            "flag": flag,
                            "severity": severity,
                            "value": res.get("Value", ""),
                            "unit": res.get("Unit", ""),
                        }
                    )
            severity_order = {"Critical": 0, "High": 1, "Moderate": 2}
            top_concerns.sort(key=lambda x: severity_order.get(x["severity"], 3))

            # --- RUN ML PREDICTIONS ---
            print("--- Running PyTorch ML Disease Classification ---")
            predictions = ml_pipeline.predict(file_results, patient_demographics=None)

            # --- RUN LLM NARRATIVE CACHE ---
            print("--- Generating Clinical Explanation ---")
            labs_dict = {
                res.get("Test_Code")
                or res.get("Test_Name_OCR", "Unknown"): res.get("Value", "")
                for res in file_results
            }
            pred_dict = {
                key: val["probability"] * 100 for key, val in predictions.items()
            }

            # Use 'Unknown' for demographic parameters since they are not reliably passed yet.
            import concurrent.futures

            with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
                f1 = executor.submit(
                    generate_explanation,
                    age="Unknown",
                    sex="Unknown",
                    labs=labs_dict,
                    predictions=pred_dict,
                    language="English",
                    prior_comparison=comparison,
                )
                f2 = executor.submit(
                    generate_explanation,
                    age="Unknown",
                    sex="Unknown",
                    labs=labs_dict,
                    predictions=pred_dict,
                    language="Arabic",
                    prior_comparison=comparison,
                )
                f3 = executor.submit(
                    generate_clinical_explanation,
                    labs=labs_dict,
                    predictions=pred_dict,
                    language="English",
                    prior_comparison=comparison,
                )
                f4 = executor.submit(
                    generate_clinical_explanation,
                    labs=labs_dict,
                    predictions=pred_dict,
                    language="Arabic",
                    prior_comparison=comparison,
                )

                try:
                    llm_explanation_en = f1.result(timeout=35.0)
                except Exception as e:
                    print(f"Error or timeout generating English explanation: {e}")
                    llm_explanation_en = "⚠️ *Error: AI explanation in English is temporarily unavailable.*"

                try:
                    llm_explanation_ar = f2.result(timeout=35.0)
                except Exception as e:
                    print(f"Error or timeout generating Arabic explanation: {e}")
                    llm_explanation_ar = "⚠️ *Error: AI explanation in Arabic is temporarily unavailable.*"

                try:
                    llm_clinical_en = f3.result(timeout=35.0)
                except Exception as e:
                    print(f"Error or timeout generating English clinical summary: {e}")
                    llm_clinical_en = "⚠️ *Error: Clinical summary in English is temporarily unavailable.*"

                try:
                    llm_clinical_ar = f4.result(timeout=35.0)
                except Exception as e:
                    print(f"Error or timeout generating Arabic clinical summary: {e}")
                    llm_clinical_ar = "⚠️ *Error: Clinical summary in Arabic is temporarily unavailable.*"

            firebase.upload_report(
                patient_data={"id": final_patient_id, "name": patient_name},
                report_data={"id": report_id, "sourceFile": filename},
                results_list=file_results,
                predictions=predictions,
                explanation_en=llm_explanation_en,
                explanation_ar=llm_explanation_ar,
                clinical_summary_en=llm_clinical_en,
                clinical_summary_ar=llm_clinical_ar,
                top_concerns=top_concerns,
                comparison=comparison,
            )

            # Save updated Excel
            with pd.ExcelWriter(output_path, engine="openpyxl") as writer:
                # Add patient sheet if possible (simplified here to just results)
                final_df.to_excel(writer, sheet_name="All_Results", index=False)

            return (
                jsonify(
                    {
                        "message": "Success",
                        "patient_id": patient_info[0],
                        "patient_name": patient_info[1],
                        "extracted_count": len(file_results),
                        "excel_path": output_path,
                        "predictions": predictions,
                        "explanation_en": llm_explanation_en,
                        "explanation_ar": llm_explanation_ar,
                        "clinical_summary_en": llm_clinical_en,
                        "clinical_summary_ar": llm_clinical_ar,
                        "results": file_results,
                    }
                ),
                200,
            )

        except Exception as e:
            import traceback

            tb = traceback.format_exc()
            print(f"Error processing file: {e}\n{tb}")
            return jsonify({"error": f"{str(e)}\n\nTraceback:\n{tb}"}), 500


@app.route("/health", methods=["GET"])
def health_check():
    return jsonify({"status": "running"}), 200


@app.route("/processed/<path:filename>", methods=["GET"])
def get_processed_image(filename):
    processed_dir = os.path.join(OUTPUT_FOLDER, "processed")
    return send_from_directory(processed_dir, filename)


if __name__ == "__main__":
    # Run on 0.0.0.0 to be accessible from other devices on the network
    app.run(host="0.0.0.0", port=5000, debug=True)
