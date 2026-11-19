// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'http://127.0.0.1:8000/api/v1';
  print('================================================================');
  print('   MB-ENGKELQQ / MOTOCARE — FULL MULTI-ROLE QA & QC AUDIT TEST  ');
  print('================================================================');

  int passedTests = 0;
  int failedTests = 0;
  final List<String> auditLogs = [];

  void assertSuccess(String testName, bool condition, [String detail = '']) {
    if (condition) {
      passedTests++;
      final msg = '  [PASS] $testName ${detail.isNotEmpty ? "($detail)" : ""}';
      print(msg);
      auditLogs.add(msg);
    } else {
      failedTests++;
      final msg = '  [FAIL] $testName ${detail.isNotEmpty ? "($detail)" : ""}';
      print(msg);
      auditLogs.add(msg);
    }
  }

  // -------------------------------------------------------------
  // 1. HEALTH & CONNECTIVITY
  // -------------------------------------------------------------
  print('\n>>> [1] HEALTH CHECK & API CONNECTIVITY');
  final healthRes = await http.get(Uri.parse('$baseUrl/health'));
  assertSuccess(
    'Backend Health Check',
    healthRes.statusCode == 200,
    'Status: ${healthRes.statusCode}',
  );

  // -------------------------------------------------------------
  // 2. ROLE: CUSTOMER (customer@motocare.test)
  // -------------------------------------------------------------
  print('\n>>> [2] AUDIT ROLE: CUSTOMER');
  final custLoginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    body: {'email': 'customer@motocare.test', 'password': 'password'},
    headers: {'Accept': 'application/json'},
  );
  assertSuccess(
    'Customer Login',
    custLoginRes.statusCode == 200,
    'HTTP ${custLoginRes.statusCode}',
  );
  final custToken = jsonDecode(custLoginRes.body)['data']['token'];

  // Me
  final custMeRes = await http.get(
    Uri.parse('$baseUrl/auth/me'),
    headers: {'Authorization': 'Bearer $custToken', 'Accept': 'application/json'},
  );
  final custMe = jsonDecode(custMeRes.body)['data'];
  assertSuccess(
    'Customer Profile Verification',
    custMeRes.statusCode == 200 && custMe['role'] == 'customer',
    'User ID: ${custMe['id']}, Role: ${custMe['role']}',
  );

  // Dashboard
  final custDashRes = await http.get(
    Uri.parse('$baseUrl/dashboard'),
    headers: {'Authorization': 'Bearer $custToken', 'Accept': 'application/json'},
  );
  assertSuccess(
    'Customer Dashboard',
    custDashRes.statusCode == 200,
    'HTTP ${custDashRes.statusCode}',
  );

  // Vehicles: List & Create
  final custVehiclesRes = await http.get(
    Uri.parse('$baseUrl/vehicles'),
    headers: {'Authorization': 'Bearer $custToken', 'Accept': 'application/json'},
  );
  assertSuccess(
    'Customer Fetch Vehicles',
    custVehiclesRes.statusCode == 200,
    'Found ${(jsonDecode(custVehiclesRes.body)['data'] as List).length} vehicles',
  );

  // Create Vehicle
  final randomPlate = 'AB ${(DateTime.now().millisecondsSinceEpoch % 8999) + 1000} QA';
  final createVehRes = await http.post(
    Uri.parse('$baseUrl/vehicles'),
    headers: {
      'Authorization': 'Bearer $custToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'nomor_polisi': randomPlate,
      'merk': 'Honda',
      'model': 'Vario 160 ABS',
      'tahun': 2023,
      'tipe_mesin': '4_tak',
      'transmisi': 'matic',
      'warna': 'Hitam Metalik',
    }),
  );
  assertSuccess(
    'Customer Create Vehicle',
    createVehRes.statusCode == 201 || createVehRes.statusCode == 200,
    'Plat: $randomPlate, HTTP: ${createVehRes.statusCode}',
  );
  final newVehicle = jsonDecode(createVehRes.body)['data'];
  final newVehicleId = newVehicle != null ? newVehicle['id'] : 1;

  // Customer Bookings: List & Create Booking
  final custBookingsRes = await http.get(
    Uri.parse('$baseUrl/bookings'),
    headers: {'Authorization': 'Bearer $custToken', 'Accept': 'application/json'},
  );
  assertSuccess(
    'Customer Fetch Bookings',
    custBookingsRes.statusCode == 200,
    'HTTP ${custBookingsRes.statusCode}',
  );

  // Create Booking
  final bookingDate = DateTime.now().add(const Duration(days: 2)).toIso8601String().substring(0, 10);
  final createBookingRes = await http.post(
    Uri.parse('$baseUrl/bookings'),
    headers: {
      'Authorization': 'Bearer $custToken',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'vehicle_id': newVehicleId,
      'tanggal': bookingDate,
      'waktu': '10:00',
      'keluhan': 'Rem belakang kurang pakem dan getar saat rpm rendah',
      'jenis_layanan': 'service_rutin',
      'pickup_requested': true,
      'alamat_pickup': 'Jl. Gejayan No. 45, Sleman, Yogyakarta',
      'estimated_distance_km': 4.5,
      'catatan': 'Harap hubungi via WhatsApp sebelum pickup.',
    }),
  );
  assertSuccess(
    'Customer Create Booking (Contract Compliant)',
    createBookingRes.statusCode == 201 || createBookingRes.statusCode == 200,
    'HTTP ${createBookingRes.statusCode}',
  );
  final createdBooking = jsonDecode(createBookingRes.body)['data'];
  final createdBookingId = createdBooking != null ? createdBooking['id'] : 1;

  // Customer Invoices & Payment Settings
  final custInvoicesRes = await http.get(
    Uri.parse('$baseUrl/invoices'),
    headers: {'Authorization': 'Bearer $custToken', 'Accept': 'application/json'},
  );
  assertSuccess(
    'Customer Fetch Invoices',
    custInvoicesRes.statusCode == 200,
    'HTTP ${custInvoicesRes.statusCode}',
  );

  final custPaymentSettingsRes = await http.get(
    Uri.parse('$baseUrl/payment-settings'),
    headers: {'Authorization': 'Bearer $custToken', 'Accept': 'application/json'},
  );
  assertSuccess(
    'Customer Fetch Payment Settings (Bank & QRIS)',
    custPaymentSettingsRes.statusCode == 200,
    'HTTP ${custPaymentSettingsRes.statusCode}',
  );

  // Customer Notifications
  final custNotifRes = await http.get(
    Uri.parse('$baseUrl/notifications'),
    headers: {'Authorization': 'Bearer $custToken', 'Accept': 'application/json'},
  );
  assertSuccess(
    'Customer Fetch Notifications',
    custNotifRes.statusCode == 200,
    'HTTP ${custNotifRes.statusCode}',
  );

  // -------------------------------------------------------------
  // 3. ROLE: ADMIN (admin@motocare.test)
  // -------------------------------------------------------------
  print('\n>>> [3] AUDIT ROLE: ADMIN');
  final adminLoginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    body: {'email': 'admin@motocare.test', 'password': 'password'},
    headers: {'Accept': 'application/json'},
  );
  assertSuccess('Admin Login', adminLoginRes.statusCode == 200, 'HTTP ${adminLoginRes.statusCode}');
  final adminToken = jsonDecode(adminLoginRes.body)['data']['token'];

  // Admin Profile
  final adminMeRes = await http.get(
    Uri.parse('$baseUrl/auth/me'),
    headers: {'Authorization': 'Bearer $adminToken', 'Accept': 'application/json'},
  );
  final adminMe = jsonDecode(adminMeRes.body)['data'];
  assertSuccess(
    'Admin Profile Verification',
    adminMeRes.statusCode == 200 && adminMe['role'] == 'admin',
    'Role: ${adminMe['role']}',
  );

  // Admin Dashboard
  final adminDashRes = await http.get(
    Uri.parse('$baseUrl/dashboard'),
    headers: {'Authorization': 'Bearer $adminToken', 'Accept': 'application/json'},
  );
  assertSuccess('Admin Dashboard Statistics', adminDashRes.statusCode == 200, 'HTTP ${adminDashRes.statusCode}');

  // Admin Master Service Items
  final itemsRes = await http.get(
    Uri.parse('$baseUrl/service-items'),
    headers: {'Authorization': 'Bearer $adminToken', 'Accept': 'application/json'},
  );
  assertSuccess(
    'Admin Catalog Master Service Items',
    itemsRes.statusCode == 200,
    'Found ${(jsonDecode(itemsRes.body)['data'] as List).length} items',
  );
  final serviceItems = jsonDecode(itemsRes.body)['data'] as List;
  final sampleItem = serviceItems.firstWhere((it) => it['is_active'] == true, orElse: () => serviceItems.first);

  // Admin Confirms Booking
  if (createdBooking != null) {
    print('  Admin confirming Booking #$createdBookingId...');
    final confirmBookingRes = await http.post(
      Uri.parse('$baseUrl/bookings/$createdBookingId/confirm'),
      headers: {
        'Authorization': 'Bearer $adminToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'mechanic_id': 2, // Budi Mekanik
      }),
    );
    assertSuccess(
      'Admin Confirm Booking & Assign Mechanic',
      confirmBookingRes.statusCode == 200,
      'HTTP ${confirmBookingRes.statusCode}',
    );
  }

  // Admin Delivery Tasks & Assign Courier
  final adminDeliveryRes = await http.get(
    Uri.parse('$baseUrl/delivery-tasks'),
    headers: {'Authorization': 'Bearer $adminToken', 'Accept': 'application/json'},
  );
  assertSuccess(
    'Admin Fetch Delivery Tasks',
    adminDeliveryRes.statusCode == 200,
    'HTTP ${adminDeliveryRes.statusCode}',
  );
  final deliveryTasks = jsonDecode(adminDeliveryRes.body)['data'] as List;
  final unassignedTask = deliveryTasks.firstWhere(
    (t) => t['status'] == 'pending',
    orElse: () => null,
  );
  if (unassignedTask != null) {
    final assignRes = await http.post(
      Uri.parse('$baseUrl/delivery-tasks/${unassignedTask['id']}/assign'),
      headers: {
        'Authorization': 'Bearer $adminToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'courier_id': 3}), // Andi Kurir
    );
    assertSuccess(
      'Admin Assign Courier to Task #${unassignedTask['id']}',
      assignRes.statusCode == 200,
      'HTTP ${assignRes.statusCode}',
    );
  }

  // -------------------------------------------------------------
  // 4. ROLE: MECHANIC (mekanik@motocare.test)
  // -------------------------------------------------------------
  print('\n>>> [4] AUDIT ROLE: MECHANIC');
  final mechLoginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    body: {'email': 'mekanik@motocare.test', 'password': 'password'},
    headers: {'Accept': 'application/json'},
  );
  assertSuccess('Mechanic Login', mechLoginRes.statusCode == 200, 'HTTP ${mechLoginRes.statusCode}');
  final mechToken = jsonDecode(mechLoginRes.body)['data']['token'];

  // Mechanic Profile
  final mechMeRes = await http.get(
    Uri.parse('$baseUrl/auth/me'),
    headers: {'Authorization': 'Bearer $mechToken', 'Accept': 'application/json'},
  );
  final mechMe = jsonDecode(mechMeRes.body)['data'];
  assertSuccess(
    'Mechanic Profile Verification',
    mechMeRes.statusCode == 200 && mechMe['role'] == 'mechanic',
    'Specialization: ${mechMe['specialization']}',
  );

  // Mechanic Service Orders
  final mechOrdersRes = await http.get(
    Uri.parse('$baseUrl/service-orders'),
    headers: {'Authorization': 'Bearer $mechToken', 'Accept': 'application/json'},
  );
  assertSuccess(
    'Mechanic Fetch Assigned Orders',
    mechOrdersRes.statusCode == 200,
    'HTTP ${mechOrdersRes.statusCode}',
  );
  final mechOrders = jsonDecode(mechOrdersRes.body)['data'] as List;
  print('  Assigned Orders for Budi: ${mechOrders.length}');

  // Find an order assigned to Budi Mekanik
  dynamic targetOrder = mechOrders.firstWhere(
    (o) => o['status'] == 'pending' || o['status'] == 'in_progress',
    orElse: () => mechOrders.firstWhere((o) => o['status'] == 'completed', orElse: () => null),
  );

  if (targetOrder != null) {
    final orderId = targetOrder['id'];
    print('  Testing operations on Service Order #$orderId (current status: ${targetOrder['status']})...');

    if (targetOrder['status'] == 'pending') {
      final startRes = await http.post(
        Uri.parse('$baseUrl/service-orders/$orderId/start'),
        headers: {'Authorization': 'Bearer $mechToken', 'Accept': 'application/json'},
      );
      assertSuccess('Mechanic Start Service Order', startRes.statusCode == 200, 'HTTP ${startRes.statusCode}');
    }

    // Save Diagnosis
    final diagRes = await http.post(
      Uri.parse('$baseUrl/service-orders/$orderId/diagnosis'),
      headers: {
        'Authorization': 'Bearer $mechToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'diagnosis_mechanic': 'Kondisi kampas rem aus 60%, oli mesin kotor dan perlu penggantian berkala.',
        'notes': 'Disarankan servis CVT pada kunjungan berikutnya.',
      }),
    );
    assertSuccess(
      'Mechanic Submit Diagnosis',
      diagRes.statusCode == 200,
      'HTTP ${diagRes.statusCode}',
    );

    // Live Test: POST /api/v1/service-orders/{id}/items
    print('  Testing Live Backend API Endpoint: POST /api/v1/service-orders/$orderId/items...');
    final addItemRes = await http.post(
      Uri.parse('$baseUrl/service-orders/$orderId/items'),
      headers: {
        'Authorization': 'Bearer $mechToken',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'service_item_id': sampleItem['id'],
        'quantity': 1,
      }),
    );
    print('  addItem response code: ${addItemRes.statusCode}, body: ${addItemRes.body}');
    assertSuccess(
      'Mechanic Add Service Item to Order (Live API)',
      addItemRes.statusCode == 201 || addItemRes.statusCode == 200,
      'HTTP ${addItemRes.statusCode}',
    );
  }

  // -------------------------------------------------------------
  // 5. ROLE: COURIER (kurir@motocare.test)
  // -------------------------------------------------------------
  print('\n>>> [5] AUDIT ROLE: COURIER');
  final courierLoginRes = await http.post(
    Uri.parse('$baseUrl/auth/login'),
    body: {'email': 'kurir@motocare.test', 'password': 'password'},
    headers: {'Accept': 'application/json'},
  );
  assertSuccess('Courier Login', courierLoginRes.statusCode == 200, 'HTTP ${courierLoginRes.statusCode}');
  final courierToken = jsonDecode(courierLoginRes.body)['data']['token'];

  // Courier Profile
  final courierMeRes = await http.get(
    Uri.parse('$baseUrl/auth/me'),
    headers: {'Authorization': 'Bearer $courierToken', 'Accept': 'application/json'},
  );
  final courierMe = jsonDecode(courierMeRes.body)['data'];
  assertSuccess(
    'Courier Profile Verification',
    courierMeRes.statusCode == 200 && courierMe['role'] == 'courier',
    'Role: ${courierMe['role']}',
  );

  // Courier Tasks
  final courierTasksRes = await http.get(
    Uri.parse('$baseUrl/delivery-tasks'),
    headers: {'Authorization': 'Bearer $courierToken', 'Accept': 'application/json'},
  );
  assertSuccess(
    'Courier Fetch Assigned Delivery Tasks',
    courierTasksRes.statusCode == 200,
    'HTTP ${courierTasksRes.statusCode}',
  );
  final courierTasks = jsonDecode(courierTasksRes.body)['data'] as List;
  print('  Courier Tasks count: ${courierTasks.length}');

  final activeCourierTask = courierTasks.firstWhere(
    (t) => t['status'] == 'assigned' || t['status'] == 'in_transit' || t['status'] == 'pending',
    orElse: () => null,
  );

  if (activeCourierTask != null) {
    final taskId = activeCourierTask['id'];
    print('  Testing operations on Delivery Task #$taskId (status: ${activeCourierTask['status']})...');
    if (activeCourierTask['status'] == 'assigned' || activeCourierTask['status'] == 'pending') {
      final startTaskRes = await http.post(
        Uri.parse('$baseUrl/delivery-tasks/$taskId/start'),
        headers: {'Authorization': 'Bearer $courierToken', 'Accept': 'application/json'},
      );
      assertSuccess('Courier Start Delivery Task', startTaskRes.statusCode == 200, 'HTTP ${startTaskRes.statusCode}');
    }
  }

  // -------------------------------------------------------------
  // 6. SECURITY & ACCESS CONTROL (RBAC & IDOR)
  // -------------------------------------------------------------
  print('\n>>> [6] SECURITY & ACCESS CONTROL AUDIT');
  // Customer attempts admin action
  final unauthorizedAdminRes = await http.post(
    Uri.parse('$baseUrl/payments/1/verify'),
    headers: {'Authorization': 'Bearer $custToken', 'Accept': 'application/json'},
  );
  assertSuccess(
    'RBAC: Customer Forbidden from Admin Payment Verification',
    unauthorizedAdminRes.statusCode == 403,
    'HTTP ${unauthorizedAdminRes.statusCode}',
  );

  // Mechanic attempts courier action
  final unauthorizedCourierRes = await http.post(
    Uri.parse('$baseUrl/delivery-tasks/1/start'),
    headers: {'Authorization': 'Bearer $mechToken', 'Accept': 'application/json'},
  );
  assertSuccess(
    'RBAC: Mechanic Forbidden from Delivery Task Action',
    unauthorizedCourierRes.statusCode == 403,
    'HTTP ${unauthorizedCourierRes.statusCode}',
  );

  // -------------------------------------------------------------
  // SUMMARY RESULTS
  // -------------------------------------------------------------
  print('\n================================================================');
  print('                  FINAL AUDIT RESULTS RECAP                     ');
  print('================================================================');
  print('  Total Assertions Tested : ${passedTests + failedTests}');
  print('  Passed Assertions       : $passedTests');
  print('  Failed Assertions       : $failedTests');
  print('================================================================');

  if (failedTests > 0) {
    print('STATUS: AUDIT DETECTED FAILURES');
    exit(1);
  } else {
    print('STATUS: ALL ROLES & FEATURES VERIFIED 100% OPERATIONAL');
    exit(0);
  }
}
