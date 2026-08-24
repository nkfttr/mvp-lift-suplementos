// lib/utils/danfe_generator.dart

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DanfeGenerator {
  static Future<File> gerarDanfeMock({
    required String clienteNome,
    required String produtoNome,
    required int quantidade,
    required double valorTotal,
    required String chaveNota,
  }) async {
    final pdf = pw.Document();

    // Estilo de fonte monoespaçada estilo impressora térmica
    final font = pw.Font.courier();
    final fontBold = pw.Font.courierBold();

    pdf.addPage(
      pw.Page(
        // Formato padrão de bobina térmica (80mm)
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Cabeçalho da Empresa
              pw.Text("Lift Suplementos", style: pw.TextStyle(font: fontBold, fontSize: 10)),
              pw.Text("", style: pw.TextStyle(font: font, fontSize: 7)),
              pw.Text("CNPJ: 12.345.678/0001-90", style: pw.TextStyle(font: font, fontSize: 7)),
              pw.Text("Rua teste, 234 - Araucária PR", style: pw.TextStyle(font: font, fontSize: 7)),
              pw.SizedBox(height: 4),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Identificação do Documento
              pw.Text("DANFE NFC-e", style: pw.TextStyle(font: fontBold, fontSize: 9)),
              pw.Text("Documento Auxiliar da Nota Fiscal de Consumidor Eletrônica", style: pw.TextStyle(font: font, fontSize: 6), textAlign: pw.TextAlign.center),
              pw.Text("Não Permite Crédito de ICMS", style: pw.TextStyle(font: font, fontSize: 6)),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Tabela de Itens
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("ITEM DESCRIÇÃO", style: pw.TextStyle(font: fontBold, fontSize: 7)),
                  pw.Text("QTD x UNIT = TOTAL", style: pw.TextStyle(font: fontBold, fontSize: 7)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text("001 $produtoNome", style: pw.TextStyle(font: font, fontSize: 7)),
                  ),
                  pw.Text("$quantidade UN x R\$ ${(valorTotal / quantidade).toStringAsFixed(2)} = R\$ ${valorTotal.toStringAsFixed(2)}", style: pw.TextStyle(font: font, fontSize: 7)),
                ],
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Totais
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("QTD. TOTAL DE ITENS:", style: pw.TextStyle(font: font, fontSize: 8)),
                  pw.Text("$quantidade", style: pw.TextStyle(font: fontBold, fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("VALOR TOTAL R\$:", style: pw.TextStyle(font: fontBold, fontSize: 9)),
                  pw.Text("R\$ ${valorTotal.toStringAsFixed(2)}", style: pw.TextStyle(font: fontBold, fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("FORMA DE PAGAMENTO:", style: pw.TextStyle(font: font, fontSize: 7)),
                  pw.Text("PIX / DINHEIRO", style: pw.TextStyle(font: font, fontSize: 7)),
                ],
              ),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Consumidor
              pw.Text("CONSUMIDOR: $clienteNome", style: pw.TextStyle(font: fontBold, fontSize: 7)),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),

              // Dados da Emissão e Chave
              pw.Text("EMISSÃO SIMULADA - AMBIENTE MOCK", style: pw.TextStyle(font: fontBold, fontSize: 7)),
              pw.SizedBox(height: 2),
              pw.Text("CHAVE DE ACESSO:", style: pw.TextStyle(font: fontBold, fontSize: 6)),
              pw.Text(chaveNota, style: pw.TextStyle(font: font, fontSize: 6), textAlign: pw.TextAlign.center),
              pw.SizedBox(height: 6),

              // QR Code
              pw.BarcodeWidget(
                data: "https://www.sefaz.pr.gov.br/nfce/consulta?chNFe=$chaveNota",
                barcode: pw.Barcode.qrCode(),
                width: 70,
                height: 70,
              ),
              pw.SizedBox(height: 4),

              pw.Text("Protocolo de Autorização: 135260000123456", style: pw.TextStyle(font: font, fontSize: 6)),
              pw.Text("Consulta via leitor de QR Code", style: pw.TextStyle(font: font, fontSize: 6)),
            ],
          );
        },
      ),
    );

    // Salva o PDF gerado em arquivo temporário no celular
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/danfe_$chaveNota.pdf");
    await file.writeAsBytes(await pdf.save());

    return file;
  }
}