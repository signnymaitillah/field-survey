import 'dart:convert';
import 'package:field_survey/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/app_routes.dart';
import '../auth/login.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _totalSurvey = 0;
  int _totalKategori = 0;
  bool _isLoading = true;

  // Endpoint API yang sama dengan SurveyPage
  final String apiUrl = 'https://sijala.biz.id/api/v1/surveys';
  static const Color primaryColor = Color(0xFF1E4CAF);

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // Mengambil data survey dari API untuk menghitung total & kategori
  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        await prefs.remove('token');
        await prefs.remove('user');
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
        return;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == true && data['data'] is List) {
          final List rawList = data['data'];
          
          List<Map<String, dynamic>> surveys = rawList
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();

          // Menghitung jumlah kategori unik dari data survey yang diinput
          // Mengecek field kategori (bisa berupa 'category_name' atau 'category')
          final Set<String> uniqueCategories = {};
          for (var survey in surveys) {
            String cat = 'Tanpa Kategori';
            if (survey['category_name'] != null &&
                survey['category_name'].toString().isNotEmpty) {
              cat = survey['category_name'].toString();
            } else if (survey['category'] is Map &&
                survey['category']['name'] != null) {
              cat = survey['category']['name'].toString();
            } else if (survey['category'] != null) {
              cat = survey['category'].toString();
            }
            uniqueCategories.add(cat);
          }

          setState(() {
            _totalSurvey = surveys.length;
            _totalKategori = uniqueCategories.length;
            _isLoading = false;
          });
          return;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mengambil nama user dari parameter (atau fallback ke default)
    final String userName = widget.user['name'] ?? widget.user['nama'] ?? 'Surveyor';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Field Survey Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ================= BODY =================
      body: RefreshIndicator(
        color: primaryColor,
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        size: 35,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Halo, Surveyor!",
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Ringkasan Survey",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),

              const SizedBox(height: 15),

              // Kartu Ringkasan Data (Total Survey & Total Kategori sesuai inputan API)
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildStatisticCard(
                            icon: Icons.assignment,
                            title: "Total Survey",
                            value: _totalSurvey.toString(),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildStatisticCard(
                            icon: Icons.category,
                            title: "Kategori",
                            value: _totalKategori.toString(),
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 30),

              const Text(
                "Menu Utama",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),

              const SizedBox(height: 15),

              // Grid Menu Utama
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildMenuCard(
                    icon: Icons.add_circle_outline,
                    title: "Buat Survey",
                    onTap: () {
                      context.go(AppRoutes.SurveyForm);
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.list_alt,
                    title: "Data Survey",
                    onTap: () {
                      context.go(AppRoutes.surveyDaftar);
                    },
                  ),
                  _buildMenuCard(
                    icon: Icons.map,
                    title: "Peta Lokasi",
                    onTap: () {},
                  ),
                  _buildMenuCard(
                    icon: Icons.bar_chart,
                    title: "Laporan",
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // ================= BOTTOM NAVIGATION BAR =================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRoutes.dashboard);
              break;
            case 1:
              context.go(AppRoutes.surveyDaftar);
              break;
            case 2:
              context.go(AppRoutes.profile);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: "Survey",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: primaryColor),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const BorderSide(color: Color(0xFFE2E8F0)).color),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: primaryColor),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ],
        ),
      ),
    );
  }
}