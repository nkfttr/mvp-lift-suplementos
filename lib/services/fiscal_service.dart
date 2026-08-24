// contrato: fiscal_service.dart
import '../models/fiscal_response.dart';

abstract class FiscalService {
  Future<FiscalResponse> emitirNFCe(Map<String, dynamic> dadosVenda);
}