# Flutter + OCR Integration Guide

## 1. Python Backend Setup

The Python script `src/api.py` acts as a server to receive images from the mobile app and process them.

### Prerequisites
- Python 3.x
- Dependencies installed:
  ```bash
  pip install flask pandas openpyxl opencv-python numpy python-doctr
  ```

### Running the Server
1. Open a terminal in `d:/Grad Project/OCR/Ocr code/src`
2. Run the API:
   ```bash
   python api.py
   ```
3. The server will start on `http://0.0.0.0:5000`.
4. Note your computer's IP address (run `ipconfig` on Windows or `ifconfig` on Mac/Linux). You will need this for the Flutter app.

---

## 2. Flutter App Setup

The Flutter code is located in `d:/Grad Project/OCR/Ocr code/flutter_integration/main.dart`.

### Dependencies
Add the following to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  flutter:
    sdk: flutter
  image_picker: ^1.0.4
  http: ^1.1.0
```

### Configuration
1. Open `flutter_integration/main.dart`.
2. Find the line:
   ```dart
   const String API_URL = "http://10.0.2.2:5000/upload_report"; 
   ```
3. Update the IP address:
   - **Android Emulator**: Use `10.0.2.2` (Default, works out of the box).
   - **iOS Simulator**: Use `127.0.0.1`.
   - **Real Device**: Use your computer's LAN IP (e.g., `192.168.1.5`). *Both devices must be on the same Wi-Fi.*

### Running the App
1. Connect your device or start an emulator.
2. Run:
   ```bash
   flutter run flutter_integration/main.dart
   ```
3. Click "Take Picture" or "Select from Gallery".
4. The image will be sent to the Python server, processed, and the results (Patient Name, ID) will be displayed on the screen.
5. The full data is saved to `d:/Grad Project/OCR/Ocr code/output/Master_Lab_Results.xlsx`.
