import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nesherprints/core/widgets/scroll_to_top.dart';

void main() {
  testWidgets('el botón aparece al bajar y devuelve al principio', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScrollToTop(
            builder: (context, controller) => ListView.builder(
              controller: controller,
              itemCount: 200,
              itemBuilder: (_, i) => SizedBox(height: 60, child: Text('f$i')),
            ),
          ),
        ),
      ),
    );
    final button = find.byTooltip('Subir al principio');
    expect(
      t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
      0,
      reason: 'arriba no se ve',
    );

    await t.drag(find.byType(ListView), const Offset(0, -2000));
    await t.pumpAndSettle();
    expect(t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);

    await t.tap(button);
    await t.pumpAndSettle();
    expect(find.text('f0'), findsOneWidget);
    expect(t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0);
  });
}
