# OCR Medical Report Analyzer

A comprehensive cloud-native system designed to digitize, interpret, and manage medical laboratory reports.

## Overview
This platform bridges the gap between raw medical PDFs and actionable patient data. It leverages advanced Optical Character Recognition (OCR) to extract tabular data from lab reports, standardizes the results using LOINC codes, and securely synchronizes structured medical data with the cloud. Both doctors and patients can access this structured data through a cross-platform mobile application, enriched with AI-generated clinical summaries and automated specialist recommendations. 

Patients and healthcare providers can monitor longitudinal biomarker trends through interactive visualizations, enabling better follow-up and early detection of health changes.

## Architecture

```text
PDF
 │
 ▼
OCR Engine
 │
 ▼
Data Cleaning
 │
 ▼
LOINC Mapping
 │
 ▼
LLM Analysis
 │
 ▼
Firestore
 │
 ├── Patient App
 └── Doctor App
```

## Core Features
1. **Intelligent OCR Parsing:** Automatically extracts complex tabular data from physical or digital medical PDFs using robust row-grouping algorithms.
2. **AI-Powered Clinical Summaries:** Integrates with Large Language Models (LLMs) to generate easy-to-understand, bilingual (English & Arabic) explanations of lab results.
3. **Automated Doctor Recommendations:** Analyzes biomarker deviations to intelligently recommend relevant medical specialists (e.g., Endocrinologist, Hematologist).
4. **Historical Trends:** Interactive charts and visualizations allow patients to track biomarker progress over time.
5. **Real-Time Cloud Sync:** Fully integrated with Google Firebase Firestore for secure, instant data synchronization between the backend and mobile clients.
6. **Bilingual Mobile Application:** A modern Flutter application supporting both English and Arabic.
7. **Biomarker Standardization:** Normalizes varied test names, maps them to standard LOINC codes, and unifies measurement units.
8. **Automated Document Generation:** Generates structured Word documents (`.docx`) and JSON exports for external record keeping.

## Repository Structure

```text
.
├── app/
│   ├── android/
│   ├── ios/
│   ├── lib/
│   └── pubspec.yaml
├── backend/
│   ├── src/
│   ├── docs/
│   └── requirements.txt
├── .gitignore
├── LICENSE
└── README.md
```

## Tech Stack

| Layer | Technologies |
|-------|--------------|
| **Frontend** | Flutter, Dart, Provider |
| **Backend** | Python, Flask |
| **OCR** | Doctr, EasyOCR |
| **AI** | Gemini/OpenAI API |
| **Database** | Firebase Firestore |
| **Visualization** | FL Chart |
| **Documents** | python-docx |

## Quick Start

```bash
# Clone the repository
git clone https://github.com/BasselOthman/ocr-medical-report-analyzer.git

# Backend Setup
cd ocr-medical-report-analyzer/backend
pip install -r src/requirements.txt
# Run the flask/python backend here

# Flutter App Setup
cd ../app
flutter pub get
flutter run
```
*See the individual `app/` and `backend/` directories for advanced configuration and deployment instructions.*
