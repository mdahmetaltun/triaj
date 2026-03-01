import 'package:flutter/widgets.dart';

import 'app.dart';
import 'services/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseBootstrap.ensureInitialized();
  runApp(const TriageMobileApp());
}
