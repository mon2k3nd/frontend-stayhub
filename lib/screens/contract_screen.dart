import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/contract_model.dart';
import '../providers/contract_provider.dart';

const kNavy = Color(0xFF0B192C);
const kGold = Color(0xFFFFD700);
const kCardBg = Color(0xFF162032);
final _fmt = NumberFormat('#,###', 'vi_VN');
final _dateFmt = DateFormat('dd/MM/yyyy');

class ContractScreen extends StatefulWidget {
  final int userId;
  final bool isOwner;

  const ContractScreen({
    super.key,
    required this.userId,
    required this.isOwner,
  });

  @override
  State<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends State<ContractScreen> {
  String _filter = 'ALL'; // ALL | ACTIVE | EXPIRED | TERMINATED

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cp = context.read<ContractProvider>();
      if (widget.isOwner) {
        cp.loadByOwner(widget.userId);
      } else {
        cp.loadByTenant(widget.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      appBar: AppBar(
        backgroundColor: kNavy,
        title: const Text('Hợp đồng thuê phòng',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (widget.isOwner)
            IconButton(
              icon: const Icon(Icons.add, color: kGold),
              onPressed: () => Navigator.pushNamed(context, '/create-contract'),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: Consumer<ContractProvider>(
              builder: (_, cp, __) {
                if (cp.isLoading) {
                  return const Center(
                      child: CircularProgressIndicator(color: kGold));
                }
                final filtered = cp.contracts
                    .where((c) =>
                _filter == 'ALL' || c.status == _filter)
                    .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.article_outlined,
                            color: Colors.white24, size: 60),
                        const SizedBox(height: 12),
                        const Text('Chưa có hợp đồng nào',
                            style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildContractCard(filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = [
      ('ALL', 'Tất cả'),
      ('ACTIVE', 'Đang hiệu lực'),
      ('PENDING', 'Chờ ký'),
      ('EXPIRED', 'Hết hạn'),
      ('TERMINATED', 'Đã chấm dứt'),
    ];

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: filters.map((f) {
          final isSelected = _filter == f.$1;
          return GestureDetector(
            onTap: () => setState(() => _filter = f.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? kGold.withOpacity(0.15) : kCardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected ? kGold : Colors.white24, width: 1),
              ),
              child: Text(f.$2,
                  style: TextStyle(
                      color: isSelected ? kGold : Colors.white54,
                      fontSize: 12,
                      fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContractCard(ContractModel c) {
    final statusColor = _statusColor(c.status);
    final statusLabel = _statusLabel(c.status);

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showContractDetail(c),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hợp đồng #${c.id}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(statusLabel,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _infoRow(Icons.calendar_today,
                    '${_dateFmt.format(c.startDate)} → ${_dateFmt.format(c.endDate)}',
                    Colors.white70),
                const SizedBox(height: 4),
                _infoRow(Icons.attach_money,
                    'Tiền thuê: ${_fmt.format(c.monthlyRent)} đ/tháng',
                    Colors.greenAccent),
                if (c.depositAmount != null) ...[
                  const SizedBox(height: 4),
                  _infoRow(Icons.savings,
                      'Tiền cọc: ${_fmt.format(c.depositAmount!)} đ',
                      Colors.orangeAccent),
                ],
                if (c.isActive) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _contractProgress(c),
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(statusColor),
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text('Còn ${c.daysRemaining} ngày',
                      style: TextStyle(color: statusColor, fontSize: 11)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: TextStyle(color: color, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  void _showContractDetail(ContractModel c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
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
            Text('Hợp đồng #${c.id}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _detailRow('Ngày bắt đầu', _dateFmt.format(c.startDate)),
            _detailRow('Ngày kết thúc', _dateFmt.format(c.endDate)),
            _detailRow('Tiền thuê',
                '${_fmt.format(c.monthlyRent)} đ/tháng'),
            if (c.depositAmount != null)
              _detailRow('Tiền cọc', '${_fmt.format(c.depositAmount!)} đ'),
            if (c.electricityPrice != null)
              _detailRow('Giá điện',
                  '${_fmt.format(c.electricityPrice!)} đ/kWh'),
            if (c.waterPrice != null)
              _detailRow('Giá nước', '${_fmt.format(c.waterPrice!)} đ/m³'),
            const Divider(color: Colors.white12, height: 24),
            if (widget.isOwner && c.status == 'ACTIVE') ...[
              _sheetBtn('Gia hạn hợp đồng', Colors.lightBlueAccent, () {
                Navigator.pop(context);
                _showRenewDialog(c);
              }),
              const SizedBox(height: 8),
              _sheetBtn('Chấm dứt hợp đồng', Colors.redAccent, () {
                Navigator.pop(context);
                _showTerminateDialog(c);
              }),
              const SizedBox(height: 8),
              _sheetBtn('Thanh lý hợp đồng', Colors.orangeAccent, () {
                Navigator.pop(context);
                _showLiquidateDialog(c);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sheetBtn(String label, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          side: BorderSide(color: color),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      ),
    );
  }

  void _showRenewDialog(ContractModel c) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        title: const Text('Gia hạn hợp đồng',
            style: TextStyle(color: Colors.white)),
        content: const Text('Gia hạn thêm 12 tháng?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok =
              await context.read<ContractProvider>().renewContract(c.id, 12);
              _showSnack(ok ? 'Gia hạn thành công!' : 'Có lỗi xảy ra', ok);
            },
            style: ElevatedButton.styleFrom(backgroundColor: kGold),
            child:
            const Text('Gia hạn 12 tháng', style: TextStyle(color: kNavy)),
          ),
        ],
      ),
    );
  }

  void _showTerminateDialog(ContractModel c) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        title: const Text('Chấm dứt hợp đồng',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Lý do chấm dứt...',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await context
                  .read<ContractProvider>()
                  .terminateContract(c.id, ctrl.text.trim());
              _showSnack(
                  ok ? 'Đã chấm dứt hợp đồng!' : 'Có lỗi xảy ra', ok);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showLiquidateDialog(ContractModel c) {
    final ctrl = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCardBg,
        title: const Text('Thanh lý hợp đồng',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Số tiền khấu trừ tài sản hỏng (đ):',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _showSnack('Đã thanh lý hợp đồng!', true);
            },
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('Thanh lý'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  double _contractProgress(ContractModel c) {
    final total = c.endDate.difference(c.startDate).inDays;
    final elapsed = DateTime.now().difference(c.startDate).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE': return Colors.greenAccent;
      case 'PENDING': return Colors.lightBlueAccent;
      case 'EXPIRED': return Colors.redAccent;
      case 'TERMINATED': return Colors.redAccent;
      case 'LIQUIDATED': return Colors.orangeAccent;
      default: return Colors.white54;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ACTIVE': return 'Đang hiệu lực';
      case 'PENDING': return 'Chờ ký';
      case 'EXPIRED': return 'Hết hạn';
      case 'TERMINATED': return 'Đã chấm dứt';
      case 'LIQUIDATED': return 'Đã thanh lý';
      default: return status;
    }
  }
}