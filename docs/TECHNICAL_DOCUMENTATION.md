# OCR Integration Technical Documentation

## 1. Implementation Plan Overview

The goal of this integration was to enable a mobile application to utilize the existing Python-based OCR (Optical Character Recognition) pipeline. Since the OCR logic relies on heavy libraries (Doctr, OpenCV) and runs on a server/backend, we created a **Client-Server Architecture**.

### Architecture
-   **Server (Python)**: Wraps the existing `OCR_robust.py` logic in a REST API using **Flask**. This allows it to receive images over the network.
-   **Client (Flutter)**: A mobile app interface that captures an image (via camera or gallery) and sends it to the server via an HTTP POST request.

---

## 2. Code Explanation

### A. Python Backend (`src/api.py`)

This script is the bridge between the mobile app and the OCR logic.

1.  **Flask Setup**:
    ```python
    app = Flask(__name__)
    ```
    We initialize a Flask web application.

2.  **Configuration**:
    We define where uploaded files should be temporarily saved (`input/`) and where the final Excel report should go (`output/`).

3.  **OCR Initialization**:
    ```python
    ocr = RobustOCR()
    patient_manager = PatientManager()
    ```
    We create instances of your existing classes. This loads the models into memory *once* when the server starts, ensuring fast response times for subsequent requests.

4.  **The API Endpoint (`/upload_report`)**:
    -   **Method**: `POST` (Standard for file uploads).
    -   **Logic**:
        -   It checks if a file is present in the request.
        -   It saves the file with a unique name (using a timestamp) to avoid collisions.
        -   It calls `ocr.process_document(filepath, patient_manager)` to run your extraction logic.
        -   It saves the results to `Master_Lab_Results.xlsx` using pandas, appending to the existing file if it exists.
        -   It returns a JSON response containing the extracted Patient Name, ID, field count, and status.

### B. Flutter App (`flutter_integration/main.dart`)

This simplified app demonstrates how to communicate with the backend.

1.  **Dependencies**:
    -   `image_picker`: Abstract away platform differences for accessing Camera/Gallery.
    -   `http`: Handles the network request to the Python server.

2.  **Configuration**:
    ```dart
    const String API_URL = "http://10.0.2.2:5000/upload_report";
    ```
    This points to the Python server. `10.0.2.2` is a special IP for Android emulators to reach the host PC's `localhost`. For real devices, this must be changed to the PC's Wi-Fi IP (e.g., `192.168.1.5`).

3.  **Image Picking (`_pickImage`)**:
    Uses `ImagePicker` to get a file handle for the photo taken.

4.  **Uploading (`_uploadImage`)**:
    -   Creates a `MultipartRequest` (standard for file uploads).
    -   Attaches the image file.
    -   Sends the request and awaits the JSON response.
    -   Updates the UI with the extracted Patient Name/ID or an error message.

---

## 3. How It Works Together

1.  **User** opens the App and taps "Take Picture".
2.  **App** captures the image and sends it to `http://<YOUR_IP>:5000/upload_report`.
3.  **Python Server** receives the image, saves it to `input/`.
4.  **RobustOCR** reads the image, detects text, extracts fields (Test Name, Result, Unit, etc.), and identifies the Patient Name.
5.  **Server** appends the data to `output/Master_Lab_Results.xlsx`.
6.  **Server** responds with `200 OK` and JSON data: `{"patient_name": "John Doe", ...}`.
7.  **App** displays "Success! Patient: John Doe".

---

## 4. Next Steps for Production

To move this from a prototype to a real medical app:
1.  **Security**: Add authentication (API Keys or OAuth) to the python server so only authorized apps can send data.
2.  **Hosting**: Deploy the Python script to a cloud server (AWS, Google Cloud, Azure) instead of running it on a local laptop.
3.  **Error Handling**: Improve validation for blurry images or non-lab reports.
