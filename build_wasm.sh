export MAKEFLAGS=-j8

SUFFIX=wasm
EMMAKE=emmake
EMCMAKE=emcmake
EMCONFIGURE=emconfigure
EMDONOTREMAKE="-o ctangle -o otangle -o tangle -o tangleboot -o tie -o ctangleboot"

FONTCONFIG_SOURCE_URL=https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.gz
FONTCONFIG_SOURCE_NAME=$(basename $FONTCONFIG_SOURCE_URL .tar.gz)

EXPAT_SOURCE_URL=https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
EXPAT_SOURCE_NAME=$(basename $EXPAT_SOURCE_URL .tar.gz)

TEXLIVE_TEXMF_URL=ftp://tug.org/texlive/historic/2020/texlive-20200406-texmf.tar.xz 
TEXLIVE_TLPDB_URL=ftp://tug.org/texlive/historic/2020/texlive-20200406-tlpdb-full.tar.gz
TEXLIVE_BASE_URL=http://mirrors.ctan.org/macros/latex/base.zip
TEXLIVE_INSTALLER_URL=http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
TEXLIVE_BASE_NAME=$(basename $TEXLIVE_BASE_URL .zip)
export TEXMFDIST=$PWD/texlive/texmf-dist

TEXLIVE_SOURCE_URL=https://github.com/TeX-Live/texlive-source/archive/9ed922e7d25e41b066f9e6c973581a4e61ac0328.tar.gz
TEXLIVE_SOURCE_NAME=texlive-source-$(basename $TEXLIVE_SOURCE_URL .tar.gz)
TEXLIVE_SOURCE_DIR=$PWD/$TEXLIVE_SOURCE_NAME

ROOT=$PWD
BACKUP=$PWD/texlive-backup
TEXLIVE=$PWD/texlive
PREFIX=$PWD/prefix-$SUFFIX
CACHE=$PWD/config-$SUFFIX.cache
XELATEX_EXE=$PREFIX/bin/xelatex
XETEX_EXE=$PREFIX/bin/xetex
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

mkdir -p $PREFIX $PREFIX/bin
mkdir -p $BACKUP/texk $BACKUP/texk/web2c

wget --no-clobber $TEXLIVE_SOURCE_URL
tar -xvf $(basename $TEXLIVE_SOURCE_URL)
cd $TEXLIVE_SOURCE_DIR

mv texk/dviout-util texk/dvipsk texk/xdvik texk/dviljk texk/dvipos texk/dvidvi texk/dvipng texk/dvi2tty texk/dvisvgm texk/dtl texk/gregorio texk/upmendex texk/cjkutils texk/musixtnt texk/tests texk/ttf2pk2 texk/ttfdump texk/makejvf texk/lcdf-typetools $BACKUP/texk || true

mkdir -p texlive-build-$SUFFIX
cd texlive-build-$SUFFIX

echo 'ac_cv_func_getwd=${ac_cv_func_getwd=no}' > $CACHE

CFLAGS="-s ERROR_ON_UNDEFINED_SYMBOLS=0 -DELIDE_CODE -I$PREFIX/include"
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
  --with-fontconfig-includes=$ROOT/$FONTCONFIG_SOURCE_NAME        \
  --with-fontconfig-libdir="$PREFIX/lib"                          \
  --with-banner-add="_BLFS" CFLAGS="$CFLAGS"

$EMMAKE make $MAKEFLAGS CFLAGS="$CFLAGS"
$EMMAKE make $MAKEFLAGS CFLAGS="$CFLAGS" install

pushd libs/icu/include/unicode
$EMMAKE make $MAKEFLAGS CFLAGS="$CFLAGS"
popd

pushd texk/dvipdfm-x
$EMMAKE make $MAKEFLAGS CFLAGS="$CFLAGS"
popd

pushd libs/freetype2
$EMMAKE make $MAKEFLAGS CFLAGS="$CFLAGS"
cp --preserve=mode $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/freetype2/ft-build/apinames $TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/freetype2/ft-build
$EMMAKE make $MAKEFLAGS CFLAGS="$CFLAGS"
popd

pushd libs
$EMMAKE make $MAKEFLAGS CFLAGS="$CFLAGS"
popd

cd $ROOT
wget --no-clobber $EXPAT_SOURCE_URL
tar -xf $(basename $EXPAT_SOURCE_URL)
mkdir $EXPAT_SOURCE_NAME/build-$SUFFIX
cd $EXPAT_SOURCE_NAME/build-$SUFFIX
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
$EMMAKE make $MAKEFLAGS install

cd $ROOT
wget --no-clobber $FONTCONFIG_SOURCE_URL
tar -xf $(basename $FONTCONFIG_SOURCE_URL)
mkdir -p $FONTCONFIG_SOURCE_NAME/build-$SUFFIX
cd $FONTCONFIG_SOURCE_NAME/build-$SUFFIX 
patch -d .. -Np1 -i $ROOT/0002-fix-fcstats-emscripten.patch 
echo 'all install:' > ../test/Makefile.in
FREETYPE_CFLAGS="-I$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/freetype2/ -I$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/freetype2/freetype2"
FREETYPE_LIBS="-L$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/freetype2/ -lfreetype"
EM_PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig EMCONFIGURE_JS=2 CFLAGS=-Duuid_generate_random=uuid_generate FREETYPE_CFLAGS="$FREETYPE_CFLAGS" FREETYPE_LIBS="$FREETYPE_LIBS" $EMCONFIGURE ../configure \
    --cache-file $ROOT/config-fontconfig-wasm.cache \
    --prefix=$PREFIX \
    --enable-static \
    --disable-shared \
    --disable-docs 
$EMMAKE make $MAKEFLAGS 
$EMMAKE make $MAKEFLAGS install



cd $TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/texk/web2c
for f in ctangle otangle tangle tangleboot tie ctangleboot; do
    cp --preserve=mode $TEXLIVE_SOURCE_DIR/texlive-build-native/texk/web2c/$f  $TEXLIVE_SOURCE_DIR/texlive-build-wasm/texk/web2c/
done
for f in fixwrites makecpool splitup web2c; do
    cp --preserve=mode $TEXLIVE_SOURCE_DIR/texlive-build-native/texk/web2c/web2c/$f  $TEXLIVE_SOURCE_DIR/texlive-build-wasm/texk/web2c/web2c/
done

$EMMAKE make $MAKEFLAGS $EMDONOTREMAKE xetex
$EMMAKE make $MAKEFLAGS $EMDONOTREMAKE install
