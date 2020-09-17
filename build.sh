set -e

export MAKEFLAGS=-j8

make source/texlive
make source/texlive.patched

make build/native/texlive.configured
make build/native/texlive/libs/libpng/libpng.a 
make build/native/texlive/libs/libpaper/libpaper.a 
make build/native/texlive/libs/zlib/libz.a 
make build/native/texlive/libs/teckit/libTECkit.a 
make build/native/texlive/libs/harfbuzz/libharfbuzz.a 
make build/native/texlive/libs/graphite2/libgraphite2.a 
make build/native/texlive/libs/pplib/libpplib.a 
make build/native/texlive/libs/freetype2/libfreetype.a 
make build/native/texlive/libs/icu/icu-build/lib/libicuuc.a 
make build/native/texlive/libs/icu/icu-build/lib/libicudata.a
make build/native/texlive/libs/icu/icu-build/bin/icupkg 
make build/native/texlive/libs/icu/icu-build/bin/pkgdata 
make build/native/expat/libexpat.a
make build/native/fontconfig/libfontconfig.a 
make build/native/texlive/texk/dvipdfm-x/xdvipdfmx 
make build/native/texlive/texk/bibtex-x/bibtexu 
make build/native/texlive/texk/web2c/xetex

#make build/wasm/texlive/configured
#make build/wasm/texlive/libs/libpng/libpng.a 
#make build/wasm/texlive/libs/libpaper/libpaper.a 
#make build/wasm/texlive/libs/zlib/libz.a 
#make build/wasm/texlive/libs/teckit/libTECkit.a 
#make build/wasm/texlive/libs/harfbuzz/libharfbuzz.a 
#make build/wasm/texlive/libs/graphite2/libgraphite2.a 
#make build/wasm/texlive/libs/pplib/libpplib.a 
#make build/wasm/texlive/libs/freetype2/libfreetype.a 
#make build/wasm/texlive/libs/icu/icu-build/lib/libicuuc.a 
#make build/wasm/texlive/libs/icu/icu-build/lib/libicudata.a
#make build/wasm/expat/libexpat.a
#make build/wasm/fontconfig/libfontconfig.a 
#make build/wasm/texlive/texk/dvipdfm-x/xdvipdfmx 
#make build/wasm/texlive/texk/bibtex-x/bibtexu 
#make build/wasm/texlive/texk/web2c/xetex
