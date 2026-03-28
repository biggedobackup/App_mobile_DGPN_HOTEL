import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../core/services/auth_service.dart';
import '../core/services/utilisateur_service.dart';
import '../core/models/user_model.dart';
import '../core/widgets/custom_button.dart';
import '../core/widgets/custom_text_field.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _auth = AuthService();
  final _userService = UtilisateurService();
  final _formKey = GlobalKey<FormState>();

  UserModel? _user;
  bool _loading = true;
  bool _saving = false;

  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerProfil();
  }

  Future<void> _chargerProfil() async {
    final user = await _userService.getProfil();
    if (mounted) {
      setState(() {
        _user = user;
        if (user != null) {
          _nomCtrl.text = user.nom;
          _prenomCtrl.text = user.prenom;
          _emailCtrl.text = user.email;
          _telCtrl.text = user.telephone ?? '';
        }
        _loading = false;
      });
    }
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    
    final ok = await _userService.updateProfil({
      'nom': _nomCtrl.text.trim(),
      'prenom': _prenomCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'telephone': _telCtrl.text.trim(),
    });

    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Profil mis à jour' : 'Erreur lors de la mise à jour'),
          backgroundColor: ok ? AppColors.emerald600 : AppColors.error,
        ),
      );
      if (ok) _chargerProfil();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Jamais';
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateStr;
    }
  }

  void _showChangePassword() {
    final oldPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool savingPwd = false;
    bool showOld = false;
    bool showNew = false;
    bool showConf = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24, left: 24, right: 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SÉCURITÉ DU COMPTE', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
              const SizedBox(height: 24),
              _buildPwdField(
                label: 'ANCIEN MOT DE PASSE', controller: oldPasswordCtrl,
                show: showOld, onToggle: () => setModalState(() => showOld = !showOld),
              ),
              const SizedBox(height: 12),
              _buildPwdField(
                label: 'NOUVEAU MOT DE PASSE', controller: newPasswordCtrl,
                show: showNew, onToggle: () => setModalState(() => showNew = !showNew),
              ),
              const SizedBox(height: 12),
              _buildPwdField(
                label: 'CONFIRMATION', controller: confirmPasswordCtrl,
                show: showConf, onToggle: () => setModalState(() => showConf = !showConf),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'CHANGER LE MOT DE PASSE',
                isLoading: savingPwd,
                onPressed: () async {
                  if (newPasswordCtrl.text != confirmPasswordCtrl.text) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les mots de passe ne correspondent pas'), backgroundColor: AppColors.error));
                    return;
                  }
                  if (newPasswordCtrl.text.length < 8) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimum 8 caractères'), backgroundColor: AppColors.error));
                    return;
                  }
                  
                  setModalState(() => savingPwd = true);
                  final success = await _auth.changePassword(oldPasswordCtrl.text, newPasswordCtrl.text);
                  
                  if (mounted) {
                    if (success) {
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mot de passe mis à jour'), backgroundColor: AppColors.emerald600));
                    } else {
                      setModalState(() => savingPwd = false);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur: Ancien mot de passe incorrect'), backgroundColor: AppColors.error));
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPwdField({required String label, required TextEditingController controller, required bool show, required VoidCallback onToggle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.slate500, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !show,
          validator: (v) => (v == null || v.isEmpty) ? 'Champ obligatoire' : null,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.slate400, size: 20),
            suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off : Icons.visibility, color: AppColors.slate400, size: 18), onPressed: onToggle),
            filled: true, fillColor: AppColors.slate50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.slate200)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.slate800, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('MON PROFIL', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: AppColors.slate800)),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('DÉCONNEXION', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14)),
                  content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ANNULER')),
                    TextButton(onPressed: () async { 
                      await _auth.logout();
                      if (context.mounted) context.go('/connexion');
                    }, child: const Text('DÉCONNECTER', style: TextStyle(color: AppColors.error))),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.emerald600))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 32),
                  
                  // SECTION INFOS GÉNÉRALES
                  _sectionHeader('INFORMATIONS GÉNÉRALES', Icons.person_outline),
                  const SizedBox(height: 16),
                  _buildCard([
                    CustomTextField(label: 'NOM', controller: _nomCtrl, prefixIcon: Icons.person_outline),
                    const SizedBox(height: 12),
                    CustomTextField(label: 'PRÉNOM', controller: _prenomCtrl, prefixIcon: Icons.person_outline),
                    const SizedBox(height: 12),
                    CustomTextField(label: 'ADRESSE EMAIL', controller: _emailCtrl, prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    CustomTextField(label: 'TÉLÉPHONE', controller: _telCtrl, prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                  ]),
                  
                  const SizedBox(height: 24),
                  
                  // SECTION HABILITATIONS
                  _sectionHeader('HABILITATIONS', Icons.shield_outlined),
                  const SizedBox(height: 16),
                  _buildInfoBox('ÉTABLISSEMENT', _user?.hotelNom ?? 'Non assigné', Icons.business_outlined, color: AppColors.emerald600),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildInfoBox('RÉGION', _user?.regionNom ?? 'N/A', Icons.map_outlined)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInfoBox('PROVINCE', _user?.provinceNom ?? 'N/A', Icons.location_on_outlined)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // SECTION MÉTAMONNÉES
                  _sectionHeader('STATISTIQUES COMPTE', Icons.show_chart_outlined),
                  const SizedBox(height: 16),
                  _buildCard([
                    _buildMetaItem('MEMBRE DEPUIS', _formatDate(_user?.dateCreation), Icons.calendar_today_outlined),
                    const Divider(height: 24, color: AppColors.slate100),
                    _buildMetaItem('DERNIÈRE CONNEXION', _formatDate(_user?.lastLogin), Icons.access_time_outlined),
                  ]),

                  const SizedBox(height: 32),

                  // BOUTON ACTION SÉCURITÉ
                  _settingsItem(
                    icon: Icons.lock_open_outlined,
                    label: 'Changer le mot de passe',
                    onTap: _showChangePassword,
                  ),

                  const SizedBox(height: 32),

                  // BOUTON ENREGISTRER
                  CustomButton(
                    label: 'METTRE À JOUR LE PROFIL',
                    isLoading: _saving,
                    onPressed: _enregistrer,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.emerald600,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.emerald600.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Center(
              child: Text(
                _user?.initials ?? '?',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${_user?.prenom} ${_user?.nom}'.toUpperCase(), 
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.slate800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(8)),
                  child: Text(_user?.roleDisplay ?? _user?.role ?? '', 
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.emerald700, letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.slate400),
        const SizedBox(width: 10),
        Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.slate500, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color != null ? color.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color != null ? color.withValues(alpha: 0.1) : AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color ?? AppColors.slate400),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.slate400, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.slate800)),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: AppColors.slate400),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.slate400, letterSpacing: 1)),
            Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.slate700)),
          ],
        ),
      ],
    );
  }

  Widget _settingsItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.slate600, size: 20),
            const SizedBox(width: 16),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.slate800)),
            const Spacer(),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.slate300),
          ],
        ),
      ),
    );
  }
}

