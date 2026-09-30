import 'package:flutter/material.dart';

const _green = Color(0xFF047857);
const _stone = Color(0xFF44403C);

/// Penjelasan bahwa semua data hanya tersimpan di perangkat.
class PrivacyNote extends StatelessWidget {
  const PrivacyNote({super.key, this.compact = false});

  /// true = ringkas (satu paragraf) untuk halaman Cadangan Data.
  final bool compact;

  static const _points = [
    'Catatan ibadah, bacaan Al-Qur\'an, hitungan dzikir, lokasi, dan '
        'pengaturan hanya disimpan di HP ini. Tidak ada akun, tidak ada '
        'server, tidak ada analitik atau iklan.',
    'Lokasi (GPS) hanya dipakai di HP untuk menghitung waktu sholat - '
        'tidak pernah dikirim ke mana pun.',
    'Internet hanya dipakai untuk mengunduh pembaruan ketetapan kalender '
        'hijriah (awal bulan), teks kitab hadits yang Anda pilih, dan '
        'memeriksa versi terbaru aplikasi (bisa dimatikan di Pengaturan). '
        'Permintaan itu tidak membawa data pribadi apa pun.',
    'File cadangan hanya keluar dari HP bila Anda sendiri membagikan atau '
        'menyimpannya ke tempat lain.',
    'Bila Cadangan Google diaktifkan di pengaturan HP, Android bisa ikut '
        'menyalin data aplikasi ke akun Google Anda - itu fitur sistem, '
        'bukan aplikasi ini.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_rounded, size: 18, color: _green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Data Anda tetap di HP ini',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (compact)
            const Text(
              'Semua catatan disimpan lokal dan tidak pernah dipublikasikan '
              'atau dikirim ke server. Karena itu, simpan file cadangan '
              'secara berkala - bila aplikasi dihapus atau HP berganti, '
              'data hanya bisa dipulihkan dari file ini.',
              style: TextStyle(fontSize: 12, height: 1.5, color: _stone),
            )
          else
            for (final p in _points)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 13,
                        color: _green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: _stone,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
