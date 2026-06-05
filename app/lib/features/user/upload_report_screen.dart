import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../l10n/app_localizations.dart';
import '../../features/common/app_colors.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/animated_scale_button.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedFile;
  bool _isPdf = false;
  bool _isUploading = false;

  final TextEditingController _doctorController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Connected via adb reverse tcp:5000 tcp:5000 to reach host's port 5000
  final String apiUrl = 'http://127.0.0.1:5000/upload_report';

  @override
  void dispose() {
    _doctorController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Colors.white,
              surface: AppColors.primary,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) await _cropImage(pickedFile.path);
  }

  Future<void> _pickImageFromCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) await _cropImage(pickedFile.path);
    } else if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.cameraPermissionDenied)));
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<void> _cropImage(String imagePath) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: AppLocalizations.of(context)!.cropReportMargin,
            toolbarColor: AppColors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false),
        IOSUiSettings(title: AppLocalizations.of(context)!.cropReportMargin),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _selectedFile = File(croppedFile.path);
        _isPdf = false;
      });
    }
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _isPdf = true;
      });
    }
  }

  Future<void> _submitToOCR() async {
    if (_selectedFile == null) return;
    setState(() => _isUploading = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        request.fields['user_id'] = user.uid;
      }
      
      // Sending additional metadata if needed by the backend future proofing
      request.fields['doctor'] = _doctorController.text;
      request.fields['description'] = _descController.text;
      request.fields['date'] = _selectedDate.toIso8601String();
      
      request.files.add(
        await http.MultipartFile.fromPath('file', _selectedFile!.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (!mounted) return;
        Navigator.pushNamed(context, '/client/analysis', arguments: jsonResponse);
      } else {
        if (!mounted) return;
        _showErrorDialog(AppLocalizations.of(context)!.uploadFailed, '${AppLocalizations.of(context)!.serverReturnedError} ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(AppLocalizations.of(context)!.connectionError, '${AppLocalizations.of(context)!.couldNotReachServer} $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 28),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.okay, style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInput({
    required String labelText,
    TextEditingController? controller,
    String? initialValue,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Let body extend behind AppBar for glass effect
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.uploadNewReport, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 1, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.meshGradient),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.reportDetails, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2)),
                    const SizedBox(height: 24),
                    
                    // Date Select
                    _buildGlassInput(
                      labelText: AppLocalizations.of(context)!.reportDate,
                      initialValue: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                      readOnly: true,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 20),
                    
                    // Doctor
                    _buildGlassInput(
                      labelText: AppLocalizations.of(context)!.assignedDoctor,
                      controller: _doctorController,
                    ),
                    const SizedBox(height: 20),
                    
                    // Description
                    _buildGlassInput(
                      labelText: AppLocalizations.of(context)!.descriptionOptional,
                      controller: _descController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    
                    Text(AppLocalizations.of(context)!.fileUpload, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2)),
                    const SizedBox(height: 16),

                    // File Actions
                    if (_selectedFile == null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: AnimatedScaleButton(
                              onTap: _pickImageFromCamera,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                                child: Column(children: [const Icon(Icons.camera_alt, color: Colors.white), const SizedBox(height: 8), Text(AppLocalizations.of(context)!.camera, style: const TextStyle(color: Colors.white, fontSize: 12))]),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnimatedScaleButton(
                              onTap: _pickImageFromGallery,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                                child: Column(children: [const Icon(Icons.photo_library, color: Colors.white), const SizedBox(height: 8), Text(AppLocalizations.of(context)!.gallery, style: const TextStyle(color: Colors.white, fontSize: 12))]),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnimatedScaleButton(
                              onTap: _pickPdf,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.2))),
                                child: Column(children: [const Icon(Icons.picture_as_pdf, color: Colors.white), const SizedBox(height: 8), Text(AppLocalizations.of(context)!.pdf, style: const TextStyle(color: Colors.white, fontSize: 12))]),
                              ),
                            ),
                          ),
                        ],
                      )
                    ] else ...[
                       // Show selected file
                       Container(
                         width: double.infinity,
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: Colors.white.withValues(alpha: 0.1),
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
                         ),
                         child: Row(
                           children: [
                             Icon(_isPdf ? Icons.picture_as_pdf : Icons.image, color: AppColors.accent, size: 32),
                             const SizedBox(width: 16),
                             Expanded(child: Text(_selectedFile!.path.split('/').last, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                             IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => setState(() => _selectedFile = null)),
                           ],
                         )
                       ),
                    ],

                    const SizedBox(height: 32),

                    // Submit Button
                    _isUploading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : AnimatedScaleButton(
                          onTap: _selectedFile == null ? () {} : _submitToOCR,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: _selectedFile == null ? Colors.white.withValues(alpha: 0.3) : AppColors.secondary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(AppLocalizations.of(context)!.startUpload, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
