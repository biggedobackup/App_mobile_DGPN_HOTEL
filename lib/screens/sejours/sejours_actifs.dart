import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sejour_service.dart';
import '../../core/models/sejour_model.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';

class SejoursActifsScreen extends StatefulWidget {
  const SejoursActifsScreen({super.key});

  @override
  State<SejoursActifsScreen> createState() => _SejoursActifsScreenState();
}

class _SejoursActifsScreenState extends State<SejoursActifsScreen> {
  final _sejourService = SejourService();
  final _searchCtrl = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateFin;

  List<SejourModel> _sejours = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
    _searchCtrl.addListener(() {
      _charger();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final data = await _sejourService.getSejoursActifs(
      search: _searchCtrl.text,
      dateDebut: _dateDebut?.toIso8601String().split('T')[0],
      dateFin: _dateFin?.toIso8601String().split('T')[0],
    );
    if (mounted) {
      setState(() {
        _sejours = data['results'] as List<SejourModel>;
        _loading = false;
      });
    }
  }

  Future<void> _selectDate(bool isDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.emerald600,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
      _charger();
    }
  }

  void _showSortieModal(SejourModel s) {
    final obsController = TextEditingController(text: s.observationsSortie);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENREGISTRER LA SORTIE',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Client: ${s.clientFullName.toUpperCase()}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: AppColors.slate500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      label: 'OBSERVATIONS DE SORTIE',
                      controller: obsController,
                      maxLines: 3,
                      prefixIcon: Icons.notes,
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sortie enregistrée'),
                                backgroundColor: AppColors.emerald600,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      appBar: AppBar(
        title: Text(
          'SÉJOURS ACTIFS',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildActiveFilterChips(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.emerald600,
                    ),
                  )
                : _sejours.isEmpty
                    ? _buildEmptyState()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          CustomTextField(
            label: 'RECHERCHE',
            controller: _searchCtrl,
            prefixIcon: Icons.search,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateBtn(
                  _dateDebut == null ? 'DÉBUT' : _dateDebut!.toIso8601String().split('T')[0],
                  () => _selectDate(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDateBtn(
                  _dateFin == null ? 'FIN' : _dateFin!.toIso8601String().split('T')[0],
                  () => _selectDate(false),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _dateDebut = null;
                    _dateFin = null;
                    _searchCtrl.clear();
                  });
                  _charger();
                },
                icon: const Icon(Icons.refresh, color: AppColors.slate400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateBtn(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.slate50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14, color: AppColors.slate400),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.slate700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    if (_dateDebut == null && _dateFin == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'FILTRES ACTIFS:',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.slate400,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'PÉRIODE PERSONNALISÉE',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: AppColors.emerald700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hotel_class_rounded, size: 64, color: AppColors.slate300),
          const SizedBox(height: 16),
          Text(
            'Aucun séjour actif trouvé',
            style: GoogleFonts.inter(color: AppColors.slate500),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _charger,
      color: AppColors.emerald600,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _sejours.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, index) => _buildSejourCard(_sejours[index]),
      ),
    );
  }

  Widget _buildSejourCard(SejourModel s) {
    return InkWell(
      onTap: () {
        context.push('/enregistrement/${s.id}/detail').then((_) => _charger());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.emerald50,
                    child: Text(
                      s.nomClient[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.emerald700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.clientFullName.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            color: AppColors.slate800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chambre ${s.numeroChambre}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.slate500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Entrée: ${s.formattedDateArrivee}',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: AppColors.slate400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ACTIF',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 8,
                        color: AppColors.emerald700,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.motifSejour,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate700,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showSortieModal(s),
                    icon: const Icon(Icons.logout, size: 14),
                    label: const Text('SORTIE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      textStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
