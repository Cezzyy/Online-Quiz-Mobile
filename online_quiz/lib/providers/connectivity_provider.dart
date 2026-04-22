import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

/// Connectivity state
class ConnectivityState {
  final bool isConnected;
  final bool isChecking;

  const ConnectivityState({
    required this.isConnected,
    this.isChecking = false,
  });

  ConnectivityState copyWith({
    bool? isConnected,
    bool? isChecking,
  }) {
    return ConnectivityState(
      isConnected: isConnected ?? this.isConnected,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}

/// Connectivity notifier
class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  final ConnectivityService _connectivityService = ConnectivityService();

  ConnectivityNotifier() : super(const ConnectivityState(isConnected: true)) {
    _initialize();
  }

  /// Initialize connectivity monitoring
  Future<void> _initialize() async {
    await _connectivityService.initialize();
    
    // Update initial state
    state = ConnectivityState(
      isConnected: _connectivityService.isConnected,
    );
    
    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((isConnected) {
      if (mounted) {
        state = state.copyWith(isConnected: isConnected);
      }
    });
  }

  /// Manually check connectivity (for retry button)
  Future<void> checkConnectivity() async {
    state = state.copyWith(isChecking: true);
    
    final isConnected = await _connectivityService.checkConnectivity();
    
    if (mounted) {
      state = ConnectivityState(
        isConnected: isConnected,
        isChecking: false,
      );
    }
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }
}

/// Connectivity provider
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>(
  (ref) => ConnectivityNotifier(),
);

/// Convenience provider for connection status
final isConnectedProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).isConnected;
});
