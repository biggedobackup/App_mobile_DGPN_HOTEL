import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/sejour_model.dart';
import '../../core/services/sejour_service.dart';

class ClientHistoriqueDetailScreen extends StatefulWidget {
  final String nom;
  final String prenom;
  final String numeroDocument;

  const ClientHistoriqueDetailScreen({
    super.key,
    required this.nom,
    required this.prenom,
    required this.numeroDocument,
  });

  @override
  State<ClientHistoriqueDetailScreen> createState() => _ClientHistoriqueDetailScreenState();
}

class _ClientHistoriqueDetailScreenState extends State<ClientHistoriqueDetailScreen> {
  final _sejourService = SejourService();
  ClientHistoriqueModel? _historique;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final h = await _sejourService.getClientHistorique(widget.nom, widget.prenom, widget.numeroDocument);
    if (mounted) {
      setState(() {
        _historique = h;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.emerald600)));
    }

    if (_historique == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Historique client introuvable')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('HISTORIQUE VOYAGEUR',
            style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2, color: AppColors.slate800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            _buildStatsRow(),
            const SizedBox(height: 24),
            _buildSejoursList(),
          ],
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(_historique!.nomClient[0] + _historique!.prenomClient[0],
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.slate400)),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_historique!.prenomClient} ${_historique!.nomClient}'.toUpperCase(),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.slate800)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(8)),
                      child: Text(_historique!.nationalite.toUpperCase(),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.emerald700, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 48, color: AppColors.slate50),
          Row(
            children: [
              _infoMini(Icons.badge_outlined, 'N° DOCUMENT', _historique!.numeroDocument),
              _infoMini(Icons.phone_outlined, 'CONTACT', _historique!.contactTelephone),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoMini(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.slate400),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.slate700), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('SÉJOURS', _historique!.nombreSejours.toString(), Icons.history),
        const SizedBox(width: 16),
        _statCard('DERNIER PASSAGE', _historique!.dernierSejourDate.split('T')[0], Icons.calendar_today),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.slate100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.emerald600),
            const SizedBox(height: 12),
            Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.slate800)),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 9, color: AppColors.slate400, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSejoursList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 16),
          child: Text('LISTE DES SÉJOURS',
              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.slate400, letterSpacing: 2)),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _historique!.sejours.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _sejourItem(_historique!.sejours[index]),
        ),
      ],
    );
  }

  Widget _sejourItem(SejourModel s) {
    bool isActif = s.statut == 'EN_SEJOUR';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.business, size: 14, color: AppColors.slate400),
                  const SizedBox(width: 8),
                  Text(s.hotelDenomination ?? 'Hôtel inconnu',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.slate800)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActif ? AppColors.emerald50 : AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(isActif ? 'ACTIF' : 'TERMINÉ',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 8, color: isActif ? AppColors.emerald700 : AppColors.slate400)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ARRIVÉE', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                    Text(s.formattedDateArrivee, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.slate700)),
                  ],
                ),
              ),
              if (s.dateSortie != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DÉPART', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                      Text(s.formattedDateSortie, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.slate700)),
                    ],
                  ),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('CHAMBRE', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                  Text(s.numeroChambre, style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.emerald600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
