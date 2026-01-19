/// Base ViewModel
/// 
/// Abstract base class for all view models in the application.
/// Provides common functionality for state management and lifecycle.

import 'package:flutter/foundation.dart';

/// Base state for view models
enum ViewState {
  idle,
  loading,
  success,
  error,
}

/// Base ViewModel class
abstract class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  bool _disposed = false;

  /// Current view state
  ViewState get state => _state;

  /// Error message if state is error
  String? get errorMessage => _errorMessage;

  /// Check if view model is loading
  bool get isLoading => _state == ViewState.loading;

  /// Check if view model has error
  bool get hasError => _state == ViewState.error;

  /// Set state to loading
  void setLoading() {
    _setState(ViewState.loading);
  }

  /// Set state to success
  void setSuccess() {
    _setState(ViewState.success);
  }

  /// Set state to error with message
  void setError(String message) {
    _errorMessage = message;
    _setState(ViewState.error);
  }

  /// Set state to idle
  void setIdle() {
    _setState(ViewState.idle);
  }

  /// Internal state setter with disposed check
  void _setState(ViewState newState) {
    if (!_disposed) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Initialize view model
  /// Override this method to perform initialization logic
  void init() {}

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Safe notify listeners that checks disposed state
  void safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
