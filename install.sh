#!/bin/bash

version=0.1.0

# Make sure we've got an extras directory
mkdir -p /boot/extra

# Remove old file versions
rm -rf /boot/extra/boiler*

# Download new
wget -q --no-check-certificate \
     -O /boot/extra/boiler-$version-noarch-unraid.tgz \
     https://github.com/nicinabox/boiler/releases/download/$version/boiler-$version-noarch-unraid.tgz

# Install
installpkg /boot/extra/boiler-$version-noarch-unraid.tgz
