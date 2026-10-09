import 'package:flutter/foundation.dart';

import '../core/errors/api_exception.dart';
import '../models/delivery_task.dart';
import '../services/delivery_service.dart';

class DeliveryProvider extends ChangeNotifier {
  DeliveryProvider({DeliveryService? deliveryService})
    : _deliveryService = deliveryService ?? DeliveryService();

  final DeliveryService _deliveryService;

  List<DeliveryTask> _deliveryTasks = [];
  DeliveryTask? _selectedDeliveryTask;

  bool _isLoading = false;
  String? _errorMessage;

  List<DeliveryTask> get deliveryTasks => List.unmodifiable(_deliveryTasks);

  DeliveryTask? get selectedDeliveryTask => _selectedDeliveryTask;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  Future<bool> loadDeliveryTasks() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _deliveryTasks = await _deliveryService.getDeliveryTasks();

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> loadDeliveryTask(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _selectedDeliveryTask = await _deliveryService.getDeliveryTask(id);

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> assignDeliveryTask({
    required int id,
    required int courierId,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final deliveryTask = await _deliveryService.assignDeliveryTask(
        id: id,
        courierId: courierId,
      );

      _updateDeliveryTask(deliveryTask);

      _selectedDeliveryTask = deliveryTask;

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> startDeliveryTask(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final deliveryTask = await _deliveryService.startDeliveryTask(id);

      _updateDeliveryTask(deliveryTask);

      _selectedDeliveryTask = deliveryTask;

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> completeDeliveryTask(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final deliveryTask = await _deliveryService.completeDeliveryTask(id);

      _updateDeliveryTask(deliveryTask);

      _selectedDeliveryTask = deliveryTask;

      return true;
    } catch (error) {
      _errorMessage = _extractErrorMessage(error);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void selectDeliveryTask(DeliveryTask? deliveryTask) {
    _selectedDeliveryTask = deliveryTask;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearDeliveryTasks() {
    _deliveryTasks = [];
    _selectedDeliveryTask = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _updateDeliveryTask(DeliveryTask deliveryTask) {
    final index = _deliveryTasks.indexWhere(
      (item) => item.id == deliveryTask.id,
    );

    if (index == -1) {
      _deliveryTasks = [..._deliveryTasks, deliveryTask];
      return;
    }

    final updatedTasks = [..._deliveryTasks];

    updatedTasks[index] = deliveryTask;

    _deliveryTasks = updatedTasks;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _extractErrorMessage(Object error) {
    return ApiException.extractMessage(error);
  }
}
