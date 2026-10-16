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

## Reusable per-dependency mappings

To fetch dependencies from different mirrors or upstreams, copy the commented
[mapping template](CMake/BextGitRemap.example), uncomment the entries you need,
and replace their destinations.  It lists every submodule path and canonical
URL, including the separate repositories within `flexbison`.

```sh
cmake --preset auto -DBEXT_GIT_REMAP=/path/to/mirrors.txt
cmake -DPROFILE=auto -DBEXT_GIT_REMAP=/path/to/mirrors.txt \
  -DLIST_ONLY=ON -P CMake/BextBootstrap.cmake
```

The second command previews bootstrap selection, resolved rewrite rules, and
transport mode without fetching.  Omit `LIST_ONLY` to populate the submodules.
Bootstrap returns an error if any selected submodule, including a recursive
submodule, cannot be populated.
Pass the same mapping file to both workflows if you use both.

The file is data, with two optional sections:

```ini
# Exact, case-sensitive paths from bext's .gitmodules.
[submodules]
zlib/zlib = https://git.example.org/libraries/zlib.git
png/libpng = /srv/git/libpng.git
flexbison/flex = ../mirrors/flex.git
flexbison/bison = git@mirror.example.org:tools/bison.git

# Original URL prefix = replacement URL prefix; also applies during recursion.
[urls]
https://github.com/BRL-CAD/ = https://mirror.example.org/brlcad/
https://other.example.org/vendor/ = ../mirrors/vendor/
```

Blank lines and full-line `#` comments are allowed.  Use UTF-8 text with LF or
CRLF endings.  Each assignment splits at its first `=`; surrounding whitespace
is ignored, and subsequent `=` characters belong to the value.  Do not quote
values.  Spaces inside paths are supported.  There are no inline comments,
variable substitutions, environment expansions, or includes.  Literal
semicolons are unsupported.  Unknown sections or submodule paths, malformed
entries, and duplicate keys within a section are errors with file/line diagnostics.

A relative `BEXT_GIT_REMAP` filename is resolved against the bext source root.
Relative destinations **inside the file** are resolved against the file's own
directory, so the file is reusable from different working directories.  Prefix
destinations retain their specified trailing slash; use one when replacing a
directory prefix.  A `[submodules]` destination names a complete repository;
CMake does not append a repository name or `.git` suffix.

The file is read again on every configure or bootstrap invocation.  Changing it
also triggers regeneration in configured builds.  Removing an entry removes
that override; parsed mappings are not retained separately in the CMake cache.

## Inline overrides and precedence

For occasional exceptions, use semicolon-separated CMake lists:

```sh
cmake --preset auto -DBEXT_GIT_REMAP=/path/to/mirrors.txt \
  '-DBEXT_SUBMODULE_URLS=zlib/zlib=https://special.example/zlib.git;png/libpng=/srv/git/libpng.git' \
  '-DBEXT_GIT_URL_MAP=https://other.example.org/vendor/=https://special.example/vendor/'
```

`BEXT_SUBMODULE_URLS` corresponds to `[submodules]`, and `BEXT_GIT_URL_MAP` to
`[urls]`.  An inline entry overrides the same key in its file section.  Relative
inline destinations, like `BEXT_REPOSITORY_ROOT`, are relative to the bext source
root.  Duplicate keys within an inline list are errors.  Quote the whole `-D`
argument to protect it from the shell; an escaped literal semicolon is still
unsupported as part of an entry.

Submodule paths resolve to their canonical URLs from `.gitmodules`.  For an
identical source prefix, submodule mappings take precedence over URL mappings,
which take precedence over `BEXT_REPOSITORY_ROOT`.  Conflicting submodule
mappings for the same canonical URL are errors.  Among different matching
prefixes, Git uses the longest match.  Thus a repository-specific rule normally
wins over a root-wide rule.

These are Git's native `url.<replacement>.insteadOf` prefix rewrites, scoped to
the Git process tree, including recursion.  Even a full repository URL is a
prefix: a mapping for `https://example.org/lib` also matches
`https://example.org/lib-extra`.  Identical URLs in nested submodules receive
the same rewrite.  Rules match original URLs and do not chain; a rule for an
already-rewritten destination will not apply a second time.  Normal user Git
configuration still participates, so avoid competing rules for identical
source prefixes outside bext.

Relative nested submodule URLs resolve against the parent's stored remote URL,
which remains canonical.  For example, remapping OIDN to `RenderKit/oidn` still
resolves its `../mkl-dnn.git` URL to `https://github.com/BRL-CAD/mkl-dnn.git`.
Add a `[urls]` entry for that resolved URL when the root-wide mapping does not
provide the nested repository.

## Transport and pinned commits

A local root defaults to file-only transport for all recursive Git operations.
An explicit remote destination in the surviving mappings enables mixed local
and network transport for that invocation, including other recursive fetches.
The default remote root also permits mixing local and remote mappings.  A
caller-supplied `GIT_ALLOW_PROTOCOL` allowlist remains a restriction in both
modes.  Preview output reports file-only or mixed mode when local sources are
configured.

Local sources enable file transport and disable shallow-clone recommendations,
even with `GIT_SHALLOW_CLONE=ON`, so full mirrors can supply older pinned commits.
Recursive submodules outside mapped prefixes need their own mappings and local
mirrors in file-only mode; otherwise initialization fails.  Environment-based
Git configuration requires Git 2.31 or newer when populating submodules.

Every replacement must contain the commits pinned by bext, including nested
submodules.  An upstream repository may lack BRL-CAD-specific commits; changing
the URL does not substitute an upstream release or change the pin.  There is no
automatic fallback to another host.

Overrides do not change `.gitmodules`, install persistent Git rewrite settings,
or synchronize stored remote URLs.  Existing canonical remotes receive rewrites
on subsequent CMake-driven updates; manually customized remotes need matching
URL rules.  Reconfiguring a populated dependency does not force a fetch or
replace its checkout.  Dependency inventory and SBOM URLs remain canonical.

To remove all overrides, clear `BEXT_GIT_REMAP`, `BEXT_SUBMODULE_URLS`, and
`BEXT_GIT_URL_MAP`, and reset `BEXT_REPOSITORY_ROOT` to
`https://github.com/BRL-CAD`.  Direct Git commands use their normal configuration.
These settings control submodule fetching, not network access by dependency
build scripts.

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

# Cross compilation development

Cross compilation is experimental.  The build now distinguishes native tools
from target dependencies, but the complete Windows dependency stack and the
downstream BRL-CAD build still require additional integration.  Native builds
retain their existing output layout.

For a cross build, `install/` contains target deliverables, `noinstall/`
contains target compile-time assets, and `noinstall/host/` contains native
tools and their library dependencies.  `BEXT_HOST_INSTALL_PREFIX` can select
a different native installation prefix.  Do not put native libraries in the
target prefix or add the native prefix to the target `CMAKE_PREFIX_PATH`.

The native compiler defaults to `cc`/`c++` (with platform alternatives).
Override it with `BEXT_HOST_C_COMPILER` and `BEXT_HOST_CXX_COMPILER`, or provide
`BEXT_HOST_TOOLCHAIN_FILE` for a more involved native configuration.  The
native compiler is checked by compiling, linking, and running C and C++
programs.  `BEXT_HOST_PREFIX_PATH` supplies additional native package prefixes.
Native sub-build configuration removes target compiler flags, toolchain, and
pkg-config settings inherited through the environment; put intentional native
settings in the native toolchain file.

Target CMake sub-builds receive the parent toolchain, compiler targets,
sysroots, resource tools, search policies, and compiler/linker flags through a
generated initial cache.  Toolchain-specific inputs can be listed in
`BEXT_TOOLCHAIN_VARIABLES`; inputs listed in
`CMAKE_TRY_COMPILE_PLATFORM_VARIABLES` are forwarded as well.  Explicit
per-dependency CMake arguments take precedence over these defaults.  Use
separate build and output trees for each target toolchain and runtime.

Dependency wrappers mark native builds with `BEXT_BUILD_ROLE HOST` in
`ExternalProject_Add`, use the `BEXT_HOST_*` compiler and installation variables,
and name their native prerequisites explicitly.  The default role is `TARGET`.
Custom configure scripts must apply `BEXT_HOST_CMAKE_ARGS` or
`BEXT_TARGET_CMAKE_ARGS` themselves when invoking CMake; ExternalProject does
not apply `CMAKE_ARGS` to a custom `CONFIGURE_COMMAND`.

The build-context regression fixture builds and runs a native source generator
inside a target library build.  It also checks list-valued toolchain inputs,
default configure commands, and explicitly empty configure commands:

```sh
cmake -S CMake/tests/build_contexts -B build/context-native -G Ninja
cmake --build build/context-native
cmake -S CMake/tests/build_contexts -B build/context-cross -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=/absolute/path/to/windows-toolchain.cmake
cmake --build build/context-cross
```

The fixture needs only target object/archive support.  That is useful for
testing build orchestration without an SDK, but does not validate target
headers, executable linking, DLL loading, or the full dependency stack.

## Windows toolchain profiles

The experimental profiles under `CMake/toolchains/` cover three distinct
toolchain families:

| Profile | Compiler and runtime |
| --- | --- |
| `windows-mingw-gcc.cmake` | MinGW-w64 GCC and its matching runtime |
| `windows-llvm-mingw.cmake` | LLVM-MinGW wrappers, CRT, and C++ runtime |
| `windows-clang-cl.cmake` | clang-cl, LLD, Windows SDK, and VC runtime |

Start with the build-context fixture when checking a new installation:

```sh
cmake -S CMake/tests/build_contexts -B build/context-mingw -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$PWD/CMake/toolchains/windows-mingw-gcc.cmake" \
  -DBEXT_TOOLCHAIN_ROOT=/opt/mingw \
  -DBEXT_WINDOWS_SYSROOT=/opt/mingw/x86_64-w64-mingw32
cmake --build build/context-mingw
```

For LLVM-MinGW, select `windows-llvm-mingw.cmake` and point
`BEXT_TOOLCHAIN_ROOT` to the LLVM-MinGW installation.  Both MinGW profiles
default to the target root beside the toolchain's `bin/` directory when that
directory exists.  Otherwise, set `BEXT_WINDOWS_SYSROOT` explicitly.  This
variable controls CMake dependency searches; compiler wrappers retain their
own runtime search configuration.  Use matching runtime and C++ libraries
throughout each build.

For clang-cl, provide a locally installed LLVM toolchain and an SDK tree:

```sh
cmake -S CMake/tests/build_contexts -B build/context-clangcl -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE="$PWD/CMake/toolchains/windows-clang-cl.cmake" \
  -DBEXT_TOOLCHAIN_ROOT=/opt/llvm \
  -DBEXT_WINDOWS_SDK_ROOT=/opt/windows-sdk
cmake --build build/context-clangcl
```

The SDK tree must contain `Windows Kits/10/{Include,Lib}/<version>/` and
`VC/Tools/MSVC/<version>/{include,lib}/`.  Version selection defaults to the
highest installed version; pin it with `BEXT_WINDOWS_SDK_VERSION` and
`BEXT_WINDOWS_VC_VERSION`.  Supply SDK headers/libraries prepared for the
host filesystem's case sensitivity.  The profile does not download an SDK
or repair filename casing.  It forwards the SDK to both the compiler and
linker and supplies SDK include directories to resource compilation.

`BEXT_WINDOWS_ARCH` defaults to `x86_64`; `i686` is available for all profiles
and `aarch64` for the LLVM profiles.  Architectures and SDK combinations
still need validation with their actual runtimes.  Individual `CMAKE_*` tool
paths can override discovery.  With an explicit `BEXT_TOOLCHAIN_ROOT`, missing
tools are errors instead of falling back to another toolchain installation.
Developer-supplied CMake toolchain files remain supported.

Normal configuration checks executable linking.  For an object/archive-only
orchestration test without a complete SDK, additionally pass
`-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY`.  Do not use that setting to
claim a working Windows toolchain: it deliberately skips the link check.
