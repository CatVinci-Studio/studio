#!/usr/bin/env bash
# Refreshes textus/ from where the materials are made, so the copies here
# never drift from the originals. Edit the originals, then run this:
#
#   scripts/sync-textus.sh [path/to/Textus]   (default: ../Textus beside catvinci/)
#
#   icon/                 <- Textus/assets/icon
#   screenshots/desktop/  <- Textus/assets/site-assets/app/{en,zh}   (the README shots)
#   screenshots/ios/      <- Textus/assets/app-store/{en,zh-Hans}    (the App Store shots)
#   video/                <- Textus/video/out                         (covers, posters, teasers)
#   social/               <- Textus/promo/assets/covers/<ratio>/        (covers by aspect ratio, -zh / -en)
#   images/<lang>/        <- Textus/promo/assets/images/<lang>          (article images)
#   press-kit.md          <- Textus/promo/press-kit.md                 (fact sheet and descriptions)
#
# textus/README.md is written by hand and left alone.
set -euo pipefail

here="$(cd "$(dirname "$0")/.." && pwd)"
src="$(cd "${1:-$here/../../Textus}" && pwd)"
dst="$here/textus"
[ -d "$src/assets" ] && [ -d "$src/video/out" ] || {
  echo "not a Textus folder: $src" >&2
  exit 1
}

copy() { # copy <from> <to-dir> - replaces the destination's files of the same names
  mkdir -p "$2"
  cp -f "$1" "$2/"
}

for f in icon-macos-1024.png icon-ios-1024.png quill-transparent.png; do
  copy "$src/assets/icon/$f" "$dst/icon"
done

for lang in en zh; do
  for f in "$src/assets/site-assets/app/$lang"/*.png; do
    copy "$f" "$dst/screenshots/desktop/$lang"
  done
done

for pair in en:en zh-Hans:zh; do
  from="${pair%%:*}" to="${pair##*:}"
  for device in "$src/assets/app-store/$from"/*/; do
    name="$(basename "$device")"
    for f in "$device"*.png; do copy "$f" "$dst/screenshots/ios/$to/$name"; done
  done
done

for lang in en zh; do
  for f in cover-$lang.png cover-portrait-$lang.png poster-$lang.png \
    teaser-hero-$lang.gif teaser-hero-$lang.webm; do
    copy "$src/video/out/$f" "$dst/video"
  done
done

# Only real files: the video covers in assets/covers are links to video/out, copied above.
for f in "$src/promo/assets/covers"/*/*.png; do [ -L "$f" ] || copy "$f" "$dst/social"; done
for dir in "$src/promo/assets/images"/*/; do
  lang="$(basename "$dir")"
  for f in "$dir"*.png; do [ -e "$f" ] && copy "$f" "$dst/images/$lang"; done
done
cp -f "$src/promo/press-kit.md" "$dst/press-kit.md"

echo "textus/ refreshed from $src"
git -C "$here" status --short -- textus
