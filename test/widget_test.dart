import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_board/main.dart';

void main() {
  testWidgets('main menu opens level selection', (tester) async {
    await tester.pumpWidget(const MemoryBoardApp());

    expect(find.text('Memory Board'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byType(FilledButton), findsWidgets);
  });

  testWidgets('level one shows tutorial instruction first', (tester) async {
    await tester.pumpWidget(const MemoryBoardApp());

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Remember the glowing tiles'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
  });
}
