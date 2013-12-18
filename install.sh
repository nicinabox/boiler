#!/bin/bash

version=0.2.0
name='boiler'

# Make sure we've got an extras directory
mkdir -p /boot/extra

# Remove old file versions
rm -rf /boot/extra/$name*

# Download new
wget -q --no-check-certificate \
     -O /boot/extra/$name-$version-noarch-unraid.tgz \
     https://github.com/nicinabox/$name/releases/download/$version/$name-$version-noarch-unraid.tgz

# Install
installpkg /boot/extra/$name-$version-noarch-unraid.tgz
