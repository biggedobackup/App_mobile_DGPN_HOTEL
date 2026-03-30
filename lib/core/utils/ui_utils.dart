import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class UIUtils {
  static void showSuccessBanner(BuildContext context, String msg, {bool isOffline = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.check_circle_rounded, 
              color: Colors.white, 
              size: 20
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isOffline ? '$msg (MODE HORS-LIGNE)'.toUpperCase() : msg.toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900, 
                  fontSize: 11, 
                  letterSpacing: 0.5
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isOffline ? const Color(0xFFD97706) : AppColors.emerald600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showErrorBanner(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg.toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900, 
                  fontSize: 11, 
                  letterSpacing: 0.5
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showInfoBanner(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg.toUpperCase(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900, 
                  fontSize: 11, 
                  letterSpacing: 0.5
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.slate700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
