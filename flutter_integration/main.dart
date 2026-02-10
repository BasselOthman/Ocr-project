import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // Add this package in pubspec.yaml
import 'package:http/http.dart' as http;

// ---------------------------------------------------------------------------
// CONFIGURATION
// ---------------------------------------------------------------------------
// REPLACE THIS URL with your computer's local IP address.
// Android Emulator: 10.0.2.2
// iOS Simulator: 127.0.0.1
// Real Device: 192.168.x.x (run 'ipconfig' or 'ifconfig' on PC to find)
const String API_URL = "http://10.0.2.2:5000/upload_report"; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the debug banner
      title: 'OCR App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), // Modern color scheme
        useMaterial3: true,
      ),
      home: const OcrHomePage(),
    );
  }
}

class OcrHomePage extends StatefulWidget {
  const OcrHomePage({super.key});

  @override
  State<OcrHomePage> createState() => _OcrHomePageState();
}

class _OcrHomePageState extends State<OcrHomePage> {
  // Tools for picking files and images
  final ImagePicker _imagePicker = ImagePicker();
  
  // State variables to show on screen
  File? _selectedFile;
  String? _selectedFileName;
  bool _isUploading = false;
  String? _resultText;
  String? _errorText;

  // 1. Function to Pick an Image (Camera or Gallery)
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(source: source);
      if (photo != null) {
        _setFile(File(photo.path), "Image from ${source == ImageSource.camera ? 'Camera' : 'Gallery'}");
      }
    } catch (e) {
      _showError("Error picking image: $e");
    }
  }

  // 2. Function to Pick a PDF
  Future<void> _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'], // Only allow PDFs
      );

      if (result != null && result.files.single.path != null) {
        _setFile(File(result.files.single.path!), result.files.single.name);
      }
    } catch (e) {
      _showError("Error picking PDF: $e");
    }
  }

  // Helper to update state with selected file and auto-upload
  void _setFile(File file, String name) {
    setState(() {
      _selectedFile = file;
      _selectedFileName = name;
      _resultText = null;
      _errorText = null;
    });
    // Auto-upload immediately after selection
    _uploadFile(file);
  }

  // 3. Function to Upload the File to Python Server
  Future<void> _uploadFile(File file) async {
    setState(() {
      _isUploading = true;
      _errorText = null;
    });

    try {
      // Create a multipart request (like a form upload)
      var request = http.MultipartRequest('POST', Uri.parse(API_URL));
      
      // Attach the file
      // Note: We use 'file' as the field name, matching the Python server
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        file.path,
      ));

      // Send the request
      var response = await request.send();

      // Read response
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        
        setState(() {
          // Format the success message
          _resultText = "Success!\n\n"
              "Patient: ${jsonResponse['patient_name'] ?? 'N/A'}\n"
              "ID: ${jsonResponse['patient_id'] ?? 'N/A'}\n"
              "Extracted: ${jsonResponse['extracted_count'] ?? 0} items";
        });
      } else {
        _showError("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Connection Error: $e\n\nMake sure the Python server is running and the IP is correct.");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _errorText = message;
    });
  }

  // 4. Function to Show Bottom Sheet with Options
  void _showSelectionOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.deepPurple), // Modified color to be distinct
                title: const Text('Upload PDF'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _pickPdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Take a Picture'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.green),
                title: const Text('Upload Image'),
                onTap: () {
                  Navigator.pop(context); // Close bottom sheet
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical OCR Upload"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Display Selected File Preview (Icon or Image)
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _selectedFile == null
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("No file selected", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: _selectedFileName!.toLowerCase().endsWith('.pdf')
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
                                  SizedBox(height: 10),
                                  Text("PDF Selected", style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            )
                          : Image.file(_selectedFile!, fit: BoxFit.contain), // Show image if it's an image
                    ),
            ),
            
            const SizedBox(height: 10),
            if (_selectedFileName != null)
              Text("Selected: $_selectedFileName", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 30),

            // Main Action Button
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _showSelectionOptions,
              icon: _isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.add_a_photo),
              label: Text(_isUploading ? "Uploading..." : "Select File / Take Photo"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),

            const SizedBox(height: 30),

            // Results Area
            if (_errorText != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50], 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200)
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorText!, style: TextStyle(color: Colors.red[900]))),
                  ],
                ),
              ),

            if (_resultText != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50], 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200)
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_resultText!, style: TextStyle(color: Colors.green[900], fontSize: 16))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
