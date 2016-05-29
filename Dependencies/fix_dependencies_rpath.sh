#!/bin/sh
# Fixes the install names of the dependencies' dylibs. This should be executed
# every time any of them are re-built.

# fix libraw, and the libraries it depends on
install_name_tool LibRaw/lib/.libs/libraw_r.15.dylib -id @rpath/libraw_r.15.dylib

# fix LensFun, and the libraries it depends on
# adjust id; the @rpath-based name is completely wrong because the library filename is different than what CMake thinks it is
install_name_tool lensfun-code/cmake_build/libs/lensfun/liblensfun.0.3.2.dylib -id @rpath/liblensfun.0.3.2.dylib

install_name_tool lensfun-code/cmake_build/libs/lensfun/liblensfun.0.3.2.dylib -change /usr/local/opt/gettext/lib/libintl.8.dylib @rpath/libintl.8.dylib
install_name_tool lensfun-code/cmake_build/libs/lensfun/liblensfun.0.3.2.dylib -change /usr/local/opt/glib/lib/libglib-2.0.0.dylib @rpath/libglib-2.0.0.dylib

# gettext (libintl)
install_name_tool gettext-0.19.7/gettext-runtime/intl/.libs/libintl.8.dylib -id @rpath/libintl.8.dylib

# glib (provided binary copy)
install_name_tool libglib-2.0.0.dylib -id @rpath/libglib-2.0.0.dylib

install_name_tool libglib-2.0.0.dylib -change /usr/local/opt/gettext/lib/libintl.8.dylib @rpath/libintl.8.dylib
