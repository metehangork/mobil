import 'package:flutter/widgets.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({Key? key, this.size = 56}) : super(key: key);

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
