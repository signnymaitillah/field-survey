import 'dart:convert';

import 'package:field_survey/screens/auth/register.dart';
import 'package:field_survey/screens/dashboard/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isHidden = true;
  bool isLoading = false;

  // =========================
  // URL API
  // =========================

  final String apiUrl = 'https://sijala.biz.id/api/v1/login';

  // =========================
  // LOGIN
  // =========================

  Future<void> login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // EMAIL KOSONG
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // PASSWORD KOSONG
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password wajib diisi'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // =========================
      // REQUEST API
      // =========================

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('STATUS CODE: ${response.statusCode}');
      print('RESPONSE: ${response.body}');

      // =========================
      // CONVERT RESPONSE
      // =========================

      final data = jsonDecode(response.body);

      // =========================
      // LOGIN BERHASIL
      // =========================

      if (response.statusCode == 200 && data['status'] == true) {
        if (!mounted) return;

        // =========================
        // SIMPAN TOKEN KE MEMORI
        // =========================
        String token =
            data['token'] ??
            data['data']?['token'] ??
            data['access_token'] ??
            '';

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        print('TOKEN SAVED: $token');

        // =========================
        // AMBIL DATA USER
        // =========================

        final Map<String, dynamic> userData = Map<String, dynamic>.from(
          data['data'],
        );

        print('USER DATA: $userData');

        // =========================
        // LOGIN BERHASIL
        // =========================

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil'),
            backgroundColor: Colors.green,
          ),
        );

        // =========================
        // KE DASHBOARD
        // KIRIM DATA USER
        // =========================

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardPage(user: userData),
          ),
        );
      }
      // =========================
      // EMAIL / PASSWORD SALAH
      // =========================
      else {
        if (!mounted) return;

        String message =
            data['message']?.toString() ?? 'Email atau password salah';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('ERROR LOGIN: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat terhubung ke server'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),

            child: Column(
              children: [
                const Icon(Icons.lock_outline, size: 90, color: Colors.blue),

                const SizedBox(height: 20),

                const Text(
                  "Selamat Datang",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Silakan login untuk melanjutkan",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),

                const SizedBox(height: 40),

                // =========================
                // EMAIL
                // =========================
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,

                  decoration: InputDecoration(
                    hintText: "Email",
                    prefixIcon: const Icon(Icons.email),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),

                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // PASSWORD
                // =========================
                TextField(
                  controller: passwordController,
                  obscureText: isHidden,

                  decoration: InputDecoration(
                    hintText: "Password",

                    prefixIcon: const Icon(Icons.lock),

                    suffixIcon: IconButton(
                      icon: Icon(
                        isHidden ? Icons.visibility_off : Icons.visibility,
                      ),

                      onPressed: () {
                        setState(() {
                          isHidden = !isHidden;
                        });
                      },
                    ),

                    filled: true,
                    fillColor: Colors.white,

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),

                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: () {},

                    child: const Text("Lupa Password?"),
                  ),
                ),

                const SizedBox(height: 10),

                // =========================
                // LOGIN BUTTON
                // =========================
                SizedBox(
                  width: double.infinity,
                  height: 50,

                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),

                    child: isLoading
                        ? const SizedBox(
                            width: 25,
                            height: 25,

                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            "LOGIN",

                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // =========================
                // REGISTER
                // =========================
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Text("Belum punya akun?"),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },

                      child: const Text("Daftar"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
