// lib/utils/pdf_helper.dart

import 'package:url_launcher/url_launcher.dart';

class PdfHelper {
  /// Abre uma URL de PDF no navegador ou leitor padrão do dispositivo.
  static Future<void> abrirPdf(String url) async {
    final Uri uri = Uri.parse(url);
    
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Não foi possível abrir o PDF: $url');
    }
  }
}