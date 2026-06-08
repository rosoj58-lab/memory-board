import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_board/src/app/memory_board_app.dart';
import 'package:memory_board/src/data/progress_repository.dart';

void main() {
  testWidgets('main menu opens level selection', (tester) async {
    await tester.pumpWidget(
      MemoryBoardApp(progressRepository: InMemoryProgressRepository()),
    );

    expect(find.text('Memory Board'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byType(FilledButton), findsWidgets);
  });

  testWidgets('level one shows tutorial instruction first', (tester) async {
    await tester.pumpWidget(
      MemoryBoardApp(progressRepository: InMemoryProgressRepository()),
    );

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pumpAndSettle();

    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Remember the glowing tiles'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);
  });

  testWidgets('locked level cannot be opened', (tester) async {
    await tester.pumpWidget(
      MemoryBoardApp(progressRepository: InMemoryProgressRepository()),
    );

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    await tester.pump();

    expect(find.byIcon(Icons.lock_rounded), findsWidgets);
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();

    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('Level 2'), findsNothing);
  });
}
