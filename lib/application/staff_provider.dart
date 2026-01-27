import 'package:sc/data/repositories/staff_repository.dart';
import 'package:flutter/material.dart';

import '../data/model/staff.dart';

class StaffProvider extends ChangeNotifier {
  final StaffRepository _staffRepository = StaffRepository();

  Staff? _currentStaff;
  bool _isLoading = false;
  String? _error;

  Staff? get currentStaff => _currentStaff;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void setError(String? error) => _setError(error);

  Future <void> getStaffById (String staffId) async {
    _setLoading(true);
    _setError(null);
    try {
      final staff = await _staffRepository.getStaffById(staffId);
      _currentStaff = staff;
    } catch (e) {
      _setError('Failed to get staff: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future <void> updateStaffName(String newName) async {
    String oldName = _currentStaff?.staffName ?? "";

    _currentStaff = _currentStaff!.copyWith(staffName: newName);
    notifyListeners();
    try{
      final staff = await _staffRepository.updateStaffName(newName);
    } catch (e) {
      _currentStaff = _currentStaff!.copyWith(staffName: oldName);
      _setError('Failed to save staff name: $e');
      notifyListeners();
    }
  }
}