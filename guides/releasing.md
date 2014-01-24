---
layout: default
title: Releasing
permalink: releasing/
excerpt: Start with an idea, end with a distributable package for unRAID.
---

Use git to create a tag that matches the version number in your `boiler.json`. If you're following the hola example, you should be on 0.1.0.

    git tag 0.1.0

Don’t forget to push your tags:

    git push --tags

You've now tagged and released 0.1.0 of hola. Congrats! Check out [Registering](/guides/registering) for info on adding it to the official registry.
