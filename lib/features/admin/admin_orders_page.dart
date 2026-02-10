// ignore_for_file: deprecated_member_use, avoid_types_as_parameter_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_logo_title.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _stageFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLogoTitle(),
            const SizedBox(height: 12),
            Text('All Orders', style: AppTextStyles.heading),
            const SizedBox(height: 12),
            _searchBar(),
            const SizedBox(height: 10),
            _filterChips(),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .orderBy('placedAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Text(
                        'Loading orders...',
                        style: AppTextStyles.subtitle,
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        'No orders yet',
                        style: AppTextStyles.subtitle,
                      ),
                    );
                  }
                  final orders = snapshot.data!.docs
                      .map(_AdminOrderView.fromDoc)
                      .where(_matchesSearch)
                      .where(_matchesStage)
                      .toList(growable: false);
                  if (orders.isEmpty) {
                    return Center(
                      child: Text(
                        'No orders match your filters',
                        style: AppTextStyles.subtitle,
                      ),
                    );
                  }
                  final totalAmount = orders.fold<double>(
                    0,
                    (sum, order) => sum + order.total,
                  );
                  final stageCounts = <String, int>{
                    'placed': 0,
                    'preparing': 0,
                    'inKitchen': 0,
                    'delivered': 0,
                  };
                  for (final order in orders) {
                    stageCounts[order.stage] =
                        (stageCounts[order.stage] ?? 0) + 1;
                  }
                  return ListView(
                    children: [
                      _OrdersSummary(
                        totalOrders: orders.length,
                        totalAmount: totalAmount,
                        stageCounts: stageCounts,
                        activeStage: _stageFilter,
                      ),
                      const SizedBox(height: 12),
                      for (final order in orders) _AdminOrderCard(order: order),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: 'Search by order #, name, phone',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _filterChips() {
    final filters = const [
      ['all', 'All'],
      ['placed', 'Placed'],
      ['preparing', 'Preparing'],
      ['inKitchen', 'In Kitchen'],
      ['delivered', 'Delivered'],
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter[1]),
                selected: _stageFilter == filter[0],
                onSelected: (_) => setState(() => _stageFilter = filter[0]),
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: _stageFilter == filter[0]
                      ? Colors.white
                      : AppColors.textPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _matchesSearch(_AdminOrderView order) {
    if (_query.isEmpty) return true;
    final haystack = [
      order.orderNumber,
      order.userName,
      order.userPhone,
      order.paymentLabel,
    ].join(' ').toLowerCase();
    return haystack.contains(_query);
  }

  bool _matchesStage(_AdminOrderView order) {
    if (_stageFilter == 'all') return true;
    return order.stage == _stageFilter;
  }
}

class _OrdersSummary extends StatelessWidget {
  final int totalOrders;
  final double totalAmount;
  final Map<String, int> stageCounts;
  final String activeStage;

  const _OrdersSummary({
    required this.totalOrders,
    required this.totalAmount,
    required this.stageCounts,
    required this.activeStage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Overview', style: AppTextStyles.title),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryMetric('Total Orders', '$totalOrders'),
              if (activeStage != 'all')
                _summaryMetric(
                  'Total Amount',
                  'GHS${totalAmount.toStringAsFixed(2)}',
                ),
            ],
          ),
          const SizedBox(height: 12),
          _activeStagePill(),
        ],
      ),
    );
  }

  Widget _summaryMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.subtitle),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.title),
      ],
    );
  }

  Widget _activeStagePill() {
    if (activeStage == 'all') {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _stagePill(
            label: 'Placed',
            count: stageCounts['placed'] ?? 0,
            color: _stageColor('placed'),
          ),
          _stagePill(
            label: 'Preparing',
            count: stageCounts['preparing'] ?? 0,
            color: _stageColor('preparing'),
          ),
          _stagePill(
            label: 'In Kitchen',
            count: stageCounts['inKitchen'] ?? 0,
            color: _stageColor('inKitchen'),
          ),
          _stagePill(
            label: 'Delivered',
            count: stageCounts['delivered'] ?? 0,
            color: _stageColor('delivered'),
          ),
        ],
      );
    }
    return _stagePill(
      label: _stageLabel(activeStage),
      count: stageCounts[activeStage] ?? 0,
      color: _stageColor(activeStage),
    );
  }

  Widget _stagePill({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$label: $count',
        style: AppTextStyles.subtitle.copyWith(color: color),
      ),
    );
  }

  String _stageLabel(String stage) {
    switch (stage) {
      case 'preparing':
        return 'Preparing';
      case 'inKitchen':
        return 'In Kitchen';
      case 'delivered':
        return 'Delivered';
      case 'placed':
      default:
        return 'Placed';
    }
  }

  Color _stageColor(String stage) => stageColor(stage);
}

class _AdminOrderCard extends StatelessWidget {
  final _AdminOrderView order;

  const _AdminOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final itemCount = order.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order #${order.orderNumber}',
                  style: AppTextStyles.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _StageDropdown(order: order),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${order.userName} ◾ ${order.userPhone}',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 6),
          Text(
            '$itemCount items ◾ ${order.paymentLabel}',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final title in order.itemTitles)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.muted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    title,
                    style: AppTextStyles.subtitle
                        .copyWith(color: AppColors.textPrimary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GHS${order.total.toStringAsFixed(2)}',
                style: AppTextStyles.price,
              ),
              _stageBadge(order.stage),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stageBadge(String stage) {
    final label = _labelForStage(stage);
    final color = _stageColor(stage);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.subtitle.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _labelForStage(String stage) {
    switch (stage) {
      case 'preparing':
        return 'Preparing';
      case 'inKitchen':
        return 'In Kitchen';
      case 'delivered':
        return 'Delivered';
      case 'placed':
      default:
        return 'Placed';
    }
  }

  Color _stageColor(String stage) => stageColor(stage);
}

Color stageColor(String stage) {
  switch (stage) {
    case 'preparing':
      return const Color(0xFFFFA000);
    case 'inKitchen':
      return const Color(0xFF7E57C2);
    case 'delivered':
      return const Color(0xFF2E7D32);
    case 'placed':
    default:
      return const Color(0xFF0277BD);
  }
}

class _StageDropdown extends StatelessWidget {
  final _AdminOrderView order;

  const _StageDropdown({required this.order});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: order.stage,
        items: const [
          DropdownMenuItem(value: 'placed', child: Text('Placed')),
          DropdownMenuItem(value: 'preparing', child: Text('Preparing')),
          DropdownMenuItem(value: 'inKitchen', child: Text('In Kitchen')),
          DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
        ],
        onChanged: (value) async {
          if (value == null || value == order.stage) return;
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(order.id)
              .update({'stage': value});
        },
      ),
    );
  }
}

class _AdminOrderView {
  final String id;
  final String orderNumber;
  final String userName;
  final String userPhone;
  final List<_OrderItemView> items;
  final String stage;
  final double total;
  final String paymentLabel;

  const _AdminOrderView({
    required this.id,
    required this.orderNumber,
    required this.userName,
    required this.userPhone,
    required this.items,
    required this.stage,
    required this.total,
    required this.paymentLabel,
  });

  List<String> get itemTitles =>
      items.map((item) => item.title).toSet().toList(growable: false);

  factory _AdminOrderView.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final itemsRaw = (data['items'] as List?) ?? [];
    final items = itemsRaw
        .whereType<Map>()
        .map(
          (item) => _OrderItemView(
            title: (item['title'] ?? '').toString(),
            quantity: (item['quantity'] ?? 0) as int,
          ),
        )
        .toList();

    final total = (data['totals']?['total'] as num?)?.toDouble() ?? 0;
    final paymentLabel =
        (data['payment']?['method'] ?? data['paymentOption'] ?? '').toString();
    final orderNumber =
        (data['orderNumber'] ?? data['mealNum'] ?? doc.id).toString();
    final userName =
        (data['user']?['name'] ?? data['userName'] ?? 'Unknown').toString();
    final userPhone =
        (data['user']?['phone'] ?? data['phone'] ?? '').toString();
    final stage = (data['stage'] ?? 'placed').toString();

    return _AdminOrderView(
      id: doc.id,
      orderNumber: orderNumber,
      userName: userName,
      userPhone: userPhone,
      items: items,
      stage: stage,
      total: total,
      paymentLabel: paymentLabel.isEmpty ? 'Cash' : paymentLabel,
    );
  }
}

class _OrderItemView {
  final String title;
  final int quantity;

  const _OrderItemView({
    required this.title,
    required this.quantity,
  });
}
