// implementacao: nfe_io_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'fiscal_service.dart';
import '../models/fiscal_response.dart';

class NFeIoService implements FiscalService {
  final String apiKey;

  NFeIoService({required this.apiKey});

  @override
  Future<FiscalResponse> emitirNFCe(Map<String, dynamic> dadosVenda) async {
    final url = Uri.parse('https://api.nfe.io/v2/consumerinvoices');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'ApiKey $apiKey',
        },
        body: jsonEncode(dadosVenda),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = jsonDecode(response.body);
        return FiscalResponse(
          isSuccess: true,
          status: body['status'],
          chaveNota: body['accessKey'],
          pdfUrl: body['pdfUrl'],
        );
      } else {
        final errorBody = jsonDecode(response.body);
        return FiscalResponse(
          isSuccess: false,
          status: 'Error',
          errorMessage: errorBody['message'] ?? 'Erro de comunicação com a SEFAZ',
        );
      }
    } catch (e) {
      return FiscalResponse(
        isSuccess: false,
        status: 'ConnectionError',
        errorMessage: 'Falha na conexão de rede: $e',
      );
    }
  }
}