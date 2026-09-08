import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'app/app.dart';
import 'app/di.dart';
import 'firebase_options.dart';

void main() async {
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  systemChromeConfigure();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initAppModule();
  runApp(MyApp());
  FlutterNativeSplash.remove();
}
