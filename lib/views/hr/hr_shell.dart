import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../repositories/attendance_repository.dart';
import '../../repositories/employee_repository.dart';
import '../../repositories/profile_request_repository.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/hr_employees_viewmodel.dart';
import '../../viewmodels/hr_requests_viewmodel.dart';
import '../../viewmodels/hr_scan_viewmodel.dart';
import '../../viewmodels/hr_today_viewmodel.dart';
import '../../viewmodels/report_viewmodel.dart';
import 'hr_employees_view.dart';
import 'hr_report_view.dart';
import 'hr_scan_view.dart';
import 'hr_today_view.dart';

/// Bottom-navigation container for the HR role: Scan / Today / Employees /
/// Reports.
class HrShell extends StatefulWidget {
  const HrShell({super.key, required this.hr});
  final AppUser hr;

  @override
  State<HrShell> createState() => _HrShellState();
}

class _HrShellState extends State<HrShell> {
  int _index = 0;

  static const _titles = [
    'Scan employee QR',
    "Today's attendance",
    'Employees',
    'Reports',
  ];

  @override
  Widget build(BuildContext context) {
    final attendanceRepo = context.read<AttendanceRepository>();
    final employeeRepo = context.read<EmployeeRepository>();
    final requestRepo = context.read<ProfileRequestRepository>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => HrScanViewModel(attendanceRepo, widget.hr)),
        ChangeNotifierProvider(
            create: (_) => HrTodayViewModel(attendanceRepo, employeeRepo)),
        ChangeNotifierProvider(
            create: (_) => HrEmployeesViewModel(employeeRepo)),
        ChangeNotifierProvider(create: (_) => HrRequestsViewModel(requestRepo)),
        ChangeNotifierProvider(
            create: (_) => ReportViewModel(attendanceRepo, employeeRepo)),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_index]),
          actions: [
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthViewModel>().signOut(),
            ),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: const [
              HrScanBody(),
              HrTodayView(),
              HrEmployeesView(),
              HrReportView(),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.qr_code_scanner_outlined),
                selectedIcon: Icon(Icons.qr_code_scanner),
                label: 'Scan'),
            NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups),
                label: 'Today'),
            NavigationDestination(
                icon: Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(Icons.people_alt),
                label: 'Employees'),
            NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Reports'),
          ],
        ),
      ),
    );
  }
}
