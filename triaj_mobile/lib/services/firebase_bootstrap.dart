import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _ready = false;
  static Object? _error;

  static bool get isReady => _ready;
  static Object? get error => _error;
  static bool get hasError => _error != null;

  static Future<void> ensureInitialized() async {
    if (_ready || _error != null) {
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _ready = true;
    } catch (e, stack) {
      _error = e;
      print('FIREBASE INITIALIZATION ERROR: $e');
      print(stack);
    }
  }
}
