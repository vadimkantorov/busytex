export MAKEFLAGS=-j20

SUFFIX=native
EMMAKE=
EMCMAKE=
EMCONFIGURE=
EMDONOTEREMAKE=

FONTCONFIG_SOURCE_URL=https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.gz
FONTCONFIG_SOURCE_NAME=$(basename $FONTCONFIG_SOURCE_URL .tar.gz)

EXPAT_SOURCE_URL=https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
EXPAT_SOURCE_NAME=$(basename $EXPAT_SOURCE_URL .tar.gz)

TEXLIVE_TEXMF_URL=ftp://tug.org/texlive/historic/2020/texlive-20200406-texmf.tar.xz 
TEXLIVE_TLPDB_URL=ftp://tug.org/texlive/historic/2020/texlive-20200406-tlpdb-full.tar.gz
TEXLIVE_BASE_URL=http://mirrors.ctan.org/macros/latex/base.zip
TEXLIVE_INSTALLER_URL=http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz

TEXLIVE_SOURCE_URL=https://github.com/TeX-Live/texlive-source/archive/9ed922e7d25e41b066f9e6c973581a4e61ac0328.tar.gz
TEXLIVE_SOURCE_NAME=$(basename $TEXLIVE_SOURCE_URL)
TEXLIVE_SOURCE_NAME=${TEXLIVE_SOURCE_NAME%%.*}
TEXLIVE_SOURCE_NAME=texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328
TEXLIVE_SOURCE_DIR=$PWD/$TEXLIVE_SOURCE_NAME

ROOT=$PWD
BACKUP=$PWD/texlive-backup
TEXLIVE=$PWD/texlive
PREFIX=$PWD/prefix-$SUFFIX
CACHE=$PWD/config-$SUFFIX.cache
XELATEX_EXE=$PREFIX/bin/xelatex
XETEX_EXE=$PREFIX/bin/xetex
mkdir -p $PREFIX
mkdir -p $BACKUP/texk $BACKUP/texk/web2c

wget --no-clobber $TEXLIVE_SOURCE_URL
tar -xvf $(basename $TEXLIVE_SOURCE_URL)
cd $TEXLIVE_SOURCE_DIR

mv texk/dviout-util texk/dvipsk texk/xdvik texk/dviljk texk/dvipos texk/dvidvi texk/dvipng texk/dvi2tty texk/dvisvgm texk/dtl texk/gregorio texk/upmendex texk/cjkutils texk/musixtnt texk/tests texk/ttf2pk2 texk/ttfdump texk/makejvf texk/lcdf-typetools $BACKUP/texk || true
#mv texk/web2c/luatexdir texk/web2c/mfluadir texk/web2c/mfluajitdir $BACKUP/texk/web2c || true

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

exit 0

cd $ROOT
wget --no-clobber $EXPAT_SOURCE_URL
tar -xf $(basename $EXPAT_SOURCE_URL)
mkdir $EXPAT_SOURCE_NAME/build-$SUFFIX
cd $EXPAT_SOURCE_NAME/build-$SUFFIX
$EMCMAKE cmake \
    -DCMAKE_C_FLAGS="-O3 --llvm-lto 1" \
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

emmake make $MAKEFLAGS $EMDONOTREMAKE xetex
