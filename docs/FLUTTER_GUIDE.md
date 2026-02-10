# Flutter App Guide: Code Explanation & How to Run

## 1. Simple Code Explanation

The file `main.dart` is the brain of your mobile app. Here is a simple breakdown of what it does:

### The Structure
-   **`MyApp`**: This is the main frame of your app. It sets the title and the color theme (Blue).
-   **`OcrHomePage`**: This is the screen you see. It holds the "State" (data that changes, like the selected image or result text).

### key Features
1.  **Selecting a File**:
    -   We use a **Bottom Sheet** (a menu that slides up) with 3 options:
        -   **PDF**: Uses a tool called `FilePicker` to let you choose a PDF file.
        -   **Camera**: Uses `ImagePicker` to open your camera.
        -   **Gallery**: Uses `ImagePicker` to open your photo gallery.

2.  **Uploading**:
    -   Once you pick a file, the app automatically calls `_uploadFile`.
    -   It wraps the file in a "Multipart Request" (like putting a letter in an envelope) and sends it to your Python server (`192.168.1.16:5000/upload_report`).

3.  **Showing Results**:
    -   If the server says "OK" (Status 200), we show the extracted Patient Name, ID, and count of tests found.
    -   If there is an error, we show a red error message.

---

## 2. How to Run in Android Studio (Step-by-Step)

Since you are new to this, follow these exact steps to run the app on an Android Emulator or your real phone.

### Step 0: Ensure Project Structure (One-Time Setup)
Since you might not have the `android` folder yet:
1.  Open your terminal in the project folder (`d:\Grad Project\OCR\Ocr code\flutter_integration`).
2.  Run: `flutter create .`
    -   This will generate the necessary Android and iOS folders. It is safe to run even if they exist.

### Step 1: Open the Project
1.  Open **Android Studio**.
2.  Click **Open** and select the folder: `D:\Grad Project\OCR\Ocr code\flutter_integration`.
3.  Wait for Android Studio to index the files (processing bar at the bottom).

### Step 2: Install Dependencies
The app needs the extra tools we added (`file_picker`, `image_picker`, `http`).
1.  Open the file `pubspec.yaml` (it's in the project root).
2.  Look for a bar at the top of the editor window that says **"Pub get"**. Click it.
    -   *Alternative*: Open the **Terminal** tab (at the bottom) and type: `flutter pub get` and hit Enter.

### Step 3: Configure Android (Important for new apps)
Since we added `image_picker` (Camera) and `file_picker` (Files), we might need to enable them, but usually for basic debugging, the default settings work.
*Note: If build fails with `minSdkVersion` error, open `android/app/build.gradle` (which was created in Step 0) and change `minSdkVersion 16` (or similar) to `minSdkVersion 21`.*

### Step 4: Start the Python Server
Your app needs to talk to your computer.
1.  Open your command prompt or VS Code terminal.
2.  Navigate to your python code folder.
3.  Run your API: `python src/api.py`
4.  **CRITICAL**: Ensure your computer and phone are on the **SAME WiFi**.
5.  Check your computer's IP address:
    -   Open CMD, type `ipconfig`.
    -   Find "IPv4 Address" (e.g., `192.168.1.16`).
    -   Update line 14 in `main.dart` with this IP: `const String API_URL = "http://192.168.1.16:5000/upload_report";`

### Step 5: Run the App
1.  **Select Device**: In the top toolbar of Android Studio, you should see a dropdown menu with devices. Select "Pixel 3a API 30" (or any emulator) or plug in your real Android phone.
2.  **Run**: Click the green **Play** button (▶) next to the device name.
3.  Wait! The first build can take 1-3 minutes. Watch the "Run" tab at the bottom.

### Troubleshooting
-   **"Connection Refused"**: The phone cannot see the computer.
    -   Disable PC Firewall temporarily.
    -   Ensure correct IP in `main.dart`.
-   **"MissingPluginException"**: Stop the app (Red Square ■) and run it again (Green Play ▶). This happens when adding new packages.

You are now ready to test! Click the camera icon and try taking a picture of a lab report.
