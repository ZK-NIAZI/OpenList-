import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:openlist/core/widgets/openlist_logo.dart';

/// Run this to export the OpenList logo as PNG
/// Usage: flutter run lib/tools/export_logo.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create logo at high resolution for email
  final logo = RepaintBoundary(
    child: Container(
      width: 512,
      height: 512,
      color: Colors.transparent,
      child: const OpenListLogo(size: 512),
    ),
  );

  // Render to image
  final RenderRepaintBoundary boundary = logo.createRenderObject(
    // ignore: use_build_context_synchronously
    NavigatorState().context,
  ) as RenderRepaintBoundary;
  
  final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
  final ByteData? byteData = await image.toByteData(
    format: ui.ImageByteFormat.png,
  );
  
  if (byteData != null) {
    final buffer = byteData.buffer;
    await File('assets/images/openlist-logo.png').writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );
    print('✅ Logo exported to assets/images/openlist-logo.png');
  }
}
