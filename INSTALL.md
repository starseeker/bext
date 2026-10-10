# bext - Installation Notes

This file covers machine setup and source checkout details.  For the main build
flow and option behavior, see [README.md](README.md).

# Base requirements

All builds need:

* Git
* CMake 3.19 or newer
* A modern C compiler
* A modern C++ compiler

Additional requirements depend on the enabled stacks:

* `USE_APPLESEED` and `USE_OSPRAY` will use a system `flex` and
  `bison` if they are already installed.  If they are not and `bext`
  needs to build them locally on non-Windows platforms, a working
  Autotools stack is also needed.
* `USE_QT`, `USE_APPLESEED`, or `USE_OSPRAY` need Python 3 available
  to the build.
* `USE_OSPRAY` needs `m4`.

# Source checkout options

Default clone:

```sh
git clone https://github.com/BRL-CAD/bext
```

This is usually the best starting point.  `bext` will populate submodules on
demand during configure.

Recursive clone:

```sh
git clone --recursive https://github.com/BRL-CAD/bext
```

Use this if you want all submodule content fetched up front, or if you expect
to configure and build without network access later.

Shallow clone options:

* `cmake ../bext -DGIT_SHALLOW_CLONE=ON ...`
* `git clone --recursive --depth=1 https://github.com/BRL-CAD/bext`

Shallow clones are fine for compile-only use, but they are not recommended for
development or for submodule update work.

# Alternate repositories and offline mirrors

`BEXT_REPOSITORY_ROOT` selects the directory containing the dependency
repositories.  It defaults to `https://github.com/BRL-CAD`.  For another host,
specify the URL of the equivalent repository directory:

```sh
cmake --preset auto -DBEXT_REPOSITORY_ROOT=https://git.example.org/brlcad
```

For offline use, the directory can contain bare Git mirrors such as
`bext.git`, `astyle.git`, and `libpng.git`, as produced by BRL-CAD's
`sh/mirror_repos.sh`.  Clone bext first, then let CMake populate the required
submodules:

```sh
git clone /path/to/mirror/BRL-CAD/bext.git
cd bext
cmake --preset auto -DBEXT_REPOSITORY_ROOT=/path/to/mirror/BRL-CAD
```

The root points directly to the repositories; CMake does not append `BRL-CAD`.
Local paths and `file://` URLs are supported, as are remote Git URLs including
`ssh://` URLs.  Relative local paths are resolved against the bext source
directory.  Quote the `-D` argument if the path contains spaces.  The setting
is saved in the configure cache.

The optional bootstrap script accepts the same setting:

```sh
cmake -DPROFILE=auto -DBEXT_REPOSITORY_ROOT=/path/to/mirror/BRL-CAD \
  -P CMake/BextBootstrap.cmake
```

Bootstrap runs separately from configure, so pass the setting to both commands
if you use both workflows.  `LIST_ONLY=ON` previews bootstrap selection without
fetching.

CMake redirects `https://github.com/BRL-CAD/` URLs using command-scoped Git
configuration, including recursive submodule operations.  Local roots enable
file transport and forbid network transport for those Git operations.  They
also disable shallow-clone recommendations, even with `GIT_SHALLOW_CLONE=ON`,
so full mirrors can supply older pinned commits.  The mirrors must contain all
required commits.  Recursive submodules outside that URL prefix need their
own Git URL mappings and local mirrors; otherwise initialization fails.

The override does not change `.gitmodules` or install persistent Git rewrite
settings.  To return CMake-driven updates to GitHub, set
`-DBEXT_REPOSITORY_ROOT=https://github.com/BRL-CAD`.  Direct Git commands use
their normal configuration.  This setting controls submodule fetching, not
network access by dependency build scripts.

# Path and directory caveats

* Avoid symlinked source or build directory paths.  `bext` warns about these
  because they can cause downstream install and rpath problems.
* On non-Windows platforms, bundled Tcl/Tk builds do not support spaces in the
  source or build directory path.

# Ubuntu Linux

Base packages:

```sh
sudo apt install git cmake gcc g++
```

For Tcl/Tk builds:

```sh
sudo apt install libfontconfig1-dev libfreetype6-dev xserver-xorg-dev libx11-dev libxi-dev libxext-dev
```

For Qt, Appleseed, and OSPRay:

```sh
sudo apt install libpython3-dev
```

For Qt on X11 systems, install the XCB development packages:

```sh
sudo apt install libx11-xcb-dev libxfixes-dev libxrender-dev libxcb1-dev libxcb-cursor-dev libxcb-glx0-dev libxcb-keysyms1-dev libxcb-image0-dev libxcb-shm0-dev libxcb-icccm4-dev libxcb-sync-dev libxcb-xfixes0-dev libxcb-shape0-dev libxcb-randr0-dev libxcb-render-util0-dev libxcb-util-dev libxcb-xinerama0-dev libxcb-xkb-dev libxkbcommon-dev libxkbcommon-x11-dev
```

For OSPRay:

```sh
sudo apt install m4 gcc-multilib g++-multilib
```

If you want to rely on system `flex` and `bison`:

```sh
sudo apt install flex bison
```

If `bext` may need to build `flex` and `bison` locally:

```sh
sudo apt install autotools-dev autoconf
```

# Windows

If you enable Qt, Appleseed, or OSPRay, make sure Python 3 is installed and
available in the build environment.

Keep the source and build directories close to the drive root when possible.
Some Windows build tools still have path length limits, even though bext enables
Git's long path handling when it checks out submodules.

# macOS

Assuming XCode is installed, good to go.
