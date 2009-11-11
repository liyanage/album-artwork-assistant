#!/bin/sh

set -e
LANG=$1
OUTDIR="$2"
WD=$PWD

WEBSITE=http://www.entropy.ch/software/macosx/album-artwork-assistant/
OUTFILE="Album Artwork Assistant Help.html"

echo outfile: "$OUTDIR/$OUTFILE"

curl -s $WEBSITE | xsltproc 2>/dev/null \
	-o "$OUTDIR/$OUTFILE" \
	--nonet \
	--stringparam website $WEBSITE \
	--stringparam lang $LANG \
	"$WD/Resources/help-tools/update-help.xslt" -

cd "$OUTDIR"

IMAGES=$(xsltproc --nonet --stringparam website $WEBSITE "$WD/Resources/help-tools/extract-images.xslt" "$OUTFILE" 2>/dev/null)

for i in $IMAGES; do
	curl -s -O $i
done
