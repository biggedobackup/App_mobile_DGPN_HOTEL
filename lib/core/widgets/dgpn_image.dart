import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../constants/api_config.dart';
import '../constants/app_colors.dart';

enum DgpnImageType { photo, recto, verso }

class DgpnImage extends StatelessWidget {
  final String? url;
  final String? localUuid;
  final DgpnImageType type;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData placeholderIcon;

  const DgpnImage({
    super.key,
    this.url,
    this.localUuid,
    required this.type,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.image_outlined,
  });

  Future<String?> _getLocalPath() async {
    if (localUuid == null || localUuid!.isEmpty) return null;
    
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final String suffix = type == DgpnImageType.photo
          ? 'photo'
          : type == DgpnImageType.recto
              ? 'recto'
              : 'verso';
      
      final path = p.join(appDocDir.path, 'offline_images', '${localUuid}_$suffix.jpg');
      if (await File(path).exists()) {
        return path;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Si l'URL est déjà un chemin local (cas offlineData['photoClient'])
    if (url != null && !url!.startsWith('http') && !url!.startsWith('/media')) {
      if (File(url!).existsSync()) {
        return Image.file(
          File(url!),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => _buildPlaceholder(),
        );
      }
    }

    // Sinon, on tente le réseau avec CachedNetworkImage
    if (url != null && url!.isNotEmpty) {
      final fullUrl = url!.startsWith('http') ? url! : '${ApiConfig.baseUrl}$url';
      
      return CachedNetworkImage(
        imageUrl: fullUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoading(),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return FutureBuilder<String?>(
      future: _getLocalPath(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.file(
            File(snapshot.data!),
            width: width,
            height: height,
            fit: fit,
          );
        }
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.slate100,
      child: Icon(placeholderIcon, color: AppColors.slate400, size: 28),
    );
  }

  Widget _buildLoading() {
    return Container(
      width: width,
      height: height,
      color: AppColors.slate50,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald600),
      ),
    );
  }
}
