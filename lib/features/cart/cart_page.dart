// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_dialogs.dart';
import '../../core/widgets/app_logo_title.dart';
import '../../core/widgets/cart_item_tile.dart';
import '../../core/widgets/delivery_destination_sheet.dart';
import '../orders/orders_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = state.cartLines;
    final subtotal = state.subtotal;
    final delivery = state.deliveryFee;
    final total = state.total;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppLogoTitle(),
            const SizedBox(height: 12),
            Text('My Cart', style: AppTextStyles.heading),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          'Your cart is empty',
                          style: AppTextStyles.subtitle,
                        ),
                      ),
                    )
                  else ...[
                    for (final line in items)
                      CartItemTile(
                        item: line.item,
                        quantity: line.quantity,
                        onAdd: () => state.addToCart(line.item),
                        onRemove: () => state.removeFromCart(line.item),
                      ),
                    const SizedBox(height: 12),
                    _summaryRow(
                      'Sub-Total',
                      'GHS${subtotal.toStringAsFixed(2)}',
                    ),
                    _summaryRow(
                      'Delivery Fee',
                      'GHS${delivery.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 24),
                    _summaryRow(
                      'Total Cost',
                      'GHS${total.toStringAsFixed(2)}',
                      isBold: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    items.isEmpty ? null : () => _confirmCheckDetails(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.subtitle),
          Text(
            value,
            style: isBold
                ? AppTextStyles.title
                : AppTextStyles.body.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCheckDetails(BuildContext context) async {
    final state = AppScope.of(context);
    PaymentMode? mode;
    DeliveryDestination? destination = state.destination;
    DeliveryDestination? draftDestination;
    final nameController = TextEditingController(text: state.displayName);
    final phoneController = TextEditingController(text: state.phone);
    final formKey = GlobalKey<FormState>();
    bool canSaveDetails = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void refreshSaveState() {
              final needsName = state.displayName.trim().isEmpty;
              final needsPhone = state.phone.trim().isEmpty;
              final nameOk =
                  !needsName || nameController.text.trim().isNotEmpty;
              final phoneText = phoneController.text.trim();
              final ghanaPhoneRegex = RegExp(
                r'^(?:0|\+?233)?(24|54|55|20|50|27|26|25|57|59)\d{7}$',
              );
              final phoneOk =
                  !needsPhone || ghanaPhoneRegex.hasMatch(phoneText);
              canSaveDetails = nameOk && phoneOk;
            }

            refreshSaveState();
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Confirm Checkout Details',
                        style: AppTextStyles.title,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.displayName.trim().isEmpty ||
                        state.phone.trim().isEmpty) ...[
                      _sectionHeader('Your Details'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.muted),
                        ),
                        child: Column(
                          children: [
                            if (state.displayName.trim().isEmpty)
                              _inputField(
                                textInputAction: TextInputAction.next,
                                controller: nameController,
                                label: 'Username',
                                icon: Icons.person_outline,
                                onChanged: (_) =>
                                    setModalState(refreshSaveState),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter a username';
                                  }
                                  return null;
                                },
                              ),
                            if (state.displayName.trim().isEmpty &&
                                state.phone.trim().isEmpty)
                              const SizedBox(height: 12),
                            if (state.phone.trim().isEmpty)
                              _inputField(
                                textInputAction: TextInputAction.done,
                                controller: phoneController,
                                label: 'Phone number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                onChanged: (_) =>
                                    setModalState(refreshSaveState),
                                validator: (value) {
                                  final trimmed = value?.trim() ?? '';
                                  if (trimmed.isEmpty) {
                                    return 'Enter a phone number';
                                  }
                                  final ghanaPhoneRegex = RegExp(
                                    r'^(?:0|\+?233)?(24|54|55|20|50|27|26|25|57|59)\d{7}$',
                                  );
                                  if (!ghanaPhoneRegex.hasMatch(trimmed)) {
                                    return 'Enter a valid Ghana number';
                                  }
                                  return null;
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: canSaveDetails
                              ? () {
                                  if (formKey.currentState?.validate() !=
                                      true) {
                                    return;
                                  }
                                  final phoneDigits = phoneController.text
                                      .trim()
                                      .replaceAll(RegExp(r'\\D'), '');
                                  state.setProfile(
                                    displayName:
                                        state.displayName.trim().isEmpty
                                            ? nameController.text.trim()
                                            : state.displayName,
                                    email: state.email,
                                    phone: state.phone.trim().isEmpty
                                        ? phoneDigits
                                        : state.phone,
                                  );
                                  setModalState(() {});
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Save Details'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Text(
                        'Your Details',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.muted),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.displayName,
                                    style: AppTextStyles.title,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    state.phone,
                                    style: AppTextStyles.subtitle,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  state.setProfile(
                                    displayName: '',
                                    email: state.email,
                                    phone: '',
                                  );
                                });
                              },
                              child: const Text('Edit'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (destination == null) ...[
                      DeliveryDestinationForm(
                        initial: null,
                        onChanged: (value) =>
                            setModalState(() => draftDestination = value),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: draftDestination == null
                              ? null
                              : () {
                                  setModalState(() {
                                    destination = draftDestination;
                                  });
                                  if (destination?.type ==
                                      DeliveryDestinationType.doorstep) {
                                    showInfoDialog(
                                      context,
                                      title: 'Doorstep Delivery',
                                      message:
                                          'Doorstep delivery may include additional fees based on your location.',
                                    );
                                  }
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Save Destination'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      _destinationSummary(
                        destination!,
                        onEdit: () async {
                          final updated = await showDeliveryDestinationSheet(
                            context,
                            initial: destination,
                          );
                          if (updated != null) {
                            setModalState(() => destination = updated);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (destination?.type ==
                        DeliveryDestinationType.doorstep) ...[
                      Text(
                        'Doorstep delivery may include additional fees based on location.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text('Select Payment Mode', style: AppTextStyles.title),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _paymentOption(
                            label: 'Cash on Delivery',
                            icon: Icons.payments_outlined,
                            value: PaymentMode.cash,
                            groupValue: mode,
                            onTap: (value) => setModalState(() => mode = value),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _paymentOption(
                            label: 'Mobile Money',
                            icon: Icons.phone_iphone,
                            value: PaymentMode.mobileMoney,
                            groupValue: mode,
                            onTap: (value) => setModalState(() => mode = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    _swipeToConfirm(
                      enabled: destination != null && mode != null,
                      onConfirmed: () {
                        if (formKey.currentState?.validate() != true) {
                          return;
                        }
                        if (mode == null) {
                          return;
                        }
                        if (state.displayName.trim().isEmpty ||
                            state.phone.trim().isEmpty) {
                          final phoneDigits = phoneController.text
                              .trim()
                              .replaceAll(RegExp(r'\\D'), '');
                          state.setProfile(
                            displayName: state.displayName.trim().isEmpty
                                ? nameController.text.trim()
                                : state.displayName,
                            email: state.email,
                            phone: state.phone.trim().isEmpty
                                ? phoneDigits
                                : state.phone,
                          );
                        }
                        _placeOrderAndSync(
                          context,
                          state: state,
                          destination: destination!,
                          mode: mode!,
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _destinationSummary(
    DeliveryDestination destination, {
    required VoidCallback onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.muted),
      ),
      child: Row(
        children: [
          const Icon(Icons.place_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery destination', style: AppTextStyles.subtitle),
                const SizedBox(height: 4),
                Text(destination.summary, style: AppTextStyles.title),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }

  Widget _paymentOption({
    required String label,
    required IconData icon,
    required PaymentMode value,
    required PaymentMode? groupValue,
    required ValueChanged<PaymentMode> onTap,
  }) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primary.withOpacity(0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.muted,
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.icon),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.subtitle.copyWith(color: AppColors.textPrimary),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required TextInputAction textInputAction,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      textInputAction: textInputAction,
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _swipeToConfirm({
    required bool enabled,
    required VoidCallback onConfirmed,
  }) {
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: enabled ? AppColors.card : AppColors.muted,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: enabled ? AppColors.primary : AppColors.muted,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'Swipe to confirm',
              style: AppTextStyles.subtitle.copyWith(
                color:
                    enabled ? AppColors.textSecondary : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !enabled,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final max = constraints.maxWidth - 56;
                  return _SwipeThumb(
                    enabled: enabled,
                    maxDrag: max,
                    onConfirmed: onConfirmed,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrderAndSync(
    BuildContext context, {
    required AppState state,
    required DeliveryDestination destination,
    required PaymentMode mode,
    String? paymentReference,
    String paymentStatus = 'pending',
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(
        title: 'Placing your order',
        subtitle: 'Please wait...',
      ),
    );

    final startedAt = DateTime.now();
    state.setDestination(destination);
    final order = state.placeOrder(mode);
    final items = order.items
        .map((line) => '${line.item.title} x${line.quantity}')
        .toList();
    final foodText = items.join(', ');
    final mealNum = order.id;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          showInfoDialog(
            context,
            title: 'Sign In Required',
            message: 'Please sign in again to place your order.',
          );
        }
        return;
      }
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user.uid,
        'orderNumber': mealNum,
        'stage': 'placed',
        'placedAt': FieldValue.serverTimestamp(),
        'user': {
          'id': user.uid,
          'name': state.displayName.isEmpty ? 'Guest' : state.displayName,
          'phone': state.phone,
        },
        'payment': {
          'method': paymentModeLabel(mode),
          'status': paymentStatus,
          'reference': paymentReference ?? '',
        },
        'delivery': {
          'type': destination.type == DeliveryDestinationType.table
              ? 'table'
              : 'doorstep',
          'tableNumber': destination.type == DeliveryDestinationType.table
              ? destination.details
              : '',
          'address': destination.type == DeliveryDestinationType.doorstep
              ? destination.details
              : '',
        },
        'items': [
          for (final line in order.items)
            {
              'title': line.item.title,
              'quantity': line.quantity,
              'unitPrice': line.item.price,
              'subtotal': line.item.price * line.quantity,
            }
        ],
        'totals': {
          'subtotal': order.total - state.deliveryFee,
          'deliveryFee': state.deliveryFee,
          'total': order.total,
        },
        'kitchenMode': false,
        'deliveredMode': false,
      });

      final elapsed = DateTime.now().difference(startedAt);
      if (elapsed < const Duration(seconds: 2)) {
        await Future<void>.delayed(
          const Duration(seconds: 2) - elapsed,
        );
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.pop(context);
        await showInfoDialog(
          context,
          title: 'Order Placed',
          message: 'Order ${order.id} placed.',
        );
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrdersPage()),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        showInfoDialog(
          context,
          title: 'Order Failed',
          message: 'We could not submit your order. Please try again.',
        );
      }
    }
  }
}

class _SwipeThumb extends StatefulWidget {
  final bool enabled;
  final double maxDrag;
  final VoidCallback onConfirmed;

  const _SwipeThumb({
    required this.enabled,
    required this.maxDrag,
    required this.onConfirmed,
  });

  @override
  State<_SwipeThumb> createState() => _SwipeThumbState();
}

class _SwipeThumbState extends State<_SwipeThumb>
    with SingleTickerProviderStateMixin {
  double _dx = 0;
  bool _completed = false;
  late final AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didUpdateWidget(covariant _SwipeThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _dx != 0) {
      _animateTo(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    _controller.stop();
    _animation = Tween<double>(begin: _dx, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    )..addListener(() {
        setState(() => _dx = _animation.value);
      });
    _controller
      ..reset()
      ..forward();
  }

  void _handleEnd() {
    if (_dx >= widget.maxDrag * 0.85 && !_completed) {
      _completed = true;
      _animateTo(widget.maxDrag);
      widget.onConfirmed();
      Future.delayed(const Duration(milliseconds: 420), () {
        if (mounted) {
          _completed = false;
          _animateTo(0);
        }
      });
    } else {
      _animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 4,
          bottom: 4,
          child: Transform.translate(
            offset: Offset(_dx, 0),
            child: GestureDetector(
              onHorizontalDragUpdate: widget.enabled
                  ? (details) {
                      setState(() {
                        _dx = (_dx + details.delta.dx).clamp(0, widget.maxDrag);
                      });
                    }
                  : null,
              onHorizontalDragEnd: widget.enabled ? (_) => _handleEnd() : null,
              child: Container(
                width: 48,
                decoration: BoxDecoration(
                  color: widget.enabled ? AppColors.primary : AppColors.muted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.double_arrow_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingDialog extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LoadingDialog({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Row(
          children: [
            const SizedBox(
              height: 36,
              width: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.title),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
