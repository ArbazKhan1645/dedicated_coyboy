// services/connectivity_service.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _connectivityController.stream;
  bool _isConnected = true;

  void initialize() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
    _checkInitialConnection();
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) async {
    final hasConnections = await hasConnection();
    if (_isConnected != hasConnections) {
      _isConnected = hasConnections;
      _connectivityController.add(_isConnected);
    }
  }

  void _checkInitialConnection() async {
    _isConnected = await hasConnection();
    _connectivityController.add(_isConnected);
  }

  Future<bool> hasConnection() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      
      // Check if we have any type of connection
      if (connectivityResults.contains(ConnectivityResult.none)) {
        return false;
      }

      // Double-check with actual internet connectivity
      return await _hasInternetConnection();
    } catch (e) {
      print('Error checking connectivity: $e');
      return false;
    }
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _connectivityController.close();
  }
}