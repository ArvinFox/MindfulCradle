import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityProvider with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _checker = InternetConnectionChecker();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _hasInternet = true;

  bool get hasInternet => _hasInternet;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    await _updateStatus();
    _subscription = _connectivity.onConnectivityChanged.listen((_) {
      _updateStatus();
    });
  }

  Future<void> _updateStatus() async {
    final results = await _connectivity.checkConnectivity();
    if (results.contains(ConnectivityResult.none) && results.length == 1) {
      _setStatus(false);
      return;
    }

    final hasInternet = await _checker.hasConnection;
    _setStatus(hasInternet);
  }

  void _setStatus(bool value) {
    if (_hasInternet == value) return;
    _hasInternet = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
