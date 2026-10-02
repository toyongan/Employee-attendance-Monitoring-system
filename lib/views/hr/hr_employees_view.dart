import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../viewmodels/hr_employees_viewmodel.dart';
import '../../viewmodels/hr_requests_viewmodel.dart';
import 'add_employee_view.dart';
import 'profile_request_review.dart';

/// HR's "Employees" tab: the roster, plus a "Requests" sub-tab for pending
/// profile-change approvals — this is the "notification" HR sees.
class HrEmployeesView extends StatelessWidget {
  const HrEmployeesView({super.key});

  @override
  Widget build(BuildContext context) {
    final pendingCount = context.watch<HrRequestsViewModel>().pending.length;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: 0,
          bottom: TabBar(
            tabs: [
              const Tab(text: 'Roster'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Requests'),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 6),
                      Badge(label: Text('$pendingCount')),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_RosterTab(), _RequestsTab()],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEmployeeView()),
          ),
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add employee'),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

class _RosterTab extends StatelessWidget {
  const _RosterTab();

  Future<void> _confirmRemove(
    BuildContext context,
    HrEmployeesViewModel vm,
    AppUser employee,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove employee?'),
        content: Text(
          "This permanently deletes ${employee.fullName}'s profile, "
          'attendance records and profile requests.\n\n'
          'To free up their email, also delete their login in Firebase '
          'console \u2192 Authentication \u2192 Users.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            // The app theme makes FilledButtons full-width; that breaks
            // inside a dialog's action row, so override the minimum size.
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final error = await vm.deleteEmployee(employee);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? '${employee.fullName} was removed.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HrEmployeesViewModel>();
    final text = Theme.of(context).textTheme;

    if (vm.loadError != null) return _ErrorMessage(vm.loadError!);
    if (!vm.loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
      children: [
        Text('${vm.employees.length} accounts', style: text.bodyMedium),
        const SizedBox(height: 12),
        if (vm.employees.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No employees yet. Tap + to add the first one.'),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < vm.employees.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _EmployeeTile(
                    employee: vm.employees[i],
                    busy: vm.busyUid == vm.employees[i].uid,
                    onRemove: () =>
                        _confirmRemove(context, vm, vm.employees[i]),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _EmployeeTile extends StatelessWidget {
  const _EmployeeTile({
    required this.employee,
    required this.busy,
    required this.onRemove,
  });

  final AppUser employee;
  final bool busy;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      isThreeLine: true,
      leading: CircleAvatar(
        backgroundImage: employee.hasPhoto
            ? MemoryImage(base64Decode(employee.photoBase64!))
            : null,
        child: employee.hasPhoto ? null : Text(employee.initials),
      ),
      title: Text(employee.fullName),
      subtitle: Text(
        '${employee.position}, ${employee.department}\n${employee.email}',
      ),
      trailing: busy
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (v) {
                if (v == 'remove') onRemove();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove employee'),
                ),
              ],
            ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HrRequestsViewModel>();
    final employees = context.watch<HrEmployeesViewModel>().employees;
    final employeesById = {for (final e in employees) e.uid: e};

    if (vm.loadError != null) return _ErrorMessage(vm.loadError!);
    if (!vm.loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.pending.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No pending profile-change requests.'),
        ),
      );
    }

    Future<void> run(Future<String?> Function() action) async {
      final error = await action();
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 88),
      itemCount: vm.pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final request = vm.pending[i];
        return ProfileRequestCard(
          request: request,
          employee: employeesById[request.employeeId],
          busy: vm.busyRequestId == request.id,
          onApprove: () => run(() => vm.approve(request)),
          onReject: () => run(() => vm.reject(request)),
        );
      },
    );
  }
}
