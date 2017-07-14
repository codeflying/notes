#!/bin/sh
imagesets=/tmp/imagesets
imagenames=/tmp/imagenames
find . -name "*.imageset" -exec basename {} ".imageset" \; >$imagesets
find . -type f -name "*.m" -exec grep "imageNamed:@" {} \; | sed -n 's/^.*imageNamed:@"\([^"]*\)".*$/\1/p' > $imagenames
find . -name "*.storyboard" -or -name "*.xib" -exec grep "image=" {} \; | sed -n 's/^.*image=\"\([^"]*\)\".*$/\1/p' >> $imagenames

awk -f check_image.awk $imagesets $imagenames
