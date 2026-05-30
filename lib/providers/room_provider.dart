import 'package:flutter/material.dart';
  import '../api/api_client.dart';
  import '../models/room_model.dart';

  class RoomProvider extends ChangeNotifier {
    final ApiClient _api = ApiClient();
    List<Room> _rooms = []; bool _isLoading = false; String? _error;

    List<Room> get rooms      => List.unmodifiable(_rooms);
    bool    get isLoading  => _isLoading;
    String? get error      => _error;

    Future<void> loadByBranch(int branchId) async {
      _setLoading(true); _error = null;
      try {
        final res = await _api.get('/api/rooms/branch/$branchId');
        _rooms = (res['data'] as List<dynamic>? ?? []).map((e) => Room.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) { _error = ApiClient.parseError(e); } finally { _setLoading(false); }
    }

    Future<void> loadByOwner(int ownerId, {String? status}) async {
      _setLoading(true); _error = null;
      try {
        final res = await _api.get('/api/rooms/owner/$ownerId',
            params: status != null ? {'status': status} : null);
        _rooms = (res['data'] as List<dynamic>? ?? []).map((e) => Room.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) { _error = ApiClient.parseError(e); } finally { _setLoading(false); }
    }

    Future<Room?> createRoom(Map<String, dynamic> data) async {
      try {
        final res = await _api.post('/api/rooms', data);
        final r = Room.fromJson(res['data'] as Map<String, dynamic>);
        _rooms = [..._rooms, r]; notifyListeners(); return r;
      } catch (e) { _error = ApiClient.parseError(e); notifyListeners(); return null; }
    }

    Future<bool> updateRoom(int roomId, Map<String, dynamic> data) async {
      try {
        final res = await _api.put('/api/rooms/$roomId', data);
        final updated = Room.fromJson(res['data'] as Map<String, dynamic>);
        _rooms = _rooms.map((r) => r.id == roomId ? updated : r).toList();
        notifyListeners(); return true;
      } catch (e) { _error = ApiClient.parseError(e); notifyListeners(); return false; }
    }

    Future<bool> deleteRoom(int roomId) async {
      try {
        await _api.delete('/api/rooms/$roomId');
        _rooms = _rooms.where((r) => r.id != roomId).toList();
        notifyListeners(); return true;
      } catch (e) { _error = ApiClient.parseError(e); notifyListeners(); return false; }
    }

    void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  }
  