import 'package:flutter/material.dart';
  import 'package:flutter_secure_storage/flutter_secure_storage.dart';
  import '../api/api_client.dart';

  class AuthProvider extends ChangeNotifier {
    final ApiClient _api = ApiClient();
    final FlutterSecureStorage _storage = const FlutterSecureStorage();

    int? _userId; String? _userName, _phoneNumber, _email, _role, _planType, _accountStatus, _avatarUrl;
    bool _isLoading = false;

    int?    get userId        => _userId;
    String? get userName      => _userName;
    String? get phoneNumber   => _phoneNumber;
    String? get email         => _email;
    String? get role          => _role;
    String? get planType      => _planType;
    String? get accountStatus => _accountStatus;
    String? get avatarUrl     => _avatarUrl;
    bool    get isLoading     => _isLoading;
    bool    get isLoggedIn    => _userId != null;
    bool    get isOwner       => _role == 'OWNER';
    bool    get isStaff       => _role == 'STAFF';
    bool    get isTenant      => _role == 'TENANT';

    Future<bool> tryAutoLogin() async {
      final token = await _storage.read(key: 'access_token');
      final uid   = await _storage.read(key: 'user_id');
      if (token == null || uid == null) return false;
      _userId = int.tryParse(uid);
      _role        = await _storage.read(key: 'user_role');
      _userName    = await _storage.read(key: 'user_name');
      _planType    = await _storage.read(key: 'plan_type');
      _phoneNumber = await _storage.read(key: 'phone_number');
      _email       = await _storage.read(key: 'user_email');
      notifyListeners();
      return _userId != null;
    }

    Future<Map<String, dynamic>> sendOtp({required String target, required String channel}) async {
      try {
        final res = await _api.post('/api/auth/send-otp',
            {'target': target, 'channel': channel, 'type': 'register'});
        return {'success': true, 'devOtp': res['devOtp']};
      } catch (e) { return {'success': false, 'message': ApiClient.parseError(e)}; }
    }

    Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
      _setLoading(true);
      try {
        final res = await _api.post('/api/auth/register', data);
        if (res['token'] != null) { await _saveSession(res); return {'success': true}; }
        return {'success': false, 'message': res['message'] ?? 'Đăng ký thất bại'};
      } catch (e) { return {'success': false, 'message': ApiClient.parseError(e)};
      } finally { _setLoading(false); }
    }

    Future<Map<String, dynamic>> login(String emailOrPhone, String password) async {
      _setLoading(true);
      try {
        final res = await _api.post('/api/auth/login',
            {'emailOrPhone': emailOrPhone, 'password': password});
        if (res['token'] != null) { await _saveSession(res); return {'success': true}; }
        return {'success': false, 'message': res['message'] ?? 'Đăng nhập thất bại'};
      } catch (e) { return {'success': false, 'message': ApiClient.parseError(e)};
      } finally { _setLoading(false); }
    }

    Future<void> logout() async {
      _userId = null; _role = _userName = _planType = _phoneNumber = _email = _avatarUrl = null;
      await _api.clearToken(); notifyListeners();
    }

    Future<void> _saveSession(Map<String, dynamic> res) async {
      final token = res['token'] as String;
      final user  = res['user'] as Map<String, dynamic>? ?? {};
      final rawId = user['id'];
      _userId      = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
      _userName    = user['fullName'] as String?;
      _email       = user['email']   as String?;
      _phoneNumber = user['phone']   as String?;
      _role        = user['roleId']  as String?;
      _planType    = user['packageId'] as String?;
      _accountStatus = user['status']?.toString();
      await _api.saveToken(token);
      await _storage.write(key: 'user_id',      value: _userId?.toString() ?? '');
      await _storage.write(key: 'user_role',    value: _role        ?? 'TENANT');
      await _storage.write(key: 'user_name',    value: _userName    ?? '');
      await _storage.write(key: 'plan_type',    value: _planType    ?? 'FREE');
      await _storage.write(key: 'phone_number', value: _phoneNumber ?? '');
      await _storage.write(key: 'user_email',   value: _email       ?? '');
      notifyListeners();
    }

    void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  }
  