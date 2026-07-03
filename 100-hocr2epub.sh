#!/usr/bin/env bash

set -eu

# dst=$(basename "$0" .sh).epub
dst=.

doc_title="$(head -n1 readme.md | sed 's/^#\s*//')"

if false; then
  scan_resolution=600
else
  source 030-measure-page-size.txt
fi

if [ "$dst" != "." ] && [ -e "$dst" ]; then
  echo "error: output exists: $dst"
  exit 1
fi

# downscale to 300 dpi
scale=$(python -c "print(300 / $scan_resolution)")

args=(
  # hocr-to-epub-fxl
  /home/user/src/archive-hocr-tools/bin/hocr-to-epub-fxl
  --output "$dst"
)
if [ "$dst" = "." ]; then
  args+=(
    --output-unpacked
  )
fi

doc_modified=$(
  {
    git show -s --format=%cI HEAD
    stat -c%y 090-ocr | sed -E 's/^([0-9-]+) ([0-9:]+)\.[0-9]+ ([+-][0-9]{2})([0-9]{2})$/\1T\2\3:\4/'
  } |
  LANG=C sort |
  tail -n1
)

args+=(
  --scale "$scale"

  # FIXME error: unrecognized arguments: --image-format
  # this should set the default value for all image formats
  # --image-format avif

  --color-image-format avif
  --grayscale-image-format avif
  --binary-image-format avif

  --grayscale-image-pages 1-228,231-
  --color-image-pages 229-230
  --image-color-levels 20x80

  # 20% smaller than avif, encode 6000x faster than avif, requires group4-polyfill
  # https://github.com/milahu/group4-polyfill
  # --binary-image-format group4.tiff

  --text-format html
  # --doc-title "$doc_title"
  --doc-modified "$doc_modified"
  --doc-title "Schizophrenie"
  --doc-subtitle "Das heilige Symbol der Psychiatrie"
  # https://book8.de/schizophrenie-das-heilige-symbol-der-psychiatrie
  --doc-description "Das 1976 erstmals veröffentlichte Buch \"Schizophrenie: The Sacred Symbol of Psychiatry\" untersucht das Konzept der Schizophrenie und die Ursprünge ihrer Klassifizierung als Krankheit.

Szasz argumentiert überzeugend, dass das Wort Schizophrenie keine medizinische Diagnose ist, sondern ein Symbol, das von Psychiatern als Mittel zur Kontrolle eingesetzt wird."
  --doc-subject ""
  --doc-date 1982
  --doc-edition 1
  --doc-extent "228 pages"
  --doc-author "Thomas Szasz"
  # --doc-introducer ""
  # --doc-contributor ""
  # --doc-translator ""
  --doc-publisher "Fischer Taschenbuch"
  --doc-language de
  --doc-isbn 9783203506982
  --doc-cover-image 077-compress-jpeg/229.jpg
  --canonical-url-base https://milahu.github.io/thomas-szasz-schizophrenie-1982/
)

 printf '>'
for a in "${args[@]}" "$@"; do printf ' %q' "$a"; done
echo ' *-ocr/*.hocr'

"${args[@]}" "$@" *-ocr/*.hocr

if [ "$dst" = "." ]; then
  echo "done ./index.xhtml"
  exit
fi

echo "done $dst"

rm -rf $dst.unzip
mkdir $dst.unzip
cd $dst.unzip
unzip -q ../$dst
cd ..

echo "done $dst.unzip/index.html"
