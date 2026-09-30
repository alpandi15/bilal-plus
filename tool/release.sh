#!/usr/bin/env bash
# Rilis Bilal+: tag + build APK + push + GitHub Release, dalam satu perintah.
# Panduan lengkap: docs/RELEASING.md
#
#   tool/release.sh              jalankan semua langkah
#   tool/release.sh --dry-run    hanya tampilkan apa yang akan dilakukan
#   tool/release.sh --no-build   pakai APK yang sudah ada (versinya dicek)
#
# Syarat: sudah di branch main, perubahan sudah di-commit, versi di
# pubspec.yaml sudah dinaikkan, dan CHANGELOG.md punya bagian "## X.Y.Z".
set -euo pipefail
cd "$(dirname "$0")/.."

DRY=0 BUILD=1
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;;
    --no-build) BUILD=0 ;;
    *) echo "Pilihan tidak dikenal: $a" >&2; exit 2 ;;
  esac
done

REPO=alpandi15/bilal-plus
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin"
run() { echo "+ $*"; [ "$DRY" = 1 ] || "$@"; }
fail() { echo "✗ $*" >&2; exit 1; }

# ---------------------------------------------------------------- versi
FULL=$(sed -n 's/^version: *//p' pubspec.yaml)
VERSION=${FULL%%+*}
BUILD_NO=${FULL##*+}
TAG="v$VERSION"
echo "Versi: $VERSION (build $BUILD_NO) → tag $TAG"

# ---------------------------------------------------------------- cek awal
[ "$(git branch --show-current)" = main ] || fail "Pindah ke branch main dulu (git checkout main)."
[ -z "$(git status --porcelain --untracked-files=no)" ] || fail "Masih ada perubahan yang belum di-commit."

NOTES=$(awk -v v="$VERSION" '
  $0 ~ "^## " v " " {on=1; next}
  on && /^## / {exit}
  on {print}' CHANGELOG.md | sed -e '/./,$!d')
[ -n "$NOTES" ] || fail "CHANGELOG.md belum punya bagian '## $VERSION ...'."

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  [ "$(git rev-list -n1 "$TAG")" = "$(git rev-parse HEAD)" ] ||
    echo "! Tag $TAG sudah ada di commit lain ($(git rev-list -n1 --abbrev-commit "$TAG")) - dipakai apa adanya."
else
  run git tag -a "$TAG" -m "Bilal+ $VERSION (build $BUILD_NO)" -m "$NOTES"
fi

# ---------------------------------------------------------------- build
APK=build/app/outputs/flutter-apk/app-release.apk
if [ "$BUILD" = 1 ]; then
  run flutter build apk --release
fi
if [ "$DRY" = 0 ]; then
  [ -f "$APK" ] || fail "APK tidak ditemukan: $APK"
  AAPT=$(ls -d "${ANDROID_HOME:-$HOME/Library/Android/sdk}"/build-tools/*/aapt2 2>/dev/null | tail -1 || true)
  if [ -n "$AAPT" ]; then
    GOT=$("$AAPT" dump badging "$APK" | sed -n "s/.*versionName='\([^']*\)'.*/\1/p")
    [ "$GOT" = "$VERSION" ] || fail "APK berversi $GOT, bukan $VERSION - build ulang tanpa --no-build."
  fi
fi

OUT=build/release
ASSET="$OUT/bilal-plus-$VERSION.apk"
NOTES_FILE="$OUT/notes-$TAG.md"
run mkdir -p "$OUT"
run cp "$APK" "$ASSET"
if [ "$DRY" = 0 ]; then
  cat >"$NOTES_FILE" <<EOF
$NOTES

---

**Cara pasang:** unduh \`bilal-plus-$VERSION.apk\` di bawah, buka berkasnya, lalu izinkan pemasangan dari sumber ini. Memperbarui cukup dipasang menimpa versi lama - catatan ibadah tetap aman.

Riwayat lengkap: [CHANGELOG.md](https://github.com/$REPO/blob/main/CHANGELOG.md)
EOF
fi
echo "Catatan rilis: $NOTES_FILE"

# ---------------------------------------------------------------- push
run git push origin main
run git push origin "$TAG"

# ---------------------------------------------------------------- release
# Release dibuat dulu (tanpa berkas), lalu APK diunggah terpisah dengan coba
# ulang: APK ±80 MB mudah putus di tengah jalan ("broken pipe"), dan
# kalau diunggah lewat `gh release create` sekaligus, Release-nya ikut batal.
upload_apk() {
  for try in 1 2 3; do
    if run gh release upload "$TAG" "$ASSET" --repo "$REPO" --clobber; then
      return 0
    fi
    echo "! Unggah APK gagal (percobaan $try/3) - mencoba lagi dalam 10 detik..."
    sleep 10
  done
  fail "APK gagal diunggah. Release $TAG sudah ada; ulangi nanti dengan: tool/release.sh --no-build"
}

if command -v gh >/dev/null; then
  if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
    echo "Release $TAG sudah ada - catatan & APK diperbarui."
  else
    run gh release create "$TAG" --repo "$REPO" --verify-tag \
      --title "Bilal+ $VERSION" --notes-file "$NOTES_FILE" --draft
  fi
  upload_apk
  # terbitkan (draft -> publik) hanya setelah APK benar-benar terunggah
  run gh release edit "$TAG" --repo "$REPO" --title "Bilal+ $VERSION" \
    --notes-file "$NOTES_FILE" --draft=false --latest
  echo "✓ Selesai: https://github.com/$REPO/releases/tag/$TAG"
else
  echo
  echo "gh belum terpasang - terbitkan Release lewat web:"
  echo "  https://github.com/$REPO/releases/new?tag=$TAG"
  echo "  judul: Bilal+ $VERSION · isi: $NOTES_FILE · lampiran: $ASSET"
fi
