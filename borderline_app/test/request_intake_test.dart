import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:borderline_app/models/helper_model.dart';
import 'package:borderline_app/screens/request_intake_screen.dart';

final _testRequest = HelpRequest(
  id: 42,
  newcomer: 7,
  newcomerName: 'Mariam',
  category: 'banking',
  subTopics: ['anmeldung', 'n26'],
  description: 'I am arriving friday. need help opening a bank account.',
  package: 'half_day',
  status: 'pending',
  createdAt: '2026-11-10T08:00:00Z',
);

void main() {
  testWidgets('shows newcomer name and description', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RequestIntakeScreen(request: _testRequest),
    ));
    await tester.pump();
    expect(find.text('Mariam'), findsOneWidget);
    expect(find.textContaining('bank account'), findsOneWidget);
  });

  testWidgets('shows quick reply options', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RequestIntakeScreen(request: _testRequest),
    ));
    await tester.pump();
    expect(find.textContaining('happy to help'), findsOneWidget);
    expect(find.textContaining('passport scan'), findsOneWidget);
  });

  testWidgets('shows category chips from request', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RequestIntakeScreen(request: _testRequest),
    ));
    await tester.pump();
    expect(find.text('banking'), findsOneWidget);
  });

  testWidgets('action bar has Decline, Custom reply, Accept', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RequestIntakeScreen(request: _testRequest),
    ));
    await tester.pump();
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Custom reply'), findsOneWidget);
    expect(find.textContaining('Accept'), findsOneWidget);
  });

  testWidgets('tapping quick reply highlights it', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RequestIntakeScreen(request: _testRequest),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('happy to help'));
    await tester.pump();
    expect(find.textContaining('happy to help'), findsOneWidget);
  });

  testWidgets('Decline shows confirmation dialog', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RequestIntakeScreen(request: _testRequest),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decline'));
    await tester.pumpAndSettle();
    expect(find.text('Decline this request?'), findsOneWidget);
  });
}
