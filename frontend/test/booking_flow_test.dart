import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart'; 
import 'package:frontend/flight_search_screen.dart';
import 'package:frontend/flight_results_screen.dart';
import 'package:frontend/flight_details_screen.dart';
import 'package:frontend/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
  });

  testWidgets('Booking Flow Test', (WidgetTester tester) async {
    // 1. Load App
    await tester.pumpWidget(const AirlineApp());
    await tester.pumpAndSettle(); 
    debugPrint('1. App Loaded');

    // Check if we are at FlightSearchScreen
    expect(find.byType(FlightSearchScreen), findsOneWidget);
    debugPrint('2. Verified FlightSearchScreen');

    // 2. Search for Flight
    final searchButton = find.text('SEARCH FLIGHTS');
    expect(searchButton, findsOneWidget);
    await tester.tap(searchButton);
    debugPrint('3. Tapped Search');
    
    // Pump for loading state (2 seconds delay in FlightResultsScreen)
    await tester.pump(const Duration(seconds: 3)); 
    await tester.pumpAndSettle();
    
    // 3. Flight Results
    expect(find.byType(FlightResultsScreen), findsOneWidget);
    debugPrint('4. Verified FlightResultsScreen');
    
    // Tap the first flight card. 
    final cards = find.byType(Card);
    // There must be cards now
    expect(cards, findsWidgets);
    await tester.tap(cards.first);
    await tester.pumpAndSettle();
    debugPrint('5. Tapped Flight Card');

    // 4. Flight Details
    expect(find.byType(FlightDetailsScreen), findsOneWidget);
    debugPrint('6. Verified FlightDetailsScreen');
    
    // Tap "SELECT FLIGHT"
    final selectFlightButton = find.text('SELECT FLIGHT');
    expect(selectFlightButton, findsOneWidget);
    await tester.scrollUntilVisible(selectFlightButton, 500); 
    await tester.tap(selectFlightButton);
    await tester.pumpAndSettle();
    debugPrint('7. Tapped Select Flight');
    
    // 5. Passenger Info
    expect(find.text('Passenger Details'), findsOneWidget);
    debugPrint('8. Verified PassengerInfoScreen');
    
  });
}
