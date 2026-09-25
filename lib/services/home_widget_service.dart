/// Pintu masuk sinkronisasi widget layar utama.
///
/// Paket `home_widget` hanya mendukung Android & iOS dan meng-`import
/// 'dart:io'` tanpa syarat - kalau diimpor langsung, build web GAGAL total.
/// Karena itu implementasinya dipisah: web memakai versi kosong (stub),
/// selainnya memakai implementasi asli.
export 'home_widget_service_stub.dart'
    if (dart.library.io) 'home_widget_service_io.dart';
