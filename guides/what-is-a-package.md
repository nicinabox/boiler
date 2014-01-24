---
layout: guide
title: What is a package?
permalink: what-is-a-package/
excerpt: Unpack the mystery behind what's in a package
---

<p class="lead">
  Boiler packages are just Slackware packages under the hood, and that's just a tarball.
</p>

Boiler uses Slackware's pkgtools as a foundation and provides a set of conveniences, conventions, and tools to make creating and consuming a package very simple.

Distributed packages are tarballs designed to be standalone-compatible with Slackware's package system.

A package can be anything you want to distribute. It could be a web app, a command line tool, daemon, or Slackware package that provides extra functionality to unRAID, like openssh. Think of them like the apps on your smartphone.

### Package structure

This is a tree from the boiler package. Each package follows the same structure of organization.

    ├── README.md
    ├── bin
    │   └── boiler
    ├── boiler.json
    ├── etc
    │   ├── bundlerc
    │   └── gemrc
    ├── install
    │   └── doinst.sh
    ├── install.sh
    └── lib
        ├── boiler
        │   ├── cli.rb
        │   ├── helpers.rb
        │   ├── slackpack.rb
        │   └── version.rb
        └── boiler.rb

### Special files

There are some special files boiler looks for when creating a tarball.

#### config/NAME.json

Prefix: `/boot/plugins/custom/NAME/`

If your project has config files, place them here.

#### bin/\*, lib/\*, Gemfile\*

Prefix: `/usr/local/boiler/NAME/`

If your package uses a Gemfile, it will be detected and run automatically.

#### install/doinst.sh

The `post_install` option in `boiler.json` appends lines here. It's okay to create this file to have more complex code and allow `post_install` to append simpler parts.

#### boiler.json

Prefix: `/var/log/boiler/NAME/`

The meat-and-potatoes of a boiler package. It is required to register a package.

#### README.\*, LICENSE.\*

Prefix: `/usr/docs/NAME/`

You should include a readme in your project detailing what your project is, how it install it, where to find configurations, etc.

### boiler.json

See the [Manifest reference](/guides/manifest) for details.
