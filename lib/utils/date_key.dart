/// Kunci tanggal `YYYY-MM-DD` - bentuk tanggal Masehi yang disimpan di basis
/// data. Hanya Y/M/D [date] yang dibaca (zona waktunya diabaikan), jadi
/// berikan tanggal di zona lokasi, mis. dari `todayInZone`.
String dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Kebalikan [dateKey]: tengah malam UTC tanggal itu.
DateTime parseDateKey(String key) {
  final p = key.split('-');
  return DateTime.utc(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

/// Selisih hari kalender [to] - [from] (keduanya kunci tanggal).
int daysBetweenKeys(String from, String to) =>
    parseDateKey(to).difference(parseDateKey(from)).inDays;

const _hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _bulanPendek = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// "Sen, 8 Feb"
String formatDateKeyShort(String key) {
  final d = parseDateKey(key);
  return '${_hariPendek[d.weekday - 1]}, ${d.day} ${_bulanPendek[d.month - 1]}';
}
