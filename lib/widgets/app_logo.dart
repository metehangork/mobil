import 'package:flutter/widgets.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/kafadar_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
