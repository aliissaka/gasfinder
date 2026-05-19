import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_flutter/shared_flutter.dart';

void main() {
  testWidgets('BigButton renders icon and label and fires onPressed', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: BigButton(
        icon: Icons.phone,
        label: 'Call',
        onPressed: () => pressed++,
      )),
    ));

    expect(find.byIcon(Icons.phone), findsOneWidget);
    expect(find.text('Call'), findsOneWidget);

    await tester.tap(find.byType(BigButton));
    expect(pressed, 1);
  });
}
