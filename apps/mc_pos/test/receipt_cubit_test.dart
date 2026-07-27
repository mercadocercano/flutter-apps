import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mc_application/mc_application.dart';
import 'package:mc_domain/mc_domain.dart';
import 'package:mc_pos/features/sale/receipt/pdf_document_printer.dart';
import 'package:mc_pos/features/sale/receipt/receipt_cubit.dart';
import 'package:mc_pos/features/sale/receipt/receipt_state.dart';

SaleReceipt _receipt() => SaleReceipt(
      id: 'sale-1',
      tenantId: TenantId('tenant-1'),
      saleNumber: '0001-00000001',
      items: [
        SaleReceiptItem(
          sku: 'SKU1',
          productName: 'Yerba',
          quantity: 2,
          unitPrice: Money.ars(1500),
          subtotal: Money.ars(3000),
        ),
      ],
      total: Money.ars(3000),
      discount: Money.zero,
      finalAmount: Money.ars(3000),
      amountPaid: Money.ars(5000),
      change: Money.ars(2000),
      currency: 'ARS',
      paymentMethodName: 'Efectivo',
      createdAt: DateTime(2026, 6, 17),
    );

class _FakeSalePort implements SalePort {
  SaleReceipt? receipt;
  bool failGet = false;
  bool failPdf = false;
  Uint8List pdfBytes = Uint8List.fromList([1, 2, 3]);

  @override
  Future<SaleReceipt> getReceipt(String saleId) async {
    if (failGet) throw Exception('boom');
    return receipt ?? _receipt();
  }

  @override
  Future<Uint8List> downloadReceiptPdf(String saleId) async {
    if (failPdf) throw Exception('no pdf endpoint');
    return pdfBytes;
  }

  @override
  Future<PosSale> createSale(PosSale sale) => throw UnimplementedError();
  @override
  Future<PosSale> getSale(String saleId) => throw UnimplementedError();
  @override
  Future<List<PosSale>> listSales({
    DateTime? from,
    DateTime? to,
    int page = 1,
    int pageSize = 50,
  }) =>
      throw UnimplementedError();
}

class _FakePdfPrinter implements PdfDocumentPrinter {
  int printed = 0;
  int shared = 0;

  @override
  Future<void> printPdf(Uint8List bytes, {String? documentName}) async {
    printed++;
  }

  @override
  Future<void> sharePdf(Uint8List bytes, {required String fileName}) async {
    shared++;
  }
}

class _FakePrinter implements PrinterPort {
  bool connected = true;
  int receipts = 0;

  @override
  Future<bool> isConnected() async => connected;
  @override
  Future<void> printReceipt(ReceiptData receipt) async {
    receipts++;
  }

  @override
  Future<void> connect(String deviceId) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<List<PrinterDevice>> discoverDevices() async => [];
}

void main() {
  late _FakeSalePort salePort;
  late _FakePdfPrinter pdfPrinter;

  setUp(() {
    salePort = _FakeSalePort();
    pdfPrinter = _FakePdfPrinter();
  });

  ReceiptCubit build({PrinterPort? printer}) => ReceiptCubit(
        salePort: salePort,
        pdfPrinter: pdfPrinter,
        thermalPrinter: printer,
      );

  group('ReceiptCubit.load', () {
    blocTest<ReceiptCubit, ReceiptState>(
      'carga ok emite [Loading, Loaded]',
      build: build,
      act: (c) => c.load('sale-1'),
      expect: () => [isA<ReceiptLoading>(), isA<ReceiptLoaded>()],
      verify: (c) {
        final s = c.state as ReceiptLoaded;
        expect(s.receipt.saleNumber, '0001-00000001');
      },
    );

    blocTest<ReceiptCubit, ReceiptState>(
      'error de red emite [Loading, Error]',
      build: () {
        salePort.failGet = true;
        return build();
      },
      act: (c) => c.load('sale-1'),
      expect: () => [isA<ReceiptLoading>(), isA<ReceiptError>()],
    );
  });

  group('ReceiptCubit.printPdf', () {
    test('descarga e imprime el PDF y reporta éxito', () async {
      final cubit = build();
      await cubit.load('sale-1');
      final outcome = await cubit.printPdf();
      expect(outcome.success, isTrue);
      expect(pdfPrinter.printed, 1);
    });

    test('si el endpoint de PDF falla reporta error sin romper el detalle',
        () async {
      salePort.failPdf = true;
      final cubit = build();
      await cubit.load('sale-1');
      final outcome = await cubit.printPdf();
      expect(outcome.success, isFalse);
      expect(cubit.state, isA<ReceiptLoaded>());
    });
  });

  group('ReceiptCubit.printThermalTicket', () {
    test('sin impresora configurada reporta error claro', () async {
      final cubit = build();
      await cubit.load('sale-1');
      final outcome = await cubit.printThermalTicket();
      expect(outcome.success, isFalse);
      expect(cubit.hasThermalPrinter, isFalse);
    });

    test('con impresora conectada imprime el ticket', () async {
      final printer = _FakePrinter();
      final cubit = build(printer: printer);
      await cubit.load('sale-1');
      final outcome = await cubit.printThermalTicket();
      expect(outcome.success, isTrue);
      expect(printer.receipts, 1);
    });

    test('con impresora desconectada reporta error', () async {
      final printer = _FakePrinter()..connected = false;
      final cubit = build(printer: printer);
      await cubit.load('sale-1');
      final outcome = await cubit.printThermalTicket();
      expect(outcome.success, isFalse);
      expect(printer.receipts, 0);
    });
  });
}
