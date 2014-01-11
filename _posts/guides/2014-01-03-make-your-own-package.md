---
layout: default
title: Make your own package
categories: guides
excerpt: Start with an idea, end with a distributable package for unRAID
---

## Getting started

You'll need:

* Github account
* Git installed
* Ruby 1.9.3 installed (RVM or rbenv can help with this)

If you're unfamiliar with using git, check out [Github’s articles](https://help.github.com/articles/set-up-git) to get started.

## Setup your dev machine

Clone the Boiler repo (we’ll clone to the ~/code directory here):

    mkdir -p ~/code && cd $_
    git clone https://github.com:nicinabox/boiler.git

Install the Boiler dependencies

    cd boiler
    bundle

Symlink `bin/boiler` so it’s in your path:

    ln -s `pwd`/bin/boiler /usr/local/bin/boiler

You should be all set to use the boiler commands. Test it out:

    boiler

## Creating

Back in your `~/code` directory, initialize a new package:

    boiler init boiler-hola

This will create a directory called `boiler-hola` with the following contents:

    boiler.json
    README.md

This is technically all you need to register your package, but let's add some more functionality first.

Create a simple configuration file at `config/hola.json`:

    {
      "name": "WRITE YOUR NAME HERE"
    }

You can have more than one config file, but it’s conventional to  use a json file named after your project.

Create a file at `bin/hola`:

```python
#!/usr/bin/env python
import json

# open the config file
file = open(ENV['boiler_config_path'] + '/boiler-hola/hola.json')

# parse it
config = json.load(file)
file.close()

# say something nice
print "Hello {0}, you're doing great!".format(config['name'])
```

We're just going to open the config file and use it to print a message to the screen. Nothing crazy.

So, now you should have a pretty basic directory structure:

    hola
      bin
        hola
      config
        hola.json
      boiler.json
      README.md

## Testing

You should always test your package on a real unRAID instance before releasing. Boiler has a couple commands that make testing a little easier.

### pack

Uses the configuration specified in boiler.json to create a tarball in the current directory. Naming will be `NAME-VERSION-ARCH-BUILD.tgz`. For our tutorial project, that’s `hola-0.1.0-noarch-unraid.tgz`

  boiler pack . # That dot isn’t a typo. That’s “this directory”

### deploy

Deploy goes one step further and copies your package to a host with `scp`. This is especially helpful if you’re using a VM with openSSH installed. You can build and copy in one step.

    deploy . root@tower.local:/root

Then on your VM:

    installpkg hola-0.1.0-noarch-unraid.tgz

## Releasing

Use git to create a tag that matches the version number in your `boiler.json`. You should be on 0.1.0.

    git tag 0.1.0

Don’t forget to push your tags:

    git push --tags

## Maintaining

Don’t forget to maintain your package! Be aware of issues or bugs that come up and try to get them fixed quickly. Releasing a new version is a simple as bumping the version string in `boiler.json` and creating a git tag to match. Once you push, your package will be available for anyone to install (or update if they’ve already got it).

You can always continue development on master or another branch of your choosing. A package won’t be updated until you bump the version.
