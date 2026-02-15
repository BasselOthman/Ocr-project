# Firebase Integration Architecture & Usage Guide

## 1. Executive Summary
The OCR pipeline has been upgraded to support **Cloud-Native Data Synchronization**. Instead of relying solely on local Excel/JSON exports, the system now automatically saves structured, patient-centric data to a **Google Firebase Firestore** database. This enables real-time access to medical reports from the mobile application (Flutter) and ensures data persistence and scalability.

---

## 2. System Architecture

The system follows a "Process & Push" architecture:

1.  **Input**: Medical Report Images/PDFs are fed into the OCR Engine.
2.  **Processing**: 
    *   **Text Extraction**: `Doctr` & `EasyOCR` extract raw text.
    *   **Normalization**: Raw text is cleaned and mapped to standard medical codes (e.g., "Haemoglobin" -> `HGB`).
3.  **Data Structuring**: The linear list of results is transformed into a hierarchical Patient -> Report format.
4.  **Cloud Sync**: The structured object is securely uploaded to Firebase Firestore using the Admin SDK.
5.  **Client Access**: The Flutter Mobile App subscribes to the Firestore data to display results in real-time.

---

## 3. Database Schema (Results Structure)

We realized that storing all results in a single flat array was inefficient. The new schema allows for tracking multiple reports over time for the same patient.

**Hierarchy:**
*   **Collection**: `patients`
    *   **Document**: `<Patient_ID>` (e.g., `10001`)
        *   `name`: "BASSEL RAMY..."
        *   `lastUpdated`: timestamp
        *   **Subcollection**: `reports`
            *   **Document**: `<Report_ID>` (e.g., `RPT_10001_172...`)
                *   `timestamp`: "2026-02-14..."
                *   `sourceFile`: "Bassel_results.pdf"
                *   **Field**: `results` (Map)
                    *   `HGB`: `{ "value": 14.5, "unit": "g/dL", "reliability": "HIGH" }`
                    *   `WBC`: `{ "value": 6.5, "unit": "10^3/uL", "reliability": "HIGH" }`

---

## 4. Workflow Logic (Code Explanation)

### Step 1: Initialization
The `FirebaseService` class initializes the connection using the secure **Service Account Key** (`serviceAccountKey.json`). This grants the Python backend "Admin" privileges to write to the database.

### Step 2: Patient Resolution
For every processed document, the system checks if the patient already exists in the `patients` collection.
*   **If Yes**: It updates the "Last Updated" timestamp.
*   **If No**: It creates a new Patient Document.

### Step 3: Report Upload
A unique `Report_ID` is generated. Use of a subcollection (`patients/{id}/reports`) ensures that a patient can have dozens of reports without cluttering the main document or hitting document size limits.

---

## 5. Benefits of this Approach

1.  **Patient History**: By nesting reports under patients, we can easily query "Show me the history of HGB for Patient X".
2.  **Real-Time Sync**: The mobile app can listen to the `patients` collection. As soon as the Python script finishes a PDF, the app updates instantly.
3.  **Data Integrity**: We separate metadata (Source File, Date) from clinical data (Values, Units), making the data cleaner for analysis.
