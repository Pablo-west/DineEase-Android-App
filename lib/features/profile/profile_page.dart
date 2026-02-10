// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_logo_title.dart';
import '../../core/widgets/delivery_destination_sheet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final destination = state.destination;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        children: [
          const AppLogoTitle(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile', style: AppTextStyles.heading),
              IconButton(
                onPressed: () async {
                  showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => Dialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
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
                              child: Text(
                                'Signing out...',
                                style: AppTextStyles.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  await FirebaseAuth.instance.signOut();
                  AppScope.of(context).setProfile(
                    displayName: '',
                    email: '',
                    phone: '',
                  );
                  if (context.mounted) {
                    Navigator.of(context, rootNavigator: true).pop();
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _profileCard(
            context,
            name: state.displayName,
            email: state.email,
          ),
          const SizedBox(height: 20),
          _sectionTitle('Preferences'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final selected = await showDeliveryDestinationSheet(
                context,
                initial: destination,
              );
              if (selected != null && context.mounted) {
                AppScope.of(context).setDestination(selected);
              }
            },
            child: _listTile(
              'Delivery Destination',
              destination?.summary ?? 'Not set',
            ),
          ),
          GestureDetector(
            onTap: () => _showProfileEdit(context),
            child: _listTile(
              'Phone Number',
              state.phone.isEmpty ? 'Not set' : state.phone,
            ),
          ),
          _listTile('Payment Methods', 'Cash, Card, Mobile Money'),
          const SizedBox(height: 20),
          _sectionTitle('Support'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HelpCenterPage()),
            ),
            child: _supportCard(
              title: 'Help Center',
              subtitle: 'FAQs, support hours, and direct help',
              actionLabel: 'Tap to open',
              onAction: () {},
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsPrivacyPage()),
            ),
            child: _supportCard(
              title: 'Terms & Privacy',
              subtitle:
                  'We only use your details for order updates and delivery.',
              actionLabel: 'Tap to open',
              onAction: () {},
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              'Version 2.10 • IpabloWest',
              style: AppTextStyles.subtitle,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _profileCard(
    BuildContext context, {
    required String name,
    required String email,
  }) {
    final needsProfile = name.trim().isEmpty || email.trim().isEmpty;
    final displayName = needsProfile ? 'Enter your username and email' : name;
    final displayEmail = needsProfile ? 'Tap to edit profile' : email;
    return GestureDetector(
      onTap: () => _showProfileEdit(context),
      child: Container(
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
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              child: Text(
                needsProfile
                    ? 'DE'
                    : name.trim().split(' ').map((e) => e[0]).take(2).join(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(displayEmail, style: AppTextStyles.subtitle),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: AppTextStyles.title);
  }

  Widget _listTile(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.muted),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.subtitle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _supportCard({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
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
          Text(title, style: AppTextStyles.title),
          const SizedBox(height: 6),
          Text(subtitle, style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              actionLabel,
              style: AppTextStyles.subtitle.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _launchWhatsApp() async {
  final uri = Uri.parse('https://wa.me/+233249522885');
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

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
              _supportTopBar(context, 'Help Center'),
              const SizedBox(height: 16),
              Text('We are here to help', style: AppTextStyles.heading),
              const SizedBox(height: 12),
              _supportSection(
                title: 'WhatsApp Desk',
                body:
                    'Chat with us for order help, delivery updates, or account issues.',
                actionLabel: 'Open WhatsApp',
                onAction: () => _launchWhatsApp(),
              ),
              _supportSection(
                title: 'Support Hours',
                body: 'We respond daily from 8:00 AM to 10:00 PM.',
              ),
              _supportSection(
                title: 'Common Questions',
                body: 'You can track your order status in the My Orders page.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TermsPrivacyPage extends StatelessWidget {
  const TermsPrivacyPage({super.key});

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
              _supportTopBar(context, 'Terms & Privacy'),
              const SizedBox(height: 16),
              Text('How we use your data', style: AppTextStyles.heading),
              const SizedBox(height: 12),
              Text(
                'We use your details to process orders, contact you about '
                'delivery, and improve the service. We do not sell your '
                'personal data.',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 16),
              Text(
                'By using DineEase you agree to these terms and our privacy '
                'practices.',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _supportTopBar(BuildContext context, String title) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      Text(title, style: AppTextStyles.title),
      const SizedBox(width: 40),
    ],
  );
}

Widget _supportSection({
  required String title,
  required String body,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.muted),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.title),
        const SizedBox(height: 6),
        Text(body, style: AppTextStyles.subtitle),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ],
    ),
  );
}

Future<void> _showProfileEdit(BuildContext context) async {
  final state = AppScope.of(context);
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: state.displayName);
  final emailController = TextEditingController(text: state.email);
  final phoneController = TextEditingController(text: state.phone);

  await showDialog<void>(
    context: context,
    builder: (context) {
      void handleSave() {
        if (formKey.currentState?.validate() != true) {
          return;
        }
        final phoneDigits =
            phoneController.text.trim().replaceAll(RegExp(r'\\D'), '');
        state.setProfile(
          displayName: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneDigits,
        );
        Navigator.pop(context);
      }

      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            18,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Edit Profile', style: AppTextStyles.title),
                          const SizedBox(height: 4),
                          Text(
                            'Update your details for faster checkout.',
                            style: AppTextStyles.subtitle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  textInputAction: TextInputAction.next,
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  textInputAction: TextInputAction.next,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter an email';
                    }
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => handleSave(),
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone number',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    filled: true,
                    fillColor: AppColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
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
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: handleSave,
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
