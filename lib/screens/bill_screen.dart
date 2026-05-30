import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../models/bill_model.dart';

const kNavy = Color(0xFF0B192C);
const kGold = Color(0xFFFFD700);
const kCardBg = Color(0xFF162032);
final _fmt = NumberFormat('#,###', 'vi_VN');

class BillScreen extends StatefulWidget {
  final int userId;
  final bool isOwner;

  const BillScreen({super.key, required this.userId, required this.isOwner});

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiClient();
  late TabController _tabCtrl;
  List<BillModel> _unpaid = [];
  List<BillModel> _paid = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadBills();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBills() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/api/bills/tenant/${widget.userId}');
      final all = (res['data'] as List? ?? [])
          .map((e) => BillModel.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _unpaid = all.where((b) => !b.isPaid).toList();
        _paid = all.where((b) => b.isPaid).toList();
      });
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
        title: const Text('Hóa đơn',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white54),
            onPressed: _loadBills,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: kGold,
          labelColor: kGold,
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(text: 'Chưa TT (${_unpaid.length})'),
            Tab(text: 'Đã TT (${_paid.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kGold))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildBillList(_unpaid, isPaid: false),
                _buildBillList(_paid, isPaid: true),
              ],
            ),
    );
  }

  Widget _buildBillList(List<BillModel> bills, {required bool isPaid}) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPaid ? Icons.check_circle_outline : Icons.receipt_outlined,
              color: isPaid ? Colors.greenAccent : Colors.white24,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              isPaid
                  ? 'Chưa có hóa đơn đã thanh toán'
                  : 'Không có hóa đơn chờ thanh toán',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadBills,
      color: kGold,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: bills.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _buildBillCard(bills[i]),
      ),
    );
  }

  Widget _buildBillCard(BillModel bill) {
    final statusColor =
        bill.isPaid ? Colors.greenAccent : Colors.orangeAccent;
    final overdueBadge = bill.isOverdue;

    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border(
            left: BorderSide(
                color: overdueBadge ? Colors.redAccent : statusColor,
                width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hóa đơn ${bill.periodLabel}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                Row(
                  children: [
                    if (overdueBadge)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Quá hạn',
                            style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        bill.isPaid ? 'Đã thanh toán' : 'Chờ thanh toán',
                        style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),
            if (bill.rentAmount != null)
              _row('Tiền thuê', '${_fmt.format(bill.rentAmount!)} đ'),
            if (bill.electricAmount != null)
              _row('Tiền điện', '${_fmt.format(bill.electricAmount!)} đ'),
            if (bill.waterAmount != null)
              _row('Tiền nước', '${_fmt.format(bill.waterAmount!)} đ'),
            if (bill.serviceAmount != null && bill.serviceAmount! > 0)
              _row('Dịch vụ', '${_fmt.format(bill.serviceAmount!)} đ'),
            const Divider(color: Colors.white12, height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TỔNG CỘNG',
                    style: TextStyle(
                        color: Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                Text(
                  '${_fmt.format(bill.totalAmount ?? 0)} đ',
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ],
            ),
            if (!bill.isPaid) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDetail(bill),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Chi tiết'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentQr(bill),
                      icon: const Icon(Icons.qr_code, size: 16),
                      label: const Text('Thanh toán'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kGold,
                        foregroundColor: kNavy,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }

  void _showDetail(BillModel bill) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('Chi tiết hóa đơn ${bill.periodLabel}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (bill.electricCurrent != null) ...[
              _row('Điện đầu kỳ',
                  '${bill.electricPrevious?.toStringAsFixed(1) ?? 0} kWh'),
              _row('Điện cuối kỳ',
                  '${bill.electricCurrent!.toStringAsFixed(1)} kWh'),
              if (bill.electricPrevious != null)
                _row('Tiêu thụ',
                    '${(bill.electricCurrent! - bill.electricPrevious!).toStringAsFixed(1)} kWh'),
              if (bill.electricUnitPrice != null)
                _row('Đơn giá điện',
                    '${_fmt.format(bill.electricUnitPrice!)} đ/kWh'),
            ],
            if (bill.waterCurrent != null) ...[
              const SizedBox(height: 6),
              _row('Nước đầu kỳ',
                  '${bill.waterPrevious?.toStringAsFixed(1) ?? 0} m³'),
              _row('Nước cuối kỳ',
                  '${bill.waterCurrent!.toStringAsFixed(1)} m³'),
              if (bill.waterUnitPrice != null)
                _row('Đơn giá nước',
                    '${_fmt.format(bill.waterUnitPrice!)} đ/m³'),
            ],
            if (bill.dueDate != null) ...[
              const SizedBox(height: 6),
              _row('Hạn thanh toán',
                  bill.dueDate!.toLocal().toString().split(' ').first),
            ],
            if (bill.isPaid && bill.paidAt != null) ...[
              const SizedBox(height: 6),
              _row('Ngày thanh toán',
                  bill.paidAt!.toLocal().toString().split(' ').first),
              _row('Hình thức',
                  bill.paidByCash ? 'Tiền mặt' : 'Chuyển khoản'),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPaymentQr(BillModel bill) {
    final amount = bill.totalAmount?.toInt() ?? 0;
    final info = Uri.encodeComponent(
        'Thue phong T${bill.month}/${bill.year}');
    final qrUrl =
        'https://img.vietqr.io/image/MB-0987654321-compact2.png?amount=$amount&addInfo=$info';

    showModalBottomSheet(
      context: context,
      backgroundColor: kCardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Quét QR để thanh toán',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${_fmt.format(amount)} đ',
                style: const TextStyle(
                    color: kGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  qrUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.qr_code, size: 80, color: kNavy),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Dùng app ngân hàng quét mã VietQR',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
