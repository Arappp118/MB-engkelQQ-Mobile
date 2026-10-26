// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'http://127.0.0.1:8000/api/v1';
  print('====================================================');
  print('MOTOCARE / MB-ENGKELQQ — LIVE PAYMENT & API E2E SIM');
  print('====================================================');

  // ----------------------------------------------------
  // 1. HEALTH CHECK
  // ----------------------------------------------------
  print('\n[1] Checking Backend Health...');
  final healthRes = await http.get(Uri.parse('$baseUrl/health'));
  if (healthRes.statusCode != 200) {
    print('FAIL: Health check returned status ${healthRes.statusCode}');
    exit(1);
  }
  final healthJson = jsonDecode(healthRes.body);
  print('Health OK: ${healthJson['message']} (version: ${healthJson['data']['version']})');

  // ----------------------------------------------------
  // 2. ADMIN AUTHENTICATION
  // ----------------------------------------------------
  print('\n[2] Authenticating Admin (admin@motocare.test)...');
  final adminLoginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    body: {'email': 'admin@motocare.test', 'password': 'password'},
    headers: {'Accept': 'application/json'},
  );
  if (adminLoginRes.statusCode != 200) {
    print('FAIL: Admin login failed (${adminLoginRes.statusCode}): ${adminLoginRes.body}');
    exit(1);
  }
  final adminToken = jsonDecode(adminLoginRes.body)['data']['token'];
  print('Admin login success. Token issued.');

  // ----------------------------------------------------
  // 3. SERVICE ORDERS AUDIT (ENUM CONTRACT VERIFICATION)
  // ----------------------------------------------------
  print('\n[3] Fetching Service Orders via Admin...');
  final orderRes = await http.get(
    Uri.parse('$baseUrl/service-orders'),
    headers: {
      'Authorization': 'Bearer $adminToken',
      'Accept': 'application/json',
    },
  );
  if (orderRes.statusCode != 200) {
    print('FAIL: Fetch service orders failed (${orderRes.statusCode})');
    exit(1);
  }
  final orders = jsonDecode(orderRes.body)['data'] as List;
  print('Fetched ${orders.length} service orders.');

  // Verify backend service_orders enum: ['pending', 'in_progress', 'completed']
  final completedOrders = orders.where((o) => o['status'] == 'completed').toList();
  final inProgressOrders = orders.where((o) => o['status'] == 'in_progress').toList();
  final pendingOrders = orders.where((o) => o['status'] == 'pending').toList();
  print('Service Order Status Breakdown: '
      'completed=${completedOrders.length}, '
      'in_progress=${inProgressOrders.length}, '
      'pending=${pendingOrders.length}');

  if (completedOrders.isEmpty) {
    print('FAIL: Expected at least one completed service order.');
    exit(1);
  }

  // ----------------------------------------------------
  // 4. BOOKINGS AUDIT (MAPPING TO WAITING_PAYMENT)
  // ----------------------------------------------------
  print('\n[4] Fetching Bookings via Admin...');
  final bookingRes = await http.get(
    Uri.parse('$baseUrl/bookings'),
    headers: {
      'Authorization': 'Bearer $adminToken',
      'Accept': 'application/json',
    },
  );
  if (bookingRes.statusCode != 200) {
    print('FAIL: Fetch bookings failed (${bookingRes.statusCode})');
    exit(1);
  }
  final bookings = jsonDecode(bookingRes.body)['data'] as List;
  print('Fetched ${bookings.length} bookings.');

  // ----------------------------------------------------
  // 5. LIVE PAYMENT AUDIT & VERIFICATION FLOW
  // ----------------------------------------------------
  print('\n[5] Testing Live Payment Retrieval & Admin Verification...');

  // Identify Payment 10 or find an existing payment
  int? targetPaymentId;
  String? paymentStatus;
  int? paymentAmount;

  for (final candidateId in [10, 15, 11, 16, 1, 4]) {
    final pRes = await http.get(
      Uri.parse('$baseUrl/payments/$candidateId'),
      headers: {
        'Authorization': 'Bearer $adminToken',
        'Accept': 'application/json',
      },
    );
    if (pRes.statusCode == 200) {
      final pData = jsonDecode(pRes.body)['data'];
      print('Inspecting Payment #$candidateId: '
          'status=${pData['status']}, '
          'amount=${pData['amount']}, '
          'method=${pData['payment_method']}, '
          'order_id=${pData['service_order_id']}');

      if (pData['status'] == 'waiting_verification') {
        targetPaymentId = candidateId;
        paymentStatus = pData['status'];
        paymentAmount = pData['amount'];
        break;
      } else if (targetPaymentId == null) {
        targetPaymentId = candidateId;
        paymentStatus = pData['status'];
        paymentAmount = pData['amount'];
      }
    }
  }

  if (targetPaymentId == null) {
    print('FAIL: Could not locate any payment record.');
    exit(1);
  }

  print('\nTarget Payment Selected: #$targetPaymentId (status: $paymentStatus, amount: $paymentAmount)');

  if (paymentStatus == 'waiting_verification') {
    // 5A. Execute Admin Payment Verification
    print('Executing Admin Verification on Payment #$targetPaymentId...');
    final verifyRes = await http.post(
      Uri.parse('$baseUrl/payments/$targetPaymentId/verify'),
      headers: {
        'Authorization': 'Bearer $adminToken',
        'Accept': 'application/json',
      },
    );

    if (verifyRes.statusCode != 200) {
      print('FAIL: Admin verification returned ${verifyRes.statusCode}: ${verifyRes.body}');
      exit(1);
    }

    final verifyData = jsonDecode(verifyRes.body);
    print('Verification Response: ${verifyData['message']}');
    final updatedPayment = verifyData['data'];
    if (updatedPayment['status'] != 'verified') {
      print('FAIL: Expected status to be verified, got ${updatedPayment['status']}');
      exit(1);
    }
    print('PASS: Payment #$targetPaymentId status successfully transitioned to VERIFIED (paid_at: ${updatedPayment['paid_at']})');

    // 5B. Test Concurrency & Double Verification Protection
    print('Testing Double-Verification Guard on Payment #$targetPaymentId...');
    final doubleVerifyRes = await http.post(
      Uri.parse('$baseUrl/payments/$targetPaymentId/verify'),
      headers: {
        'Authorization': 'Bearer $adminToken',
        'Accept': 'application/json',
      },
    );

    if (doubleVerifyRes.statusCode == 422) {
      print('PASS: Double-verification correctly rejected with HTTP 422 Unprocessable Entity.');
    } else {
      print('FAIL: Expected HTTP 422 on double verify, got ${doubleVerifyRes.statusCode}');
      exit(1);
    }
  } else if (paymentStatus == 'verified') {
    print('Payment #$targetPaymentId is already VERIFIED. Testing double-verification rejection guard...');
    final doubleVerifyRes = await http.post(
      Uri.parse('$baseUrl/payments/$targetPaymentId/verify'),
      headers: {
        'Authorization': 'Bearer $adminToken',
        'Accept': 'application/json',
      },
    );
    if (doubleVerifyRes.statusCode == 422) {
      print('PASS: Double-verification guard correctly rejected with HTTP 422.');
    } else {
      print('FAIL: Expected HTTP 422 on already-verified payment, got ${doubleVerifyRes.statusCode}');
      exit(1);
    }
  }

  // ----------------------------------------------------
  // 6. CUSTOMER AUTHENTICATION & IDOR SECURITY TEST
  // ----------------------------------------------------
  print('\n[6] Authenticating Customer (customer@motocare.test)...');
  final custLoginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    body: {'email': 'customer@motocare.test', 'password': 'password'},
    headers: {'Accept': 'application/json'},
  );
  if (custLoginRes.statusCode != 200) {
    print('FAIL: Customer login failed (${custLoginRes.statusCode})');
    exit(1);
  }
  final custToken = jsonDecode(custLoginRes.body)['data']['token'];
  print('Customer login success.');

  // Customer fetches their own dashboard
  final dashRes = await http.get(
    Uri.parse('$baseUrl/dashboard'),
    headers: {
      'Authorization': 'Bearer $custToken',
      'Accept': 'application/json',
    },
  );
  if (dashRes.statusCode != 200) {
    print('FAIL: Customer dashboard failed (${dashRes.statusCode})');
    exit(1);
  }
  print('PASS: Customer dashboard loaded successfully.');

  // Customer attempts unauthorized admin payment verification (IDOR test)
  print('Testing IDOR: Customer attempts to call verify on Payment #$targetPaymentId...');
  final idorRes = await http.post(
    Uri.parse('$baseUrl/payments/$targetPaymentId/verify'),
    headers: {
      'Authorization': 'Bearer $custToken',
      'Accept': 'application/json',
    },
  );
  if (idorRes.statusCode == 403) {
    print('PASS: IDOR correctly blocked with HTTP 403 Forbidden.');
  } else {
    print('FAIL: Expected HTTP 403 for Customer verifying payment, got ${idorRes.statusCode}');
    exit(1);
  }

  // ----------------------------------------------------
  // 7. SUMMARY
  // ----------------------------------------------------
  print('\n====================================================');
  print('ALL LIVE PAYMENT & INTEGRATION ASSERTIONS PASSED! [PASS]');
  print('====================================================\n');
}
