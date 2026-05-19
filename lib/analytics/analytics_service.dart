import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  const AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  // Event name constants — use these at all call sites, never raw strings.
  static const _skinChanged = 'skin_changed';
  static const _deviceConnected = 'device_connected';
  static const _deviceDisconnected = 'device_disconnected';
  static const _keySent = 'key_sent';
  static const _adViewed = 'ad_viewed';
  static const _layoutSelected = 'layout_selected';
  static const _layoutCreated = 'layout_created';
  static const _layoutEdited = 'layout_edited';
  static const _layoutDeleted = 'layout_deleted';

  Future<void> logSkinChanged(String skinName) {
    return _analytics.logEvent(
      name: _skinChanged,
      parameters: {'skin_name': skinName},
    );
  }

  Future<void> logDeviceConnected(String deviceModel) {
    return _analytics.logEvent(
      name: _deviceConnected,
      parameters: {'device_model': deviceModel},
    );
  }

  Future<void> logDeviceDisconnected() {
    return _analytics.logEvent(name: _deviceDisconnected);
  }

  Future<void> logKeySent(String key) {
    return _analytics.logEvent(name: _keySent, parameters: {'key': key});
  }

  Future<void> logAdViewed(String adUnitId) {
    return _analytics.logEvent(
      name: _adViewed,
      parameters: {'ad_unit_id': adUnitId},
    );
  }

  /// Logs the layout *id* — never the user-entered name — to avoid PII.
  Future<void> logLayoutSelected(String layoutId) {
    return _analytics.logEvent(
      name: _layoutSelected,
      parameters: {'layout_id': layoutId},
    );
  }

  Future<void> logLayoutCreated(String layoutId) {
    return _analytics.logEvent(
      name: _layoutCreated,
      parameters: {'layout_id': layoutId},
    );
  }

  Future<void> logLayoutEdited(String layoutId) {
    return _analytics.logEvent(
      name: _layoutEdited,
      parameters: {'layout_id': layoutId},
    );
  }

  Future<void> logLayoutDeleted(String layoutId) {
    return _analytics.logEvent(
      name: _layoutDeleted,
      parameters: {'layout_id': layoutId},
    );
  }

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);
}
