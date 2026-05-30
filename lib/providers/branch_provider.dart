import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/branch_model.dart'; // Đảm bảo import đúng đường dẫn model của bạn

class BranchProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<Branch> _branches = [];
  bool _isLoading = false;
  String? _error;

  List<Branch> get branches  => List.unmodifiable(_branches);
  bool    get isLoading  => _isLoading;
  String? get error      => _error;

  // Đổi tên từ loadBranches thành loadByOwner cho đúng với các màn hình UI đang gọi
  Future<void> loadByOwner(int ownerId) async {
    _setLoading(true); _error = null;
    try {
      final res = await _api.get('/api/branches/owner/$ownerId');
      final data = res['data'] as List<dynamic>? ?? [];
      _branches = data.map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) { _error = ApiClient.parseError(e); } finally { _setLoading(false); }
  }

  Future<Branch?> createBranch(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/api/branches', data);
      final b = Branch.fromJson(res['data'] as Map<String, dynamic>);
      _branches = [..._branches, b]; notifyListeners(); return b;
    } catch (e) { _error = ApiClient.parseError(e); notifyListeners(); return null; }
  }

  // Thêm hàm updateBranch vì màn hình branch_management_screen.dart đang gọi hàm này
  Future<bool> updateBranch(int branchId, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('/api/branches/$branchId', data);
      final updated = Branch.fromJson(res['data'] as Map<String, dynamic>);
      _branches = _branches.map((b) => b.id == branchId ? updated : b).toList();
      notifyListeners(); return true;
    } catch (e) { _error = ApiClient.parseError(e); notifyListeners(); return false; }
  }

  Future<bool> deleteBranch(int branchId) async {
    try {
      await _api.delete('/api/branches/$branchId');
      _branches = _branches.where((b) => b.id != branchId).toList();
      notifyListeners(); return true;
    } catch (e) { _error = ApiClient.parseError(e); notifyListeners(); return false; }
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
}