#!/bin/sh

set -e

echo updating help content in $PWD

WEBSITE=http://www.entropy.ch/software/macosx/album-artwork-assistant/
OUTFILE="Album Artwork Assistant Help.html"

curl $WEBSITE | xsltproc 2>/dev/null -o "$OUTFILE" --nonet --stringparam website $WEBSITE update-help.xslt -

IMAGES=$(xsltproc --nonet --stringparam website $WEBSITE extract-images.xslt "$OUTFILE" 2>/dev/null)

for i in $IMAGES; do
	curl -O $i
done
