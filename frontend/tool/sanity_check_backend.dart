// Run with:
//   cd frontend
//   dart run tool/sanity_check_backend.dart
//
// This script performs a lightweight sanity-check against the backend JSON
// contract used by the current Flutter UI.

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:zaku_app/services/api_config.dart';

Future<void> main() async {
  final base = ApiConfig.baseUrl;
  stdout('Sanity-check backend at: $base');

  final airports = await _getJsonList('$base/airports');
  if (airports.isEmpty) {
    fail('No airports returned');
  }

  final airportById = <int, Map<String, dynamic>>{};
  for (final a in airports) {
    if (a is Map) {
      final id = a['id'];
      if (id is int) {
        airportById[id] = a.cast<String, dynamic>();
      }
    }
  }

  stdout('OK: airports=${airports.length}');

  final flights = await _getJsonList('$base/flights');
  if (flights.isEmpty) {
    fail('No flights returned');
  }
  stdout('OK: flights=${flights.length}');

  final first = flights.first;
  if (first is! Map) {
    fail('Expected flight to be an object, got: ${first.runtimeType}');
  }

  final flight = first.cast<String, dynamic>();
  requireKeys(
    flight,
    const [
      'id',
      'flight_number',
      'origin_id',
      'destination_id',
      'departure_time',
      'arrival_time',
      'price',
      'status',
    ],
  );

  final dep = parseIso(flight['departure_time']);
  final arr = parseIso(flight['arrival_time']);
  if (dep == null || arr == null) {
    fail('departure_time/arrival_time are not ISO strings');
  }

  final originId = asInt(flight['origin_id']);
  final destinationId = asInt(flight['destination_id']);
  if (originId == null || destinationId == null) {
    fail('origin_id/destination_id are not ints');
  }

  final origin = airportById[originId];
  final dest = airportById[destinationId];
  if (origin == null || dest == null) {
    stdout('WARN: flight airport ids not found in /airports (still OK for API, but UI will show fallback)');
  } else {
    stdout('OK: route ${origin['code']} -> ${dest['code']}');
  }

  final price = asNum(flight['price']);
  if (price == null) {
    fail('price is not numeric');
  }

  final id = asInt(flight['id']);
  if (id == null) {
    fail('id is not int');
  }

  final seats = await _getJsonList('$base/flights/$id/seats');
  if (seats.isEmpty) {
    fail('No seats returned for flight $id');
  }

  final sample = seats.first;
  if (sample is! Map) {
    fail('Expected seat to be an object, got: ${sample.runtimeType}');
  }

  final seat = sample.cast<String, dynamic>();
  requireKeys(seat, const ['id', 'flight_id', 'code', 'seat_class', 'is_occupied', 'price_markup']);

  final code = seat['code']?.toString() ?? '';
  if (!_looksLikeSeatCode(code)) {
    fail('Seat code does not look like "12A": $code');
  }

  if (seat['is_occupied'] is! bool) {
    fail('is_occupied is not bool');
  }

  if (asNum(seat['price_markup']) == null) {
    fail('price_markup is not numeric');
  }

  stdout('OK: seats=${seats.length} (sample=$code)');
  stdout('PASS: backend JSON matches current Flutter expectations');
}

Future<List<dynamic>> _getJsonList(String url) async {
  final resp = await http.get(Uri.parse(url));
  if (resp.statusCode != 200) {
    fail('GET $url failed: ${resp.statusCode} ${resp.body}');
  }

  final decoded = jsonDecode(resp.body);
  if (decoded is! List) {
    fail('GET $url: expected JSON list, got: ${decoded.runtimeType}');
  }
  return decoded;
}

DateTime? parseIso(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

num? asNum(dynamic v) {
  if (v is num) return v;
  if (v == null) return null;
  return num.tryParse(v.toString());
}

int? asInt(dynamic v) {
  if (v is int) return v;
  if (v == null) return null;
  return int.tryParse(v.toString());
}

bool _looksLikeSeatCode(String code) {
  if (code.length < 2 || code.length > 3) return false;
  final letter = code.substring(code.length - 1);
  final row = code.substring(0, code.length - 1);
  if (!RegExp(r'^[A-F]$').hasMatch(letter)) return false;
  final rowNum = int.tryParse(row);
  if (rowNum == null) return false;
  return rowNum >= 1 && rowNum <= 99;
}

void requireKeys(Map<String, dynamic> obj, List<String> keys) {
  for (final k in keys) {
    if (!obj.containsKey(k)) {
      fail('Missing key "$k" in object: ${obj.keys.toList()}');
    }
  }
}

Never fail(String message) {
  throw StateError('SANITY CHECK FAILED: $message');
}

void stdout(String message) {
  // Simple stdout wrapper to keep output consistent.
  // ignore: avoid_print
  print(message);
}
