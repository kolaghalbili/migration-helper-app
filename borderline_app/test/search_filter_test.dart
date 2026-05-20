import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:borderline_app/models/filter_params.dart';
import 'package:borderline_app/screens/search_filter_screen.dart';

void main() {
  group('FilterParams', () {
    test('defaults have zero activeCount', () {
      expect(FilterParams.defaults.activeCount, 0);
    });

    test('activeCount increments correctly', () {
      final p = FilterParams(
        city: 'Berlin', maxRate: 30, verifiedOnly: true,
      );
      expect(p.activeCount, 3);
    });

    test('copyWith preserves unchanged fields', () {
      final p = FilterParams(city: 'Berlin', maxRate: 50);
      final p2 = p.copyWith(verifiedOnly: true);
      expect(p2.city, 'Berlin');
      expect(p2.maxRate, 50);
      expect(p2.verifiedOnly, true);
    });
  });

  group('SearchFilterScreen widget', () {
    testWidgets('shows all category chips', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SearchFilterScreen(
          initial: FilterParams.defaults,
          totalHelpers: 23,
          categories: const ['Banking', 'Housing', 'SIM & Net'],
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Banking'), findsOneWidget);
      expect(find.text('Housing'), findsOneWidget);
      expect(find.text('Show 23 helpers →'), findsOneWidget);
    });

    testWidgets('Reset button restores defaults', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SearchFilterScreen(
          initial: FilterParams(city: 'Berlin', maxRate: 30),
          totalHelpers: 5,
          categories: const ['Banking', 'Housing'],
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text ?? '',
        '',
      );
    });

    testWidgets('pops with FilterParams on apply', (tester) async {
      FilterParams? popped;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (ctx) => ElevatedButton(
          onPressed: () async {
            popped = await Navigator.push<FilterParams>(
              ctx,
              MaterialPageRoute(builder: (_) => SearchFilterScreen(
                initial: FilterParams.defaults, totalHelpers: 10,
                categories: const ['Banking', 'Housing'],
              )),
            );
          },
          child: const Text('open'),
        )),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show 10 helpers →'));
      await tester.pumpAndSettle();
      expect(popped, isNotNull);
    });
  });
}
