import 'package:flutter/material.dart';
import '../../../home/home_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Delegate to the new messaging-first HomeScreen prototype.
    return const HomeScreen();
  }
}