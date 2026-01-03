import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/zaku_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);
  runApp(const MyApp());
}
