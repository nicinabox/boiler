# boiler

**/!\ boiler is not ready for production usage**

## Install

    wget -qO- --no-check-certificate https://raw.github.com/nicinabox/boiler/master/install.sh | sh -

## Usage

    init                    # Create a boiler.json in the current directory
    install NAME [VERSION]  # Install a package by name
    list                    # List installed packages
    pack DIR                # Pack a directory for distribution
    register NAME URL       # Register a package
    remove NAME             # Remove (uninstall) a package
    search NAME             # Search for packages
    update NAME             # Update package by name

## Creating a package

The simplest package is just directory with a boiler.json file. This project is a boiler package itself (meta!).

1. Create a directory for your project
2. Run `boiler init` in that directory

## Registering a package

Boiler packages use git as the distribution mechanism. Your package must be a publicly available git repo (Github recommended, but not required).

1. Run `boiler register NAME URL`, where NAME is the name of your package, and URL is the git url (use the git:// protocol!)
2. Profit!

## Maintaining your package

Once a package is registered, it does not need to be updated through boiler. Boiler makes use of git tags (use semver!) to deliver a package version. Commit and tag as normal to release your package.

## boiler.json

See this project's boiler.json for a working example.

**name** [string, required] - The name of your package

**version** [string, required] - The version of your package. Should be semver and match git tags

**description** [string] - A description of your package

**dependencies** [string] - A hash of dependencies (`"openssl": ">=1.0.1c"`). Maybe use version constraints

**ignore** [array] - Ignore files or directories when building the package

**prefix** [array] - Prefix files or directories with a path during packaging. Useful for mapping directories (say `bin` to, `/usr/local/bin`)

**symlink** [hash] - Define files to be symlinked on install

**post_install** [array] - Define commands to run during post install

## License

Copyright (c) 2013 Nic Aitch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
