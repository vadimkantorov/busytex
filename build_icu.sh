ROOT=$PWD
TEXLIVE_SOURCE_DIR=$ROOT/texlive-source-*
TEXLIVE_BUILD_DIR=$TEXLIVE_SOURCE_DIR/texlive-build-wasm
TEXLIVE_BUILD_DIR_NATIVE=$TEXLIVE_SOURCE_DIR/texlive-build-native
MAKEFLAGS=-j8
EMCONFIGURE=emconfigure
EMMAKE=emmake

EMCCSKIP_ICU="python3 $ROOT/ccskip.py $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/bin/icupkg $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/bin/pkgdata --"

CFLAGS="-s ERROR_ON_UNDEFINED_SYMBOLS=0"

pushd $TEXLIVE_BUILD_DIR/libs/icu

$EMCONFIGURE $TEXLIVE_SOURCE_DIR/libs/icu/configure CC="$EMCCSKIP_ICU emcc $CFLAGS" CXX="$EMCCSKIP_ICU em++ $CFLAGS"
#echo "all install: " > $TEXLIVE_BUILD_DIR/libs/icu/icu-build/test/Makefile

#exit 1
NATIVE_ICUPKG_INC="$TEXLIVE_BUILD_DIR_NATIVE/libs/icu/icu-build/data/icupkg.inc"
WASM_ICUPKG_INC="$TEXLIVE_BUILD_DIR/libs/icu/icu-build/data/icupkg.inc"
$EMMAKE make $MAKEFLAGS -e PKGDATA_OPTS="--without-assembly -O $WASM_ICUPKG_INC" -e CC="$EMCCSKIP_ICU emcc $CFLAGS" -e CXX="$EMCCSKIP_ICU em++ $CFLAGS"

exit 1
pushd /icu-build
$EMMAKE make $MAKEFLAGS 

popd


#mkdir -p bin stubdata lib
#cp --preserve=mode  $TEXLIVE_BUILD_DIR/libs/icu/icu-build/bin/
#cp $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/stubdata/libicudata.a $TEXLIVE_BUILD_DIR/libs/icu/icu-build/stubdata/
