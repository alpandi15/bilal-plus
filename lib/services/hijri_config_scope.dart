import 'package:flutter/widgets.dart';

import 'hijri_config.dart';

/// Membagikan satu [HijriConfigController] ke seluruh subtree - pola yang
/// sama dengan `UserLocationScope`, tanpa paket state management tambahan.
class HijriConfigScope extends InheritedNotifier<HijriConfigController> {
  const HijriConfigScope({
    super.key,
    required HijriConfigController controller,
    required super.child,
  }) : super(notifier: controller);

  static HijriConfigController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<HijriConfigScope>();
    assert(
      scope != null,
      'HijriConfigScope tidak ditemukan di atas widget ini',
    );
    return scope!.notifier!;
  }
}
