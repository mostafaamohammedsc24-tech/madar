import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/presentation/providers/employee_auth_notifier.dart';
import '../../data/hr_repository.dart';

class HrEmployeesScreen extends StatefulWidget {
  const HrEmployeesScreen({super.key});

  @override
  State<HrEmployeesScreen> createState() => _HrEmployeesScreenState();
}

class _HrEmployeesScreenState extends State<HrEmployeesScreen> {
  late HrRepository _repo;
  bool _loading = true;
  List<Map<String, dynamic>> _employees = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repo = HrRepository(context.read<EmployeeAuthNotifier>().repository);
      _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.listEmployees();
    if (!mounted) return;
    setState(() {
      _employees = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            onPressed: () => context.push('/employee/hr/employees/create'),
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _employees.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final e = _employees[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    title: Text(e['full_name']?.toString() ?? ''),
                    subtitle: Text(
                      '${e['employee_code']} · ${e['job_title'] ?? ''} · '
                      '${e['employment_status']}',
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class HrCreateEmployeeScreen extends StatefulWidget {
  const HrCreateEmployeeScreen({super.key});

  @override
  State<HrCreateEmployeeScreen> createState() => _HrCreateEmployeeScreenState();
}

class _HrCreateEmployeeScreenState extends State<HrCreateEmployeeScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _title = TextEditingController();
  final _branch = TextEditingController();
  late HrRepository _repo;
  List<Map<String, dynamic>> _depts = const [];
  List<Map<String, dynamic>> _roles = const [];
  String? _deptCode;
  String? _roleCode;
  bool _busy = false;
  bool _loading = true;

  static const _blockedRoles = {'system_administrator', 'super_admin'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _repo = HrRepository(context.read<EmployeeAuthNotifier>().repository);
      final depts = await _repo.listDepartments();
      final roles = await _repo.listRoles();
      if (!mounted) return;
      setState(() {
        _depts = depts;
        _roles = roles
            .where((r) => !_blockedRoles.contains(r['code']?.toString()))
            .toList();
        _deptCode = _depts.isEmpty ? null : _depts.first['code']?.toString();
        _roleCode = _roles.isEmpty ? null : _roles.first['code']?.toString();
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _title.dispose();
    _branch.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_deptCode == null || _roleCode == null || _name.text.trim().isEmpty) {
      return;
    }
    setState(() => _busy = true);
    final res = await _repo.createEmployee(
      fullName: _name.text.trim(),
      departmentCode: _deptCode!,
      roleCode: _roleCode!,
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      email: _email.text.trim().isEmpty ? null : _email.text.trim(),
      jobTitle: _title.text.trim().isEmpty ? null : _title.text.trim(),
      branchCode: _branch.text.trim().isEmpty ? null : _branch.text.trim(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? 'Failed')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Credentials issued'),
        content: Text(
          'Employee ID: ${res.code}\n'
          'Temporary password shown once — deliver securely.\n\n'
          '${res.tempSecret}\n\n'
          'Employee must change password and enable 2FA on first login.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Add employee')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Full name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _email,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _deptCode,
            items: _depts
                .map(
                  (d) => DropdownMenuItem(
                    value: d['code']?.toString(),
                    child: Text(d['name_en']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _deptCode = v),
            decoration: const InputDecoration(
              labelText: 'Department',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _roleCode,
            items: _roles
                .map(
                  (r) => DropdownMenuItem(
                    value: r['code']?.toString(),
                    child: Text(r['name_en']?.toString() ?? ''),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _roleCode = v),
            decoration: const InputDecoration(
              labelText: 'Role (no Super Admin)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Job title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _branch,
            decoration: const InputDecoration(
              labelText: 'Branch',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Employee ID is generated automatically (FIN-001, SALES-001, LAW-C-001, …).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create employee'),
          ),
        ],
      ),
    );
  }
}

class HrOrganizationScreen extends StatefulWidget {
  const HrOrganizationScreen({super.key});

  @override
  State<HrOrganizationScreen> createState() => _HrOrganizationScreenState();
}

class _HrOrganizationScreenState extends State<HrOrganizationScreen> {
  late HrRepository _repo;
  List<Map<String, dynamic>> _depts = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _repo = HrRepository(context.read<EmployeeAuthNotifier>().repository);
      final depts = await _repo.listDepartments();
      if (!mounted) return;
      setState(() {
        _depts = depts;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organization')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Company structure',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._depts.map(
                  (d) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(d['name_en']?.toString() ?? ''),
                    subtitle: Text(d['code']?.toString() ?? ''),
                  ),
                ),
              ],
            ),
    );
  }
}
