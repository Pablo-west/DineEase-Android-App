// ignore_for_file: deprecated_member_use, avoid_types_as_parameter_names

import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_logo_title.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

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
            Text('My Orders', style: AppTextStyles.heading),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where(
                      'userId',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid ?? '',
                    )
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
                      .map(_OrderView.fromDoc)
                      .toList(growable: false);
                  return ListView(
                    children: [
                      for (final order in orders) _OrderCard(order: order),
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
}

class _OrderCard extends StatelessWidget {
  final _OrderView order;

  const _OrderCard({required this.order});

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
          Text(
            'Order #${order.orderNumber}',
            style: AppTextStyles.title,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '$itemCount items • ${order.paymentLabel}',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: OrderStage.values
                .map((stage) => _StageChip(
                      label: _stageLabel(stage),
                      active: order.stage.index >= stage.index,
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          _orderTitles(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GHS${order.total.toStringAsFixed(2)}',
                style: AppTextStyles.price,
              ),
              Text(
                order.stage == OrderStage.delivered
                    ? 'Delivered'
                    : 'In progress',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderTitles() {
    final titles =
        order.items.map((line) => line.title).toSet().toList(growable: false);
    return Wrap(
      spacing: 3,
      runSpacing: 2,
      children: [
        for (final title in titles)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              title,
              style:
                  AppTextStyles.subtitle.copyWith(color: AppColors.textPrimary),
            ),
          ),
      ],
    );
  }

  String _stageLabel(OrderStage stage) {
    switch (stage) {
      case OrderStage.placed:
        return 'Placed';
      case OrderStage.preparing:
        return 'Preparing';
      case OrderStage.inKitchen:
        return 'In Kitchen';
      case OrderStage.delivered:
        return 'Delivered';
    }
  }
}

class _StageChip extends StatelessWidget {
  final String label;
  final bool active;

  const _StageChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border(
              top: BorderSide(
                color: Colors.black87.withOpacity(0.7),
                width: 1,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderView {
  final String orderNumber;
  final List<_OrderItemView> items;
  final OrderStage stage;
  final double total;
  final String paymentLabel;

  const _OrderView({
    required this.orderNumber,
    required this.items,
    required this.stage,
    required this.total,
    required this.paymentLabel,
  });

  factory _OrderView.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
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

    final total = (data['totals']?['total'] as num?)?.toDouble() ??
        (data['foodAmt'] is String
            ? double.tryParse(
                    data['foodAmt'].toString().replaceAll('GHS', '').trim()) ??
                0
            : 0);

    final stage = _parseStage((data['stage'] ?? 'placed').toString());
    final paymentLabel =
        (data['payment']?['method'] ?? data['paymentOption'] ?? '').toString();
    final orderNumber =
        (data['orderNumber'] ?? data['mealNum'] ?? doc.id).toString();

    return _OrderView(
      orderNumber: orderNumber,
      items: items,
      stage: stage,
      total: total,
      paymentLabel: paymentLabel.isEmpty ? 'Cash' : paymentLabel,
    );
  }

  static OrderStage _parseStage(String value) {
    switch (value) {
      case 'preparing':
        return OrderStage.preparing;
      case 'inKitchen':
        return OrderStage.inKitchen;
      case 'delivered':
        return OrderStage.delivered;
      case 'placed':
      default:
        return OrderStage.placed;
    }
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
