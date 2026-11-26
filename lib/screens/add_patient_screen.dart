import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/patient.dart';
import '../database/database_helper.dart';
import '../utils/app_theme.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController fatherController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  bool saving = false;
  File? pickedPhoto;

  @override
  void dispose() {
    nameController.dispose();
    fatherController.dispose();
    phoneController.dispose();
    addressController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (picked == null) return;

      setState(() {
        pickedPhoto = File(picked.path);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Could not open camera/gallery: $e")));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              ListTile(
                leading: const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.deepTeal,
                ),
                title: const Text("Take Photo"),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.camera);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.deepTeal,
                ),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(ImageSource.gallery);
                },
              ),

              if (pickedPhoto != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    "Remove Photo",
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => pickedPhoto = null);
                  },
                ),

              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _savePhotoLocally() async {
    if (pickedPhoto == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final patientPhotosDir = Directory(p.join(appDir.path, 'patient_photos'));

    if (!await patientPhotosDir.exists()) {
      await patientPhotosDir.create(recursive: true);
    }

    final fileName =
        'patient_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedPhoto!.path)}';
    final savedPath = p.join(patientPhotosDir.path, fileName);

    await pickedPhoto!.copy(savedPath);

    return savedPath;
  }

  Future<void> savePatient() async {
    if (nameController.text.isEmpty || phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Name and Phone are required")),
      );
      return;
    }

    setState(() => saving = true);

    String? savedPhotoPath = await _savePhotoLocally();

    Patient patient = Patient(
      name: nameController.text,
      fatherName: fatherController.text,
      phone: phoneController.text,
      address: addressController.text,
      email: emailController.text,
      photoPath: savedPhotoPath,
    );

    await DatabaseHelper.insertPatient(patient);

    if (!mounted) return;

    setState(() {
      saving = false;
      pickedPhoto = null;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Patient Saved Successfully")));

    nameController.clear();
    fatherController.clear();
    phoneController.clear();
    addressController.clear();
    emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppDecor.appBar("Add Patient"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onTap: _showPhotoOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.teal.withOpacity(0.12),
                        border: Border.all(
                          color: AppColors.teal.withOpacity(0.4),
                          width: 1.5,
                        ),
                        image: pickedPhoto != null
                            ? DecorationImage(
                                image: FileImage(pickedPhoto!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: pickedPhoto == null
                          ? const Icon(
                              Icons.person,
                              size: 44,
                              color: AppColors.deepTeal,
                            )
                          : null,
                    ),

                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.deepTeal,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            Center(
              child: Text(
                pickedPhoto == null ? "Add Photo (Optional)" : "Change Photo",
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.ink.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppDecor.card,
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: AppDecor.input(
                      "Patient Name",
                      icon: Icons.badge_outlined,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: fatherController,
                    decoration: AppDecor.input(
                      "Father Name",
                      icon: Icons.person_outline,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: AppDecor.input(
                      "Phone Number",
                      icon: Icons.call_outlined,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: addressController,
                    maxLines: 3,
                    decoration: AppDecor.input(
                      "Address",
                      icon: Icons.location_on_outlined,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: AppDecor.input(
                      "Email (Optional)",
                      icon: Icons.mail_outline,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: saving ? null : savePatient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  saving ? "Saving..." : "Save Patient",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
