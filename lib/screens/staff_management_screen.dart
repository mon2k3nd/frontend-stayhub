import 'package:flutter/material.dart';
import '../api/api_client.dart';

const kNavy = Color(0xFF0B192C);
const kGold = Color(0xFFFFD700);
const kCardBg = Color(0xFF162032);

class StaffManagementScreen extends StatefulWidget {
  final int ownerId;
  const StaffManagementScreen({super.key, required this.ownerId});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final _api = ApiClient();
  List<Map<String, dynamic>> _staff = [];
  bool _isLoading = true;

  final _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void initState() {
    super.initState();
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/staff/owner/${widget.ownerId}');
      setState(() => _staff = List<Map<String, dynamic>>.from(res['data'] ?? []));
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
        title: const Text('Quản lý nhân viên',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateStaffDialog(),
        backgroundColor: kGold,
        foregroundColor: kNavy,
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm nhân viên',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kGold))
          : _staff.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadStaff,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _staff.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildStaffCard(_staff[i]),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, color: Colors.white24, size: 64),
          const SizedBox(height: 12),
          const Text('Chưa có nhân viên nào',
              style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCreateStaffDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm nhân viên'),
            style: ElevatedButton.styleFrom(
                backgroundColor: kGold, foregroundColor: kNavy),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> staff) {
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
                (staff['name'] ?? 'S')[0].toUpperCase(),
                style: const TextStyle(
                    color: kGold, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff['name'] ?? 'Nhân viên',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(staff['phoneNumber'] ?? '',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.lightBlueAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Nhân viên',
                        style: TextStyle(
                            color: Colors.lightBlueAccent, fontSize: 10)),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              color: kCardBg,
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              onSelected: (v) {
                if (v == 'schedule') _showScheduleDialog(staff);
                if (v == 'delete') _confirmDelete(staff);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'schedule',
                  child: Row(children: [
                    Icon(Icons.schedule, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text('Lịch trực', style: TextStyle(color: Colors.white70)),
                  ]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.person_remove, color: Colors.redAccent, size: 16),
                    SizedBox(width: 8),
                    Text('Xóa', style: TextStyle(color: Colors.redAccent)),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateStaffDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Thêm nhân viên mới',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field(nameCtrl, 'Tên nhân viên', Icons.person, (v) =>
                  v!.isEmpty ? 'Nhập tên nhân viên' : null),
              const SizedBox(height: 12),
              _field(phoneCtrl, 'Số điện thoại', Icons.phone, (v) =>
                  v!.length < 10 ? 'Số điện thoại không hợp lệ' : null,
                  type: TextInputType.phone),
              const SizedBox(height: 12),
              _field(passCtrl, 'Mật khẩu', Icons.lock, (v) =>
                  v!.length < 6 ? 'Mật khẩu ít nhất 6 ký tự' : null,
                  obscure: true),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await _api.post('/api/staff/create', {
                        'name': nameCtrl.text.trim(),
                        'phoneNumber': phoneCtrl.text.trim(),
                        'password': passCtrl.text,
                        'ownerId': widget.ownerId,
                        'branchIds': [],
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadStaff();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Tạo tài khoản nhân viên thành công!'),
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
                  child: const Text('Tạo tài khoản',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      String? Function(String?) validator,
      {TextInputType? type, bool obscure = false}) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      keyboardType: type,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
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

  void _showScheduleDialog(Map<String, dynamic> staff) {
    final selected = <String>{};
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: kCardBg,
          title: Text('Lịch trực: ${staff['name']}',
              style: const TextStyle(color: Colors.white, fontSize: 15)),
          content: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _weekdays.map((d) {
              final isSelected = selected.contains(d);
              return GestureDetector(
                onTap: () => setS(() {
                  if (isSelected) {
                    selected.remove(d);
                  } else {
                    selected.add(d);
                  }
                }),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? kGold : Colors.white12,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(d,
                        style: TextStyle(
                            color: isSelected ? kNavy : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Gọi API cập nhật lịch trực
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Đã cập nhật lịch trực!'),
                  backgroundColor: Colors.green,
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: kGold),
              child: const Text('Lưu lịch', style: TextStyle(color: kNavy)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> staff) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        title: const Text('Xóa nhân viên?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Xóa "${staff['name']}" khỏi danh sách nhân viên?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _api.delete(
                  '/api/staff/${staff['id']}/owner/${widget.ownerId}');
              _loadStaff();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
