import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../services/security_service.dart';
import '../services/secure_data_manager.dart';
import '../services/analytics_service.dart';

/// Security settings screen for managing biometric authentication,
/// encryption settings, and security audit features
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SecurityService _securityService = SecurityService();
  final SecureDataManager _dataManager = SecureDataManager();
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isLoading = true;
  SecurityStatus? _securityStatus;
  BiometricSupport? _biometricSupport;
  SecuritySettings? _securitySettings;
  BiometricSettings? _biometricSettings;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _analyticsService.logScreenView('security_settings');
    _initializeSecurityData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeSecurityData() async {
    try {
      await _securityService.initialize();
      await _dataManager.initialize();

      _securityStatus = _securityService.getSecurityStatus();
      _biometricSupport = await _securityService.checkBiometricSupport();
      _securitySettings =
          await _dataManager.getSecuritySettings() ??
          SecuritySettings(lastUpdated: DateTime.now());
      _biometricSettings =
          await _dataManager.getBiometricSettings() ??
          BiometricSettings(enabled: false, lastUpdated: DateTime.now());

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        _showErrorSnackBar('Error initializing security settings: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.fingerprint), text: 'Biometric'),
            Tab(icon: Icon(Icons.security), text: 'Security'),
            Tab(icon: Icon(Icons.assessment), text: 'Audit'),
            Tab(icon: Icon(Icons.build), text: 'Tools'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBiometricTab(),
                _buildSecurityTab(),
                _buildAuditTab(),
                _buildToolsTab(),
              ],
            ),
    );
  }

  Widget _buildBiometricTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBiometricStatusCard(),
          const SizedBox(height: 16),
          _buildBiometricSettingsCard(),
          const SizedBox(height: 16),
          _buildBiometricTestCard(),
        ],
      ),
    );
  }

  Widget _buildBiometricStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fingerprint,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Biometric Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              'Device Support',
              _biometricSupport?.isDeviceSupported == true
                  ? 'Supported'
                  : 'Not Supported',
              _biometricSupport?.isDeviceSupported == true
                  ? Colors.green
                  : Colors.red,
            ),
            _buildStatusRow(
              'Biometric Available',
              _biometricSupport?.isAvailable == true
                  ? 'Available'
                  : 'Not Available',
              _biometricSupport?.isAvailable == true
                  ? Colors.green
                  : Colors.red,
            ),
            _buildStatusRow(
              'Current Status',
              _securityStatus?.biometricEnabled == true
                  ? 'Enabled'
                  : 'Disabled',
              _securityStatus?.biometricEnabled == true
                  ? Colors.green
                  : Colors.orange,
            ),
            if (_biometricSupport?.availableBiometrics.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Available Biometrics:',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              ...(_biometricSupport!.availableBiometrics.map(
                (type) => Chip(
                  label: Text(_getBiometricTypeName(type)),
                  avatar: Icon(_getBiometricTypeIcon(type), size: 18),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Biometric Settings',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Biometric Authentication'),
              subtitle: const Text(
                'Use biometrics to unlock sensitive features',
              ),
              value: _biometricSettings?.enabled == true,
              onChanged: _biometricSupport?.isAvailable == true
                  ? (value) => _toggleBiometric(value)
                  : null,
            ),
            if (_biometricSettings?.enabled == true) ...[
              SwitchListTile(
                title: const Text('Require for Login'),
                subtitle: const Text(
                  'Require biometric authentication for app login',
                ),
                value: _biometricSettings?.requireForLogin == true,
                onChanged: (value) =>
                    _updateBiometricSetting('requireForLogin', value),
              ),
              SwitchListTile(
                title: const Text('Require for Sensitive Data'),
                subtitle: const Text(
                  'Require biometric for accessing patient data',
                ),
                value: _biometricSettings?.requireForSensitiveData == true,
                onChanged: (value) =>
                    _updateBiometricSetting('requireForSensitiveData', value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricTestCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Biometric Authentication',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _biometricSupport?.isAvailable == true
                    ? _testBiometric
                    : null,
                child: const Text('Test Biometric Authentication'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Test your biometric authentication to ensure it works correctly.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSecurityStatusCard(),
          const SizedBox(height: 16),
          _buildSecuritySettingsCard(),
          const SizedBox(height: 16),
          _buildEncryptionCard(),
        ],
      ),
    );
  }

  Widget _buildSecurityStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Security Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              'Security Service',
              _securityStatus?.isInitialized == true
                  ? 'Initialized'
                  : 'Not Initialized',
              _securityStatus?.isInitialized == true
                  ? Colors.green
                  : Colors.red,
            ),
            _buildStatusRow(
              'Encryption',
              _securityStatus?.encryptionEnabled == true
                  ? 'Enabled'
                  : 'Disabled',
              _securityStatus?.encryptionEnabled == true
                  ? Colors.green
                  : Colors.orange,
            ),
            _buildStatusRow(
              'Account Status',
              _securityStatus?.isLockedOut == true ? 'Locked Out' : 'Active',
              _securityStatus?.isLockedOut == true ? Colors.red : Colors.green,
            ),
            if (_securityStatus?.failedAttempts != null) ...[
              _buildStatusRow(
                'Failed Attempts',
                '${_securityStatus!.failedAttempts}/${_securityStatus!.maxAttempts}',
                _securityStatus!.failedAttempts > 0
                    ? Colors.orange
                    : Colors.green,
              ),
            ],
            if (_securityStatus?.lastAuthTime != null) ...[
              _buildStatusRow(
                'Last Authentication',
                _formatDateTime(_securityStatus!.lastAuthTime!),
                Colors.blue,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Settings',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-Lock'),
              subtitle: const Text('Automatically lock app after inactivity'),
              value: _securitySettings?.autoLockEnabled == true,
              onChanged: (value) =>
                  _updateSecuritySetting('autoLockEnabled', value),
            ),
            if (_securitySettings?.autoLockEnabled == true) ...[
              ListTile(
                title: const Text('Auto-Lock Timeout'),
                subtitle: Text(
                  '${_securitySettings!.autoLockTimeout ~/ 60} minutes',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showAutoLockTimeoutDialog,
                ),
              ),
            ],
            SwitchListTile(
              title: const Text('Data Encryption'),
              subtitle: const Text('Encrypt all stored data'),
              value: _securitySettings?.dataEncryptionEnabled == true,
              onChanged: (value) =>
                  _updateSecuritySetting('dataEncryptionEnabled', value),
            ),
            SwitchListTile(
              title: const Text('Audit Logging'),
              subtitle: const Text('Log security events for audit trail'),
              value: _securitySettings?.auditLoggingEnabled == true,
              onChanged: (value) =>
                  _updateSecuritySetting('auditLoggingEnabled', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEncryptionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Encryption',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _securityStatus?.encryptionEnabled == true
                      ? Icons.lock
                      : Icons.lock_open,
                  color: _securityStatus?.encryptionEnabled == true
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _securityStatus?.encryptionEnabled == true
                      ? 'All data is encrypted'
                      : 'Data encryption disabled',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testEncryption,
                child: const Text('Test Encryption'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuditSummaryCard(),
          const SizedBox(height: 16),
          _buildRecentEventsCard(),
        ],
      ),
    );
  }

  Widget _buildAuditSummaryCard() {
    final auditReport = _securityService.getSecurityAudit();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Audit Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildStatusRow(
              'Total Events',
              '${auditReport.totalEvents}',
              Colors.blue,
            ),
            _buildStatusRow(
              'Recent Events (30 days)',
              '${auditReport.recentEvents.length}',
              Colors.blue,
            ),
            _buildStatusRow(
              'Successful Authentications',
              '${auditReport.authSuccessCount}',
              Colors.green,
            ),
            _buildStatusRow(
              'Failed Authentications',
              '${auditReport.authFailureCount}',
              Colors.red,
            ),
            _buildStatusRow(
              'Data Access Events',
              '${auditReport.dataAccessCount}',
              Colors.orange,
            ),
            _buildStatusRow(
              'Security Violations',
              '${auditReport.securityViolations.length}',
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentEventsCard() {
    final auditReport = _securityService.getSecurityAudit();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Security Events',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (auditReport.recentEvents.isEmpty)
              Text(
                'No recent security events',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              ...auditReport.recentEvents
                  .take(10)
                  .map(
                    (event) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Icon(_getEventIcon(event.eventType)),
                        title: Text(_formatEventType(event.eventType)),
                        subtitle: Text(_formatDateTime(event.timestamp)),
                        trailing: event.data != null
                            ? const Icon(Icons.info_outline)
                            : null,
                        onTap: event.data != null
                            ? () => _showEventDetails(event)
                            : null,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataManagementCard(),
          const SizedBox(height: 16),
          _buildSecurityToolsCard(),
          const SizedBox(height: 16),
          _buildExportCard(),
        ],
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showDataSummary,
                child: const Text('View Data Summary'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _clearUserData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text('Clear User Data'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _clearAllData,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Clear All Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityToolsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Tools',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateSecurityReport,
                child: const Text('Generate Security Report'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _testDataIntegrity,
                child: const Text('Test Data Integrity'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _forceReauthentication,
                child: const Text('Force Re-authentication'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Export',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _exportSecurityEvents,
                child: const Text('Export Security Events'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _exportAllData,
                child: const Text('Export All Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(26),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withAlpha(77)),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.weak:
        return 'Weak';
      case BiometricType.strong:
        return 'Strong';
    }
  }

  IconData _getBiometricTypeIcon(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face;
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.iris:
        return Icons.visibility;
      case BiometricType.weak:
        return Icons.security;
      case BiometricType.strong:
        return Icons.verified_user;
    }
  }

  IconData _getEventIcon(String eventType) {
    if (eventType.contains('auth_success')) return Icons.check_circle;
    if (eventType.contains('auth_failed')) return Icons.error;
    if (eventType.contains('locked')) return Icons.lock;
    if (eventType.contains('data')) return Icons.storage;
    if (eventType.contains('error')) return Icons.warning;
    return Icons.info;
  }

  String _formatEventType(String eventType) {
    return eventType.replaceAll('_', ' ').toUpperCase();
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  // Action methods
  Future<void> _toggleBiometric(bool enabled) async {
    try {
      if (enabled) {
        final result = await _securityService.authenticateWithBiometric(
          reason: 'Please authenticate to enable biometric security',
        );

        if (!result.success) {
          if (mounted) {
            _showErrorSnackBar('Biometric authentication failed');
          }
          return;
        }
      }

      await _securityService.setBiometricEnabled(enabled);

      final newSettings = BiometricSettings(
        enabled: enabled,
        enabledBiometrics: _biometricSettings?.enabledBiometrics ?? [],
        requireForLogin: _biometricSettings?.requireForLogin ?? true,
        requireForSensitiveData:
            _biometricSettings?.requireForSensitiveData ?? true,
        lastUpdated: DateTime.now(),
      );

      await _dataManager.storeBiometricSettings(newSettings);

      setState(() {
        _biometricSettings = newSettings;
        _securityStatus = _securityService.getSecurityStatus();
      });

      _analyticsService.logUserAction(
        'biometric_toggled',
        context: {'enabled': enabled},
      );
      if (mounted) {
        _showSuccessSnackBar(
          'Biometric authentication ${enabled ? 'enabled' : 'disabled'}',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating biometric setting: $e');
      }
    }
  }

  Future<void> _updateBiometricSetting(String setting, bool value) async {
    try {
      BiometricSettings newSettings;

      switch (setting) {
        case 'requireForLogin':
          newSettings = BiometricSettings(
            enabled: _biometricSettings!.enabled,
            enabledBiometrics: _biometricSettings!.enabledBiometrics,
            requireForLogin: value,
            requireForSensitiveData:
                _biometricSettings!.requireForSensitiveData,
            lastUpdated: DateTime.now(),
          );
          break;
        case 'requireForSensitiveData':
          newSettings = BiometricSettings(
            enabled: _biometricSettings!.enabled,
            enabledBiometrics: _biometricSettings!.enabledBiometrics,
            requireForLogin: _biometricSettings!.requireForLogin,
            requireForSensitiveData: value,
            lastUpdated: DateTime.now(),
          );
          break;
        default:
          return;
      }

      await _dataManager.storeBiometricSettings(newSettings);
      setState(() {
        _biometricSettings = newSettings;
      });

      if (mounted) {
        _showSuccessSnackBar('Biometric setting updated');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating biometric setting: $e');
      }
    }
  }

  Future<void> _updateSecuritySetting(String setting, bool value) async {
    try {
      SecuritySettings newSettings;

      switch (setting) {
        case 'autoLockEnabled':
          newSettings = SecuritySettings(
            autoLockEnabled: value,
            autoLockTimeout: _securitySettings!.autoLockTimeout,
            dataEncryptionEnabled: _securitySettings!.dataEncryptionEnabled,
            secureBackupEnabled: _securitySettings!.secureBackupEnabled,
            auditLoggingEnabled: _securitySettings!.auditLoggingEnabled,
            lastUpdated: DateTime.now(),
          );
          break;
        case 'dataEncryptionEnabled':
          await _securityService.setEncryptionEnabled(value);
          newSettings = SecuritySettings(
            autoLockEnabled: _securitySettings!.autoLockEnabled,
            autoLockTimeout: _securitySettings!.autoLockTimeout,
            dataEncryptionEnabled: value,
            secureBackupEnabled: _securitySettings!.secureBackupEnabled,
            auditLoggingEnabled: _securitySettings!.auditLoggingEnabled,
            lastUpdated: DateTime.now(),
          );
          break;
        case 'auditLoggingEnabled':
          newSettings = SecuritySettings(
            autoLockEnabled: _securitySettings!.autoLockEnabled,
            autoLockTimeout: _securitySettings!.autoLockTimeout,
            dataEncryptionEnabled: _securitySettings!.dataEncryptionEnabled,
            secureBackupEnabled: _securitySettings!.secureBackupEnabled,
            auditLoggingEnabled: value,
            lastUpdated: DateTime.now(),
          );
          break;
        default:
          return;
      }

      await _dataManager.storeSecuritySettings(newSettings);
      setState(() {
        _securitySettings = newSettings;
        _securityStatus = _securityService.getSecurityStatus();
      });

      if (mounted) {
        _showSuccessSnackBar('Security setting updated');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating security setting: $e');
      }
    }
  }

  Future<void> _testBiometric() async {
    final result = await _securityService.authenticateWithBiometric(
      reason: 'Test biometric authentication',
    );

    if (!mounted) return;
    if (result.success) {
      _showSuccessSnackBar('Biometric authentication test successful!');
    } else {
      _showErrorSnackBar(
        'Biometric authentication test failed: ${result.error ?? 'Unknown error'}',
      );
    }
  }

  Future<void> _testEncryption() async {
    try {
      const testData = 'Test encryption data';
      await _securityService.storeSecureData('test_encryption', testData);
      final retrievedData = await _securityService.retrieveSecureData(
        'test_encryption',
      );
      await _securityService.deleteSecureData('test_encryption');

      if (mounted) {
        if (retrievedData == testData) {
          _showSuccessSnackBar('Encryption test successful!');
        } else {
          _showErrorSnackBar('Encryption test failed: Data mismatch');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Encryption test failed: $e');
      }
    }
  }

  Future<void> _showAutoLockTimeoutDialog() async {
    final currentContext = context;
    int currentTimeout = _securitySettings?.autoLockTimeout ?? 300;
    int newTimeout = currentTimeout;

    final result = await showDialog<int>(
      context: currentContext,
      builder: (context) => AlertDialog(
        title: const Text('Auto-Lock Timeout'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select timeout in minutes:'),
              const SizedBox(height: 16),
              DropdownButton<int>(
                value: newTimeout ~/ 60,
                onChanged: (value) {
                  setState(() {
                    newTimeout = (value ?? 5) * 60;
                  });
                },
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 minute')),
                  DropdownMenuItem(value: 2, child: Text('2 minutes')),
                  DropdownMenuItem(value: 5, child: Text('5 minutes')),
                  DropdownMenuItem(value: 10, child: Text('10 minutes')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                  DropdownMenuItem(value: 30, child: Text('30 minutes')),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(newTimeout);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final newSettings = SecuritySettings(
        autoLockEnabled: _securitySettings!.autoLockEnabled,
        autoLockTimeout: result,
        dataEncryptionEnabled: _securitySettings!.dataEncryptionEnabled,
        secureBackupEnabled: _securitySettings!.secureBackupEnabled,
        auditLoggingEnabled: _securitySettings!.auditLoggingEnabled,
        lastUpdated: DateTime.now(),
      );

      await _dataManager.storeSecuritySettings(newSettings);
      setState(() {
        _securitySettings = newSettings;
      });

      if (mounted) {
        _showSuccessSnackBar('Auto-lock timeout updated');
      }
    }
  }

  Future<void> _showDataSummary() async {
    final summary = await _dataManager.getDataSummary();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Summary'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: summary.entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('${entry.key}: ${entry.value}'),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearUserData() async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear User Data'),
        content: const Text(
          'This will clear all user-specific data including credentials and tokens. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dataManager.clearUserData();
        _analyticsService.logUserAction('user_data_cleared');
        if (mounted) {
          _showSuccessSnackBar('User data cleared successfully');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error clearing user data: $e');
        }
      }
    }
  }

  Future<void> _clearAllData() async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete ALL stored data. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dataManager.clearAllData();
        _analyticsService.logUserAction('all_data_cleared');
        if (mounted) {
          _showSuccessSnackBar('All data cleared successfully');
        }

        // Reinitialize after clearing
        await _initializeSecurityData();
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar('Error clearing all data: $e');
        }
      }
    }
  }

  Future<void> _generateSecurityReport() async {
    try {
      final metrics = _securityService.getSecurityMetrics();
      final report = {
        'generated_at': DateTime.now().toIso8601String(),
        'security_metrics': metrics,
        'audit_report': _securityService.getSecurityAudit(),
      };

      await Clipboard.setData(ClipboardData(text: report.toString()));
      if (!mounted) return;
      _showSuccessSnackBar('Security report copied to clipboard');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error generating security report: $e');
    }
  }

  Future<void> _testDataIntegrity() async {
    try {
      const testData = 'Test data integrity';
      final hash = _dataManager.generateDataHash(testData);
      final isValid = await _dataManager.verifyDataIntegrity(testData, hash);

      if (mounted) {
        if (isValid) {
          _showSuccessSnackBar('Data integrity test passed');
        } else {
          _showErrorSnackBar('Data integrity test failed');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error testing data integrity: $e');
      }
    }
  }

  Future<void> _forceReauthentication() async {
    _securityService.requireReAuthentication();
    if (mounted) {
      _showSuccessSnackBar(
        'Re-authentication required for next secure operation',
      );
    }
  }

  Future<void> _exportSecurityEvents() async {
    try {
      final events = _securityService.exportSecurityEvents();
      await Clipboard.setData(ClipboardData(text: events));
      if (!mounted) return;
      _showSuccessSnackBar('Security events exported to clipboard');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error exporting security events: $e');
    }
  }

  Future<void> _exportAllData() async {
    try {
      final result = await _securityService.authenticateWithBiometric(
        reason: 'Authenticate to export all data',
      );

      if (!mounted) return;
      if (!result.success) {
        _showErrorSnackBar('Authentication required to export data');
        return;
      }

      final data = await _dataManager.exportAllData();
      if (!mounted) return;
      if (data != null) {
        await Clipboard.setData(ClipboardData(text: data));
        if (!mounted) return;
        _showSuccessSnackBar('All data exported to clipboard');
      } else {
        if (!mounted) return;
        _showErrorSnackBar('Error exporting data');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error exporting all data: $e');
    }
  }

  void _showEventDetails(SecurityEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_formatEventType(event.eventType)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${_formatDateTime(event.timestamp)}'),
            const SizedBox(height: 8),
            if (event.data != null) ...[
              const Text('Details:'),
              const SizedBox(height: 4),
              Text(
                event.data.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
