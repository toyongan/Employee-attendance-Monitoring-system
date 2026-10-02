import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/profile_fields.dart';
import '../../models/profile_update_request.dart';
import '../../viewmodels/edit_profile_viewmodel.dart';

/// Shows the employee what the badge on the "My QR" tab is counting:
/// their pending profile-change request (waiting on HR) and any approved or
/// rejected requests they haven't dismissed yet, each with the exact
/// fields that were changed. Renders nothing when there's nothing to show.
class RequestNotifications extends StatelessWidget {
  const RequestNotifications({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditProfileViewModel>();
    final pending = vm.pending;

    final items = <Widget>[
      for (final r in vm.unseenResolved) _ResolvedCard(request: r),
      if (pending != null) _PendingCard(request: pending),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: items,
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.request});
  final ProfileUpdateRequest request;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Waiting for HR approval',
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Submitted ${DateFormat('MMM d, y \u2022 h:mm a').format(request.requestedAt)}',
                style: text.bodySmall,
              ),
              const SizedBox(height: 8),
              _ChangeLines(request.changes),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () =>
                    context.read<EditProfileViewModel>().cancelPending(),
                child: const Text('Cancel request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResolvedCard extends StatelessWidget {
  const _ResolvedCard({required this.request});
  final ProfileUpdateRequest request;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final approved = request.status == RequestStatus.approved;
    final reviewedAt = request.reviewedAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    approved
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    color: approved ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      approved
                          ? 'HR approved your changes'
                          : 'HR rejected your changes',
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Dismiss',
                    onPressed: () => context
                        .read<EditProfileViewModel>()
                        .dismiss(request.id),
                  ),
                ],
              ),
              if (reviewedAt != null)
                Text(DateFormat('MMM d, y \u2022 h:mm a').format(reviewedAt),
                    style: text.bodySmall),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _ChangeLines(request.changes),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  approved
                      ? 'These changes are now on your profile.'
                      : 'Your profile was not changed.',
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One "Field: new value" line per changed field.
class _ChangeLines extends StatelessWidget {
  const _ChangeLines(this.changes);
  final Map<String, dynamic> changes;

  String _line(String key, dynamic value) {
    final label = ProfileFields.label(key);
    final shown = ProfileFields.displayValue(key, value);
    return shown == null ? '$label: new photo' : '$label: $shown';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in changes.entries)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(_line(e.key, e.value)),
          ),
      ],
    );
  }
}
