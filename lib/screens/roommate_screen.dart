import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/roommate_model.dart';
import '../api/api_client.dart';

const kNavy = Color(0xFF0B192C);
const kGold = Color(0xFFFFD700);
const kCardBg = Color(0xFF162032);

final _dateFmt = DateFormat('dd/MM/yyyy');

class RoommateScreen extends StatefulWidget {
  final int contractId;
  final int roomId;
  final String roomName;

  const RoommateScreen({
    super.key,
    required this.contractId,
    required this.roomId,
    required this.roomName,
  });

  @override
  State<RoommateScreen> createState() => _RoommateScreenState();
}

class _RoommateScreenState extends State<RoommateScreen> {
  final _api = ApiClient();
  List<RoommateModel> _roommates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/roommates/contract/${widget.contractId}');
      setState(() => _roommates = (res['data'] as List)
          .map((e) => RoommateModel.fromJson(e))
          .toList());
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: Text('Người ở cùng - ${widget.roomName}',
            style: const TextStyle(color: Colors.white, fontSize: 15)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        backgroundColor: kGold,
        foregroundColor: kNavy,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm người ở cùng',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kGold))
          : _roommates.isEmpty
              ? const Center(
                  child: Text('Chưa có người ở cùng',
                      style: TextStyle(color: Colors.white54)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _roommates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildCard(_roommates[i]),
                ),
    );
  }

  Widget _buildCard(RoommateModel r) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: kGold.withOpacity(0.15),
              child: Text(
                r.fullName[0].toUpperCase(),
                style: const TextStyle(
                    color: kGold, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.fullName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  if (r.phoneNumber != null)
                    Text(r.phoneNumber!,
                        style:
                            const TextStyle(color: Colors.white54, fontSize: 12)),
                  if (r.cccdNumber != null)
                    Text('CCCD: ${r.cccdNumber}',
                        style:
                            const TextStyle(color: Colors.white38, fontSize: 11)),
                  if (r.checkInDate != null)
                    Text('Ngày vào: ${_dateFmt.format(r.checkInDate!)}',
                        style: const TextStyle(
                            color: Colors.greenAccent, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmCheckout(r),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final cccdCtrl = TextEditingController();
    final hometownCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Thêm người ở cùng',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _inputField(nameCtrl, 'Họ và tên *', validator: (v) =>
                    v!.isEmpty ? 'Vui lòng nhập họ tên' : null),
                const SizedBox(height: 12),
                _inputField(phoneCtrl, 'Số điện thoại',
                    type: TextInputType.phone),
                const SizedBox(height: 12),
                _inputField(cccdCtrl, 'Số CCCD'),
                const SizedBox(height: 12),
                _inputField(hometownCtrl, 'Quê quán'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      try {
                        await _api.post('/api/roommates', {
                          'contractId': widget.contractId,
                          'roomId': widget.roomId,
                          'fullName': nameCtrl.text.trim(),
                          'phoneNumber': phoneCtrl.text.trim(),
                          'cccdNumber': cccdCtrl.text.trim(),
                          'hometown': hometownCtrl.text.trim(),
                          'checkInDate': DateTime.now().toIso8601String().split('T')[0],
                          'isActive': true,
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Thêm người ở cùng thành công!'),
                            backgroundColor: Colors.green,
                          ));
                        }
                      } catch (e) {
                        if (context.mounted) {
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
                    child: const Text('Thêm',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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
        fillColor: const Color(0x14FFFFFF),
      ),
    );
  }

  void _confirmCheckout(RoommateModel r) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        title: const Text('Xóa người ở cùng?',
            style: TextStyle(color: Colors.white)),
        content: Text('"${r.fullName}" sẽ được đánh dấu là đã rời đi.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _api.post('/api/roommates/${r.id}/checkout', {});
              _load();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
