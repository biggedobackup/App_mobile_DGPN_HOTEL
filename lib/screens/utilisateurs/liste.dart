import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/utilisateur_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/skeleton.dart';

class UtilisateursListeScreen extends StatefulWidget {
  const UtilisateursListeScreen({super.key});
  @override
  State<UtilisateursListeScreen> createState() => _UtilisateursListeScreenState();
}

class _UtilisateursListeScreenState extends State<UtilisateursListeScreen> {
  final _service = UtilisateurService();
  final _auth = AuthService();
  final _searchCtrl = TextEditingController();

  List<UserModel> _all = [];
  List<UserModel> _filtered = [];
  bool _loading = true;
  UserModel? _me;

  @override
  void initState() {
    super.initState();
    _init();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _me = await _auth.getCurrentUser();
    await _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    // On passe la recherche à l'API pour filtrage serveur
    final users = await _service.getUtilisateurs(
      search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
    );
    if (mounted) {
      setState(() {
        _all = users;
        _filtered = List.from(users); // déjà filtrés par l'API
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    // Filtre local en temps réel (pendant la frappe avant de relancer l'API)
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? List.from(_all)
          : _all.where((u) =>
              u.fullName.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q) ||
              u.role.toLowerCase().contains(q)).toList();
    });
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
        title: Text('GESTION DES UTILISATEURS',
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5, color: AppColors.slate800)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _charger),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/utilisateurs/ajouter');
          _charger();
        },
        backgroundColor: AppColors.emerald600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('AJOUTER', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                hintStyle: GoogleFonts.inter(color: AppColors.slate400, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.slate400, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: AppColors.slate400),
                        onPressed: () { _searchCtrl.clear(); _applyFilter(); })
                    : null,
                filled: true,
                fillColor: AppColors.slate50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.emerald600, width: 1.5)),
              ),
            ),
          ),

          // Compteur
          if (!_loading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_filtered.length} utilisateur${_filtered.length > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate400, letterSpacing: 1),
                  ),
                ],
              ),
            ),

          // Liste
          Expanded(
            child: _loading
                ? const SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
                    child: ListSkeleton(itemCount: 8),
                  )
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _charger,
                        color: AppColors.emerald600,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) => _buildCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: AppColors.slate200),
          const SizedBox(height: 16),
          Text('Aucun utilisateur trouvé',
              style: GoogleFonts.inter(color: AppColors.slate400, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCard(UserModel user) {
    final bool isGerant = user.role == 'GERANT_HOTEL';
    final bool estMoi = user.id == _me?.id;
    final bool actif = user.isActif ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await context.push('/utilisateurs/${user.id}/detail');
            _charger();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar avec indicateur de statut
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: isGerant ? AppColors.emerald100 : AppColors.slate100,
                      child: Text(
                        user.initials,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          color: isGerant ? AppColors.emerald700 : AppColors.slate700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: actif ? AppColors.success : AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Infos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.fullName.toUpperCase(),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.slate800),
                            ),
                          ),
                          if (estMoi) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(4)),
                              child: Text('MOI', style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w900, color: AppColors.slate500)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(user.email, style: GoogleFonts.inter(fontSize: 11, color: AppColors.slate500), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isGerant ? AppColors.emerald50 : AppColors.slate50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isGerant ? AppColors.emerald100 : AppColors.slate200),
                        ),
                        child: Text(
                          user.role.replaceAll('_', ' '),
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900,
                              color: isGerant ? AppColors.emerald700 : AppColors.slate600, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                // Boutons d'action
                Column(
                  children: [
                    _iconBtn(Icons.visibility_outlined, AppColors.emerald600, () async {
                      await context.push('/utilisateurs/${user.id}/detail');
                      _charger();
                    }),
                    const SizedBox(height: 6),
                    _iconBtn(Icons.edit_outlined, const Color(0xFF3B82F6), () async {
                      await context.push('/utilisateurs/${user.id}/modifier');
                      _charger();
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
