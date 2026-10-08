import 'package:flutter/foundation.dart';

import '../models/invoice.dart';
import '../services/invoice_service.dart';

class InvoiceProvider extends ChangeNotifier {
  InvoiceProvider({InvoiceService? invoiceService})
    : _invoiceService = invoiceService ?? InvoiceService();

  final InvoiceService _invoiceService;

  List<Invoice> _invoices = [];
  Invoice? _selectedInvoice;

  bool _isLoading = false;
  String? _errorMessage;

  List<Invoice> get invoices => List.unmodifiable(_invoices);
  Invoice? get selectedInvoice => _selectedInvoice;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> loadInvoices() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _invoices = await _invoiceService.getInvoices();
      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loadInvoice(int serviceOrderId) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _selectedInvoice = await _invoiceService.getInvoice(serviceOrderId);
      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearSelectedInvoice() {
    _selectedInvoice = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    return error.toString().replaceFirst('ApiException(null): ', '');
  }
}
