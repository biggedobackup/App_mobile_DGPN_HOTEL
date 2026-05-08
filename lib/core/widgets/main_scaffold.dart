import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  const MainScaffold({super.key, required this.child, required this.currentIndex});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _userRole = prefs.getString('user_role') ?? '');
  }

  List<Map<String, dynamic>> get _items {
    final bool isGerant = _userRole == 'GERANT_HOTEL';
    return [
      {'label': 'Tableau de Bord', 'icon': Icons.dashboard_rounded, 'route': '/tableau'},
      {'label': 'Enregistrer séjour', 'icon': Icons.person_add_alt_1_rounded, 'route': '/enregistrement'},
      {'label': 'Séjours en cours', 'icon': Icons.bed_rounded, 'route': '/sejours-actifs'},
      {'label': 'Sorties prévues', 'icon': Icons.logout_rounded, 'route': '/sejour-terminer'},
      if (isGerant) {'label': 'Gestion des Utilisateurs', 'icon': Icons.people_rounded, 'route': '/utilisateurs'},
      {'label': 'Profil', 'icon': Icons.account_circle_rounded, 'route': '/profil'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF059669),
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 30,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.hotel, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'DGPN HÔTEL',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final isActive = widget.currentIndex == i;
                return GestureDetector(
                  onTap: () {
                    if (!isActive) {
                      Navigator.pushReplacementNamed(
                          context, item['route'] as String);
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFECFDF5)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFF94A3B8),
                          size: 22,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: isActive
                                ? FontWeight.w900
                                : FontWeight.w500,
                            color: isActive
                                ? const Color(0xFF059669)
                                : const Color(0xFF94A3B8),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
