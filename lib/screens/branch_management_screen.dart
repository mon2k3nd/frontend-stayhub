import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/branch_model.dart';
import '../providers/branch_provider.dart';

const kNavy = Color(0xFF0B192C);
const kGold = Color(0xFFFFD700);
const kCardBg = Color(0xFF162032);

class BranchManagementScreen extends StatefulWidget {
  final int ownerId;
  const BranchManagementScreen({super.key, required this.ownerId});

  @override
  State<BranchManagementScreen> createState() => _BranchManagementScreenState();
}

class _BranchManagementScreenState extends State<BranchManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BranchProvider>().loadByOwner(widget.ownerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: const Text('Quản lý dãy trọ',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(),
        backgroundColor: kGold,
        foregroundColor: kNavy,
        icon: const Icon(Icons.add),
        label: const Text('Thêm dãy trọ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<BranchProvider>(
        builder: (_, bp, __) {
          if (bp.isLoading) {
            return const Center(child: CircularProgressIndicator(color: kGold));
          }
          if (bp.branches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.apartment, color: Colors.white24, size: 64),
                  const SizedBox(height: 12),
                  const Text('Chưa có dãy trọ nào',
                      style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm dãy trọ đầu tiên'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kGold, foregroundColor: kNavy),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: bp.branches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _BranchCard(
              branch: bp.branches[i],
              onEdit: () => _showEditDialog(bp.branches[i]),
              onDelete: () => _confirmDelete(bp.branches[i]),
              onView: () => Navigator.pushNamed(context, '/room-grid',
                  arguments: {
                    'branchId': bp.branches[i].id,
                    'branchName': bp.branches[i].branchName,
                    'ownerId': widget.ownerId,
                  }),
            ),
          );
        },
      ),
    );
  }

  void _showCreateDialog() {
    _showBranchDialog(null);
  }

  void _showEditDialog(BranchModel branch) {
    _showBranchDialog(branch);
  }

  void _showBranchDialog(BranchModel? existing) {
    final nameCtrl = TextEditingController(text: existing?.branchName);
    final addrCtrl = TextEditingController(text: existing?.address);
    final descCtrl = TextEditingController(text: existing?.description);
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(existing == null ? 'Thêm dãy trọ mới' : 'Chỉnh sửa dãy trọ',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _inputField(nameCtrl, 'Tên dãy trọ', validator: (v) =>
                  v!.isEmpty ? 'Vui lòng nhập tên dãy trọ' : null),
              const SizedBox(height: 12),
              _inputField(addrCtrl, 'Địa chỉ', validator: (v) =>
                  v!.isEmpty ? 'Vui lòng nhập địa chỉ' : null),
              const SizedBox(height: 12),
              _inputField(descCtrl, 'Mô tả (tùy chọn)', maxLines: 2),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final bp = context.read<BranchProvider>();
                    final data = {
                      'ownerId': widget.ownerId,
                      'branchName': nameCtrl.text.trim(),
                      'address': addrCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                    };
                    bool ok;
                    if (existing == null) {
                      ok = await bp.createBranch(data);
                    } else {
                      ok = await bp.updateBranch(existing.id, data);
                    }
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok
                            ? (existing == null
                                ? 'Thêm dãy trọ thành công!'
                                : 'Cập nhật thành công!')
                            : 'Có lỗi xảy ra!'),
                        backgroundColor: ok ? Colors.green : Colors.red,
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kGold,
                    foregroundColor: kNavy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(existing == null ? 'Thêm dãy trọ' : 'Lưu thay đổi',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String label,
      {String? Function(String?)? validator, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      validator: validator,
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

  void _confirmDelete(BranchModel branch) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        title: const Text('Xóa dãy trọ?', style: TextStyle(color: Colors.white)),
        content: Text(
            'Bạn có chắc muốn xóa dãy trọ "${branch.branchName}"? Hành động này không thể hoàn tác.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok =
                  await context.read<BranchProvider>().deleteBranch(branch.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(ok ? 'Đã xóa dãy trọ!' : 'Không thể xóa dãy trọ!'),
                  backgroundColor: ok ? Colors.green : Colors.red,
                ));
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final BranchModel branch;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _BranchCard({
    required this.branch,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onView,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: kGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.apartment, color: kGold, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(branch.branchName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(branch.address,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text('${branch.totalRooms} phòng',
                          style: const TextStyle(
                              color: kGold, fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: kCardBg,
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, color: Colors.white70, size: 16),
                        SizedBox(width: 8),
                        Text('Chỉnh sửa',
                            style: TextStyle(color: Colors.white70)),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete, color: Colors.redAccent, size: 16),
                        SizedBox(width: 8),
                        Text('Xóa',
                            style: TextStyle(color: Colors.redAccent)),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
