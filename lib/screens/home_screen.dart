import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../db/database.dart';
import '../l10n/app_localizations.dart';
import '../models/pass_record.dart';
import '../services/pkpass_service.dart';
import '../services/widget_service.dart';
import '../widgets/app_background.dart';
import '../widgets/pass_card.dart';
import 'pass_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _channel = MethodChannel('com.tickety/pkpass');

  List<PassRecord> _passes = [];
  bool _isLoading = true;
  String? _error;
  bool _isAdding = false;
  int _selectedDestination = 0;
  Timer? _archiveTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _channel.setMethodCallHandler(_onMethodCall);
    _checkPendingFile();
  }

  @override
  void dispose() {
    _archiveTimer?.cancel();
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  void _scheduleArchiveRefresh() {
    _archiveTimer?.cancel();
    final now = DateTime.now();
    final upcomingDates = _passes
        .map((pass) => pass.archiveDate)
        .whereType<DateTime>()
        .where((date) => date.isAfter(now))
        .toList()
      ..sort();
    if (upcomingDates.isEmpty) return;

    _archiveTimer = Timer(upcomingDates.first.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleArchiveRefresh();
      WidgetService.update();
    });
  }

  Future<dynamic> _onMethodCall(MethodCall call) async {
    if (call.method == 'openFile') {
      final path = call.arguments as String?;
      if (path != null) await _importFile(path);
    }
  }

  Future<void> _checkPendingFile() async {
    try {
      final path = await _channel.invokeMethod<String>('getPendingFile');
      if (path != null && mounted) await _importFile(path);
    } catch (_) {}
  }

  Future<void> _importFile(String path) async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    try {
      final locale = Localizations.localeOf(context);
      final result = await addPassFromFile(path, locale);
      if (!mounted) return;
      if (result is AddPassSuccess) {
        await _silentRefresh();
      } else if (result is AddPassError) {
        _showError(result.message);
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final passes = await DatabaseHelper.instance.getAllPasses();
      if (mounted) {
        setState(() => _passes = passes);
        _scheduleArchiveRefresh();
      }
      WidgetService.update();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final passes = await DatabaseHelper.instance.getAllPasses();
      if (mounted) {
        setState(() => _passes = passes);
        _scheduleArchiveRefresh();
      }
      WidgetService.update();
    } catch (_) {}
  }

  Future<void> _addPass() async {
    if (_isAdding) return;
    setState(() => _isAdding = true);
    try {
      final locale = Localizations.localeOf(context);
      final result = await addPassFromPicker(locale);
      if (!mounted) return;
      if (result is AddPassSuccess) {
        await _silentRefresh();
      } else if (result is AddPassError) {
        _showError(result.message);
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _showError(String message) {
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.homeError),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openPass(PassRecord pass) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PassDetailScreen(passId: pass.id),
    ).then((deleted) {
      if (deleted == true) _silentRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();
    final activePasses = _passes
        .where((pass) => !pass.isArchivedAt(now))
        .toList();
    final archivedPasses =
        _passes.where((pass) => pass.isArchivedAt(now)).toList()..sort((a, b) {
          final aDate = a.archiveDate;
          final bDate = b.archiveDate;
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
    final visiblePasses = _selectedDestination == 0
        ? activePasses
        : archivedPasses;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header — title only
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  _selectedDestination == 0 ? l.homeTitle : l.archiveTitle,
                  style: tt.headlineLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      l.homeErrorLoad,
                      style: tt.bodyMedium?.copyWith(color: colorScheme.error),
                    ),
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? Center(
                        child: Semantics(
                          label: l.homeLoading,
                          child: const CircularProgressIndicator(),
                        ),
                      )
                    : visiblePasses.isEmpty
                    ? _buildEmptyState(
                        title: _selectedDestination == 0
                            ? l.homeEmptyTitle
                            : l.archiveEmptyTitle,
                        hint: _selectedDestination == 0
                            ? l.homeEmptyHint
                            : l.archiveEmptyHint,
                        icon: _selectedDestination == 0
                            ? Icons.confirmation_number_rounded
                            : Icons.inventory_2_outlined,
                        colorScheme: colorScheme,
                        tt: tt,
                      )
                    : _buildList(visiblePasses),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedDestination,
        onDestinationSelected: (index) {
          setState(() => _selectedDestination = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.confirmation_number_outlined),
            selectedIcon: const Icon(Icons.confirmation_number_rounded),
            label: l.homeTitle,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: archivedPasses.isNotEmpty,
              label: Text('${archivedPasses.length}'),
              child: const Icon(Icons.inventory_2_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: archivedPasses.isNotEmpty,
              label: Text('${archivedPasses.length}'),
              child: const Icon(Icons.inventory_2_rounded),
            ),
            label: l.archiveTitle,
          ),
        ],
      ),
      floatingActionButton: _isLoading || _selectedDestination != 0
          ? null
          : Semantics(
              button: true,
              label: l.homeAddTicket,
              child: FloatingActionButton(
                onPressed: _isAdding ? null : _addPass,
                child: _isAdding
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
              ),
            ),
    );
  }

  Widget _buildList(List<PassRecord> passes) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: passes.length,
      itemBuilder: (context, index) =>
          PassCard(pass: passes[index], onTap: () => _openPass(passes[index])),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    required TextTheme tt,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  // M3: secondary container for illustrative icon
                  color: colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: tt.headlineSmall?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: tt.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
