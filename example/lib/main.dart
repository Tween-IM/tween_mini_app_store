import 'package:flutter/material.dart';
import 'package:tween_mini_app_store/tween_mini_app_store.dart';

void main() => runApp(const HostDemo());
class HostDemo extends StatelessWidget {
  const HostDemo({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Host App • Mini Apps',
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)), useMaterial3: true),
    home: MiniAppStore(repository: DemoMiniAppRepository(), title: 'Tween Mini Apps'),
  );
}
