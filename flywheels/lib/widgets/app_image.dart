import 'dart:io';

import 'package:flywheels/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  bool get _isNetwork =>
      path.startsWith('http://') || path.startsWith('https://');

  bool get _isDocument {
    final lower = path.toLowerCase();
    return lower.endsWith('.pdf') ||
        lower.endsWith('.doc') ||
        lower.endsWith('.docx');
  }

  @override
  Widget build(BuildContext context) {
    if (_isDocument) {
      return _Placeholder(
        width: width,
        height: height,
        icon: Icons.description,
      );
    }

    final image = _isNetwork
        ? Image.network(
            path,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) =>
                _Placeholder(width: width, height: height),
          )
        : Image.file(
            File(path),
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) =>
                _Placeholder(width: width, height: height),
          );

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.width,
    required this.height,
    this.icon = Icons.image_outlined,
  });

  final double? width;
  final double? height;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppPalette.soft,
      alignment: Alignment.center,
      child: Icon(icon, color: AppPalette.muted),
    );
  }
}
