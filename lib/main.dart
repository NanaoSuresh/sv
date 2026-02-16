import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';

import 'models/player_state.dart' as app;
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const VplayerApp());
}

class VplayerApp extends StatelessWidget {
  const VplayerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => app.PlayerState(),
      child: MaterialApp(
        title: 'Vplayer',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          colorSchemeSeed: const Color(0xFF00D9FF),
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
