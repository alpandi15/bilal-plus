import 'package:flutter/material.dart';

import '../pages/global_search_page.dart';

/// Bilah "Cari" di Beranda: ketuk membuka pencarian global.
class SearchPill extends StatelessWidget {
  const SearchPill({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: "Cari di Al-Qur'an, hadits, do'a",
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const GlobalSearchPage())),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1E4CF)),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: Color(0xFF78716C)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Cari Al-Qur'an, hadits, do'a…",
                style: TextStyle(fontSize: 14, color: Color(0xFF78716C)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
