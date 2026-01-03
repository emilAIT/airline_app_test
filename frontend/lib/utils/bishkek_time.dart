class BishkekTime {
  // Bishkek timezone is UTC+6 and does not observe DST.
  static const Duration offset = Duration(hours: 6);

  /// Backend returns ISO timestamps without timezone. Treat them as UTC.
  static DateTime? parseServerUtc(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;

    final hasTz = s.endsWith('Z') || s.contains('+') || RegExp(r'-\d\d:\d\d$').hasMatch(s);
    final parsed = DateTime.tryParse(hasTz ? s : '${s}Z');
    return parsed?.toUtc();
  }

  static DateTime toBishkek(DateTime dt) => dt.toUtc().add(offset);

  static String fmtYmdHm(DateTime? dt) {
    if (dt == null) return '—';
    final t = toBishkek(dt);
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  static String fmtDdMmHm(DateTime? dt) {
    if (dt == null) return '--:--';
    final t = toBishkek(dt);
    final dd = t.day.toString().padLeft(2, '0');
    final mm = t.month.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mi = t.minute.toString().padLeft(2, '0');
    return '$dd.$mm $hh:$mi';
  }

  static String fmtHm(DateTime? dt) {
    if (dt == null) return '—';
    final t = toBishkek(dt);
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static String fmtDate(DateTime? dt) {
    if (dt == null) return '—';
    final t = toBishkek(dt);
    final dd = t.day.toString().padLeft(2, '0');
    final mm = t.month.toString().padLeft(2, '0');
    final yy = t.year.toString();
    return '$dd.$mm.$yy';
  }

  static String fmtTime(DateTime? dt) {
    if (dt == null) return '—';
    final t = toBishkek(dt);
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
