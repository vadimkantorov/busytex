export MAKEFLAGS=-j8

SUFFIX=native
EMMAKE=
EMCMAKE=
EMCONFIGURE=
EMDONOTEREMAKE=

EXPAT_SOURCE_URL=https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
EXPAT_SOURCE_NAME=$(basename $EXPAT_SOURCE_URL .tar.gz)

FONTCONFIG_SOURCE_URL=https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.gz
FONTCONFIG_SOURCE_NAME=$(basename $FONTCONFIG_SOURCE_URL .tar.gz)

TEXLIVE_SOURCE_URL=https://github.com/TeX-Live/texlive-source/archive/9ed922e7d25e41b066f9e6c973581a4e61ac0328.tar.gz
TEXLIVE_SOURCE_NAME=texlive-source-$(basename $TEXLIVE_SOURCE_URL .tar.gz)
TEXLIVE_SOURCE_DIR=$PWD/$TEXLIVE_SOURCE_NAME

ROOT=$PWD
BACKUP=$PWD/texlive-backup
PREFIX=$PWD/prefix-$SUFFIX
CACHE=$PWD/config-$SUFFIX.cache
XELATEX_EXE=$PREFIX/bin/xelatex
XETEX_EXE=$PREFIX/bin/xetex

export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

mkdir -p $PREFIX $PREFIX/bin
mkdir -p $BACKUP/texk $BACKUP/texk/web2c

wget --no-clobber $TEXLIVE_SOURCE_URL
#tar -xvf $(basename $TEXLIVE_SOURCE_URL)
cd $TEXLIVE_SOURCE_DIR

mv texk/dviout-util texk/dvipsk texk/xdvik texk/dviljk texk/dvipos texk/dvidvi texk/dvipng texk/dvi2tty texk/dvisvgm texk/dtl texk/gregorio texk/upmendex texk/cjkutils texk/musixtnt texk/tests texk/ttf2pk2 texk/ttfdump texk/makejvf texk/lcdf-typetools $BACKUP/texk || true

mkdir -p texlive-build-$SUFFIX
cd texlive-build-$SUFFIX

#echo 'ac_cv_func_getwd=${ac_cv_func_getwd=no}' > $CACHE
#CFLAGS="-I$PREFIX/include"
#$EMCONFIGURE ../configure                                    \
#  --cache-file=$CACHE                           \
#  --prefix=$PREFIX                              \
#  --enable-dump-share                           \
#  --enable-static                               \
#  --enable-xetex                                \
#  --enable-dvipdfm-x                            \
#  --enable-icu                                  \
#  --enable-freetype2                            \
#  --disable-shared                              \
#  --disable-multiplatform                       \
#  --disable-native-texlive-build                \
#  --disable-all-pkgs                            \
#  --without-x                                   \
#  --without-system-cairo                        \
#  --without-system-gmp                          \
#  --without-system-graphite2                    \
#  --without-system-harfbuzz                     \
#  --without-system-libgs                        \
#  --without-system-libpaper                     \
#  --without-system-mpfr                         \
#  --without-system-pixman                       \
#  --without-system-poppler                      \
#  --without-system-xpdf                         \
#  --without-system-icu                          \
#  --without-system-fontconfig                   \
#  --without-system-freetype2                    \
#  --without-system-libpng                       \
#  --without-system-zlib                         \
#  --with-fontconfig-includes=$ROOT/$FONTCONFIG_SOURCE_NAME        \
#  --with-fontconfig-libdir="$PREFIX/lib"                          \
#  --with-banner-add="_BLFS" CFLAGS="$CFLAGS"
#
#$EMMAKE make $MAKEFLAGS
#$EMMAKE make $MAKEFLAGS install
#
#pushd libs/icu/include/unicode
#$EMMAKE make $MAKEFLAGS
#popd
#
#pushd texk/dvipdfm-x
#$EMMAKE make $MAKEFLAGS
#popd
#
#pushd libs/freetype2
#$EMMAKE make $MAKEFLAGS
#popd
#
#cd $ROOT
#wget --no-clobber $EXPAT_SOURCE_URL
#tar -xf $(basename $EXPAT_SOURCE_URL)
#mkdir -p $EXPAT_SOURCE_NAME/build-$SUFFIX
#cd $EXPAT_SOURCE_NAME/build-$SUFFIX
#$EMCMAKE cmake \
#    -DCMAKE_INSTALL_PREFIX=$PREFIX \
#    -DEXPAT_BUILD_DOCS=off \
#    -DEXPAT_SHARED_LIBS=off \
#    -DEXPAT_BUILD_EXAMPLES=off \
#    -DEXPAT_BUILD_FUZZERS=off \
#    -DEXPAT_BUILD_TESTS=off \
#    -DEXPAT_BUILD_TOOLS=off \
#    .. 
#$EMMAKE make $MAKEFLAGS 
#$EMMAKE make $MAKEFLAGS install
#
#cd $ROOT
#wget --no-clobber $FONTCONFIG_SOURCE_URL
#tar -xf $(basename $FONTCONFIG_SOURCE_URL)
#mkdir -p $FONTCONFIG_SOURCE_NAME/build-$SUFFIX
#cd $FONTCONFIG_SOURCE_NAME/build-$SUFFIX
#echo 'all install:' > ../test/Makefile.in
#FREETYPE_CFLAGS="-I$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/freetype2/ -I$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/freetype2/freetype2"
#FREETYPE_LIBS="-L$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/freetype2/ -lfreetype"
#CFLAGS=-Duuid_generate_random=uuid_generate FREETYPE_CFLAGS="$FREETYPE_CFLAGS" FREETYPE_LIBS="$FREETYPE_LIBS" $EMCONFIGURE ../configure \
#    --cache-file $ROOT/config-fontconfig-wasm.cache \
#    --prefix=$PREFIX \
#    --enable-static \
#    --disable-shared \
#    --disable-docs 
#$EMMAKE make $MAKEFLAGS 
#$EMMAKE make $MAKEFLAGS install
#
#cd $TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/texk/web2c
#
#$EMMAKE make $MAKEFLAGS $EMDONOTREMAKE xetex
#cp xetex $XETEX_EXE
#cp $XETEX_EXE $XELATEX_EXE
