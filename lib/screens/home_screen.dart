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

  @override
  void initState() {
    super.initState();
    _load();
    _channel.setMethodCallHandler(_onMethodCall);
    _checkPendingFile();
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
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
      if (mounted) setState(() => _passes = passes);
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
      if (mounted) setState(() => _passes = passes);
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
                  l.homeTitle,
                  style: tt.headlineLarge?.copyWith(color: colorScheme.onSurface),
                ),
              ),

              if (_error != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
                    : _passes.isEmpty
                        ? _buildEmptyState(l, colorScheme, tt)
                        : _buildList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _isLoading
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
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      )
                    : const Icon(Icons.add_rounded),
              ),
            ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 100),
      itemCount: _passes.length,
      itemBuilder: (context, index) => PassCard(
        pass: _passes[index],
        onTap: () => _openPass(_passes[index]),
      ),
    );
  }

  Widget _buildEmptyState(
      AppLocalizations l, ColorScheme colorScheme, TextTheme tt) {
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
                child: Icon(Icons.confirmation_number_rounded,
                    size: 48, color: colorScheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l.homeEmptyTitle,
              style: tt.headlineSmall?.copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l.homeEmptyHint,
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
