---
layout: guide
title: Manifest
permalink: manifest/
excerpt: A reference for boiler.json
---

The `boiler.json` contains package metadata. It's used by boiler to construct the final name, setup dependencies, map directories, and run commands.

This file will be generated when running `boiler init`, or you can create it manually.

**name** *string* (required) - The name of your package

**version** *string* (required) - The version of your package. Should be semver and match git tags

**description** *string* - A description of your package. This helps people discover your package.

**arch** *string* - Defaults to `noarch`

**build** *string* - Defaults to `unraid`

**authors** *array* - An array of authors/contributors.

**license** *string* - Specify a license for your package so people know how they're permitted to use it and any restrictions you're placing on it

**homepage** *string* - Url to the project's homepage

**dependencies** *string* - A hash of Slackware dependencies (`"openssl": ">=1.0.1c"`). May use version constraints

**ignore** *array* - Ignore files or directories when building the package

**prefix** *array* - Prefix files or directories with a path during packaging. Useful for mapping directories (say `bin` to, `/usr/local/bin`)

**tasks** *array* - Define commands to be run before packing. Useful for precompile tasks.

**symlink** *hash* - Define files to be symlinked on install

**post_install** *array* - Define commands to run during post install
