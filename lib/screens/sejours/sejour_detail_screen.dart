import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/sejour_model.dart';
import '../../core/services/sejour_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SejourDetailScreen extends StatefulWidget {
  final int sejourId;
  const SejourDetailScreen({super.key, required this.sejourId});

  @override
  State<SejourDetailScreen> createState() => _SejourDetailScreenState();
}

class _SejourDetailScreenState extends State<SejourDetailScreen> {
  final _sejourService = SejourService();
  SejourModel? _sejour;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final data = await _sejourService.getSejourById(widget.sejourId);
    if (mounted) {
      setState(() {
        _sejour = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Text(
          'DÉTAILS DU SÉJOUR',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.emerald600))
          : _sejour == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Séjour introuvable', style: GoogleFonts.inter(color: AppColors.slate500)),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final s = _sejour!;
    final bool isActif = s.statut == 'EN_SEJOUR';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(s, isActif),
          const SizedBox(height: 24),
          
          _buildInfoSection('IDENTITÉ DU CLIENT', [
            _buildInfoRow(Icons.work, 'PROFESSION', s.profession),
            _buildInfoRow(Icons.phone, 'TÉLÉPHONE', s.contactTelephone),
            _buildInfoRow(Icons.flag, 'NATIONALITÉ', s.nationalite),
            _buildInfoRow(Icons.cake, 'NAISSANCE', '${s.dateNaissance} à ${s.lieuNaissance}'),
            _buildInfoRow(Icons.home, 'RÉSIDENCE', s.lieuResidence),
          ]),
          
          const SizedBox(height: 16),
          
          _buildInfoSection('DÉTAILS DU SÉJOUR', [
            _buildInfoRow(Icons.business, 'HÔTEL', s.hotelDenomination ?? s.hotel.toString()),
            _buildInfoRow(Icons.hotel, 'CHAMBRE', s.numeroChambre),
            _buildInfoRow(Icons.notes, 'MOTIF', s.motifSejour),
            _buildInfoRow(Icons.login, 'ENTRÉE', s.formattedDateArrivee),
            _buildInfoRow(Icons.logout, 'SORTIE', s.formattedDateSortie),
          ]),

          const SizedBox(height: 16),

          _buildInfoSection('PIÈCE D\'IDENTITÉ', [
            _buildInfoRow(Icons.badge, 'TYPE', s.typeDocument),
            _buildInfoRow(Icons.numbers, 'NUMÉRO', s.numeroDocument),
            const SizedBox(height: 12),
            _buildDocumentScans(s),
          ]),

          const SizedBox(height: 16),

          _buildInfoSection('TRAÇABILITÉ', [
            _buildInfoRow(Icons.person_add, 'ENREGISTRÉ PAR', s.agentEntreeNom ?? 'Inconnu'),
            _buildInfoRow(Icons.schedule, 'DERNIÈRE MAJ', s.dateModification != null ? DateTime.parse(s.dateModification!).toLocal().toString().split('.')[0] : 'N/A'),
            if (s.agentSortieNom != null)
              _buildInfoRow(Icons.person_remove, 'SORTIE VALIDÉE PAR', s.agentSortieNom!),
            if (s.observationsSortie != null && s.observationsSortie!.isNotEmpty)
              _buildInfoRow(Icons.comment, 'OBSERVATIONS', s.observationsSortie!),
          ]),

          const SizedBox(height: 32),
          
          if (isActif)
            CustomButton(
              label: 'ENREGISTRER LA SORTIE',
              color: AppColors.error,
              onPressed: () => _showSortieModal(s),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(SejourModel s, bool isActif) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundImage: s.photoClient != null
                ? CachedNetworkImageProvider(s.photoClient!)
                : null,
            backgroundColor: AppColors.slate50,
            child: s.photoClient == null
                ? const Icon(Icons.person, size: 48, color: AppColors.slate300)
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            s.clientFullName.toUpperCase(),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: AppColors.slate800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActif ? AppColors.emerald50 : AppColors.slate50,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isActif ? AppColors.emerald100 : AppColors.slate200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActif ? AppColors.emerald600 : AppColors.slate400,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isActif ? 'EN SÉJOUR' : 'SÉJOUR TERMINÉ',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 1,
                    color: isActif ? AppColors.emerald700 : AppColors.slate600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentScans(SejourModel s) {
    return Row(
      children: [
        if (s.documentRecto != null)
          Expanded(child: _buildImageThumbnail('RECTO', s.documentRecto!)),
        if (s.documentRecto != null && s.documentVerso != null)
          const SizedBox(width: 12),
        if (s.documentVerso != null)
          Expanded(child: _buildImageThumbnail('VERSO', s.documentVerso!)),
      ],
    );
  }

  Widget _buildImageThumbnail(String label, String url) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: AppColors.slate400,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: AppColors.slate50),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.emerald600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: AppColors.slate400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: AppColors.slate500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortieModal(SejourModel s) {
    final obsController = TextEditingController();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ENREGISTRER LA SORTIE',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Voulez-vous confirmer la sortie de ${s.clientFullName} ?',
                  style: GoogleFonts.inter(
                    color: AppColors.slate500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'OBSERVATIONS DE SORTIE',
                  controller: obsController,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'VALIDER LA SORTIE',
                  color: AppColors.error,
                  isLoading: saving,
                  onPressed: () async {
                    setModalState(() => saving = true);
                    final success = await _sejourService.enregistrerSortie(
                      s.id!,
                      DateTime.now().toIso8601String(),
                      obsController.text,
                    );
                    if (!context.mounted) return;
                    setModalState(() => saving = false);
                    if (success) {
                      Navigator.pop(context);
                      if (mounted) _charger();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
