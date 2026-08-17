import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../providers/office_auth_notifier.dart';

class OfficeDocumentsScreen extends StatefulWidget {
  const OfficeDocumentsScreen({super.key});

  @override
  State<OfficeDocumentsScreen> createState() => _OfficeDocumentsScreenState();
}

class _OfficeDocumentsScreenState extends State<OfficeDocumentsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _docs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = context.read<OfficeAuthNotifier>().repository;
    setState(() => _loading = true);
    final list = await repo.listDocuments();
    if (!mounted) return;
    setState(() {
      _docs = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(title: Text(loc.officeDocuments)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _docs.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(child: Text(loc.officeNoDocuments)),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final d = _docs[i];
                        return ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: Text(d['title']?.toString() ?? ''),
                          subtitle: Text(d['document_type']?.toString() ?? ''),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
