import os
from datetime import datetime

import firebase_admin
from firebase_admin import credentials, firestore


class FirebaseService:
    def __init__(self, cred_path=None):
        if not cred_path:
            # Default to src/config/serviceAccountKey.json
            base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            cred_path = os.path.join(
                base_dir, "src", "config", "serviceAccountKey.json"
            )

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
            print(
                f"Warning: Firebase credentials not found at {cred_path}. Firebase upload will be skipped."
            )

    def get_previous_report(self, patient_id):
        if not self.db:
            return None
        try:
            reports = list(
                self.db.collection("patients")
                .document(str(patient_id))
                .collection("reports")
                .order_by("createdAt", direction=firestore.Query.DESCENDING)
                .limit(1)
                .stream()
            )
            if reports:
                report = reports[0].to_dict()
                report["id"] = reports[0].id
                return report
        except Exception as e:
            print(f"Error fetching previous report: {e}")
        return None

    def process_followups(self, patient_id, report_id, results_list, comparison_data):
        if not self.db:
            return
        try:
            # Find active follow-ups
            followups = list(
                self.db.collection("patients")
                .document(str(patient_id))
                .collection("followups")
                .where("status", "==", "pending")
                .stream()
            )
            for f in followups:
                data = f.to_dict()
                tests_to_repeat = data.get("testsToRepeat", [])
                if not tests_to_repeat:
                    continue

                # Check if the new report satisfies the follow-up tests
                outcomes = []
                for test in tests_to_repeat:
                    # Find in current results
                    curr_val = None
                    unit = ""
                    sanitized = test.replace("/", "_").replace(".", "_")
                    for r in results_list:
                        k = r.get("Test_Code") or r.get("Test_Name_OCR", "")
                        if (
                            k.lower() == test.lower()
                            or k.replace("/", "_").replace(".", "_") == sanitized
                        ):
                            curr_val = r.get("Value")
                            unit = r.get("Unit", "")
                            break

                    if curr_val and comparison_data and "deltas" in comparison_data:
                        delta_info = comparison_data["deltas"].get(sanitized)
                        if delta_info:
                            prev_val = delta_info["prev_val"]
                            c_val = delta_info["curr_val"]
                            pct = delta_info["percent_change"]

                            # Determine status (basic logic: assuming lower is better for some, but generally just reporting the change)
                            # We can refine this with biological directionality later.
                            status = "Stable"
                            if pct < -5:
                                status = (
                                    "Improving"
                                    if test.lower()
                                    in [
                                        "glucose",
                                        "hba1c",
                                        "ldl",
                                        "cholesterol",
                                        "creatinine",
                                        "alt",
                                        "ast",
                                    ]
                                    else "Worsening"
                                )
                            elif pct > 5:
                                status = (
                                    "Worsening"
                                    if test.lower()
                                    in [
                                        "glucose",
                                        "hba1c",
                                        "ldl",
                                        "cholesterol",
                                        "creatinine",
                                        "alt",
                                        "ast",
                                    ]
                                    else "Improving"
                                )

                            outcomes.append(
                                {
                                    "test": test,
                                    "previous": prev_val,
                                    "current": c_val,
                                    "unit": unit,
                                    "change_percent": pct,
                                    "status": status,
                                }
                            )

                if outcomes:
                    # Mark as completed
                    f.reference.update(
                        {
                            "status": "completed",
                            "completedAt": datetime.now(),
                            "linkedReportId": report_id,
                            "outcomes": outcomes,
                        }
                    )
                    print(
                        f"Follow-up {f.id} completed automatically with {len(outcomes)} outcomes tracked."
                    )
        except Exception as e:
            print(f"Error processing follow-ups: {e}")

    def upload_report(
        self,
        patient_data,
        report_data,
        results_list,
        predictions=None,
        explanation_en=None,
        explanation_ar=None,
        clinical_summary_en=None,
        clinical_summary_ar=None,
        top_concerns=None,
        comparison=None,
    ):
        """
        Uploads structured data to Firebase.
        Structure:
        patients/{patient_id}
            - name: ...
            - reports/{report_id}
                - createdAt: ...
                - sourceFile: ...
                - results: { TEST_CODE: { value: ..., unit: ... } }
                - predictions: { disease: { probability: ..., is_positive: ... } }
                - explanation_en: "Markdown narrative in English"
                - explanation_ar: "Markdown narrative in Arabic"
                - clinical_summary_en: "Markdown clinical summary in English"
                - clinical_summary_ar: "Markdown clinical summary in Arabic"
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
            patient_ref.set(
                {"name": patient_data.get("name"), "lastUpdated": datetime.now()},
                merge=True,
            )

            # 2. Prepare Report
            report_id = report_data.get("id")
            results_map = {}

            # Convert list of results to a map keyed by Test Code (or Name)
            for res in results_list:
                key = res.get("Test_Code") or res.get("Test_Name_OCR")
                if not key:
                    continue

                # Sanitize key for Firestore (no slashes, etc.)
                key = key.replace("/", "_").replace(".", "_")

                results_map[key] = {
                    "value": res.get("Value"),
                    "unit": res.get("Unit"),
                    "ref_range": res.get("Reference_Range"),
                    "reliability": res.get("Reliability_Level"),
                    "flag": res.get(
                        "Flag", "Normal"
                    ),  # Assuming you might add flags later
                    "loinc_code": res.get("LOINC_Code"),
                    "crop_path": res.get("Crop_Path"),
                }

            report_payload = {
                "createdAt": datetime.now(),
                "sourceFile": report_data.get("sourceFile"),
                "results": results_map,
                "predictions": predictions or {},
                "explanation_en": explanation_en or "",
                "explanation_ar": explanation_ar or "",
                "clinical_summary_en": clinical_summary_en or "",
                "clinical_summary_ar": clinical_summary_ar or "",
            }
            if top_concerns is not None:
                report_payload["top_concerns"] = top_concerns
            if comparison is not None:
                report_payload["comparison"] = comparison

            # 3. Upload Report
            # Using a subcollection 'reports' under the patient
            reports_ref = patient_ref.collection("reports").document(str(report_id))
            reports_ref.set(report_payload)

            print(
                f"Successfully uploaded Report {report_id} for Patient {patient_id} to Firebase."
            )

            # 4. Process Outcomes and Follow-ups
            self.process_followups(patient_id, report_id, results_list, comparison)

        except Exception as e:
            print(f"Failed to upload to Firebase: {e}")
