import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final birthPlaceController = TextEditingController();
  final birthDateController = TextEditingController();

  String? selectedGender;

  bool isLoading = false;

  final String updateProfileUrl = 'https://sijala.biz.id/api/v1/profile';

  @override
  void initState() {
    super.initState();

    nameController.text = widget.user['name']?.toString() ?? '';

    usernameController.text = widget.user['username']?.toString() ?? '';

    emailController.text = widget.user['email']?.toString() ?? '';

    phoneController.text = widget.user['phone']?.toString() ?? '';

    birthPlaceController.text = widget.user['birth_place']?.toString() ?? '';

    birthDateController.text = widget.user['birth_date']?.toString() ?? '';

    final gender = widget.user['gender']?.toString();

    if (gender == 'L' || gender == 'P') {
      selectedGender = gender;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    birthPlaceController.dispose();
    birthDateController.dispose();

    super.dispose();
  }

  // =========================
  // UPDATE PROFILE
  // =========================
  Future<void> updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final token = widget.user['token'];

      final response = await http.put(
        Uri.parse(updateProfileUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': nameController.text.trim(),
          'username': usernameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
          'gender': selectedGender,
          'birth_place': birthPlaceController.text.trim(),
          'birth_date': birthDateController.text.trim(),
        }),
      );

      print('UPDATE PROFILE STATUS: ${response.statusCode}');
      print('UPDATE PROFILE RESPONSE: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['status'] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );

        // Kembali ke halaman profile
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Gagal memperbarui profile',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('UPDATE PROFILE ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================
  // DATE PICKER
  // =========================
  Future<void> selectBirthDate() async {
    DateTime initialDate = DateTime.now();

    if (birthDateController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(birthDateController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        birthDateController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            children: [
              // =========================
              // FOTO PROFILE
              // =========================
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color.fromARGB(255, 0, 131, 238),
                child: Icon(Icons.person, size: 55, color: Colors.white),
              ),

              const SizedBox(height: 25),

              // =========================
              // NAMA
              // =========================
              _buildTextField(
                controller: nameController,
                label: 'Nama',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 15),

              // =========================
              // USERNAME
              // =========================
              _buildTextField(
                controller: usernameController,
                label: 'Username',
                icon: Icons.account_circle_outlined,
              ),

              const SizedBox(height: 15),

              // =========================
              // EMAIL
              // =========================
              _buildTextField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 15),

              // =========================
              // PHONE
              // =========================
              _buildTextField(
                controller: phoneController,
                label: 'Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 15),

              // =========================
              // GENDER
              // =========================
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(
                    Icons.wc_outlined,
                    color: Color.fromARGB(255, 0, 131, 238),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedGender = value;
                  });
                },
              ),

              const SizedBox(height: 15),

              // =========================
              // TEMPAT LAHIR
              // =========================
              _buildTextField(
                controller: birthPlaceController,
                label: 'Tempat Lahir',
                icon: Icons.location_on_outlined,
              ),

              const SizedBox(height: 15),

              // =========================
              // TANGGAL LAHIR
              // =========================
              TextFormField(
                controller: birthDateController,
                readOnly: true,
                onTap: selectBirthDate,
                decoration: InputDecoration(
                  labelText: 'Tanggal Lahir',
                  prefixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    color: Color.fromARGB(255, 0, 131, 238),
                  ),
                  suffixIcon: const Icon(Icons.date_range),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // =========================
              // TOMBOL SIMPAN
              // =========================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 131, 238),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 15),

              // =========================
              // TOMBOL BATAL
              // =========================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // TEXT FIELD
  // =========================
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,

      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color.fromARGB(255, 0, 131, 238)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),

      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label tidak boleh kosong';
        }

        return null;
      },
    );
  }
}
