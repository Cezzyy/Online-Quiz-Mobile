import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Service to monitor internet connectivity status
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicCheckTimer;
  
  final _connectivityController = StreamController<bool>.broadcast();
  
  bool _isConnected = true;
  
  Timer? _debounceTimer;
  
  // Configuration
  static const Duration _checkTimeout = Duration(seconds: 10);
  static const Duration _periodicCheckInterval = Duration(seconds: 30);
  static const Duration _debounceDelay = Duration(seconds: 2);
  
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  bool get isConnected => _isConnected;
  
  Future<void> initialize() async {
    await _updateConnectionStatus();
    
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
    );
    
    _startPeriodicCheck();
  }
  
  void _startPeriodicCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(_periodicCheckInterval, (_) {
      _updateConnectionStatus();
    });
  }
  
  Future<void> _updateConnectionStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final hasNetworkInterface = results.any((result) => 
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet ||
        result == ConnectivityResult.vpn
      );
      
      if (!hasNetworkInterface) {
        _updateStatus(false);
        return;
      }
      
      final hasInternet = await _checkActualInternetAccess();
      _updateStatus(hasInternet);
      
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _updateStatus(true);
    }
  }
  
  Future<bool> _checkActualInternetAccess() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(_checkTimeout);
      
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      try {
        final result = await InternetAddress.lookup('one.one.one.one')
            .timeout(const Duration(seconds: 5));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    } catch (e) {
      debugPrint('Unexpected error checking internet: $e');
      return true;
    }
  }
  
  void _updateStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectivityController.add(isConnected);
      debugPrint('Connectivity changed: ${isConnected ? "Online" : "Offline"}');
    }
  }
  
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      _updateConnectionStatus();
    });
  }

  Future<bool> checkConnectivity() async {
    await _updateConnectionStatus();
    return _isConnected;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicCheckTimer?.cancel();
    _debounceTimer?.cancel();
    _connectivityController.close();
  }
}
