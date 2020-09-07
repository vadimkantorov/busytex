export MAKEFLAGS=-j4

SUFFIX=wasm
EMMAKE=emmake
EMCMAKE=emcmake
EMCONFIGURE=emconfigure

ROOT=$PWD

EXPAT_SOURCE_URL=https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
EXPAT_SOURCE_NAME=$(basename $EXPAT_SOURCE_URL .tar.gz)
EXPAT_SOURCE_DIR=$ROOT/$EXPAT_SOURCE_NAME
EXPAT_BUILD_DIR=$EXPAT_SOURCE_DIR/build-$SUFFIX

FONTCONFIG_SOURCE_URL=https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.gz
FONTCONFIG_SOURCE_NAME=$(basename $FONTCONFIG_SOURCE_URL .tar.gz)
FONTCONFIG_SOURCE_DIR=$ROOT/$FONTCONFIG_SOURCE_NAME
FONTCONFIG_BUILD_DIR=$ROOT/$FONTCONFIG_SOURCE_NAME/build-$SUFFIX
FONTCONFIG_CACHE=$ROOT/config-$SUFFIX-fontconfig.cache

TEXLIVE_SOURCE_URL=https://github.com/TeX-Live/texlive-source/archive/9ed922e7d25e41b066f9e6c973581a4e61ac0328.tar.gz
TEXLIVE_SOURCE_NAME=texlive-source-$(basename $TEXLIVE_SOURCE_URL .tar.gz)
TEXLIVE_SOURCE_DIR=$ROOT/$TEXLIVE_SOURCE_NAME
TEXLIVE_BUILD_DIR=$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX

BACKUP=$ROOT/texlive-backup
PREFIX=$ROOT/prefix-$SUFFIX
CACHE=$ROOT/config-$SUFFIX.cache
XELATEX_EXE=$PREFIX/bin/xelatex
XETEX_EXE=$PREFIX/bin/xetex
#export EM_PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

mkdir -p $PREFIX $PREFIX/bin
mkdir -p $BACKUP/texk $BACKUP/texk/web2c

wget --no-clobber $TEXLIVE_SOURCE_URL
#tar -xvf $(basename $TEXLIVE_SOURCE_URL)
cd $TEXLIVE_SOURCE_DIR

#mv texk/dviout-util texk/dvipsk texk/xdvik texk/dviljk texk/dvipos texk/dvidvi texk/dvipng texk/dvi2tty texk/dvisvgm texk/dtl texk/gregorio texk/upmendex texk/cjkutils texk/musixtnt texk/tests texk/ttf2pk2 texk/ttfdump texk/makejvf texk/lcdf-typetools $BACKUP/texk || true

mkdir -p texlive-build-$SUFFIX
cd texlive-build-$SUFFIX

echo 'ac_cv_func_getwd=${ac_cv_func_getwd=no}' > $CACHE
echo > $FONTCONFIG_CACHE

EMCCFLAGS="-s ERROR_ON_UNDEFINED_SYMBOLS=0 -DELIDE_CODE"
CFLAGS="$EMCCFLAGS -I$PREFIX/include -I$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/icu/include -I$FONTCONFIG_SOURCE_DIR"
$EMCONFIGURE ../configure                                    \
  --cache-file=$CACHE                           \
  --prefix=$PREFIX                              \
  --enable-dump-share                           \
  --enable-static                               \
  --enable-xetex                                \
  --enable-dvipdfm-x                            \
  --enable-icu                                  \
  --enable-freetype2                            \
  --disable-shared                              \
  --disable-multiplatform                       \
  --disable-native-texlive-build                \
  --disable-all-pkgs                            \
  --without-x                                   \
  --without-system-cairo                        \
  --without-system-gmp                          \
  --without-system-graphite2                    \
  --without-system-harfbuzz                     \
  --without-system-libgs                        \
  --without-system-libpaper                     \
  --without-system-mpfr                         \
  --without-system-pixman                       \
  --without-system-poppler                      \
  --without-system-xpdf                         \
  --without-system-icu                          \
  --without-system-fontconfig                   \
  --without-system-freetype2                    \
  --without-system-libpng                       \
  --without-system-zlib                         \
  --with-fontconfig-includes="$ROOT/$FONTCONFIG_SOURCE_NAME"                         \
  --with-fontconfig-libdir="$ROOT/$FONTCONFIG_SOURCE_NAME/build-$SUFFIX/src/.libs"   \
  --with-banner-add="_BLFS" CFLAGS="$CFLAGS" CPPFLAGS="$CFLAGS"

$EMMAKE make $MAKEFLAGS 
$EMMAKE make $MAKEFLAGS install

for d in texk/dvipdfm-x libs/teckit libs/harfbuzz libs/graphite2 libs/libpng libs/zlib libs/pplib libs/icu libs/icu/include/unicode; do
    pushd $d
    $EMMAKE make $MAKEFLAGS
    popd
done

pushd libs/freetype2
CC="python3 $ROOT/ccskip.py $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/freetype2/ft-build/apinames --"
$EMMAKE make $MAKEFLAGS CC="$CC emcc"
popd

pushd libs/icu/icu-build
#CXX="em++ -s ERROR_ON_UNDEFINED_SYMBOLS=0"
mkdir -p bin stubdata lib
cp $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/stubdata/libicudata.a $TEXLIVE_BUILD_DIR/libs/icu/icu-build/stubdata/
cp --preserve=mode $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/bin/icupkg $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/bin/pkgdata $TEXLIVE_BUILD_DIR/libs/icu/icu-build/bin/
pushd common
$EMMAKE make $MAKEFLAGS 
popd
pushd i18n
$EMMAKE make $MAKEFLAGS
popd

cd $ROOT
wget --no-clobber $EXPAT_SOURCE_URL
tar -xf $(basename $EXPAT_SOURCE_URL)
mkdir -p $EXPAT_BUILD_DIR
cd $EXPAT_BUILD_DIR
$EMCMAKE cmake \
    -DCMAKE_C_FLAGS="-s USE_PTHREADS=0 -s NO_FILESYSTEM=1 -s NO_EXIT_RUNTIME=1 -s MODULARIZE=1" \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DEXPAT_BUILD_DOCS=off \
    -DEXPAT_SHARED_LIBS=off \
    -DEXPAT_BUILD_EXAMPLES=off \
    -DEXPAT_BUILD_FUZZERS=off \
    -DEXPAT_BUILD_TESTS=off \
    -DEXPAT_BUILD_TOOLS=off \
    .. 
$EMMAKE make $MAKEFLAGS 

echo > $FONTCONFIG_CACHE
cd $ROOT
wget --no-clobber $FONTCONFIG_SOURCE_URL
tar -xf $(basename $FONTCONFIG_SOURCE_URL)
mkdir -p $FONTCONFIG_BUILD_DIR
cd $FONTCONFIG_BUILD_DIR
patch -d .. -Np1 -i $ROOT/0002-fix-fcstats-emscripten.patch 
echo 'all install:' > ../test/Makefile.in
FREETYPE_CFLAGS="-I$TEXLIVE_BUILD_DIR/libs/freetype2/ -I$TEXLIVE_BUILD_DIR/libs/freetype2/freetype2"
FREETYPE_LIBS="-L$TEXLIVE_BUILD_DIR/libs/freetype2/ -lfreetype"
EM_PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig $EMCONFIGURE ../configure \
    --cache-file $FONTCONFIG_CACHE \
    --prefix=$PREFIX \
    --enable-static \
    --disable-shared \
    --disable-docs CFLAGS="-Duuid_generate_random=uuid_generate" \
    --with-expat-includes="$EXPAT_SOURCE_DIR/lib" --with-expat-lib="$EXPAT_BUILD_DIR" FREETYPE_CFLAGS="$FREETYPE_CFLAGS" FREETYPE_LIBS="$FREETYPE_LIBS" 
$EMMAKE make $MAKEFLAGS 

cd $TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/texk/web2c
WEB2C_TOOLS_DIR=$TEXLIVE_SOURCE_DIR/texlive-build-native/texk/web2c
CC="python3 $ROOT/ccskip.py $WEB2C_TOOLS_DIR/ctangle $WEB2C_TOOLS_DIR/ctangleboot $WEB2C_TOOLS_DIR/web2c/fixwrites $WEB2C_TOOLS_DIR/web2c/splitup $WEB2C_TOOLS_DIR/tangle $WEB2C_TOOLS_DIR/tangleboot $WEB2C_TOOLS_DIR/tie $WEB2C_TOOLS_DIR/web2c/web2c $WEB2C_TOOLS_DIR/otangle $WEB2C_TOOLS_DIR/web2c/makecpool $WEB2C_TOOLS_DIR/xetex --"
$EMMAKE make $MAKEFLAGS xetex CC="$CC emcc" CXX="$CC em++"

em++ -g -O2 -o xetex xetexdir/xetex-xetexextra.o synctexdir/xetex-synctex.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o  libxetex.a $TEXLIVE_BUILD_DIR/libs/harfbuzz/libharfbuzz.a $TEXLIVE_BUILD_DIR/libs/graphite2/libgraphite2.a $TEXLIVE_BUILD_DIR/libs/teckit/libTECkit.a $TEXLIVE_BUILD_DIR/libs/libpng/libpng.a $TEXLIVE_BUILD_DIR/libs/freetype2/libfreetype.a $TEXLIVE_BUILD_DIR/libs/pplib/libpplib.a $TEXLIVE_BUILD_DIR/libs/zlib/libz.a libmd5.a lib/lib.a $TEXLIVE_BUILD_DIR/texk/kpathsea/.libs/libkpathsea.a $FONTCONFIG_BUILD_DIR/src/.libs/libfontconfig.a $EXPAT_BUILD_DIR/libexpat.a $TEXLIVE_BUILD_DIR/libs/icu/icu-build/lib/libicuuc.a -s ERROR_ON_UNDEFINED_SYMBOLS=0

#$PREFIX/lib/libfontconfig.a
