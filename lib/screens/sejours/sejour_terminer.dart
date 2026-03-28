import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/sejour_service.dart';
import '../../core/models/sejour_model.dart';
import '../../core/widgets/custom_text_field.dart';

class SejourTerminerScreen extends StatefulWidget {
  const SejourTerminerScreen({super.key});

  @override
  State<SejourTerminerScreen> createState() => _SejourTerminerScreenState();
}

class _SejourTerminerScreenState extends State<SejourTerminerScreen> {
  final _sejourService = SejourService();
  final _searchCtrl = TextEditingController();

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
    if (!mounted) return;
    setState(() => _loading = true);
    final data = await _sejourService.getSejoursTermines(
      search: _searchCtrl.text,
    );
    if (mounted) {
      setState(() {
        _sejours = data['results'] as List<SejourModel>;
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
          'SÉJOURS TERMINÉS',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              label: 'RECHERCHER UN CLIENT',
              controller: _searchCtrl,
              prefixIcon: Icons.search,
            ),
          ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded, size: 64, color: AppColors.slate300),
          const SizedBox(height: 16),
          Text(
            'Aucun séjour terminé trouvé',
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: _sejours.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildTerminatedCard(_sejours[i]),
      ),
    );
  }

  Widget _buildTerminatedCard(SejourModel s) {
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
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check_circle, color: AppColors.emerald600),
              ),
              const SizedBox(width: 16),
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
                      'Sortie le : ${s.formattedDateSortie}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.slate400),
            ],
          ),
        ),
      ),
    );
  }
}
