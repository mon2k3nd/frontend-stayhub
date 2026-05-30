import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../providers/auth_provider.dart';
import '../providers/branch_provider.dart';
import '../providers/notification_provider.dart';

const kNavy = Color(0xFF0B192C);
const kGold = Color(0xFFFFD700);
const kCardBg = Color(0xFF162032);

class OwnerDashboardScreen extends StatefulWidget {
  final int ownerId;
  final String ownerName;
  final String planType;

  const OwnerDashboardScreen({
    super.key,
    required this.ownerId,
    required this.ownerName,
    required this.planType,
  });

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen>
    with TickerProviderStateMixin {
  final _api = ApiClient();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // Stats từ API /api/dashboard/owner — khớp với DashboardStats.java
  Map<String, dynamic>? _stats;
  List<dynamic> _revenueChart = [];
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
      context.read<BranchProvider>().loadByOwner(widget.ownerId);
      context.read<NotificationProvider>().loadNotifications(widget.ownerId);
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final res = await _api.get('/api/dashboard/owner');
      final data = res['data'] as Map<String, dynamic>? ?? {};
      setState(() {
        _stats = data;
        _revenueChart = (data['revenueChart'] as List?) ?? [];
      });
    } catch (_) {
    } finally {
      setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kNavy,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 16),
                    _buildPlanBadge(),
                    const SizedBox(height: 16),
                    _buildStatCards(),
                    const SizedBox(height: 20),
                    if (_revenueChart.isNotEmpty) ...[
                      _buildRevenueChart(),
                      const SizedBox(height: 20),
                    ],
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildBranchList(),
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

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: kNavy,
      expandedHeight: 100,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: kGold,
                child: Text(
                  widget.ownerName.isNotEmpty
                      ? widget.ownerName[0].toUpperCase()
                      : 'O',
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kNavy),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Xin chào, ${widget.ownerName}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    const Text('Dashboard Chủ nhà',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Consumer<NotificationProvider>(
                builder: (_, np, __) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined,
                          color: Colors.white, size: 26),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/notifications'),
                    ),
                    if (np.unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: kGold, shape: BoxShape.circle),
                          child: Text(
                            np.unreadCount > 9 ? '9+' : '${np.unreadCount}',
                            style: const TextStyle(
                                color: kNavy,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout,
                    color: Colors.white54, size: 20),
                tooltip: 'Đăng xuất',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: kCardBg,
                      title: const Text('Đăng xuất?',
                          style: TextStyle(color: Colors.white)),
                      content: const Text('Bạn có chắc muốn đăng xuất?',
                          style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent),
                          child: const Text('Đăng xuất',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await context.read<AuthProvider>().logout();
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanBadge() {
    final colors = {
      'FREE': [Colors.grey, Colors.grey.shade700],
      'PRO': [const Color(0xFF1E90FF), const Color(0xFF0066CC)],
      'VIP': [kGold, const Color(0xFFFF8C00)],
    };
    final c = colors[widget.planType] ?? colors['FREE']!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: c),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            widget.planType == 'VIP'
                ? Icons.workspace_premium
                : widget.planType == 'PRO'
                    ? Icons.star
                    : Icons.person,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text('Gói ${widget.planType}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          const Spacer(),
          if (widget.planType == 'FREE')
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/upgrade-package'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Nâng cấp',
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    if (_loadingStats) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(color: kGold)),
      );
    }

    final s = _stats ?? {};
    // Khớp với các field của DashboardStats.java
    final totalRooms = s['totalRooms'] ?? 0;
    final occupiedRooms = s['occupiedRooms'] ?? 0;
    final totalRevenue = (s['totalRevenueThisMonth'] as num?)?.toDouble() ?? 0;
    final netProfit = (s['netProfitThisMonth'] as num?)?.toDouble() ?? 0;
    final unpaidBills = s['unpaidBillsCount'] ?? 0;
    final expiringContracts = s['expiringContracts'] ?? 0;

    final cards = [
      _StatCard('Phòng có khách', '$occupiedRooms/$totalRooms',
          Icons.meeting_room, kGold),
      _StatCard(
          'Doanh thu tháng này',
          '${(totalRevenue / 1000000).toStringAsFixed(1)}tr',
          Icons.attach_money,
          Colors.greenAccent),
      _StatCard(
          'Lợi nhuận ròng',
          '${(netProfit / 1000000).toStringAsFixed(1)}tr',
          Icons.trending_up,
          Colors.lightBlueAccent),
      _StatCard('HĐ sắp hết hạn', '$expiringContracts',
          Icons.receipt_long, Colors.orangeAccent),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: cards
          .map((c) =>
              _buildStatCardWidget(c.label, c.value, c.icon, c.color))
          .toList(),
    );
  }

  Widget _buildStatCardWidget(
      String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    // revenueChart: List<{month, year, revenue, expenses}> từ backend
    final spots = _revenueChart.asMap().entries.map((e) {
      final rev = (e.value['revenue'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), rev / 1000000);
    }).toList();

    final months = _revenueChart
        .map((e) => 'T${e['month']}')
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Doanh thu (triệu đ)',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                backgroundColor: kCardBg,
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.white12, strokeWidth: 1),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(months[idx],
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: kGold,
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      color: kGold.withValues(alpha: 0.12),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                            radius: 4,
                            color: kGold,
                            strokeWidth: 2,
                            strokeColor: kNavy,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('Phòng', Icons.grid_view, '/rooms'),
      _QuickAction('Hợp đồng', Icons.article, '/contracts'),
      _QuickAction('Hóa đơn', Icons.receipt, '/bills'),
      _QuickAction('Nhân viên', Icons.people, '/staff'),
      _QuickAction('Dãy trọ', Icons.apartment, '/branches'),
      _QuickAction('Chi phí', Icons.payments, '/expenses'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Truy cập nhanh',
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
          childAspectRatio: 1.1,
          children: actions.map((a) => _buildActionBtn(a)).toList(),
        ),
      ],
    );
  }

  Widget _buildActionBtn(_QuickAction action) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, action.route),
      child: Container(
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: kGold, size: 26),
            const SizedBox(height: 6),
            Text(action.label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchList() {
    return Consumer<BranchProvider>(
      builder: (_, bp, __) {
        if (bp.isLoading) {
          return const Center(
              child: CircularProgressIndicator(color: kGold));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dãy trọ của tôi',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/branches'),
                  child: const Text('Xem tất cả',
                      style: TextStyle(color: kGold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...bp.branches.take(3).map((b) => GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/room-grid',
                  arguments: {
                    'ownerId': widget.ownerId,
                    'branchId': b.id,
                    'branchName': b.branchName,
                  }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: kGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          const Icon(Icons.apartment, color: kGold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.branchName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(b.address,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Text('${b.totalRooms} phòng',
                        style:
                            const TextStyle(color: kGold, fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        color: Colors.white24, size: 18),
                  ],
                ),
              ),
            )),
          ],
        );
      },
    );
  }
}

class _StatCard {
  final String label, value;
  final IconData icon;
  final Color color;
  _StatCard(this.label, this.value, this.icon, this.color);
}

class _QuickAction {
  final String label, route;
  final IconData icon;
  _QuickAction(this.label, this.icon, this.route);
}
