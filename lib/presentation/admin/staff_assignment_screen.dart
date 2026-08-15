import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/localization/app_localizations.dart';

class StaffAssignmentScreen extends StatefulWidget {
  const StaffAssignmentScreen({super.key});

  @override
  State<StaffAssignmentScreen> createState() => _StaffAssignmentScreenState();
}

class _StaffAssignmentScreenState extends State<StaffAssignmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterDept = 'All';
  String _filterStatus = 'All';

  final List<_StaffMember> _staff = _demoStaff;
  final List<_Assignment> _assignments = _demoAssignments;
  final List<_Task> _tasks = _demoTasks;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1220),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          loc.staffAssignment,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFF6C63FF)),
            onPressed: () => _showAssignDialog(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6C63FF),
            unselectedLabelColor: Colors.white38,
            indicatorColor: const Color(0xFF6C63FF),
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.dmSans(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 11.sp),
            tabs: [
              Tab(text: loc.assignments),
              Tab(text: loc.staffDirectory),
              Tab(text: loc.taskQueue),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AssignmentsTab(
            assignments: _assignments,
            staff: _staff,
            onReassign: (a) => _showReassignDialog(context, a),
          ),
          _StaffDirectoryTab(
            staff: _staff,
            searchQuery: _searchQuery,
            filterDept: _filterDept,
            onSearchChanged: (v) => setState(() => _searchQuery = v),
            onDeptChanged: (v) => setState(() => _filterDept = v),
            onAssign: (s) => _showAssignToStaffDialog(context, s),
          ),
          _TaskQueueTab(
            tasks: _tasks,
            staff: _staff,
            filterStatus: _filterStatus,
            onStatusChanged: (v) => setState(() => _filterStatus = v),
            onAssign: (t) => _showAssignTaskDialog(context, t),
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewAssignmentSheet(staff: _staff, tasks: _tasks),
    );
  }

  void _showReassignDialog(BuildContext context, _Assignment a) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReassignSheet(assignment: a, staff: _staff),
    );
  }

  void _showAssignToStaffDialog(BuildContext context, _StaffMember s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignToStaffSheet(staff: s, tasks: _tasks),
    );
  }

  void _showAssignTaskDialog(BuildContext context, _Task t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignTaskSheet(task: t, staff: _staff),
    );
  }
}

// ─── Assignments Tab ──────────────────────────────────────────────────────────
class _AssignmentsTab extends StatelessWidget {
  final List<_Assignment> assignments;
  final List<_StaffMember> staff;
  final Function(_Assignment) onReassign;

  const _AssignmentsTab({
    required this.assignments,
    required this.staff,
    required this.onReassign,
  });

  @override
  Widget build(BuildContext context) {
    // Summary row
    final active = assignments.where((a) => a.status == 'active').length;
    final pending = assignments.where((a) => a.status == 'pending').length;
    final completed = assignments.where((a) => a.status == 'completed').length;

    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        // Stats row
        Row(
          children: [
            _StatChip(
              label: 'Active',
              count: active,
              color: const Color(0xFF10B981),
            ),
            SizedBox(width: 2.w),
            _StatChip(
              label: 'Pending',
              count: pending,
              color: const Color(0xFFF59E0B),
            ),
            SizedBox(width: 2.w),
            _StatChip(label: 'Done', count: completed, color: Colors.white38),
          ],
        ),
        SizedBox(height: 2.h),
        ...assignments.map((a) {
          final assignee = staff.firstWhere(
            (s) => s.id == a.staffId,
            orElse: () => _StaffMember(
              id: '',
              name: 'Unassigned',
              role: '',
              dept: '',
              avatar: '👤',
              workload: 0,
              isAvailable: false,
              country: 'IQ',
            ),
          );
          return _AssignmentCard(
            assignment: a,
            assignee: assignee,
            onReassign: () => onReassign(a),
          );
        }),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.dmSans(
                color: color,
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: color.withAlpha(204),
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  final _Assignment assignment;
  final _StaffMember assignee;
  final VoidCallback onReassign;

  const _AssignmentCard({
    required this.assignment,
    required this.assignee,
    required this.onReassign,
  });

  Color get _statusColor {
    switch (assignment.status) {
      case 'active':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'completed':
        return Colors.white38;
      default:
        return Colors.white38;
    }
  }

  Color get _priorityColor {
    switch (assignment.priority) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1.5.h),
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  assignment.title,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  assignment.status.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    color: _statusColor,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          Text(
            assignment.description,
            style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 10.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Text(assignee.avatar, style: const TextStyle(fontSize: 16)),
              SizedBox(width: 1.5.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignee.name,
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      assignee.role,
                      style: GoogleFonts.dmSans(
                        color: Colors.white38,
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 1.5.w,
                  vertical: 0.3.h,
                ),
                decoration: BoxDecoration(
                  color: _priorityColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  assignment.priority.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    color: _priorityColor,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              GestureDetector(
                onTap: onReassign,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withAlpha(38),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withAlpha(77),
                    ),
                  ),
                  child: Text(
                    'Reassign',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF6C63FF),
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.8.h),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 12, color: Colors.white38),
              SizedBox(width: 1.w),
              Text(
                'Due: ${assignment.dueDate}',
                style: GoogleFonts.dmSans(
                  color: Colors.white38,
                  fontSize: 9.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Icon(Icons.tag_rounded, size: 12, color: Colors.white38),
              SizedBox(width: 1.w),
              Text(
                assignment.transactionId,
                style: GoogleFonts.dmSans(
                  color: Colors.white38,
                  fontSize: 9.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Staff Directory Tab ──────────────────────────────────────────────────────
class _StaffDirectoryTab extends StatelessWidget {
  final List<_StaffMember> staff;
  final String searchQuery;
  final String filterDept;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onDeptChanged;
  final Function(_StaffMember) onAssign;

  const _StaffDirectoryTab({
    required this.staff,
    required this.searchQuery,
    required this.filterDept,
    required this.onSearchChanged,
    required this.onDeptChanged,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final depts = [
      'All',
      ...{...staff.map((s) => s.dept)},
    ];
    final filtered = staff.where((s) {
      final matchSearch =
          searchQuery.isEmpty ||
          s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          s.role.toLowerCase().contains(searchQuery.toLowerCase());
      final matchDept = filterDept == 'All' || s.dept == filterDept;
      return matchSearch && matchDept;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            children: [
              // Search
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141929),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: TextField(
                  onChanged: onSearchChanged,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search staff...',
                    hintStyle: GoogleFonts.dmSans(
                      color: Colors.white38,
                      fontSize: 12.sp,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
              SizedBox(height: 1.h),
              // Dept filter
              SizedBox(
                height: 4.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: depts.length,
                  separatorBuilder: (_, __) => SizedBox(width: 2.w),
                  itemBuilder: (_, i) {
                    final isActive = depts[i] == filterDept;
                    return GestureDetector(
                      onTap: () => onDeptChanged(depts[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF6C63FF).withAlpha(51)
                              : Colors.white.withAlpha(13),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF6C63FF)
                                : Colors.white.withAlpha(26),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            depts[i],
                            style: GoogleFonts.dmSans(
                              color: isActive
                                  ? const Color(0xFF6C63FF)
                                  : Colors.white54,
                              fontSize: 10.sp,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => SizedBox(height: 1.h),
            itemBuilder: (_, i) => _StaffCard(
              staff: filtered[i],
              onAssign: () => onAssign(filtered[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _StaffCard extends StatelessWidget {
  final _StaffMember staff;
  final VoidCallback onAssign;

  const _StaffCard({required this.staff, required this.onAssign});

  @override
  Widget build(BuildContext context) {
    final workloadColor = staff.workload >= 80
        ? const Color(0xFFEF4444)
        : staff.workload >= 60
        ? const Color(0xFFF59E0B)
        : const Color(0xFF10B981);

    return Container(
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(18)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withAlpha(38),
              shape: BoxShape.circle,
              border: Border.all(
                color: staff.isAvailable
                    ? const Color(0xFF10B981).withAlpha(128)
                    : Colors.white.withAlpha(26),
              ),
            ),
            child: Center(
              child: Text(staff.avatar, style: const TextStyle(fontSize: 20)),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        staff.name,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: staff.isAvailable
                            ? const Color(0xFF10B981)
                            : Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                Text(
                  staff.role,
                  style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 10.sp,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Text(
                      staff.dept,
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF6C63FF),
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '•',
                      style: GoogleFonts.dmSans(
                        color: Colors.white24,
                        fontSize: 9.sp,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      staff.country,
                      style: GoogleFonts.dmSans(
                        color: Colors.white38,
                        fontSize: 9.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.5.h),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: staff.workload / 100,
                          backgroundColor: Colors.white.withAlpha(20),
                          valueColor: AlwaysStoppedAnimation(workloadColor),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '${staff.workload}%',
                      style: GoogleFonts.dmSans(
                        color: workloadColor,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 2.w),
          GestureDetector(
            onTap: onAssign,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                color: staff.isAvailable
                    ? const Color(0xFF6C63FF).withAlpha(38)
                    : Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: staff.isAvailable
                      ? const Color(0xFF6C63FF).withAlpha(102)
                      : Colors.white.withAlpha(26),
                ),
              ),
              child: Text(
                'Assign',
                style: GoogleFonts.dmSans(
                  color: staff.isAvailable
                      ? const Color(0xFF6C63FF)
                      : Colors.white38,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Task Queue Tab ───────────────────────────────────────────────────────────
class _TaskQueueTab extends StatelessWidget {
  final List<_Task> tasks;
  final List<_StaffMember> staff;
  final String filterStatus;
  final ValueChanged<String> onStatusChanged;
  final Function(_Task) onAssign;

  const _TaskQueueTab({
    required this.tasks,
    required this.staff,
    required this.filterStatus,
    required this.onStatusChanged,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      'All',
      'unassigned',
      'pending',
      'in_progress',
      'completed',
    ];
    final filtered = filterStatus == 'All'
        ? tasks
        : tasks.where((t) => t.status == filterStatus).toList();

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
          child: SizedBox(
            height: 4.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: statuses.length,
              separatorBuilder: (_, __) => SizedBox(width: 2.w),
              itemBuilder: (_, i) {
                final isActive = statuses[i] == filterStatus;
                return GestureDetector(
                  onTap: () => onStatusChanged(statuses[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(horizontal: 3.w),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF6C63FF).withAlpha(51)
                          : Colors.white.withAlpha(13),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF6C63FF)
                            : Colors.white.withAlpha(26),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        statuses[i].replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.dmSans(
                          color: isActive
                              ? const Color(0xFF6C63FF)
                              : Colors.white54,
                          fontSize: 9.sp,
                          fontWeight: isActive
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => SizedBox(height: 1.h),
            itemBuilder: (_, i) => _TaskCard(
              task: filtered[i],
              staff: staff,
              onAssign: () => onAssign(filtered[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final _Task task;
  final List<_StaffMember> staff;
  final VoidCallback onAssign;

  const _TaskCard({
    required this.task,
    required this.staff,
    required this.onAssign,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignee = task.assignedTo != null
        ? staff.firstWhere(
            (s) => s.id == task.assignedTo,
            orElse: () => _StaffMember(
              id: '',
              name: 'Unknown',
              role: '',
              dept: '',
              avatar: '👤',
              workload: 0,
              isAvailable: false,
              country: 'IQ',
            ),
          )
        : null;

    return Container(
      padding: EdgeInsets.all(3.5.w),
      decoration: BoxDecoration(
        color: const Color(0xFF141929),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: task.assignedTo == null
              ? const Color(0xFFF59E0B).withAlpha(77)
              : Colors.white.withAlpha(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: _priorityColor.withAlpha(38),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  task.priority.toUpperCase(),
                  style: GoogleFonts.dmSans(
                    color: _priorityColor,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.3.h),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  task.type,
                  style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 9.sp,
                  ),
                ),
              ),
              const Spacer(),
              if (task.assignedTo == null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.3.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withAlpha(38),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'UNASSIGNED',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFFF59E0B),
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 0.8.h),
          Text(
            task.title,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.4.h),
          Text(
            task.description,
            style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 10.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              if (assignee != null) ...[
                Text(assignee.avatar, style: const TextStyle(fontSize: 14)),
                SizedBox(width: 1.5.w),
                Text(
                  assignee.name,
                  style: GoogleFonts.dmSans(
                    color: Colors.white60,
                    fontSize: 10.sp,
                  ),
                ),
                const Spacer(),
              ] else ...[
                Icon(Icons.person_off_rounded, size: 14, color: Colors.white38),
                SizedBox(width: 1.5.w),
                Text(
                  'No assignee',
                  style: GoogleFonts.dmSans(
                    color: Colors.white38,
                    fontSize: 10.sp,
                  ),
                ),
                const Spacer(),
              ],
              GestureDetector(
                onTap: onAssign,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.5.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF6C63FF).withAlpha(77),
                    ),
                  ),
                  child: Text(
                    task.assignedTo == null ? 'Assign' : 'Reassign',
                    style: GoogleFonts.dmSans(
                      color: const Color(0xFF6C63FF),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Sheets ────────────────────────────────────────────────────────────
class _NewAssignmentSheet extends StatefulWidget {
  final List<_StaffMember> staff;
  final List<_Task> tasks;

  const _NewAssignmentSheet({required this.staff, required this.tasks});

  @override
  State<_NewAssignmentSheet> createState() => _NewAssignmentSheetState();
}

class _NewAssignmentSheetState extends State<_NewAssignmentSheet> {
  _StaffMember? _selectedStaff;
  _Task? _selectedTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1220),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'New Assignment',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Select Task',
            style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 11.sp),
          ),
          SizedBox(height: 0.8.h),
          DropdownButtonFormField<_Task>(
            initialValue: _selectedTask,
            dropdownColor: const Color(0xFF1A2035),
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11.sp),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withAlpha(13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withAlpha(26)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withAlpha(26)),
              ),
            ),
            hint: Text(
              'Choose a task',
              style: GoogleFonts.dmSans(color: Colors.white38),
            ),
            items: widget.tasks
                .map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.title, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedTask = v),
          ),
          SizedBox(height: 1.5.h),
          Text(
            'Assign To',
            style: GoogleFonts.dmSans(color: Colors.white60, fontSize: 11.sp),
          ),
          SizedBox(height: 0.8.h),
          DropdownButtonFormField<_StaffMember>(
            initialValue: _selectedStaff,
            dropdownColor: const Color(0xFF1A2035),
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11.sp),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withAlpha(13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withAlpha(26)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.white.withAlpha(26)),
              ),
            ),
            hint: Text(
              'Choose staff member',
              style: GoogleFonts.dmSans(color: Colors.white38),
            ),
            items: widget.staff
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Row(
                      children: [
                        Text(s.avatar),
                        SizedBox(width: 2.w),
                        Text(
                          '${s.name} (${s.workload}%)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _selectedStaff = v),
          ),
          SizedBox(height: 2.5.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedStaff != null && _selectedTask != null)
                  ? () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Assigned "${_selectedTask!.title}" to ${_selectedStaff!.name}',
                            style: GoogleFonts.dmSans(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                disabledBackgroundColor: Colors.white.withAlpha(26),
                padding: EdgeInsets.symmetric(vertical: 1.8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm Assignment',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}

class _ReassignSheet extends StatelessWidget {
  final _Assignment assignment;
  final List<_StaffMember> staff;

  const _ReassignSheet({required this.assignment, required this.staff});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1220),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Reassign Task',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            assignment.title,
            style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 11.sp),
          ),
          SizedBox(height: 2.h),
          ...staff.map(
            (s) => ListTile(
              leading: Text(s.avatar, style: const TextStyle(fontSize: 20)),
              title: Text(
                s.name,
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12.sp),
              ),
              subtitle: Text(
                '${s.role} • ${s.workload}% workload',
                style: GoogleFonts.dmSans(
                  color: Colors.white38,
                  fontSize: 10.sp,
                ),
              ),
              trailing: s.isAvailable
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 18,
                    )
                  : const Icon(
                      Icons.cancel_rounded,
                      color: Colors.white24,
                      size: 18,
                    ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Reassigned to ${s.name}',
                      style: GoogleFonts.dmSans(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}

class _AssignToStaffSheet extends StatelessWidget {
  final _StaffMember staff;
  final List<_Task> tasks;

  const _AssignToStaffSheet({required this.staff, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final unassigned = tasks.where((t) => t.assignedTo == null).toList();
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1220),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Text(staff.avatar, style: const TextStyle(fontSize: 24)),
              SizedBox(width: 3.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    staff.role,
                    style: GoogleFonts.dmSans(
                      color: Colors.white54,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Unassigned Tasks (${unassigned.length})',
            style: GoogleFonts.dmSans(
              color: Colors.white60,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ...unassigned
              .take(5)
              .map(
                (t) => ListTile(
                  dense: true,
                  title: Text(
                    t.title,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 11.sp,
                    ),
                  ),
                  subtitle: Text(
                    t.type,
                    style: GoogleFonts.dmSans(
                      color: Colors.white38,
                      fontSize: 9.sp,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Assigned to ${staff.name}',
                            style: GoogleFonts.dmSans(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'Assign',
                      style: GoogleFonts.dmSans(
                        color: const Color(0xFF6C63FF),
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ),
              ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}

class _AssignTaskSheet extends StatelessWidget {
  final _Task task;
  final List<_StaffMember> staff;

  const _AssignTaskSheet({required this.task, required this.staff});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1220),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Assign Task',
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            task.title,
            style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 11.sp),
          ),
          SizedBox(height: 2.h),
          Text(
            'Available Staff',
            style: GoogleFonts.dmSans(
              color: Colors.white60,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ...staff
              .where((s) => s.isAvailable)
              .map(
                (s) => ListTile(
                  leading: Text(s.avatar, style: const TextStyle(fontSize: 20)),
                  title: Text(
                    s.name,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 12.sp,
                    ),
                  ),
                  subtitle: Text(
                    '${s.dept} • ${s.workload}%',
                    style: GoogleFonts.dmSans(
                      color: Colors.white38,
                      fontSize: 10.sp,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Task assigned to ${s.name}',
                          style: GoogleFonts.dmSans(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}

// ─── Data Models ──────────────────────────────────────────────────────────────
class _StaffMember {
  final String id;
  final String name;
  final String role;
  final String dept;
  final String avatar;
  final int workload;
  final bool isAvailable;
  final String country;

  const _StaffMember({
    required this.id,
    required this.name,
    required this.role,
    required this.dept,
    required this.avatar,
    required this.workload,
    required this.isAvailable,
    required this.country,
  });
}

class _Assignment {
  final String id;
  final String title;
  final String description;
  final String staffId;
  final String status;
  final String priority;
  final String dueDate;
  final String transactionId;

  const _Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.staffId,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.transactionId,
  });
}

class _Task {
  final String id;
  final String title;
  final String description;
  final String type;
  final String priority;
  final String status;
  final String? assignedTo;

  const _Task({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.status,
    this.assignedTo,
  });
}

// ─── Demo Data ────────────────────────────────────────────────────────────────
const List<_StaffMember> _demoStaff = [
  _StaffMember(
    id: 's1',
    name: 'Ahmed Al-Rashidi',
    role: 'Transaction Coordinator',
    dept: 'Operations',
    avatar: '👨‍💼',
    workload: 72,
    isAvailable: true,
    country: 'IQ',
  ),
  _StaffMember(
    id: 's2',
    name: 'Sara Al-Khalidi',
    role: 'Lawyer',
    dept: 'Legal',
    avatar: '👩‍⚖️',
    workload: 45,
    isAvailable: true,
    country: 'IQ',
  ),
  _StaffMember(
    id: 's3',
    name: 'Omar Hassan',
    role: 'Bank Escrow Officer',
    dept: 'Finance',
    avatar: '🏦',
    workload: 88,
    isAvailable: false,
    country: 'IQ',
  ),
  _StaffMember(
    id: 's4',
    name: 'Fatima Al-Zahraa',
    role: 'Finance Officer',
    dept: 'Finance',
    avatar: '👩‍💻',
    workload: 60,
    isAvailable: true,
    country: 'IQ',
  ),
  _StaffMember(
    id: 's5',
    name: 'Khalid Al-Saud',
    role: 'Transaction Coordinator',
    dept: 'Operations',
    avatar: '👨‍💼',
    workload: 30,
    isAvailable: true,
    country: 'SA',
  ),
  _StaffMember(
    id: 's6',
    name: 'Nour Al-Din',
    role: 'Customer Support',
    dept: 'Support',
    avatar: '🎧',
    workload: 55,
    isAvailable: true,
    country: 'IQ',
  ),
  _StaffMember(
    id: 's7',
    name: 'Zainab Karimi',
    role: 'Risk Analyst',
    dept: 'Risk',
    avatar: '🔍',
    workload: 40,
    isAvailable: true,
    country: 'IQ',
  ),
];

const List<_Assignment> _demoAssignments = [
  _Assignment(
    id: 'a1',
    title: 'Review Contract — Karrada Property',
    description:
        'Review and finalize sale contract for residential property in Karrada district',
    staffId: 's2',
    status: 'active',
    priority: 'high',
    dueDate: '2026-08-20',
    transactionId: 'MADAR-IQ-2026-00047',
  ),
  _Assignment(
    id: 'a2',
    title: 'Escrow Confirmation — Al-Mansour',
    description:
        'Confirm bank escrow deposit for Al-Mansour property transaction',
    staffId: 's3',
    status: 'pending',
    priority: 'high',
    dueDate: '2026-08-18',
    transactionId: 'MADAR-IQ-2026-00046',
  ),
  _Assignment(
    id: 'a3',
    title: 'Document Verification — Buyer KYC',
    description:
        'Verify national ID and proof of funds for buyer in transaction 00045',
    staffId: 's1',
    status: 'active',
    priority: 'medium',
    dueDate: '2026-08-17',
    transactionId: 'MADAR-IQ-2026-00045',
  ),
  _Assignment(
    id: 'a4',
    title: 'Fee Calculation — Settlement',
    description:
        'Calculate final settlement fees including tax and brokerage for completed deal',
    staffId: 's4',
    status: 'completed',
    priority: 'low',
    dueDate: '2026-08-15',
    transactionId: 'MADAR-IQ-2026-00044',
  ),
];

const List<_Task> _demoTasks = [
  _Task(
    id: 't1',
    title: 'Verify Seller Identity Documents',
    description:
        'Check national ID and ownership proof for seller in new transaction',
    type: 'KYC',
    priority: 'high',
    status: 'unassigned',
    assignedTo: null,
  ),
  _Task(
    id: 't2',
    title: 'Draft Sale Contract — Zayouna',
    description:
        'Prepare standard Arabic sale contract for residential property',
    type: 'Legal',
    priority: 'high',
    status: 'pending',
    assignedTo: 's2',
  ),
  _Task(
    id: 't3',
    title: 'Bank Escrow Setup',
    description:
        'Initialize escrow account at Baghdad Bank for transaction 00048',
    type: 'Finance',
    priority: 'medium',
    status: 'unassigned',
    assignedTo: null,
  ),
  _Task(
    id: 't4',
    title: 'Client Follow-up Call',
    description: 'Call buyer to confirm property inspection appointment',
    type: 'Support',
    priority: 'low',
    status: 'in_progress',
    assignedTo: 's6',
  ),
  _Task(
    id: 't5',
    title: 'Risk Assessment — Agricultural Land',
    description:
        'Assess risk profile for agricultural land transaction in Diyala',
    type: 'Risk',
    priority: 'medium',
    status: 'unassigned',
    assignedTo: null,
  ),
  _Task(
    id: 't6',
    title: 'Generate Settlement Receipt',
    description: 'Create final payout receipt for completed transaction 00044',
    type: 'Finance',
    priority: 'low',
    status: 'completed',
    assignedTo: 's4',
  ),
];
