import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../api/api_client.dart';

const kNavy = Color(0xFF0B192C);
const kGold = Color(0xFFFFD700);
const kCardBg = Color(0xFF162032);

class TenantDashboardScreen extends StatefulWidget {
  final int tenantId;
  const TenantDashboardScreen({super.key, required this.tenantId});

  @override
  State<TenantDashboardScreen> createState() =>
      _TenantDashboardScreenState();
}

class _TenantDashboardScreenState
    extends State<TenantDashboardScreen> {
  final _api = ApiClient();
  Map<String, dynamic>? _room;
  Map<String, dynamic>? _contract;
  Map<String, dynamic>? _latestBill;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<NotificationProvider>()
          .loadNotifications(widget.tenantId);
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final contractRes = await _api
          .get('/api/contracts/tenant/${widget.tenantId}');
      final contracts = contractRes['data'] as List? ?? [];
      if (contracts.isNotEmpty) {
        _contract = contracts.firstWhere(
              (c) => c['status'] == 'ACTIVE',
          orElse: () => contracts.first,
        );
      }
      final billRes = await _api
          .get('/api/bills/tenant/${widget.tenantId}/unpaid');
      final bills = billRes['data'] as List? ?? [];
      if (bills.isNotEmpty) _latestBill = bills.first;
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: kNavy,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: kGold,
          backgroundColor: kCardBg,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(auth),
              SliverPadding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(
                          child: CircularProgressIndicator(
                              color: kGold))
                    else ...[
                      // ✅ Banner quét QR khi chưa có phòng
                      if (_contract == null)
                        _buildQrScanBanner(),
                      if (_contract == null)
                        const SizedBox(height: 14),
                      _buildRoomCard(),
                      const SizedBox(height: 14),
                      _buildBillCard(),
                      const SizedBox(height: 14),
                      _buildContractCard(),
                      const SizedBox(height: 14),
                      _buildQuickActions(),
                    ],
                    const SizedBox(height: 80),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Banner nổi bật để quét QR thuê phòng
  Widget _buildQrScanBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              kGold.withValues(alpha: 0.2),
              kGold.withValues(alpha: 0.05),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kGold.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.qr_code_scanner,
                  color: kGold, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quét mã QR thuê phòng',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  SizedBox(height: 2),
                  Text(
                      'Quét mã QR do chủ nhà cung cấp để gửi yêu cầu thuê phòng',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 12),
                      maxLines: 2),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: kGold, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AuthProvider auth) {
    return SliverAppBar(
      backgroundColor: kNavy,
      expandedHeight: 80,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kGold,
                child: Text(
                  (auth.userName ?? 'T')[0].toUpperCase(),
                  style: const TextStyle(
                      color: kNavy,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${auth.userName ?? 'Khách thuê'}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const Text('Khách thuê',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              Consumer<NotificationProvider>(
                builder: (_, np, __) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white),
                      onPressed: () => Navigator.pushNamed(
                          context, '/notifications'),
                    ),
                    if (np.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                              color: kGold,
                              shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              '${np.unreadCount}',
                              style: const TextStyle(
                                  color: kNavy,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout,
                    color: Colors.white54, size: 20),
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(
                        context, '/login');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCard() {
    if (_contract == null) {
      return _emptyCard(
        icon: Icons.home_outlined,
        title: 'Chưa có phòng',
        subtitle: 'Quét mã QR bên trên để yêu cầu thuê phòng',
        color: Colors.white38,
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A2E44), Color(0xFF0F1F30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.home, color: kGold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Phòng hiện tại',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 12)),
                Text('Phòng #${_contract!['roomId']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
                Text(
                  'HĐ tới: ${_contract!['endDate']?.toString().split('T').first ?? 'N/A'}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          // ✅ Icon QR có thể bấm → mở scanner
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, '/qr-scanner'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_scanner,
                  color: kGold, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillCard() {
    if (_latestBill == null) {
      return _emptyCard(
        icon: Icons.receipt_outlined,
        title: 'Không có hóa đơn',
        subtitle: 'Chưa có hóa đơn nào chờ thanh toán',
        color: Colors.greenAccent,
      );
    }
    final bill = _latestBill!;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/bills'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.orangeAccent.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.receipt_long,
                  color: Colors.orangeAccent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hóa đơn cần thanh toán',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  Text(
                    'Tháng ${bill['month']}/${bill['year']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  Text(
                    '${_formatVnd(bill['totalAmount'])} đ',
                    style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                Colors.orangeAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border:
                Border.all(color: Colors.orangeAccent),
              ),
              child: const Text('Xem chi tiết',
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractCard() {
    if (_contract == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/contracts'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            const Icon(Icons.article_outlined,
                color: Colors.lightBlueAccent, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Xem hợp đồng của tôi',
                  style: TextStyle(
                      color: Colors.white, fontSize: 13)),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      (Icons.receipt_long, 'Hóa đơn', Colors.orangeAccent, '/bills'),
      (Icons.notifications, 'Thông báo', kGold, '/notifications'),
      (Icons.article, 'Hợp đồng', Colors.lightBlueAccent, '/contracts'),
      (Icons.people_alt, 'Ở cùng', Colors.purpleAccent, '/roommates'),
      // ✅ Thêm nút quét QR vào quick actions
      (Icons.qr_code_scanner, 'Quét QR', Colors.lightGreenAccent,
      '/qr-scanner'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tiện ích',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: actions
              .map((a) => GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, a.$4),
            child: Container(
              decoration: BoxDecoration(
                color: kCardBg,
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(a.$1, color: a.$3, size: 26),
                  const SizedBox(height: 6),
                  Text(a.$2,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ))
              .toList(),
        ),
      ],
    );
  }

  Widget _emptyCard(
      {required IconData icon,
        required String title,
        required String subtitle,
        required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatVnd(dynamic amount) {
    if (amount == null) return '0';
    final n = (amount as num).toInt();
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},');
  }
}