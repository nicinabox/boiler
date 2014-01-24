---
layout: guide
title: Testing
permalink: testing/
excerpt: Test your package with a virtual machine
---

<p class="lead">
  You should always test your package on a real unRAID instance before releasing. Boiler has a couple commands that make testing a little easier.
</p>

### boiler pack

Uses the configuration specified in boiler.json to create a tarball in the current directory. Naming will be `NAME-VERSION-ARCH-BUILD.tgz`. For our tutorial project, that’s `hola-0.1.0-noarch-unraid.tgz`

    boiler pack .

At this point, you'll need to transfer it to a VM, or machine to install. For a more automated solution, see "deploy".

### boiler deploy

Deploy goes one step further and copies your package to a host with `scp`. This is especially helpful if you’re using a VM with openSSH installed. You can build and copy in one step.

    deploy . root@tower.local:/root

Then on your VM:

    installpkg hola-0.1.0-noarch-unraid.tgz

Watch for errors during installation. What you see here is what users will see when your package is installed.
