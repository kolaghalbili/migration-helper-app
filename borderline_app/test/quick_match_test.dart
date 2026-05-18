import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:borderline_app/models/helper_model.dart';
import 'package:borderline_app/screens/quick_match_screen.dart';
import 'package:borderline_app/services/api_service.dart';

class _MockApiService extends ApiService {
  @override
  Future<List<Helper>> getHelpers({String? city, String? search}) async => [
        Helper(
          id: 1,
          firstName: 'Reza',
          lastName: 'M',
          bio: 'I help newcomers',
          city: 'Berlin',
          country: 'Germany',
          ratingAvg: 4.9,
          totalReviews: 41,
          isVerified: true,
          specialties: [],
          profileImages: [],
          badges: [],
        ),
        Helper(
          id: 2,
          firstName: 'Nadia',
          lastName: 'H',
          bio: 'Housing expert',
          city: 'Toronto',
          country: 'Canada',
          ratingAvg: 5.0,
          totalReviews: 18,
          isVerified: false,
          specialties: [],
          profileImages: [],
          badges: [],
        ),
      ];
}

class _EmptyApiService extends ApiService {
  @override
  Future<List<Helper>> getHelpers({String? city, String? search}) async => [];
}

void main() {
  testWidgets('shows first helper name on card', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: QuickMatchScreen(service: _MockApiService()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reza'), findsWidgets);
  });

  testWidgets('shows empty state when deck exhausted', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: QuickMatchScreen(service: _EmptyApiService()),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining("You've seen all"), findsOneWidget);
  });

  testWidgets('action bar shows three buttons', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: QuickMatchScreen(service: _MockApiService()),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
  });
}
