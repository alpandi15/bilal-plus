import 'package:flutter/widgets.dart';

import 'app_database.dart';

/// Membagikan satu [AppDatabase] ke seluruh subtree - pola yang sama dengan
/// `UserLocationScope`. Basis datanya sendiri yang memberi tahu perubahan
/// (lewat stream drift), jadi cukup `InheritedWidget` biasa.
class AppDatabaseScope extends InheritedWidget {
  const AppDatabaseScope({
    super.key,
    required this.database,
    required super.child,
  });

  final AppDatabase database;

  static AppDatabase of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppDatabaseScope>();
    assert(
      scope != null,
      'AppDatabaseScope tidak ditemukan di atas widget ini',
    );
    return scope!.database;
  }

  @override
  bool updateShouldNotify(AppDatabaseScope oldWidget) =>
      database != oldWidget.database;
}
