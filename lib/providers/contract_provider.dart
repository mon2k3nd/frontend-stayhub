import 'package:flutter/material.dart';
import '../api/api_client.dart';
import '../models/contract_model.dart'; // Đảm bảo import đúng model của bạn

class ContractProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  List<ContractModel> _contracts = [];
  bool _isLoading = false;
  String? _error;

  List<ContractModel> get contracts => List.unmodifiable(_contracts);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadByOwner(int ownerId) async {
    _setLoading(true); _error = null;
    try {
      final res = await _api.get('/api/contracts/owner/$ownerId');
      _contracts = (res['data'] as List<dynamic>? ?? []).map((e) => Contract.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) { _error = ApiClient.parseError(e); } finally { _setLoading(false); }
  }
  // ... Các hàm loadByOwner, loadByTenant, v.v giữ nguyên ...
  Future<void> loadByTenant(int tenantId) async {
    _setLoading(true); _error = null;
    try {
      final res = await _api.get('/api/contracts/tenant/$tenantId');
      _contracts = (res['data'] as List<dynamic>? ?? []).map((e) => Contract.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) { _error = ApiClient.parseError(e); } finally { _setLoading(false); }
  }
  // ĐÂY LÀ NƠI ĐẶT HÀM RENEW CONTRACT CHUẨN
  Future<bool> renewContract(int contractId, int months) async {
    try {
      final res = await _api.post('/api/contracts/$contractId/renew', {'months': months});
      // Phải map đúng theo tên Model bạn đang dùng (ở đây UI dùng ContractModel)
      final updated = ContractModel.fromJson(res['data'] as Map<String, dynamic>);

      _contracts = _contracts.map((c) => c.id == contractId ? updated : c).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _error = ApiClient.parseError(e);
      notifyListeners();
      return false;
    }
  }
}