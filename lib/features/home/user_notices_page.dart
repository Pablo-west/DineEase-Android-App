import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class UserNoticesPage extends StatefulWidget {
  final String userId;

  const UserNoticesPage({
    super.key,
    required this.userId,
  });

  @override
  State<UserNoticesPage> createState() => _UserNoticesPageState();
}

class _UserNoticesPageState extends State<UserNoticesPage> {
  bool _markingRead = false;

  Future<void> _markUnreadAsRead(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (_markingRead) return;
    final unreadDocs = docs
        .where((doc) => (doc.data()['read'] as bool?) != true)
        .toList(growable: false);
    if (unreadDocs.isEmpty) return;

    _markingRead = true;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unreadDocs) {
        batch.update(doc.reference, {
          'read': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } finally {
      _markingRead = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Text('Notifications', style: AppTextStyles.heading),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('notices')
                      .where('userId', isEqualTo: widget.userId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Text(
                          'Loading notices...',
                          style: AppTextStyles.subtitle,
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'No notifications yet',
                          style: AppTextStyles.subtitle,
                        ),
                      );
                    }

                    final notices = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                      snapshot.data!.docs,
                    )
                      ..sort((a, b) {
                        final aDate = (a.data()['createdAt'] as Timestamp?)?.toDate();
                        final bDate = (b.data()['createdAt'] as Timestamp?)?.toDate();
                        if (aDate == null && bDate == null) return 0;
                        if (aDate == null) return 1;
                        if (bDate == null) return -1;
                        return bDate.compareTo(aDate);
                      });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _markUnreadAsRead(notices);
                    });
                    final grouped = _groupNotices(notices);
                    return ListView.builder(
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final group = grouped[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.muted),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order #${group.orderNumber}',
                                style: AppTextStyles.title,
                              ),
                              if (group.foodNames.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Foods: ${group.foodNames.join(', ')}',
                                  style: AppTextStyles.subtitle,
                                ),
                              ],
                              const SizedBox(height: 8),
                              for (final entry in group.entries) ...[
                                Text(
                                  '• ${entry.message}',
                                  style: AppTextStyles.subtitle,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDateTime(entry.createdAt),
                                  style: AppTextStyles.subtitle.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_NoticeGroup> _groupNotices(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> notices,
  ) {
    final grouped = <String, _NoticeGroup>{};
    for (final doc in notices) {
      final data = doc.data();
      final orderId = (data['orderId'] ?? '').toString();
      final orderNumber = (data['orderNumber'] ?? '').toString();
      final message = (data['message'] ?? '').toString();
      final stage = (data['stage'] ?? '').toString();
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

      final foodNames = (data['foodNames'] as List? ?? [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      final key = orderId.isNotEmpty
          ? orderId
          : orderNumber.isNotEmpty
              ? 'order-number:$orderNumber'
              : 'notice:${doc.id}';

      final group = grouped.putIfAbsent(
        key,
        () => _NoticeGroup(
          orderNumber: orderNumber.isNotEmpty ? orderNumber : 'Unknown',
        ),
      );

      if (group.orderNumber == 'Unknown' && orderNumber.isNotEmpty) {
        group.orderNumber = orderNumber;
      }
      group.foodNames.addAll(foodNames);
      final dedupeKey = stage.trim().isNotEmpty
          ? 'stage:${stage.trim().toLowerCase()}'
          : 'message:${message.trim().toLowerCase()}';
      if (!group.seenKeys.contains(dedupeKey)) {
        group.seenKeys.add(dedupeKey);
        group.entries.add(_NoticeEntry(message: message, createdAt: createdAt));
      }
      if (createdAt != null &&
          (group.latestAt == null || createdAt.isAfter(group.latestAt!))) {
        group.latestAt = createdAt;
      }
    }

    final list = grouped.values.toList(growable: false)
      ..sort((a, b) {
        if (a.latestAt == null && b.latestAt == null) return 0;
        if (a.latestAt == null) return 1;
        if (b.latestAt == null) return -1;
        return b.latestAt!.compareTo(a.latestAt!);
      });
    return list;
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Unknown date';
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _NoticeGroup {
  String orderNumber;
  final Set<String> foodNames = {};
  final Set<String> seenKeys = {};
  final List<_NoticeEntry> entries = [];
  DateTime? latestAt;

  _NoticeGroup({
    required this.orderNumber,
  });
}

class _NoticeEntry {
  final String message;
  final DateTime? createdAt;

  const _NoticeEntry({
    required this.message,
    required this.createdAt,
  });
}
