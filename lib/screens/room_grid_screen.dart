import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/room_provider.dart';
import '../models/room_model.dart';

const kNavy = Color(0xFF0B192C);
const kGold = Color(0xFFFFD700);
const kCardBg = Color(0xFF162032);

class RoomGridScreen extends StatefulWidget {
  final int ownerId;
  final int? branchId;
  final String branchName;

  const RoomGridScreen({
    super.key,
    required this.ownerId,
    this.branchId,
    required this.branchName,
  });

  @override
  State<RoomGridScreen> createState() => _RoomGridScreenState();
}

class _RoomGridScreenState extends State<RoomGridScreen> {
  // null = hiển thị tất cả
  String? _filterStatus;

  // Các giá trị status khớp đúng với backend enum
  static const _allStatuses = ['TRONG', 'DA_THUE', 'BAO_TRI', 'DONG_CUA'];

  static const _statusLabel = {
    'TRONG': 'Trống',
    'DA_THUE': 'Đã thuê',
    'BAO_TRI': 'Bảo trì',
    'DONG_CUA': 'Đóng cửa',
  };

  static const _statusColor = {
    'TRONG': Color(0xFF4CAF50),
    'DA_THUE': Color(0xFF2196F3),
    'BAO_TRI': Color(0xFFFF9800),
    'DONG_CUA': Color(0xFF9E9E9E),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRooms());
  }

  void _loadRooms() {
    final provider = context.read<RoomProvider>();
    if (widget.branchId != null) {
      provider.loadByBranch(widget.branchId!);
    } else {
      provider.loadByOwner(widget.ownerId);
    }
  }

  List<RoomModel> _filtered(List<RoomModel> all) =>
      _filterStatus == null ? all : all.where((r) => r.status == _filterStatus).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: Text(widget.branchName,
            style: const TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: kGold),
            onPressed: () => Navigator.pushNamed(context, '/create-room'),
          ),
        ],
      ),
      body: Consumer<RoomProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: kGold));
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 12),
                  Text('Lỗi tải dữ liệu', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loadRooms,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                    style: ElevatedButton.styleFrom(backgroundColor: kGold, foregroundColor: kNavy),
                  ),
                ],
              ),
            );
          }

          final rooms = _filtered(provider.rooms);

          return Column(
            children: [
              _buildFilterBar(provider.rooms),
              _buildLegend(),
              Expanded(
                child: rooms.isEmpty
                    ? const Center(
                        child: Text('Không có phòng',
                            style: TextStyle(color: Colors.white54)))
                    : RefreshIndicator(
                        onRefresh: () async => _loadRooms(),
                        color: kGold,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: rooms.length,
                          itemBuilder: (context, i) => _buildRoomCard(rooms[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(List<RoomModel> all) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: kCardBg,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip(null, 'Tất cả (${all.length})', all),
          ...(_allStatuses.map((s) {
            final count = all.where((r) => r.status == s).length;
            return _filterChip(s, '${_statusLabel[s]} ($count)', all);
          })),
        ],
      ),
    );
  }

  Widget _filterChip(String? status, String label, List<RoomModel> all) {
    final selected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: GestureDetector(
        onTap: () => setState(() => _filterStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? kGold : Colors.white10,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected ? kNavy : Colors.white70,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: kNavy,
      child: Row(
        children: _allStatuses.map((s) => Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(children: [
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                  color: _statusColor[s], shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(_statusLabel[s] ?? s,
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        )).toList(),
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    final color = _statusColor[room.status] ?? Colors.grey;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/room-detail',
          arguments: {'roomId': room.id}),
      child: Container(
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(
                room.isDaThue
                    ? Icons.person
                    : room.isBaoTri
                        ? Icons.build
                        : room.isDongCua
                            ? Icons.lock
                            : Icons.home,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(room.roomName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(room.statusLabel,
                  style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
