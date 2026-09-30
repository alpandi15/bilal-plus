import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rindu_ramadan/pages/splash_view.dart';

void main() {
  testWidgets('splash memakai wordmark Bilal+ di tengah layar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashView()));
    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/branding/logo-only.png',
    );
    expect(find.text('Teman ibadah harian'), findsOneWidget);
  });
}
