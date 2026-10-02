import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/profile_fields.dart';
import '../../models/app_user.dart';
import '../../models/profile_update_request.dart';

/// One pending request, with an old-value → new-value line per changed
/// field, and Approve/Reject actions.
class ProfileRequestCard extends StatelessWidget {
  const ProfileRequestCard({
    super.key,
    required this.request,
    required this.employee,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  final ProfileUpdateRequest request;
  final AppUser? employee;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  String? _currentValue(String key) {
    final e = employee;
    if (e == null) return null;
    switch (key) {
      case 'firstName':
        return e.firstName;
      case 'middleName':
        return e.middleName ?? '';
      case 'lastName':
        return e.lastName;
      case 'birthdate':
        return DateFormat('MMMM d, y').format(e.birthdate);
      case 'gender':
        return e.gender;
      case 'phone':
        return e.phone;
      case 'address':
        return e.address;
      case 'department':
        return e.department;
      case 'position':
        return e.position;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final emp = employee;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: emp != null && emp.hasPhoto
                      ? MemoryImage(base64Decode(emp.photoBase64!))
                      : null,
                  child: emp == null || !emp.hasPhoto
                      ? Text(emp?.initials ?? '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.employeeName,
                          style: text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        DateFormat('MMM d, y \u2022 h:mm a')
                            .format(request.requestedAt),
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final key in request.changes.keys)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ChangeRow(
                  fieldKey: key,
                  oldValue: key == 'photoBase64' ? null : _currentValue(key),
                  newValue: request.changes[key],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (busy)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                else ...[
                  TextButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    // FIX: the app theme gives FilledButtons an infinite
                    // minimum width (full-width form buttons). Inside a Row
                    // that means "infinite width" and the whole card fails
                    // to lay out — which is why pending requests showed a
                    // badge but a blank list. Override for this button.
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: onApprove,
                    child: const Text('Approve'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.fieldKey,
    required this.oldValue,
    required this.newValue,
  });

  final String fieldKey;
  final String? oldValue;
  final dynamic newValue;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final label = ProfileFields.label(fieldKey);
    final old = oldValue;

    if (fieldKey == 'photoBase64') {
      Uint8List? bytes;
      try {
        bytes = base64Decode(newValue as String);
      } catch (_) {
        bytes = null;
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: text.bodySmall),
          ),
          if (bytes != null)
            CircleAvatar(radius: 18, backgroundImage: MemoryImage(bytes))
          else
            const Text('New photo'),
        ],
      );
    }

    final display =
        ProfileFields.displayValue(fieldKey, newValue) ?? newValue.toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: text.bodySmall),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: text.bodyMedium?.copyWith(color: Colors.black),
              children: [
                if (old != null && old.isNotEmpty) ...[
                  TextSpan(
                    text: old,
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  const TextSpan(text: '  \u2192  '),
                ],
                TextSpan(
                  text: display,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
