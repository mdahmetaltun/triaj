import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/models/firestore_models.dart';
import '../services/triage_record_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TriageRecordRepository _recordRepository = TriageRecordRepository();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();

  String? _photoUrl;
  File? _selectedImageFile;
  AppUserProfile? _currentUserProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final profile = await _recordRepository.fetchUserProfile();

      setState(() {
        _currentUserProfile = profile;
        _nameController.text = profile?.name ?? '';
        _surnameController.text = profile?.surname ?? '';
        _institutionController.text = profile?.institution ?? '';
        _professionController.text = profile?.profession ?? '';
        _photoUrl = profile?.photoUrl ?? user.photoURL;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading profile: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fotoğraf seçilemedi: $e')));
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String finalPhotoUrl = _photoUrl ?? '';

      // Upload image if a new one is selected
      if (_selectedImageFile != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');

        final uploadTask = await ref.putFile(_selectedImageFile!);
        finalPhotoUrl = await uploadTask.ref.getDownloadURL();
      }

      // Prepare updated profile
      AppUserProfile updatedProfile;

      if (_currentUserProfile != null) {
        updatedProfile = _currentUserProfile!.copyWith(
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          institution: _institutionController.text.trim(),
          profession: _professionController.text.trim(),
          photoUrl: finalPhotoUrl,
        );
      } else {
        // Create new
        updatedProfile = AppUserProfile(
          uid: user.uid,
          email: user.email,
          providerIds: user.providerData.map((e) => e.providerId).toList(),
          name: _nameController.text.trim(),
          surname: _surnameController.text.trim(),
          institution: _institutionController.text.trim(),
          profession: _professionController.text.trim(),
          photoUrl: finalPhotoUrl,
        );
      }

      await _recordRepository.upsertUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil güncellenirken bir hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _institutionController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100 bg
      appBar: AppBar(
        title: const Text(
          "Kullanıcı Profili",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Photo Avatar
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: _selectedImageFile != null
                                ? Image.file(
                                    _selectedImageFile!,
                                    fit: BoxFit.cover,
                                  )
                                : (_photoUrl != null && _photoUrl!.isNotEmpty)
                                ? Image.network(_photoUrl!, fit: BoxFit.cover)
                                : const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ??
                        'Bilinmeyen Kullanıcı',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form Fields mapped like cards
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildTextField(
                          "Adınız",
                          _nameController,
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Soyadınız",
                          _surnameController,
                          Icons.badge_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Kurum",
                          _institutionController,
                          Icons.account_balance_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          "Meslek (Dr., Hemşire vb.)",
                          _professionController,
                          Icons.work_outline,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Değişiklikleri Kaydet",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueGrey, size: 22),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}
