import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'app_dialogs.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DeliveryDestinationForm extends StatefulWidget {
  final DeliveryDestination? initial;
  final ValueChanged<DeliveryDestination?> onChanged;

  const DeliveryDestinationForm({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<DeliveryDestinationForm> createState() =>
      _DeliveryDestinationFormState();
}

class _DeliveryDestinationFormState extends State<DeliveryDestinationForm> {
  late DeliveryDestinationType _type;
  late TextEditingController _controller;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initial?.type ?? DeliveryDestinationType.doorstep;
    _controller = TextEditingController(text: widget.initial?.details ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _emit() {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      widget.onChanged(null);
    } else {
      widget.onChanged(
        DeliveryDestination(type: _type, details: trimmed),
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);
    var dialogClosed = false;
    if (mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const _LoadingDialog(
            title: 'Getting your location',
            subtitle: 'Please wait a moment...',
          );
        },
      );
    }
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          dialogClosed = true;
          await showInfoDialog(
            context,
            title: 'Enable Location',
            message:
                'Location services are off. Please enable them and try again.',
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (permission == LocationPermission.deniedForever) {
          await Geolocator.openAppSettings();
        }
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          dialogClosed = true;
          await showInfoDialog(
            context,
            title: 'Permission Needed',
            message: 'Location permission is required to fetch your address.',
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      String address = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final addressParts = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].where((part) => part != null && part.trim().isNotEmpty).toList();
          address = addressParts.map((part) => part!.trim()).join(', ');
        }
      } catch (_) {
        address = '';
      }

      if (address.isEmpty) {
        address =
            'Lat ${position.latitude.toStringAsFixed(5)}, Lng ${position.longitude.toStringAsFixed(5)}';
      }
      _controller.text = address;
      _emit();
    } catch (error) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        dialogClosed = true;
        await showInfoDialog(
          context,
          title: 'Location Error',
          message: error.toString(),
        );
      }
    } finally {
      if (mounted && !dialogClosed) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoorstep = _type == DeliveryDestinationType.doorstep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Destination', style: AppTextStyles.title),
        const SizedBox(height: 8),
        RadioListTile<DeliveryDestinationType>(
          contentPadding: EdgeInsets.zero,
          title: Text('Doorstep delivery', style: AppTextStyles.body),
          value: DeliveryDestinationType.doorstep,
          groupValue: _type,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _type = value;
              _controller.clear();
              _emit();
            });
          },
        ),
        RadioListTile<DeliveryDestinationType>(
          contentPadding: EdgeInsets.zero,
          title: Text('Table service', style: AppTextStyles.body),
          value: DeliveryDestinationType.table,
          groupValue: _type,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _type = value;
              _controller.clear();
              _emit();
            });
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (_) => _emit(),
                minLines: 2,
                maxLines: 3,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: isDoorstep
                      ? 'Enter delivery address'
                      : 'Enter table number',
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (isDoorstep) ...[
              const SizedBox(width: 10),
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: IconButton(
                  icon: _isFetchingLocation
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 20),
                  color: AppColors.primary,
                  onPressed: _isFetchingLocation ? null : _useCurrentLocation,
                ),
              ),
            ],
          ],
        ),
        if (isDoorstep) ...[
          const SizedBox(height: 8),
          Text(
            'Doorstep delivery may include additional fees based on location.',
            style: AppTextStyles.subtitle,
          ),
        ],
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

Future<DeliveryDestination?> showDeliveryDestinationSheet(
  BuildContext context, {
  DeliveryDestination? initial,
}) {
  DeliveryDestination? selection = initial;
  return showModalBottomSheet<DeliveryDestination>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery Destination', style: AppTextStyles.title),
                const SizedBox(height: 12),
                DeliveryDestinationForm(
                  initial: initial,
                  onChanged: (value) => setModalState(() => selection = value),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selection == null
                        ? null
                        : () async {
                            if (selection!.type ==
                                DeliveryDestinationType.doorstep) {
                              await showInfoDialog(
                                context,
                                title: 'Doorstep Delivery',
                                message:
                                    'Doorstep delivery may include additional fees based on your location.',
                              );
                            }
                            if (context.mounted) {
                              Navigator.pop(context, selection);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Save Destination',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
