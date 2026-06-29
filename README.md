# OCR Medical Report Analyzer

A comprehensive cloud-native system designed to digitize, interpret, and manage medical laboratory reports. 

## Overview
This platform bridges the gap between raw medical PDFs and actionable patient data. It uses advanced Optical Character Recognition (OCR) to extract tabular data from lab reports, standardizes the results using LOINC codes, and syncs everything securely to the cloud. Both doctors and patients can access this structured data through a cross-platform mobile application, complete with AI-generated clinical summaries and automated specialist recommendations.

## Core Features
- **Intelligent OCR Parsing:** Automatically extracts complex tabular data from physical or digital medical PDFs using robust row-grouping algorithms.
- **Biomarker Standardization:** Normalizes varied test names, maps them to standard LOINC codes, and unifies measurement units.
- **AI-Powered Clinical Summaries:** Integrates with Large Language Models (LLMs) to generate easy-to-understand, bilingual (English & Arabic) explanations of lab results.
- **Automated Doctor Recommendations:** Analyzes biomarker deviations to intelligently recommend relevant medical specialists (e.g., Endocrinologist, Hematologist).
- **Real-Time Cloud Sync:** Fully integrated with Google Firebase Firestore for secure, instant data synchronization between the backend and mobile clients.
- **Bilingual Mobile Application:** A modern Flutter application supporting both English and Arabic. It allows doctors to track patient follow-ups and patients to visualize historical health trends via interactive charts.
- **Automated Document Generation:** Generates structured Word documents (`.docx`) and JSON exports for external record keeping.

## Repository Structure
- `/app` - The Flutter mobile application containing the UI, state management, and client-side Firebase logic.
- `/backend` - The Python processing engine, OCR scripts, Flask API endpoints, and LLM pipelines.

## Tech Stack
- **Frontend:** Flutter, Dart, Provider (State Management), FL Chart (Data Visualization)
- **Backend:** Python, Flask, Doctr (Torch), EasyOCR, Pandas, python-docx
- **Cloud & AI:** Firebase (Auth & Firestore), Generative LLM APIs
- **Linting & Code Quality:** `dart format`, `dart analyze`, `black`, `isort`, `flake8`

## Setup & Deployment
*(See the respective `app/` and `backend/` directories for detailed environment setup and deployment instructions)*
