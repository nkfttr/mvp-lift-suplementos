// lib/models/fiscal_response.dart

class FiscalResponse {
  final bool isSuccess;
  final String status;
  final String? chaveNota;
  final String? pdfUrl;
  final String? errorMessage;

  FiscalResponse({
    required this.isSuccess,
    required this.status,
    this.chaveNota,
    this.pdfUrl,
    this.errorMessage,
  });
}