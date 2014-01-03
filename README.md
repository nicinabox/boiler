# boiler

Boiler is a tool to create, distribute, install, and update unRAID packages (plugins) easily. It extends Slackware's native package system to provide conveniences to devs (like config persistence) as well as users (like no need to reboot when installing or removing a package and easy updating).

[Visit the registry](http://registry.getboiler.com/) to see all available packages.

![](http://i.minus.com/iPuI9DhwCn2cA.gif)

## Install

    wget -qO- --no-check-certificate https://raw.github.com/nicinabox/boiler/master/install.sh | sh -

## Usage

    convert PLG             # Convert a plg to boiler package
    help [COMMAND]          # Describe available commands or one specific command
    info NAME               # Get info on installed package
    init                    # Create a boiler.json in the current directory
    install NAME [VERSION]  # Install a package by name
    list [NAME]             # List installed packages
    pack DIR                # Pack a directory for distribution
    register NAME URL       # Register a package
    remove NAME             # Remove (uninstall) a package
    search NAME             # Search for packages
    update NAME             # Update package by name
    version                 # Prints version

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

## Package anatomy

There are some special files boiler looks for when creating the final package.

**config/\*.json** - (prefix: `/boot/plugins/custom/NAME/`)

If your project has config files, place them here.

**bin/\***, **lib/\***, **Gemfile\*** - (prefix: `/usr/local/boiler/NAME/`)

**install/doinst.sh**

The `post_install` option in `boiler.json` appends lines here. It's okay to create this file to have more complex code and allow `post_install` to append simpler parts.

**boiler.json** - (prefix: `/var/log/boiler/NAME/`)

The meat-and-potatoes of a boiler package. It is required to register a package.

**README.\***, **LICENSE\*** - (prefix: `/usr/docs/NAME/`)

You should include a readme in your project detailing what your project is, how it install it, where to find configurations, etc.

## boiler.json

See this project's boiler.json for a working example.

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

**symlink** *hash* - Define files to be symlinked on install

**post_install** *array* - Define commands to run during post install

## Todo

* Tests
* Robustness on install (thin dependencies if possible)
* Better error reporting when something fails
* Convert plgs more accurately
* Version string appears 3 times in repo :/
* Add info on testing your package with a vm
* Setup as gem? Useful for development (convert, pack)
* boiler.json
  * dependencies: supports urls and version
  * peerDependencies: same as dependencies, but for boiler packages

## Contributing

Boiler loves contributors!

1. Fork it
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create new Pull Request

## License

MIT. Copyright 2014 Nic Aitch


[![Bitdeli Badge](https://d2weczhvl823v0.cloudfront.net/nicinabox/boiler/trend.png)](https://bitdeli.com/free "Bitdeli Badge")

