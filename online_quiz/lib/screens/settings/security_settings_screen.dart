import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/local_auth_provider.dart';
import '../../utils/app_theme.dart';

/// Security settings screen - displays authentication status and info
/// Authentication is MANDATORY and always enabled
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    // Refresh auth info when screen loads
    Future.microtask(() {
      ref.read(localAuthProvider.notifier).refreshAuthInfo();
    });
  }

  Future<void> _testAuthentication() async {
    setState(() {
      _isTesting = true;
    });

    final success = await ref.read(localAuthProvider.notifier).testAuthentication();

    if (mounted) {
      setState(() {
        _isTesting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  success
                      ? 'Authentication successful!'
                      : 'Authentication failed. Please try again.',
                ),
              ),
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localAuthState = ref.watch(localAuthProvider);
    final authInfo = localAuthState.authInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
        elevation: 0,
      ),
      body: authInfo == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Security Status Card
                  _buildSecurityStatusCard(context, authInfo),
                  const SizedBox(height: 16),

                  // Authentication Method Card
                  _buildAuthMethodCard(context, authInfo),
                  const SizedBox(height: 16),

                  // Device Capabilities Card
                  _buildCapabilitiesCard(context, authInfo),
                  const SizedBox(height: 16),

                  // Test Authentication Button
                  _buildTestButton(context),
                  const SizedBox(height: 24),

                  // Information Section
                  _buildInformationSection(context),
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityStatusCard(BuildContext context, Map<String, dynamic> authInfo) {
    final isSupported = authInfo['isSupported'] as bool;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSupported
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSupported ? Icons.verified_user : Icons.warning,
                    color: isSupported ? Colors.green : Colors.orange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSupported ? 'Protected' : 'Limited Protection',
                        style: TextStyle(
                          color: isSupported ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Authentication is mandatory and always enabled',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthMethodCard(BuildContext context, Map<String, dynamic> authInfo) {
    final authMethod = authInfo['authenticationMethod'] as String;
    final hasFace = authInfo['hasFaceRecognition'] as bool;
    final hasFingerprint = authInfo['hasFingerprint'] as bool;

    IconData methodIcon;
    Color methodColor;

    if (hasFace) {
      methodIcon = Icons.face;
      methodColor = Colors.blue;
    } else if (hasFingerprint) {
      methodIcon = Icons.fingerprint;
      methodColor = Colors.purple;
    } else {
      methodIcon = Icons.pin;
      methodColor = Colors.orange;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authentication Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: methodColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    methodIcon,
                    color: methodColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authMethod,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Currently active',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilitiesCard(BuildContext context, Map<String, dynamic> authInfo) {
    final canCheckBiometrics = authInfo['canCheckBiometrics'] as bool;
    final hasFace = authInfo['hasFaceRecognition'] as bool;
    final hasFingerprint = authInfo['hasFingerprint'] as bool;
    final hasIris = authInfo['hasIris'] as bool;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Device Capabilities',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildCapabilityRow(
              context,
              'Biometric Support',
              canCheckBiometrics,
              Icons.security,
            ),
            const Divider(height: 24),
            _buildCapabilityRow(
              context,
              'Face Recognition',
              hasFace,
              Icons.face,
            ),
            const Divider(height: 24),
            _buildCapabilityRow(
              context,
              'Fingerprint',
              hasFingerprint,
              Icons.fingerprint,
            ),
            const Divider(height: 24),
            _buildCapabilityRow(
              context,
              'Iris Scan',
              hasIris,
              Icons.remove_red_eye,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityRow(
    BuildContext context,
    String label,
    bool isAvailable,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: isAvailable ? Colors.green : Colors.grey,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isAvailable
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isAvailable ? 'Available' : 'Not Available',
            style: TextStyle(
              color: isAvailable ? Colors.green : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTestButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isTesting ? null : _testAuthentication,
        icon: _isTesting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.verified_user),
        label: Text(_isTesting ? 'Testing...' : 'Test Authentication'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildInformationSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About Security',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          'Why is authentication required?',
          'To protect your quiz data and ensure academic integrity, authentication is mandatory when resuming the app or starting a quiz.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          'What if I don\'t have biometrics?',
          'The app will automatically use your device PIN or pattern as a fallback authentication method.',
        ),
        const SizedBox(height: 12),
        _buildInfoItem(
          context,
          'When is authentication required?',
          'You\'ll be asked to authenticate when the app resumes from background and before starting any quiz.',
        ),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
