import 'package:flutter/foundation.dart';

import '../models/service_item.dart';
import '../models/service_order.dart';
import '../services/service_item_service.dart';
import '../services/service_order_service.dart';

class ServiceOrderProvider extends ChangeNotifier {
  ServiceOrderProvider({
    ServiceOrderService? serviceOrderService,
    ServiceItemService? serviceItemService,
  }) : _serviceOrderService = serviceOrderService ?? ServiceOrderService(),
       _serviceItemService = serviceItemService ?? ServiceItemService();

  final ServiceOrderService _serviceOrderService;
  final ServiceItemService _serviceItemService;

  List<ServiceOrder> _serviceOrders = [];
  ServiceOrder? _selectedServiceOrder;
  List<ServiceItem> _serviceItems = [];

  bool _isLoading = false;
  bool _isLoadingItems = false;
  String? _errorMessage;
  String? _errorMessageItems;

  List<ServiceOrder> get serviceOrders => List.unmodifiable(_serviceOrders);

  ServiceOrder? get selectedServiceOrder => _selectedServiceOrder;

  List<ServiceItem> get serviceItems => List.unmodifiable(_serviceItems);

  bool get isLoading => _isLoading;
  bool get isLoadingItems => _isLoadingItems;

  String? get errorMessage => _errorMessage;
  String? get errorMessageItems => _errorMessageItems;

  Future<bool> loadServiceOrders() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _serviceOrders = await _serviceOrderService.getServiceOrders();

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loadServiceOrder(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _selectedServiceOrder = await _serviceOrderService.getServiceOrder(id);

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> startServiceOrder(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final serviceOrder = await _serviceOrderService.startServiceOrder(id);

      _updateServiceOrder(serviceOrder);
      _selectedServiceOrder = serviceOrder;

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitDiagnosis({
    required int id,
    required String diagnosis,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final serviceOrder = await _serviceOrderService.submitDiagnosis(
        id: id,
        diagnosis: diagnosis,
      );

      _updateServiceOrder(serviceOrder);
      _selectedServiceOrder = serviceOrder;

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeServiceOrder(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final serviceOrder = await _serviceOrderService.completeServiceOrder(id);

      debugPrint(
        '[PAYMENT DEBUG] ServiceOrder ${serviceOrder.id} '
        'status setelah complete: ${serviceOrder.status}',
      );

      _updateServiceOrder(serviceOrder);
      _selectedServiceOrder = serviceOrder;

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Ambil katalog service item / sparepart dari backend.
  /// Mechanic boleh melihat (ServiceItemPolicy.viewAny = true).
  /// Mechanic TIDAK boleh mengubah harga — itu otoritas backend.
  Future<bool> loadServiceItems() async {
    _isLoadingItems = true;
    _errorMessageItems = null;
    notifyListeners();

    try {
      _serviceItems = await _serviceItemService.getServiceItems();

      return true;
    } catch (error) {
      _errorMessageItems = _extractErrorMessage(error);
      return false;
    } finally {
      _isLoadingItems = false;
      notifyListeners();
    }
  }

  void selectServiceOrder(ServiceOrder? serviceOrder) {
    _selectedServiceOrder = serviceOrder;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearServiceOrders() {
    _serviceOrders = [];
    _selectedServiceOrder = null;
    _serviceItems = [];
    _errorMessage = null;
    _errorMessageItems = null;
    notifyListeners();
  }

  void _updateServiceOrder(ServiceOrder serviceOrder) {
    final index = _serviceOrders.indexWhere(
      (item) => item.id == serviceOrder.id,
    );

    if (index == -1) {
      _serviceOrders = [..._serviceOrders, serviceOrder];
      return;
    }

    final updatedOrders = [..._serviceOrders];

    updatedOrders[index] = serviceOrder;

    _serviceOrders = updatedOrders;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    return error.toString().replaceFirst('ApiException(null): ', '');
  }
}
