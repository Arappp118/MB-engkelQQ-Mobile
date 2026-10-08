// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'http://127.0.0.1:8000/api/v1';

  // 1. Login Admin
  print('Logging in Admin...');
  final loginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    body: {'email': 'admin@motocare.test', 'password': 'password'},
  );
  if (loginRes.statusCode != 200) {
    print('FAIL: Login failed');
    return;
  }
  final token = jsonDecode(loginRes.body)['data']['token'];
  print('Login success. Token: $token');

  // 2. Fetch Service Orders
  print('Fetching Service Orders...');
  final orderRes = await http.get(
    Uri.parse('$baseUrl/service-orders'),
    headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
  );
  if (orderRes.statusCode != 200) {
    print('FAIL: Fetch service orders failed');
    return;
  }

  final orders = jsonDecode(orderRes.body)['data'] as List;
  print('Found ${orders.length} service orders.');

  // The Flutter UI filters by 'waiting_payment'
  final waitingPayments = orders
      .where((o) => o['status'] == 'waiting_payment')
      .toList();
  print('Found ${waitingPayments.length} waiting payments based on UI logic.');

  if (waitingPayments.isEmpty) {
    print(
      'FAIL: No payments to test (due to missing data or backend enum mismatch).',
    );
  }
}
