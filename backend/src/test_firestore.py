import os

import firebase_admin
from firebase_admin import credentials, firestore

base_dir = os.path.dirname(os.path.abspath(__file__))
cred_path = os.path.join(base_dir, "config", "serviceAccountKey.json")

try:
    cred = credentials.Certificate(cred_path)
    try:
        app = firebase_admin.get_app()
    except ValueError:
        app = firebase_admin.initialize_app(cred)

    db = firestore.client()
    patients = db.collection("patients").stream()

    with open("debug_firestore.txt", "w", encoding="utf-8") as f:
        count = 0
        for patient in patients:
            count += 1
            f.write(f"--- PATIENT ID: {patient.id} ---\n")
            try:
                f.write(f"Data: {patient.to_dict()}\n")
            except Exception:
                pass

            reports = (
                db.collection("patients")
                .document(patient.id)
                .collection("reports")
                .stream()
            )
            report_count = 0
            for report in reports:
                report_count += 1
                f.write(f"  -> REPORT: {report.id}\n")
                r_dict = report.to_dict()
                f.write(f"     File: {r_dict.get('sourceFile')}\n")
                f.write(f"     Date: {r_dict.get('createdAt')}\n")
            f.write(f"  Total reports: {report_count}\n\n")

        f.write(f"TOTAL PATIENTS SCANNED: {count}\n")

except Exception as e:
    with open("debug_firestore.txt", "w", encoding="utf-8") as f:
        f.write(f"Error: {str(e)}")
