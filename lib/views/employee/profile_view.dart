import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../services/pdf_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/edit_profile_viewmodel.dart';
import 'edit_profile_view.dart';
import 'request_notifications.dart';

/// Shows the employee's auto-generated QR code and their profile.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const RequestNotifications(),
        Text('My QR code',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('Let HR scan this code to mark you present.',
            style: text.bodyMedium),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: user.hasPhoto
                      ? MemoryImage(base64Decode(user.photoBase64!))
                      : null,
                  child: user.hasPhoto
                      ? null
                      : Text(user.initials,
                          style: text.headlineSmall
                              ?.copyWith(color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Container(
                  color: Colors.white,
                  child: QrImageView(
                    data: '${AppConstants.qrPrefix}${user.qrToken}',
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(user.fullName,
                    style: text.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('${user.position}, ${user.department}'),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final bytes = await PdfService.buildEmployeeIdCard(user);
                    await Printing.sharePdf(
                      bytes: bytes,
                      filename: '${user.lastName}_id_card.pdf',
                    );
                  },
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('Export ID card (PDF)'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text('Profile',
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            TextButton.icon(
              onPressed: () {
                // EditProfileViewModel lives in EmployeeShell's provider
                // scope, which sits BELOW the Navigator — a plain push
                // would land outside its reach, so the existing instance
                // is carried along explicitly with `.value`.
                final vm = context.read<EditProfileViewModel>();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ChangeNotifierProvider<EditProfileViewModel>.value(
                      value: vm,
                      child: const EditProfileView(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _Row('Email', user.email),
              _Row('Birthdate', DateFormat('MMMM d, y').format(user.birthdate)),
              _Row('Gender', user.gender),
              _Row('Phone', user.phone),
              _Row('Address', user.address),
              _Row('Department', user.department),
              _Row('Position', user.position),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => context.read<AuthViewModel>().signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
