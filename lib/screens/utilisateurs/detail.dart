import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/utilisateur_service.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/skeleton.dart';

class UtilisateurDetailScreen extends StatefulWidget {
  final int userId;
  const UtilisateurDetailScreen({super.key, required this.userId});
  @override
  State<UtilisateurDetailScreen> createState() => _UtilisateurDetailScreenState();
}

class _UtilisateurDetailScreenState extends State<UtilisateurDetailScreen> {
  final _service = UtilisateurService();
  UserModel? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await _service.getUtilisateurById(widget.userId);
      if (mounted) setState(() { _user = user; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Erreur lors du chargement'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.slate700),
        title: Text('DÉTAILS UTILISATEUR',
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5, color: AppColors.slate800)),
        actions: [
          if (_user != null)
            TextButton.icon(
              onPressed: () async {
                await context.push('/utilisateurs/${widget.userId}/modifier');
                _charger();
              },
              icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.emerald600),
              label: Text('MODIFIER', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.emerald600)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Skeleton(height: 120, borderRadius: 16),
                  SizedBox(height: 20),
                  Skeleton(height: 25, width: 200),
                  SizedBox(height: 12),
                  Skeleton(height: 180, borderRadius: 16),
                  SizedBox(height: 20),
                  Skeleton(height: 25, width: 150),
                  SizedBox(height: 12),
                  Skeleton(height: 100, borderRadius: 16),
                ],
              ),
            )
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: AppColors.error.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(_error!, style: GoogleFonts.inter(color: AppColors.slate500)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _charger,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald600),
              child: Text('RÉESSAYER', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final user = _user!;
    final bool isGerant = user.role == 'GERANT_HOTEL';
    final bool actif = user.isActif ?? true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête profil
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.slate100),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: isGerant ? AppColors.emerald100 : AppColors.slate100,
                      child: Text(user.initials,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 20,
                              color: isGerant ? AppColors.emerald700 : AppColors.slate700)),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 16, height: 16,
                        decoration: BoxDecoration(
                          color: actif ? AppColors.success : AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName.toUpperCase(),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.slate800)),
                      const SizedBox(height: 4),
                      Text(user.email, style: GoogleFonts.inter(fontSize: 12, color: AppColors.slate500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isGerant ? AppColors.emerald50 : AppColors.slate50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isGerant ? AppColors.emerald100 : AppColors.slate200),
                            ),
                            child: Text(user.role.replaceAll('_', ' '),
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900,
                                    color: isGerant ? AppColors.emerald700 : AppColors.slate600, letterSpacing: 0.5)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: actif ? AppColors.emerald50 : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(actif ? 'ACTIF' : 'INACTIF',
                                style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900,
                                    color: actif ? AppColors.emerald700 : AppColors.error)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 01 - Informations personnelles
          _buildSectionTitle('01', 'Informations personnelles', AppColors.emerald600, const Color(0xFFD1FAE5)),
          const SizedBox(height: 12),
          _buildInfoCard([
            _infoRow(Icons.person_outline, 'NOM', user.nom),
            _infoRow(Icons.person_outline, 'PRÉNOM', user.prenom),
            _infoRow(Icons.email_outlined, 'EMAIL', user.email),
            _infoRow(Icons.phone_outlined, 'TÉLÉPHONE', user.telephone ?? 'N/A'),
          ]),

          const SizedBox(height: 20),

          // Section 02 - Affectation
          _buildSectionTitle('02', 'Affectation', const Color(0xFF3B82F6), const Color(0xFFDBEAFE)),
          const SizedBox(height: 12),
          _buildInfoCard([
            _infoRow(Icons.shield_outlined, 'RÔLE', user.role.replaceAll('_', ' ')),
            _infoRow(Icons.hotel_outlined, 'IDENTIFIANT HÔTEL', user.hotelId?.toString() ?? 'N/A'),
          ]),

          const SizedBox(height: 20),

          // Section 03 - Statut
          _buildSectionTitle('03', 'Informations système', AppColors.slate600, AppColors.slate100),
          const SizedBox(height: 12),
          _buildInfoCard([
            _infoRow(Icons.circle, 'STATUT', actif ? 'Actif' : 'Inactif',
                valueColor: actif ? AppColors.emerald600 : AppColors.error),
            _infoRow(Icons.tag, 'ID UTILISATEUR', '#${user.id}'),
          ]),

          const SizedBox(height: 32),

          // Bouton modifier
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await context.push('/utilisateurs/${widget.userId}/modifier');
                _charger();
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text('MODIFIER CE PROFIL',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w900, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                shadowColor: AppColors.emerald600.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String num, String title, Color color, Color bgColor) {
    return Row(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(num, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: color))),
        ),
        const SizedBox(width: 10),
        Text(title.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate700, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildInfoCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.slate100, indent: 16, endIndent: 16),
        itemBuilder: (_, i) => rows[i],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.slate300),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900,
                    color: AppColors.slate400, letterSpacing: 1)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700,
                    color: valueColor ?? AppColors.slate800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
