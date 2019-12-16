#!/bin/bash

VERSION=$(awk -F '>' '/<Version>/ {print substr($2,1,match($2,"<")-1)}' manifest.xml)
PACKAGE_NAME="lil.cupcake.PushyPushPush-v$VERSION.xrnx"

echo "Packing Renoise .xrnx '$PACKAGE_NAME'"
zip -X $PACKAGE_NAME ./*.lua ./*.xml
echo "Moving XRNX package to ~/Documents"
mv -v $PACKAGE_NAME ~/Documents/
