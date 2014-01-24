---
layout: default
title: Boiler basics
categories: guides
excerpt: Use of common boiler commands
---

The `boiler` command allows you to interact with packages. A full reference of available commands can be found by running `boiler help`.

## Finding packages

The `search` command lets you find packages by name.

```bash
$ boiler search tvnamer
tvnamer  git://github.com/nicinabox/boiler-tvnamer.git
```

To get list of all registered packages just leave out the search parameter.

```bash
$ boiler search
couchpotato_v2_unplugged  git://github.com/dawiki/couchpotato_v2_unplugged
transmission_unplugged    git://github.com/dawiki/transmission_unplugged
sickbeard_unplugged       git://github.com/dawiki/sickbeard_unplugged
plexupdater               git://github.com/dawiki/plexupdater
btsync                    git://github.com/nicinabox/boiler-btsync.git
tvnamer                   git://github.com/nicinabox/boiler-tvnamer.git
boiler                    git://github.com/nicinabox/boiler.git
sabnzbd_unplugged         git://github.com/dawiki/sabnzbd_unplugged
trolley                   git://github.com/nicinabox/trolley.git
...
```

## Installing packages

The `install` command downloads and installs the package and any necessary dependencies.

```bash
$ boiler install tvnamer
=> Downloading tvnamer
=> Installing
=> Installed!
```

## Listing installed packages

The `list` command shows your locally installed packages.

```bash
$ boiler list
tvnamer  0.1.0   A utility to rename and move tv shows
btsync   0.1.0   BTSync for unRAID
boiler   0.3.0   Plugin packaging and distribution for unRAID
trolley  0.1.11
```
You can filter the list by specifying a package name:

```bash
$ boiler list tvnamer
tvnamer  0.1.0   A utility to rename and move tv shows
```

## Updating packages

The `update` command updates a package to the newest version by default.

```bash
$ boiler update tvnamer
=> Removing old package
=> Installing
=> Installed!
```

You can also specify a target version:

```bash
$ boiler update tvnamer 0.1.0
=> Removing old package
=> Installing
=> Installed!
```
