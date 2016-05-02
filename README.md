# Avocado
A native OS X Lightroom alternative, with support for RAW file processing via `LibRaw.`

## Building
The app can be built as normally via Xcode. All dependencies (installed via CocoaPods, and git submodules) must be installed beforehand, however. Several dependencies must also be built, in the following order:

### LibRaw
Execute `./configure --disable-lcms --disable-openmp --disable-static` followed by `make all` in the LibRaw directory. The library is automagically built, and Xcode will link with the dylib.

Note that the `--disable-lcms` flag will disable colour management support in LibRaw; this is not a problem, since we do our own colour management using Cocoa APIs, but this means that all RGB data coming out of LibRaw will be in the sensor colour space.

### gettext
This library is needed as a dependency for Lensfun, as OS X does not ship with gettext by default; as thus, it must be built before Lensfun. To build, change into the directory, then run `./configure --disable-java --disable-native-java --disable-curses --disable-libasprintf --disable-openmp --enable-rpath` followed by `make.`

You will need to acquire the gettext source separately, and place it into the Dependencies folder. gettext-0.19.7 is the version used.

# glib
Building glib is a pain in the arse, as many different conditions must be met before it will build. Set the following environment variables, before invoking any commands:

```
# LibFFI: the include path _may_ need to be changed, depending on the current SDK
export LIBFFI_CFLAGS="-I/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk/usr/include/ffi"
export LIBFFI_LIBS="-lffi"

# gettext: adjust the include path as needed, knowing it must be absolute.
export CFLAGS="-I/Users/tristan/Photography/Avocado/Dependencies/gettext-0.19.7/gettext-runtime/intl/"
export CPPFLAGS="-I/Users/tristan/Photography/Avocado/Dependencies/gettext-0.19.7/gettext-runtime/intl/"
export CXXFLAGS="-I/Users/tristan/Photography/Avocado/Dependencies/gettext-0.19.7/gettext-runtime/intl/"
export LDFLAGS="-L/Users/tristan/Photography/Avocado/Dependencies/gettext-0.19.7/gettext-runtime/intl/.libs/"

# gettext tools: add them to the path; again, adjust the path, knowing it must be absolute.
export PATH=$PATH:/Users/tristan/Photography/Avocado/Dependencies/gettext-0.19.7/gettext-tools/src
```

Then, to actually build glib, execute the following sequence of commands:

```
./autogen.sh --disable-dtrace --disable-fam --disable-libelf --disable-xattr --disable-man --disable-gtk-doc
```

### Lensfun
Create a directory named cmake_build, change into it, then execute `cmake ..` to create Makefiles. Build as you normally would. The CMakeList file may need to be patched to use `@rpath` for the install name, and to modify the library search path to use our copy of gettext and glib — see the `lensfun-patches` directory.

### After all dependencies
Do not forget to execute the `fix_dependencies_rpath.sh` script in the Dependencies folder, after compiling and building any dependencies. This will fix up paths in these libraries so that they can be properly linked, and will not cause a dylib error at runtime.

## Licensing
Avocado is released under the terms of the simplified three-clause BSD license, as reproduced below:

Copyright (c) 2016, Tristan Seifert
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
