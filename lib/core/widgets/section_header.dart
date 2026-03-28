import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String num;
  final String title;

  const SectionHeader({
    super.key,
    required this.num,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.emerald50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              num,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.emerald600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColors.slate800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
