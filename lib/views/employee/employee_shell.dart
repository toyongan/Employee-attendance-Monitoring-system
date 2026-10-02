import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../repositories/attendance_repository.dart';
import '../../repositories/profile_request_repository.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/edit_profile_viewmodel.dart';
import '../../viewmodels/history_viewmodel.dart';
import 'attendance_view.dart';
import 'dashboard_view.dart';
import 'profile_view.dart';

/// Bottom-navigation container for the employee role.
class EmployeeShell extends StatefulWidget {
  const EmployeeShell({super.key, required this.user});
  final AppUser user;

  @override
  State<EmployeeShell> createState() => _EmployeeShellState();
}

class _EmployeeShellState extends State<EmployeeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AttendanceRepository>();
    final profileRequestRepo = context.read<ProfileRequestRepository>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => DashboardViewModel(repo, widget.user)),
        ChangeNotifierProvider(
            create: (_) => HistoryViewModel(repo, widget.user)),
        ChangeNotifierProvider(
            create: (_) =>
                EditProfileViewModel(profileRequestRepo, widget.user)),
      ],
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: [
              DashboardView(
                user: widget.user,
                onShowQr: () => setState(() => _index = 2),
              ),
              const AttendanceView(),
              ProfileView(user: widget.user),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Today'),
            const NavigationDestination(
                icon: Icon(Icons.event_note_outlined),
                selectedIcon: Icon(Icons.event_note),
                label: 'Attendance'),
            NavigationDestination(
              icon: Consumer<EditProfileViewModel>(
                builder: (context, vm, _) => Badge(
                  isLabelVisible: vm.notificationCount > 0,
                  label: Text('${vm.notificationCount}'),
                  child: const Icon(Icons.qr_code_2_outlined),
                ),
              ),
              selectedIcon: const Icon(Icons.qr_code_2),
              label: 'My QR',
            ),
          ],
        ),
      ),
    );
  }
}
