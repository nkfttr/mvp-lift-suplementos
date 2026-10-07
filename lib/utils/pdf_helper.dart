import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/pdf_viewer_screen.dart';

class PdfHelper {
  static Future<void> abrirPdf(BuildContext context, String url) async {
    final uri = Uri.parse(url);

    if (kIsWeb) {
      // No ambiente Web, abre o PDF numa nova aba sem usar o path_provider/dart:io
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, webOnlyWindowName: '_blank');
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível abrir a URL do PDF.')),
          );
        }
      }
    } else {
      // No Android/iOS nativo, navega para a tela de PDF
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(pdfUrl: url),
        ),
      );
    }
  }
}