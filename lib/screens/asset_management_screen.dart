import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/asset_model.dart';
import '../api/api_client.dart';

const kNavy = Color(0xFF0B192C);
const kGold = Color(0xFFFFD700);
const kCardBg = Color(0xFF162032);

final _fmt = NumberFormat('#,###', 'vi_VN');

class AssetManagementScreen extends StatefulWidget {
  final int roomId;
  final String roomName;

  const AssetManagementScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<AssetManagementScreen> createState() => _AssetManagementScreenState();
}

class _AssetManagementScreenState extends State<AssetManagementScreen> {
  final _api = ApiClient();
  List<AssetModel> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/assets/room/${widget.roomId}');
      setState(() => _assets = (res['data'] as List)
          .map((e) => AssetModel.fromJson(e))
          .toList());
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  double get _totalValue => _assets.fold(
      0.0, (sum, a) => sum + (a.value ?? 0) * a.quantity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: Text('Tài sản - ${widget.roomName}',
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: kGold,
        foregroundColor: kNavy,
        icon: const Icon(Icons.add),
        label: const Text('Thêm tài sản',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          if (_assets.isNotEmpty) _buildTotalCard(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kGold))
                : _assets.isEmpty
                    ? const Center(
                        child: Text('Chưa có tài sản nào',
                            style: TextStyle(color: Colors.white54)))
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _assets.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _buildAssetCard(_assets[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1A2A3A), Color(0xFF0B192C)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2, color: kGold, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_assets.length} loại tài sản',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('Tổng giá trị: ${_fmt.format(_totalValue)} đ',
                  style: const TextStyle(
                      color: kGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(AssetModel asset) {
    final statusColor = _statusColor(asset.assetStatus);
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_assetIcon(asset.assetStatus),
              color: statusColor, size: 20),
        ),
        title: Text(asset.assetName,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text('Số lượng: ${asset.quantity}',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            if (asset.value != null)
              Text('Giá trị: ${_fmt.format(asset.value! * asset.quantity)} đ',
                  style: const TextStyle(
                      color: Colors.greenAccent, fontSize: 11)),
            if (asset.conditionNote != null && asset.conditionNote!.isNotEmpty)
              Text(asset.conditionNote!,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(asset.statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _confirmDelete(asset),
              child: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '1');
    final valueCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedStatus = 'GOOD';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Thêm tài sản',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _inputField(nameCtrl, 'Tên tài sản *', validator: (v) =>
                      v!.isEmpty ? 'Nhập tên tài sản' : null),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _inputField(qtyCtrl, 'Số lượng',
                              type: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _inputField(valueCtrl, 'Giá trị (đ)',
                              type: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    dropdownColor: kCardBg,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Tình trạng',
                      labelStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kGold),
                      ),
                      filled: true,
                      fillColor: Colors.white38,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'GOOD', child: Text('Tốt')),
                      DropdownMenuItem(value: 'DAMAGED', child: Text('Hỏng')),
                      DropdownMenuItem(value: 'LOST', child: Text('Mất')),
                      DropdownMenuItem(value: 'REPAIRED', child: Text('Đã sửa')),
                    ],
                    onChanged: (v) => setS(() => selectedStatus = v!),
                  ),
                  const SizedBox(height: 12),
                  _inputField(noteCtrl, 'Ghi chú tình trạng'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        try {
                          await _api.post('/api/assets', {
                            'roomId': widget.roomId,
                            'assetName': nameCtrl.text.trim(),
                            'quantity': int.tryParse(qtyCtrl.text) ?? 1,
                            'value': double.tryParse(valueCtrl.text),
                            'conditionNote': noteCtrl.text.trim(),
                            'assetStatus': selectedStatus,
                          });
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _load();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thêm tài sản thành công!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text('Lỗi: $e'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: kNavy,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Thêm tài sản',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label,
      {String? Function(String?)? validator, TextInputType? type}) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kGold),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        filled: true,
        fillColor: Colors.white38,
      ),
    );
  }

  void _confirmDelete(AssetModel asset) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        title: const Text('Xóa tài sản?',
            style: TextStyle(color: Colors.white)),
        content: Text('Xóa "${asset.assetName}" khỏi danh sách?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _api.delete('/api/assets/${asset.id}');
              _load();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'GOOD': return Colors.greenAccent;
      case 'DAMAGED': return Colors.redAccent;
      case 'LOST': return Colors.grey;
      case 'REPAIRED': return Colors.orangeAccent;
      default: return Colors.white54;
    }
  }

  IconData _assetIcon(String s) {
    switch (s) {
      case 'DAMAGED': return Icons.warning;
      case 'LOST': return Icons.not_interested;
      case 'REPAIRED': return Icons.build;
      default: return Icons.inventory;
    }
  }
}
