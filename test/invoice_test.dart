import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mb_engkelqq_mobile/features/customer/invoices/customer_invoice_detail_page.dart';
import 'package:mb_engkelqq_mobile/features/customer/invoices/customer_invoices_page.dart';
import 'package:mb_engkelqq_mobile/models/invoice.dart';
import 'package:mb_engkelqq_mobile/providers/invoice_provider.dart';
import 'package:mb_engkelqq_mobile/services/invoice_service.dart';
import 'package:provider/provider.dart';

class FakeInvoiceService extends InvoiceService {
  final List<Invoice> fakeInvoices = [
    const Invoice(
      invoiceNumber: 'INV-00000001',
      serviceOrderId: 1,
      grandTotal: 110000,
    ),
    const Invoice(
      invoiceNumber: 'INV-00000002',
      serviceOrderId: 2,
      grandTotal: 250000,
    ),
  ];

  final Invoice fakeDetail = const Invoice(
    invoiceNumber: 'INV-00000001',
    serviceOrderId: 1,
    nomorBooking: 'MC202609290001',
    tanggal: '09/10/2026',
    customer: {'name': 'Customer Test', 'email': 'customer@motocare.test'},
    vehicle: {'nomor_polisi': 'B1234TEST', 'merk': 'Honda', 'model': 'Vario'},
    items: [
      InvoiceItem(
        name: 'Oli Mesin',
        price: 55000,
        quantity: 2,
        subtotal: 110000,
      ),
    ],
    subtotal: 110000,
    deliveryFee: 0,
    grandTotal: 110000,
    paymentStatus: 'verified',
    paymentMethod: 'cash',
  );

  @override
  Future<List<Invoice>> getInvoices() async {
    return fakeInvoices;
  }

  @override
  Future<Invoice> getInvoice(int serviceOrderId) async {
    return fakeDetail;
  }
}

void main() {
  group('Invoice Model Tests', () {
    test('parses index summary JSON correctly', () {
      final json = {
        'invoice_number': 'INV-00000001',
        'service_order_id': 1,
        'grand_total': 110000,
      };

      final invoice = Invoice.fromJson(json);

      expect(invoice.invoiceNumber, 'INV-00000001');
      expect(invoice.serviceOrderId, 1);
      expect(invoice.grandTotal, 110000.0);
    });

    test('parses detailed show JSON correctly', () {
      final json = {
        'invoice_number': 'INV-00000001',
        'nomor_booking': 'MC202609290001',
        'tanggal': '09/10/2026',
        'customer': {
          'name': 'Customer Test',
          'email': 'customer@motocare.test',
        },
        'vehicle': {
          'nomor_polisi': 'B1234TEST',
          'merk': 'Honda',
          'model': 'Vario',
        },
        'items': [
          {'name': 'oli', 'price': 55000, 'quantity': 1, 'subtotal': 55000},
        ],
        'subtotal': 55000,
        'delivery_fee': 15000,
        'grand_total': 70000,
        'payment_status': 'verified',
        'payment_method': 'cash',
      };

      final invoice = Invoice.fromJson(json);

      expect(invoice.invoiceNumber, 'INV-00000001');
      expect(invoice.nomorBooking, 'MC202609290001');
      expect(invoice.tanggal, '09/10/2026');
      expect(invoice.customerName, 'Customer Test');
      expect(invoice.customerEmail, 'customer@motocare.test');
      expect(invoice.vehiclePlate, 'B1234TEST');
      expect(invoice.vehicleMerk, 'Honda');
      expect(invoice.vehicleModel, 'Vario');
      expect(invoice.items.length, 1);
      expect(invoice.items.first.name, 'oli');
      expect(invoice.items.first.subtotal, 55000.0);
      expect(invoice.subtotal, 55000.0);
      expect(invoice.deliveryFee, 15000.0);
      expect(invoice.grandTotal, 70000.0);
      expect(invoice.paymentStatus, 'verified');
      expect(invoice.paymentMethod, 'cash');
    });
  });

  group('Invoice Provider Tests', () {
    test('loadInvoices sets invoices list', () async {
      final fakeService = FakeInvoiceService();
      final provider = InvoiceProvider(invoiceService: fakeService);

      final result = await provider.loadInvoices();

      expect(result, isTrue);
      expect(provider.invoices.length, 2);
      expect(provider.invoices.first.invoiceNumber, 'INV-00000001');
    });

    test('loadInvoice sets selectedInvoice', () async {
      final fakeService = FakeInvoiceService();
      final provider = InvoiceProvider(invoiceService: fakeService);

      final result = await provider.loadInvoice(1);

      expect(result, isTrue);
      expect(provider.selectedInvoice?.invoiceNumber, 'INV-00000001');
      expect(provider.selectedInvoice?.customerName, 'Customer Test');
    });
  });

  group('Invoice Widget Tests', () {
    testWidgets('CustomerInvoicesPage renders invoices correctly', (
      tester,
    ) async {
      final fakeService = FakeInvoiceService();
      final provider = InvoiceProvider(invoiceService: fakeService);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<InvoiceProvider>.value(
            value: provider,
            child: const CustomerInvoicesPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Riwayat Invoice'), findsOneWidget);
      expect(find.text('INV-00000001'), findsOneWidget);
      expect(find.text('Service Order #1'), findsOneWidget);
      expect(find.text('Rp 110.000'), findsOneWidget);
    });

    testWidgets('CustomerInvoiceDetailPage renders details correctly', (
      tester,
    ) async {
      final fakeService = FakeInvoiceService();
      final provider = InvoiceProvider(invoiceService: fakeService);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<InvoiceProvider>.value(
            value: provider,
            child: const CustomerInvoiceDetailPage(serviceOrderId: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Detail Invoice'), findsOneWidget);
      expect(find.text('INV-00000001'), findsOneWidget);
      expect(find.text('Customer Test'), findsOneWidget);
      expect(find.text('B1234TEST'), findsOneWidget);
      expect(find.text('Oli Mesin'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('VERIFIED'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('VERIFIED'), findsOneWidget);
      expect(find.text('CASH'), findsOneWidget);
    });
  });
}
