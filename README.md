# Dotfiles

My OSX / Ubuntu / Cygwin dotfiles.

## About this project

This is my fork of Ben Alman's [dotfiles repository](https://github.com/cowboy/dotfiles). Please note that this README is not completely up to date with all of my changes to this repository since I forked it.

[dotfiles]: bin/dotfiles

## How the "dotfiles" command works

When [dotfiles][dotfiles] is run for the first time, it does a few things:

1. In Ubuntu, Git is installed if necessary via APT (it's already there in OSX).
1. This repo is cloned into your user directory, under `~/.dotfiles`.
1. Files in [`/copy`](copy/) are copied into `~/`. ([read more](#the-copy-step))
1. Files in [`/link`](link/) are symlinked into `~/`. ([read more](#the-link-step))
1. You are prompted to choose scripts in `/init` to be executed. The installer attempts to only select relevant scripts, based on the detected OS and the script filename.
1. Your chosen init scripts are executed (according to the order specified in [init/ordered_init_files](init/ordered_init_files)). ([read more](#the-init-step))

On subsequent runs, step 1 is skipped, step 2 just updates the already-existing repo, and step 5 remembers what you selected the last time. The other steps are the same.

### Other subdirectories

* The `/backups` directory gets created when necessary. Any files in `~/` that would have been overwritten by files `/link` get backed up there.
* The [`/bin`](bin/) directory contains executable shell scripts (including the [dotfiles][dotfiles] script) and symlinks to executable shell scripts. This directory is added to the path.
* The `/caches` directory contains cached files, used by some scripts or functions.
* The [`/conf`](conf/) directory just exists. If a config file doesn't **need** to go in `~/`, reference it from the `/conf` directory.
* The [`/source`](source/) directory contains files that are sourced whenever a new shell is opened (in alphanumeric order, hence the funky names).
* The [`/test`](test/) directory contains unit tests for especially complicated bash functions.
* The [`/vendor`](vendor/) directory contains third-party libraries.

### The "copy" step
Any file in the [`/copy`](copy/) subdirectory will be copied into `~/` unless a file with the same name already exists there. Any file that _needs_ to be modified with personal information (like [copy/.gitconfig](copy/.gitconfig) which contains an email address and private key) should be _copied_ into `~/`. Because the file you'll be editing is no longer in `~/.dotfiles`, it's less likely to be accidentally committed into your public dotfiles repo.

### The "link" step
Any file in the [`/link`](link/) subdirectory gets symlinked into `~/` with `ln -s`. Edit one or the other, and you change the file in both places. Don't link files containing sensitive data, or you might accidentally commit that data! If you're linking a directory that might contain sensitive data (like `~/.ssh`) add the sensitive files to your [.gitignore](.gitignore) file!

### The "init" step
Scripts in the [`/init`](init/) subdirectory will be executed. First, chosen init scripts are executed in the order defined in [source/ordered_init_files](source/ordered_init_files). Then chosen init files that are unordered (not mentioned in that file) are executed. A whole bunch of things will be installed, but _only_ if they aren't already.

#### OS X

* Minor XCode init via the [init/osx_xcode.sh](init/osx_xcode.sh) script
* Homebrew via the [init/osx_homebrew.sh](init/osx_homebrew.sh) script
* Homebrew recipes via the [init/osx_homebrew_recipes.sh](init/osx_homebrew_recipes.sh) script
* Homebrew casks via the [init/osx_homebrew_casks.sh](init/osx_homebrew_casks.sh) script
* [Fonts](/timedelta/dotfiles/tree/master/conf/osx/fonts) via the [init/osx_fonts.sh](init/osx_fonts.sh) script

#### Ubuntu

* APT packages and git-extras via the [init/ubuntu_apt.sh](init/ubuntu_apt.sh) script

## Hacking my dotfiles

Because the [dotfiles][dotfiles] script is completely self-contained, you should be able to delete everything else from your dotfiles repo fork, and it will still work. The only thing it really cares about are the `/copy`, `/link` and `/init` subdirectories, which will be ignored if they are empty or don't exist.

If you modify things and notice a bug or an improvement, [file an issue](https://github.com/timedelta/dotfiles/issues) or [a pull request](https://github.com/timedelta/dotfiles/pulls) and let me know.

Also, before installing, be sure to [read my gently-worded note](#heed-this-critically-important-warning-before-you-install).

## Installation

### OS X Notes

You need to have [XCode](https://developer.apple.com/downloads/index.action?=xcode) or, at the very minimum, the [XCode Command Line Tools](https://developer.apple.com/downloads/index.action?=command%20line%20tools), which are available as a much smaller download.

The easiest way to install the XCode Command Line Tools in OSX 10.9+ is to open up a terminal, type `xcode-select --install` and [follow the prompts](http://osxdaily.com/2014/02/12/install-command-line-tools-mac-os-x/).

_Tested in OSX 10.10_

### Ubuntu Notes

You might want to set up your ubuntu server [like I do it](https://github.com/cowboy/dotfiles/wiki/ubuntu-setup), but then again, you might not.

Either way, you should at least update/upgrade APT with `sudo apt-get -qq update && sudo apt-get -qq dist-upgrade` first.

_Tested in Ubuntu 14.04 LTS_

### Heed this critically important warning before you install

**If you're not me, please _do not_ install dotfiles directly from this repo!**

Why? Because I often completely break this repo while updating. Which means that if I do that and you run the `dotfiles` command, your home directory will burst into flames, and you'll have to go buy a new computer. No, not really, but it will be very messy.

### Actual installation (for you)

1. [Read my gently-worded note](#heed-this-critically-important-warning-before-you-install)
1. Fork this repo
1. Open a terminal/shell and do this:

```sh
export github_user=YOUR_GITHUB_USER_NAME

bash -c "$(curl -fsSL https://raw.github.com/$github_user/dotfiles/master/bin/dotfiles)" && source ~/.bashrc
```

Since you'll be using the [dotfiles][dotfiles] command on subsequent runs, you'll only have to export the `github_user` variable for the initial install.

There's a lot of stuff that requires admin access via `sudo`, so be warned that you might need to enter your password here or there.

### Actual installation (for me)

```sh
bash -c "$(curl -fsSL http://bit.ly/timedelta-dotfiles)" && source ~/.bashrc
```

## Aliases and Functions
To keep things easy, the `~/.bashrc` and `~/.bash_profile` files are extremely simple, and should never need to be modified. Instead, add your aliases, functions, settings, etc into one of the files in the `source` subdirectory, or add a new file. They're all automatically sourced when a new shell is opened. Take a look, I have [a lot of aliases and functions](source). I have split my aliases and functions into multiple categories, each of which is only sourced under certain circumstances. The categories are universal, platform-specific, and machine-specific. Universal ones are generic enough to always be sourced. Platform-specific ones are only sourced if certain platform constraints are met, such as OS or domain name, etc. Machine-specific ones are too specific to apply to more than one machine and, as such are not versioned in this repository. Sourcing always occurs in this order: universal, platform-specific, machine-specific. Because of this, machine-specific functions override platform-specific ones, which override universal ones. Aliases cannot be overriden unless you first use `unalias name_of_alias_to_override`. I even have a [fancy prompt](source/prompt.sh) that integrates with [iTerm2](https://iterm2.com) and shows the current directory along with the current git/svn/bzr branch.

## Scripts
In addition to the aforementioned [dotfiles][dotfiles] script, there are a few other [bin scripts](bin). This includes [nave](https://github.com/isaacs/nave), which is a [git submodule](vendor).

* [dotfiles][dotfiles] - (re)initialize dotfiles. It might ask for your password (for `sudo`).
* [src](link/.bashrc#L8-18) - (re)source all files in `/source` directory
* Look through the [bin](bin) subdirectory for a few more.

## Prompt
Defined in [source/prompt.sh](source/prompt.sh). It shows the current directory in yellow, shortened hostname in green, and code repository information in blue / cyan.

Git / Bazaar Repository:

![git repository](http://s15.postimg.org/enuo12for/Screen_Shot_2015_11_10_at_8_55_41_PM.png)

Svn Repository:

![svn repository](http://s11.postimg.org/7h1byvj37/Screen_Shot_2015_11_10_at_9_04_42_PM.png)

The number here is the currently checked out revision number.

## Inspiration
<https://github.com/cowboy/dotfiles>

## License
Original work:  
Copyright (c) 2014 "" Ben Alman  
Licensed under the MIT license.  
<http://benalman.com/about/license/>

Edits:  
Copyright (c) 2015 "" Bryan Herman  
Licensed under the MIT license.  
