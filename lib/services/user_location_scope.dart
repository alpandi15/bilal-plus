import 'package:flutter/widgets.dart';

import 'user_location_controller.dart';

/// Membagikan satu [UserLocationController] ke seluruh subtree lewat
/// `InheritedNotifier` bawaan Flutter - tanpa perlu paket state management
/// tambahan (`provider`/`riverpod`) hanya untuk satu nilai yang dipakai
/// beberapa kartu (jadwal sholat & hitung mundur Ramadan) sekaligus.
class UserLocationScope extends InheritedNotifier<UserLocationController> {
  const UserLocationScope({
    super.key,
    required UserLocationController controller,
    required super.child,
  }) : super(notifier: controller);

  static UserLocationController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<UserLocationScope>();
    assert(
      scope != null,
      'UserLocationScope tidak ditemukan di atas widget ini',
    );
    return scope!.notifier!;
  }
}
