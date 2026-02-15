import firebase_admin
from firebase_admin import credentials, firestore
import os
import json
from datetime import datetime

class FirebaseService:
    def __init__(self, cred_path=None):
        if not cred_path:
            # Default to src/config/serviceAccountKey.json
            base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            cred_path = os.path.join(base_dir, "src", "config", "serviceAccountKey.json")
            
        self.db = None
        if os.path.exists(cred_path):
            try:
                cred = credentials.Certificate(cred_path)
                # Check for existing app instance
                try:
                    firebase_admin.get_app()
                except ValueError:
                    firebase_admin.initialize_app(cred)
                self.db = firestore.client()
                print("Firebase initialized successfully.")
            except Exception as e:
                print(f"Error initializing Firebase: {e}")
        else:
            print(f"Warning: Firebase credentials not found at {cred_path}. Firebase upload will be skipped.")

    def upload_report(self, patient_data, report_data, results_list):
        """
        Uploads structured data to Firebase.
        Structure:
        patients/{patient_id}
            - name: ...
            - reports/{report_id}
                - createdAt: ...
                - sourceFile: ...
                - results: { TEST_CODE: { value: ..., unit: ... } }
        """
        if not self.db:
            print("Firebase DB not initialized. Skipping upload.")
            return

        patient_id = patient_data.get("id")
        if not patient_id or patient_id == "UNKNOWN":
            print("Skipping Firebase upload: Invalid Patient ID")
            return

        try:
            # 1. Update Patient
            patient_ref = self.db.collection("patients").document(str(patient_id))
            patient_ref.set({
                "name": patient_data.get("name"),
                "lastUpdated": datetime.now()
            }, merge=True)

            # 2. Prepare Report
            report_data = report_data.get("id")
            results_map = {}
            
            # Convert list of results to a map keyed by Test Code (or Name)
            for res in results_list:
                key = res.get("Test_Code") or res.get("Test_Name_OCR")
                if not key: continue
                
                # Sanitize key for Firestore (no slashes, etc.)
                key = key.replace("/", "_").replace(".", "_")
                
                results_map[key] = {
                    "value": res.get("Value"),
                    "unit": res.get("Unit"),
                    "ref_range": res.get("Reference_Range"),
                    "reliability": res.get("Reliability_Level"),
                    "flag": res.get("Flag", "Normal") # Assuming you might add flags later
                }

            report_payload = {
                "createdAt": datetime.now(),
                "sourceFile": report_data.get("sourceFile"),
                "results": results_map
            }

            # 3. Upload Report
            # Using a subcollection 'reports' under the patient
            reports_ref = patient_ref.collection("reports").document(str(report_id))
            reports_ref.set(report_payload)
            
            print(f"Successfully uploaded Report {report_id} for Patient {patient_id} to Firebase.")

        except Exception as e:
            print(f"Failed to upload to Firebase: {e}")
