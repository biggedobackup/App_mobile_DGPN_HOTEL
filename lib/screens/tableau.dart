import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_colors.dart';
import '../core/services/auth_service.dart';
import '../core/services/sejour_service.dart';
import '../core/services/sync_service.dart';
import '../core/models/user_model.dart';

// ─── Modèle d'une stat card ────────────────────────────────────────────────
class _StatItem {
  final String id;
  final IconData icon;
  final String label;
  final String value;
  final String route;
  final Color color;

  const _StatItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.value,
    required this.route,
    required this.color,
  });
}

// ─── Écran principal ────────────────────────────────────────────────────────
class TableauScreen extends StatefulWidget {
  const TableauScreen({super.key});
  @override
  State<TableauScreen> createState() => _TableauScreenState();
}

class _TableauScreenState extends State<TableauScreen> {
  final _sejourService = SejourService();
  final _auth = AuthService();

  Map<String, dynamic> _stats = {
    'nombre_clients_en_sejour': 0,
    'nombre_sorties_clients': 0,
    'nombre_enregistrements_clients': 0,
    'nombre_historique_sejours': 0,
    'nombre_utilisateurs': 0,
    'activites_recentes': [],
  };
  bool _loading = true;
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _loading = true);
    final user = await _auth.getCurrentUser();
    final stats = await _sejourService.getStats();
    if (mounted) {
      setState(() {
        _user = user;
        if (stats != null) _stats = stats;
        _loading = false;
      });
    }
  }

  Future<void> _refresh() => _chargerDonnees();

  // ── Stats filtrées par rôle (comme React) ──────────────────────────────
  List<_StatItem> _getStats() {
    final d = _stats;
    final bool isGerant = _user?.role == 'GERANT_HOTEL';

    final all = [
      _StatItem(
        id: 'sorties',
        icon: Icons.logout_outlined,
        label: 'Sortie Clients',
        value: d['nombre_sorties_clients']?.toString() ?? '0',
        route: '/sejour-terminer',
        color: const Color(0xFFF59E0B),
      ),
      _StatItem(
        id: 'actifs',
        icon: Icons.hotel_outlined,
        label: 'Clients en Séjour',
        value: d['nombre_clients_en_sejour']?.toString() ?? '0',
        route: '/sejours-actifs',
        color: AppColors.emerald600,
      ),
      _StatItem(
        id: 'historique',
        icon: Icons.history_outlined,
        label: 'Historique des Séjours',
        value: d['nombre_historique_sejours']?.toString() ?? '0',
        route: '/historique-sejours',
        color: const Color(0xFFEC4899),
      ),
      _StatItem(
        id: 'users',
        icon: Icons.people_outline,
        label: 'Utilisateurs',
        value: d['nombre_utilisateurs']?.toString() ?? '0',
        route: '/utilisateurs',
        color: const Color(0xFF3B82F6),
      ),
    ];

    // Agent : enregistrement + sorties + actifs
    if (_user?.role == 'AGENT_ACCUEIL') {
      return all.where((s) => ['enregistrement', 'sorties', 'actifs'].contains(s.id)).toList();
    }
    // Gérant : tout sauf si non pertinent
    if (isGerant) {
      return all.where((s) => ['enregistrement', 'sorties', 'actifs', 'historique', 'users'].contains(s.id)).toList();
    }
    // Fallback : tout
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'TABLEAU DE BORD',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
            color: AppColors.slate800,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.slate700),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.emerald600))
          : RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.emerald600,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSyncBadge(),
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // ── Section : Stats Cards ──────────────────────────
                    _buildSectionTitle('Statistiques'),
                    const SizedBox(height: 12),
                    _buildStatsGrid(),

                    const SizedBox(height: 28),

                    // ── Section : Actions Rapides (Gérant uniquement) ──
                    if (_user?.role == 'GERANT_HOTEL') ...[
                      _buildSectionTitle('Actions Rapides'),
                      const SizedBox(height: 12),
                      _buildQuickActions(),
                      const SizedBox(height: 28),
                    ],

                    // ── Section : Activités Récentes ───────────────────
                    _buildSectionTitle('Activités Récentes'),
                    const SizedBox(height: 12),
                    _buildRecentActivities(),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Sync Badge ──────────────────────────────────────────────────────────
  Widget _buildSyncBadge() {
    return ValueListenableBuilder(
      valueListenable: Hive.box('sejours_offline').listenable(),
      builder: (context, Box box, _) {
        if (box.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              const Icon(Icons.sync_problem_rounded, color: Color(0xFFD97706), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MODE HORS-LIGNE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD97706),
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      '${box.length} séjour${box.length > 1 ? 's' : ''} en attente.',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF92400E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => SyncService().processQueue(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  minimumSize: const Size(80, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'SYNCHRO',
                  style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final subtitle = (_user?.role == 'AGENT_ACCUEIL' || _user?.role == 'GERANT_HOTEL')
        ? 'Gestion de votre établissement'
        : 'Vue globale';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.emerald50,
            child: Text(
              _user?.initials ?? '?',
              style: GoogleFonts.inter(
                color: AppColors.emerald700,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour,',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _user?.fullName ?? 'Hôtelier',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.emerald100),
            ),
            child: Text(
              (_user?.role ?? '').replaceAll('_', ' '),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.emerald700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Titre de section ───────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppColors.slate400,
        letterSpacing: 2,
      ),
    );
  }

  // ── Grille des stats ───────────────────────────────────────────────────
  Widget _buildStatsGrid() {
    final stats = _getStats();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 6,
        childAspectRatio: 2.8,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildStatCard(stat);
      },
    );
  }

  Widget _buildStatCard(_StatItem stat) {
    return InkWell(
      onTap: () => context.push(stat.route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: stat.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(stat.icon, color: stat.color, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.label.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate400,
                      letterSpacing: 0.2,
                      height: 0.9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    stat.value,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.slate800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 8, color: AppColors.slate300),
          ],
        ),
      ),
    );
  }

  // ── Actions Rapides (Gérant) ───────────────────────────────────────────
  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF059669), Color(0xFF047857)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald600.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions Rapides',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Accès direct aux fonctionnalités',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _quickActionBtn(
                  label: 'Enregistrer',
                  icon: Icons.person_add_outlined,
                  route: '/enregistrement',
                  isWhite: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickActionBtn(
                  label: 'Clients actifs',
                  icon: Icons.hotel_outlined,
                  route: '/sejours-actifs',
                  isWhite: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _quickActionBtn(
                  label: 'Utilisateurs',
                  icon: Icons.people_outline,
                  route: '/utilisateurs',
                  isWhite: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickActionBtn(
                  label: 'Historique',
                  icon: Icons.history_outlined,
                  route: '/historique-sejours',
                  isWhite: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionBtn({
    required String label,
    required IconData icon,
    required String route,
    required bool isWhite,
  }) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isWhite ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: isWhite ? AppColors.emerald700 : Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isWhite ? AppColors.emerald700 : Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Activités Récentes ─────────────────────────────────────────────────
  Widget _buildRecentActivities() {
    final List activities = _stats['activites_recentes'] ?? [];

    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Column(
          children: [
            Icon(Icons.history_outlined, size: 40, color: AppColors.slate200),
            const SizedBox(height: 12),
            Text(
              'Aucune activité récente',
              style: GoogleFonts.inter(color: AppColors.slate400, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(4),
        itemCount: activities.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.slate100),
        itemBuilder: (context, index) {
          final act = activities[index];
          return _activityItem(act);
        },
      ),
    );
  }

  Widget _activityItem(Map<String, dynamic> act) {
    final int? id = act['id'];
    final String nom = act['nom'] ?? 'Client inconnu';
    final String hotel = act['hotel'] ?? '';
    final String date = act['date'] ?? '';
    final String statut = act['statut'] ?? '';

    final bool isActif = statut.toLowerCase().contains('séjour') ||
        statut.toLowerCase().contains('sejour') ||
        statut.toLowerCase().contains('actif');

    final Color dotColor = isActif ? AppColors.emerald600 : const Color(0xFFF59E0B);
    final Color dotBg = isActif ? AppColors.emerald50 : const Color(0xFFFEF3C7);

    return InkWell(
      onTap: id == null ? null : () => context.push('/enregistrement/$id/detail'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // Icône / dot
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: dotBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Nom & hotel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate800,
                    ),
                  ),
                  if (hotel.isNotEmpty)
                    Text(
                      hotel,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.slate500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Date & statut
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statut,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AppColors.slate500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Drawer ─────────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    final bool isGerant = _user?.role == 'GERANT_HOTEL';

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.emerald600),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _user?.initials ?? '?',
                style: const TextStyle(
                  color: AppColors.emerald600,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            accountName: Text(
              _user?.fullName ?? '',
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
            accountEmail: Text(
              _user?.email ?? '',
              style: GoogleFonts.inter(fontSize: 12),
            ),
          ),
          _drawerItem(Icons.dashboard_outlined, 'Tableau de bord', '/tableau', true),
          _drawerItem(Icons.person_add_outlined, 'Enregistrement', '/enregistrement', false),
          _drawerItem(Icons.hotel_outlined, 'Clients en séjour', '/sejours-actifs', false),
          _drawerItem(Icons.check_circle_outline, 'Séjours terminés', '/sejour-terminer', false),
          _drawerItem(Icons.history_outlined, 'Historique des séjours', '/historique-sejours', false),
          if (isGerant)
            _drawerItem(Icons.people_outline, 'Gestion des Utilisateurs', '/utilisateurs', false),
          const Spacer(),
          const Divider(),
          _drawerItem(Icons.person_outline, 'Mon Profil', '/profil', false),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              'DÉCONNEXION',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('DÉCONNEXION'),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULER')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('SE DÉCONNECTER', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _auth.logout();
                if (mounted) context.go('/connexion');
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, String route, bool selected) {
    return ListTile(
      leading: Icon(icon, color: selected ? AppColors.emerald600 : AppColors.slate600),
      title: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          color: selected ? AppColors.emerald600 : AppColors.slate700,
          letterSpacing: 0.5,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (!selected) context.push(route);
      },
      selected: selected,
      selectedTileColor: AppColors.emerald50.withValues(alpha: 0.5),
    );
  }
}
