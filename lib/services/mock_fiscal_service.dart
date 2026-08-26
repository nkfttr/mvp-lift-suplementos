// lib/services/mock_fiscal_service.dart

import 'dart:math';
import '../models/fiscal_response.dart';
import '../utils/danfe_generator.dart';
import 'fiscal_service.dart';

class MockFiscalService implements FiscalService {
  @override
  Future<FiscalResponse> emitirNFCe(Map<String, dynamic> dadosVenda) async {
    await Future.delayed(const Duration(seconds: 2));

    final chaveFalsa = '35260812345678901234650010000000011${Random().nextInt(900000) + 100000}';

    // Gera o PDF
    final pdfFile = await DanfeGenerator.gerarDanfeMock(
      clienteNome: dadosVenda['cliente'] ?? "CONSUMIDOR NÃO IDENTIFICADO",
      produtoNome: dadosVenda['produto'] ?? "PRODUTO DIVERSO",
      quantidade: dadosVenda['quantidade'] ?? 1,
      valorTotal: (dadosVenda['total'] as num?)?.toDouble() ?? 0.0,
      chaveNota: chaveFalsa,
    );

    return FiscalResponse(
      isSuccess: true,
      status: 'Issued',
      chaveNota: chaveFalsa,
      // retorna o caminho do arquivo PDF q foi gerado localmente
      pdfUrl: pdfFile.path, 
    );
  }
}