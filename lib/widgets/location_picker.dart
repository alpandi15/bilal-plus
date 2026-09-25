import 'package:flutter/material.dart';

import '../services/kabupaten_service.dart';
import '../services/user_location_controller.dart';
import '../services/user_location_scope.dart';

/// Lembar pemilih lokasi: tombol "gunakan lokasi saat ini" + pencarian
/// kabupaten/kota. Padanan `LocationPicker.tsx` di web.
Future<void> showLocationPicker(BuildContext context) {
  final controller = UserLocationScope.of(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _LocationPickerSheet(controller: controller),
  );
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({required this.controller});
  final UserLocationController controller;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet>
    with WidgetsBindingObserver {
  List<Kabupaten> _items = searchKabupaten('', limit: 40);

  /// true selagi pengguna dibawa ke pengaturan (GPS / izin aplikasi): begitu
  /// kembali ke aplikasi, lokasi otomatis dicoba lagi tanpa perlu menekan
  /// tombolnya sekali lagi.
  bool _retryOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _retryOnResume) {
      _retryOnResume = false;
      _useCurrentLocation();
    }
  }

  void _onSearch(String value) {
    setState(() {
      _items = searchKabupaten(value, limit: 40);
    });
  }

  /// Alur "Gunakan lokasi saat ini": cek GPS & izin dulu, tuntun pengguna
  /// bila ada yang kurang, dan lembar ini hanya ditutup kalau lokasi
  /// benar-benar didapat.
  Future<void> _useCurrentLocation() async {
    final result = await widget.controller.requestGps();
    if (!mounted) return;

    switch (result) {
      case GpsResult.ok:
        Navigator.of(context).pop();
      case GpsResult.serviceDisabled:
        final open = await _confirm(
          title: 'GPS belum aktif',
          message:
              'Layanan lokasi perangkat sedang mati. Nyalakan GPS di '
              'pengaturan, lalu kembali ke aplikasi - lokasi akan dicari '
              'otomatis.',
          action: 'Nyalakan GPS',
        );
        if (open) {
          _retryOnResume = true;
          await widget.controller.openLocationSettings();
        }
      case GpsResult.permissionDeniedForever:
        final open = await _confirm(
          title: 'Izin lokasi ditolak',
          message:
              'Izin lokasi untuk aplikasi ini ditolak permanen. Buka '
              'pengaturan aplikasi, izinkan Lokasi, lalu kembali - lokasi '
              'akan dicari otomatis.',
          action: 'Buka Pengaturan',
        );
        if (open) {
          _retryOnResume = true;
          await widget.controller.openAppSettings();
        }
      case GpsResult.permissionDenied:
        _snack('Izin lokasi ditolak. Ketuk lagi untuk mencoba memberi izin.');
      case GpsResult.failed:
        _snack(
          'Lokasi belum terbaca. Pastikan sinyal GPS baik, lalu coba lagi.',
        );
    }
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFFDF8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.location_off_rounded, color: Color(0xFFB45309)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1C1917),
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF57534E),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Nanti',
              style: TextStyle(color: Color(0xFF78716C)),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB45309),
              shape: const StadiumBorder(),
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _snack(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.controller.location;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: const Color(0xFFFFFDF8),
            child: Column(
              children: [
                // -------------------------------- header --------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'LOKASI',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: Color(0xB3B45309),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pilih Kabupaten / Kota',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1C1917),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xB3FDE9C8)),
                        ),
                      ),
                    ],
                  ),
                ),

                // -------------------------- gunakan lokasi saat ini --------------------------
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AnimatedBuilder(
                    animation: widget.controller,
                    builder: (context, _) {
                      final locating =
                          widget.controller.status == LocationStatus.locating;
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: locating ? null : _useCurrentLocation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFDE9C8)),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFBBF24),
                                      Color(0xFFEA580C),
                                    ],
                                  ),
                                ),
                                child: locating
                                    ? const Padding(
                                        padding: EdgeInsets.all(9),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.my_location,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Gunakan lokasi saat ini',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      locating
                                          ? 'Mencari posisi Anda…'
                                          : widget.controller.deniedGps
                                          ? 'Izin lokasi ditolak - ketuk untuk mengatur'
                                          : 'Cek izin & GPS otomatis',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF78716C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // -------------------------------- pencarian --------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: TextField(
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      hintText: "Cari kabupaten/kota, misal 'medan'",
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
                      ),
                    ),
                  ),
                ),

                // -------------------------------- daftar --------------------------------
                Expanded(
                  child: _items.isEmpty
                      ? const Center(
                          child: Text(
                            'Tidak ada kabupaten/kota yang cocok',
                            style: TextStyle(
                              color: Color(0xFF78716C),
                              fontSize: 12,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final item = _items[i];
                            final active = current.id == item.id;
                            return ListTile(
                              dense: true,
                              title: Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: active
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: active
                                      ? const Color(0xFF78350F)
                                      : const Color(0xFF57534E),
                                ),
                              ),
                              trailing: active
                                  ? const Text(
                                      'AKTIF',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        color: Color(0xFFB45309),
                                      ),
                                    )
                                  : null,
                              tileColor: active
                                  ? const Color(0xCCFDE9C8)
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              onTap: () async {
                                await widget.controller.setKabupaten(item);
                                if (context.mounted)
                                  Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
