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
  List<Map<String, dynamic>> _latestSurveys = [];
  bool _isLoading = true;

  final String apiUrl = 'https://sijala.biz.id/api/v1/surveys';
  static const Color primaryColor = Color(0xFF1E4CAF);
  static const Color primaryDark = Color(0xFF153B8A);
  static const Color backgroundColor = Color(0xFFF1F5F9);

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

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

          // Menghitung kategori unik
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
            // Ambil maksimal 5 survey terbaru untuk ditampilkan
            _latestSurveys = surveys.take(5).toList();
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

  String _getCategoryName(Map<String, dynamic> survey) {
    if (survey['category_name'] != null &&
        survey['category_name'].toString().isNotEmpty) {
      return survey['category_name'].toString();
    }
    if (survey['category'] is Map && survey['category']['name'] != null) {
      return survey['category']['name'].toString();
    }
    return 'Umum';
  }

  @override
  Widget build(BuildContext context) {
    final String userName = widget.user['name'] ?? widget.user['nama'] ?? 'Surveyor';

    return Scaffold(
      backgroundColor: backgroundColor,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Menghilangkan tombol back
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.analytics_rounded, size: 24),
            SizedBox(width: 10),
            Text(
              "Field Survey",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchDashboardData,
            tooltip: "Perbarui Data",
          ),
        ],
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
              // HEADER BANNER PROFIL
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryColor, primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const CircleAvatar(
                            radius: 28,
                            backgroundColor: Color(0xFFEFF6FF),
                            child: Icon(
                              Icons.person_rounded,
                              size: 32,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Selamat Datang,",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // RINGKASAN DATA SECTION
              const Text(
                "Ringkasan Data",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 14),

              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: "Total Survey",
                            value: _totalSurvey.toString(),
                            icon: Icons.assignment_rounded,
                            badgeColor: const Color(0xFFEFF6FF),
                            iconColor: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildStatCard(
                            title: "Kategori",
                            value: _totalKategori.toString(),
                            icon: Icons.category_rounded,
                            badgeColor: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 28),

              // SECTION: SURVEY TERBARU (Menggantikan Menu Utama)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Survey Terbaru",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go(AppRoutes.surveyDaftar);
                    },
                    child: const Text(
                      "Lihat Semua",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              _isLoading
                  ? const SizedBox.shrink()
                  : _latestSurveys.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.inbox_rounded, size: 40, color: Color(0xFF94A3B8)),
                              SizedBox(height: 8),
                              Text(
                                "Belum ada survey",
                                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _latestSurveys.length,
                          itemBuilder: (context, index) {
                            final survey = _latestSurveys[index];
                            final title = survey['title']?.toString() ?? 'Tanpa Judul';
                            final category = _getCategoryName(survey);
                            final description = survey['description']?.toString() ?? '-';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.assignment_outlined, color: primaryColor),
                                ),
                                title: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        category,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  context.go(AppRoutes.surveyDaftar);
                                },
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),

      // ================= BOTTOM NAVIGATION BAR =================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
              activeIcon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: "Survey",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color badgeColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}