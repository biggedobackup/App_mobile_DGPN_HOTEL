import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/sejour_model.dart';
import '../../core/services/sejour_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/dgpn_image.dart';



class ClientHistoriqueDetailScreen extends StatefulWidget {
  final int clientId;

  const ClientHistoriqueDetailScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<ClientHistoriqueDetailScreen> createState() => _ClientHistoriqueDetailScreenState();
}

class _ClientHistoriqueDetailScreenState extends State<ClientHistoriqueDetailScreen> {
  final _sejourService = SejourService();
  final _authService = AuthService();
  UserModel? _user;
  ClientHistoriqueModel? _historique;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final user = await _authService.getCurrentUser();
    final h = await _sejourService.getClientHistoriqueById(widget.clientId);
    if (mounted) {
      setState(() {
        _user = user;
        _historique = h;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Skeleton(height: 180, borderRadius: 32),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Skeleton(height: 100, borderRadius: 24)),
                  SizedBox(width: 16),
                  Expanded(child: Skeleton(height: 100, borderRadius: 24)),
                ],
              ),
              SizedBox(height: 24),
              ListSkeleton(itemCount: 3),
            ],
          ),
        ),
      );
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.slate800, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
    final String? role = _user?.role;
    final bool restrictMedia = role == 'AGENT_ACCUEIL' || role == 'GERANT_HOTEL';
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
              if (!restrictMedia) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _buildAvatar(),
                ),
                const SizedBox(width: 20),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_historique!.client.prenom} ${_historique!.client.nom}'.toUpperCase(),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.slate800)),
                    if (_historique!.client.nomJeuneFille != null && _historique!.client.nomJeuneFille!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('NÉE ${_historique!.client.nomJeuneFille!}'.toUpperCase(),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.slate500)),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(8)),
                      child: Text(_historique!.client.nationalite.toUpperCase(),
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.emerald700, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: AppColors.slate50),
          Row(
            children: [
              _infoMini(Icons.badge_outlined, 'N° DOCUMENT', _historique!.client.numeroDocument),
              _infoMini(Icons.phone_outlined, 'CONTACT', _historique!.client.contactTelephone),
            ],
          ),
          if ((_historique!.client.adresseComplete?.isNotEmpty ?? false) || (_historique!.client.paysDelivranceDoc?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (_historique!.client.adresseComplete?.isNotEmpty ?? false)
                  _infoMini(Icons.location_on_outlined, 'ADRESSE', _historique!.client.adresseComplete!)
                else
                  const Spacer(),
                if (_historique!.client.paysDelivranceDoc?.isNotEmpty ?? false)
                  _infoMini(Icons.public, 'PAYS DÉLIVRANCE', _historique!.client.paysDelivranceDoc!)
                else
                  const Spacer(),
              ],
            ),
          ],
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
        _statCard('DERNIER PASSAGE', 
          (_historique!.dernierSejourDate.isNotEmpty && _historique!.dernierSejourDate.contains('T')) 
            ? _historique!.dernierSejourDate.split('T')[0] 
            : (_historique!.dernierSejourDate.isNotEmpty ? _historique!.dernierSejourDate : 'N/A'), 
          Icons.calendar_today),

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
              if (isActif && s.dateSortiePrevue != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PRÉVUE', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.emerald600)),
                      Text(s.formattedDateSortiePrevue, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.emerald700)),
                    ],
                  ),
                ),
              if (!isActif && s.dateSortie != null)
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
          if ((s.venantDe != null && s.venantDe!.isNotEmpty) || (s.allantA != null && s.allantA!.isNotEmpty) || (s.moyenTransport != null && s.moyenTransport!.isNotEmpty)) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppColors.slate100),
            ),
            Row(
              children: [
                if (s.venantDe != null && s.venantDe!.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PROVENANCE', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                        Text(s.venantDe!, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.slate700), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                if (s.allantA != null && s.allantA!.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DESTINATION', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                        Text(s.allantA!, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.slate700), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
              ],
            ),
            if ((s.moyenTransport != null && s.moyenTransport!.isNotEmpty) || (s.numeroImmatriculation != null && s.numeroImmatriculation!.isNotEmpty)) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (s.moyenTransport != null && s.moyenTransport!.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TRANSPORT', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                          Text(s.moyenTransport!, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.slate700), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  if (s.numeroImmatriculation != null && s.numeroImmatriculation!.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('IMMATRICULATION', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.slate400)),
                          Text(s.numeroImmatriculation!, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.slate700), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    // On cherche le séjour le plus récent ayant une photo
    final hasPhoto = _historique!.sejours.any((s) => s.photoClient != null && s.photoClient!.isNotEmpty);
    final s = hasPhoto 
        ? _historique!.sejours.firstWhere((s) => s.photoClient != null && s.photoClient!.isNotEmpty)
        : _historique!.sejours.first;

    return DgpnImage(
      url: s.photoClient,
      localUuid: s.identifiantUnique,
      type: DgpnImageType.photo,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      placeholderIcon: Icons.person,
    );
  }
}
