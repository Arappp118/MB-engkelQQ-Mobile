import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/invoice.dart';

class InvoiceService {
  InvoiceService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<Invoice>> getInvoices() async {
    final response = await _apiClient.get(ApiConstants.invoices);

    final data = response['data'];

    if (data is! List) {
      throw const FormatException(
        'Response invoice tidak memiliki format data yang valid.',
      );
    }

    return data
        .whereType<Map>()
        .map((item) => Invoice.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Invoice> getInvoice(int serviceOrderId) async {
    final response = await _apiClient.get(
      '${ApiConstants.invoices}/$serviceOrderId',
    );

    final data = response['data'];

    if (data is! Map) {
      throw const FormatException(
        'Response detail invoice tidak memiliki format data yang valid.',
      );
    }

    final invoice = Invoice.fromJson(Map<String, dynamic>.from(data));
    if (invoice.serviceOrderId == null) {
      return invoice.copyWith(serviceOrderId: serviceOrderId);
    }
    return invoice;
  }
}
