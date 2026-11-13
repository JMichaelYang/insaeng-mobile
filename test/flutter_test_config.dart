import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insaeng/design_system/theme/fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'helpers/tolerant_golden_comparator.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final comparator = goldenFileComparator;
  if (comparator is LocalFileComparator) {
    goldenFileComparator = TolerantGoldenComparator(comparator.basedir.resolve('golden_test.dart'));
  }

  final isCi = Platform.environment.containsKey('CI');
  await AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      goldenTestTheme: GoldenTestTheme(
        backgroundColor: const Color(0xFFE0E0E0),
        borderColor: const Color(0xFFBDBDBD),
        nameTextStyle: const TextStyle(fontFamily: AppFonts.family, fontSize: 14, color: Color(0xFF000000)),
        padding: const EdgeInsets.all(8),
      ),
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isCi, platforms: {HostPlatform.macOS}),
    ),
    run: testMain,
  );
}
