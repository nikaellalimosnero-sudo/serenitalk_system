import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'controllers/appointment_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/community_controller.dart';
import 'controllers/doctor_controller.dart';
import 'controllers/user_controller.dart';
import 'firebase_options.dart';
import 'views/auth_gate.dart';
import 'views/widgets/sereni_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phone-only app: keep it upright.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => UserController()),
        ChangeNotifierProvider(create: (_) => AppointmentController()),
        ChangeNotifierProvider(create: (_) => DoctorController()),
        ChangeNotifierProvider(create: (_) => CommunityController()),
      ],
      child: const SereniTalkApp(),
    ),
  );
}

class SereniTalkApp extends StatelessWidget {
  const SereniTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SereniTalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: SereniColors.brand),
      ),
      home: const AuthGate(),
    );
  }
}
