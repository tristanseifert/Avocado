#!/bin/sh
# Fixes the install names of the dependencies' dylibs. This should be executed
# every time any of them are re-built.

# fix libraw, and the libraries it depends on
install_name_tool LibRaw/lib/.libs/libraw_r.15.dylib -id @executable_path/../Frameworks/libraw_r.15.dylib

install_name_tool LibRaw/lib/.libs/libraw_r.15.dylib -change /usr/local/lib/liblcms2.2.dylib @rpath/liblcms2.2.dylib

# fix LCMS2
install_name_tool lcms2-2.7/src/.libs/liblcms2.2.dylib -id @executable_path/../Frameworks/liblcms2.2.dylib