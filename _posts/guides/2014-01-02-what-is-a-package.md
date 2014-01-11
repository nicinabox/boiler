---
layout: default
title: What is a package?
categories: guides
excerpt: Unpack the mystery behind what's in a boiler package
---

<p class="lead">
  Simply put, Boiler packages are Slackware packages with a layer of icing.
</p>

This so-called icing is a set of conveniences, conventions, and tools that Boiler provides to make creating and consuming a package very simple.

Distributed packages are tarballs designed to be standalone-compatible with Slackware's native pkgtools.

A package can be anything you want to distribute. It could be a web app, a command line tool, daemon, or Slackware package that provides extra functionality to unRAID, like openssh.

## Special files

There are some special files boiler looks for when creating a tarball.

#### config/NAME.json

Prefix: `/boot/plugins/custom/NAME/`

If your project has config files, place them here.

#### bin/\*, lib/\*, Gemfile\*

Prefix: `/usr/local/boiler/NAME/`

#### install/doinst.sh

The `post_install` option in `boiler.json` appends lines here. It's okay to create this file to have more complex code and allow `post_install` to append simpler parts.

#### boiler.json

Prefix: `/var/log/boiler/NAME/`

The meat-and-potatoes of a boiler package. It is required to register a package.

#### README.\*, LICENSE.\*

Prefix: `/usr/docs/NAME/`

You should include a readme in your project detailing what your project is, how it install it, where to find configurations, etc.


## The boiler.json

See the [Specification Reference](/guides/specification-reference) for details.
