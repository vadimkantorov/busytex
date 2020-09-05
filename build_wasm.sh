export MAKEFLAGS=-j4

SUFFIX=wasm
EMMAKE=emmake
EMCMAKE=emcmake
EMCONFIGURE=emconfigure
EMDONOTREMAKE="-o ctangle -o otangle -o tangle -o tangleboot -o tie -o ctangleboot"

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
export EM_PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig

mkdir -p $PREFIX $PREFIX/bin
mkdir -p $BACKUP/texk $BACKUP/texk/web2c

wget --no-clobber $TEXLIVE_SOURCE_URL
#tar -xvf $(basename $TEXLIVE_SOURCE_URL)
cd $TEXLIVE_SOURCE_DIR

#mv texk/dviout-util texk/dvipsk texk/xdvik texk/dviljk texk/dvipos texk/dvidvi texk/dvipng texk/dvi2tty texk/dvisvgm texk/dtl texk/gregorio texk/upmendex texk/cjkutils texk/musixtnt texk/tests texk/ttf2pk2 texk/ttfdump texk/makejvf texk/lcdf-typetools $BACKUP/texk || true

mkdir -p texlive-build-$SUFFIX
cd texlive-build-$SUFFIX

#echo 'ac_cv_func_getwd=${ac_cv_func_getwd=no}' > $CACHE
#CFLAGS="-s ERROR_ON_UNDEFINED_SYMBOLS=0 -DELIDE_CODE -I$PREFIX/include -I$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/icu/include"
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
#  --with-banner-add="_BLFS" CFLAGS="$CFLAGS" CPPFLAGS="$CFLAGS"
#
#$EMMAKE make $MAKEFLAGS 
#$EMMAKE make $MAKEFLAGS install
#
#echo BEFORE LIBS
#for f in texk/dvipdfm-x libs/teckit libs/harfbuzz libs/graphite2 libs/libpng libs/zlib libs/pplib libs/icu libs/icu/include/unicode; do
#    pushd libs/$f
#    $EMMAKE make $MAKEFLAGS
#    popd
#done
#echo AFTER LIBS
#pushd libs/icu/icu-build
#mkdir -p bin stubdata lib
#cp --preserve=mode $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/bin/icupkg $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/bin/pkgdata bin/
#cp $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/stubdata/libicudata.a stubdata/
#pushd common
#$EMMAKE make $MAKEFLAGS #CXX="em++ -s ERROR_ON_UNDEFINED_SYMBOLS=0"
#popd
#pushd i18n
#$EMMAKE make $MAKEFLAGS #CXX="em++ -s ERROR_ON_UNDEFINED_SYMBOLS=0"
#popd
#echo "BEGIN FREETYPE"
#pushd libs/freetype2
#CC="python3 $ROOT/ccskip.py $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/freetype2/ft-build/apinames -- emcc"
#$EMMAKE make $MAKEFLAGS CC="$CC"
#popd
#echo "END FREETYPE"
#
#cd $ROOT
#wget --no-clobber $EXPAT_SOURCE_URL
#tar -xf $(basename $EXPAT_SOURCE_URL)
#mkdir -p $EXPAT_SOURCE_NAME/build-$SUFFIX
#cd $EXPAT_SOURCE_NAME/build-$SUFFIX
#$EMCMAKE cmake \
#    -DCMAKE_C_FLAGS="-s USE_PTHREADS=0 -s NO_FILESYSTEM=1 -s NO_EXIT_RUNTIME=1 -s MODULARIZE=1" \
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
#patch -d .. -Np1 -i $ROOT/0002-fix-fcstats-emscripten.patch 
#echo 'all install:' > ../test/Makefile.in
#FREETYPE_CFLAGS="-I$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/freetype2/ -I$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/freetype2/freetype2"
#FREETYPE_LIBS="-L$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/freetype2/ -lfreetype"
#EM_PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig $EMCONFIGURE ../configure \
#    --cache-file $ROOT/config-fontconfig-wasm.cache \
#    --prefix=$PREFIX \
#    --enable-static \
#    --disable-shared \
#    --disable-docs FREETYPE_CFLAGS="$FREETYPE_CFLAGS" FREETYPE_LIBS="$FREETYPE_LIBS" CFLAGS="-Duuid_generate_random=uuid_generate" 
#$EMMAKE make $MAKEFLAGS 
#$EMMAKE make $MAKEFLAGS install

cd $TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/texk/web2c
WEB2C_TOOLS_DIR=$TEXLIVE_SOURCE_DIR/texlive-build-native/texk/web2c
CC="python3 $ROOT/ccskip.py $WEB2C_TOOLS_DIR/ctangle $WEB2C_TOOLS_DIR/ctangleboot $WEB2C_TOOLS_DIR/web2c/fixwrites $WEB2C_TOOLS_DIR/web2c/splitup $WEB2C_TOOLS_DIR/tangle $WEB2C_TOOLS_DIR/tangleboot $WEB2C_TOOLS_DIR/tie $WEB2C_TOOLS_DIR/web2c/web2c $WEB2C_TOOLS_DIR/otangle $WEB2C_TOOLS_DIR/web2c/makecpool $WEB2C_TOOLS_DIR/xetex --"
$EMMAKE make $MAKEFLAGS xetex CC="$CC emcc" CXX="$CC em++"

em++ -g -O2 -o xetex xetexdir/xetex-xetexextra.o synctexdir/xetex-synctex.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o  libxetex.a /mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/harfbuzz/libharfbuzz.a /mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/graphite2/libgraphite2.a /mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/teckit/libTECkit.a /mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/libpng/libpng.a /mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/freetype2/libfreetype.a /mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/pplib/libpplib.a /mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/zlib/libz.a libmd5.a lib/lib.a /mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/texk/kpathsea/.libs/libkpathsea.a -s ERROR_ON_UNDEFINED_SYMBOLS=0 $PREFIX/lib/libfontconfig.a $PREFIX/lib/libexpat.a $TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/icu/icu-build/lib/libicuuc.a

#xetex_web2c_dir = $(XETEX_BUILD_DIR)texk/web2c/
#web2c_objs = $(addprefix $(xetex_web2c_dir), xetexdir/xetex-xetexextra.o synctexdir/xetex-synctex.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o)
#xetex_libs_dir = $(XETEX_BUILD_DIR)libs/
#xetex_libs = $(addprefix $(xetex_libs_dir), harfbuzz/libharfbuzz.a graphite2/libgraphite2.a icu/icu-build/lib/libicuuc.a icu/icu-build/lib/libicudata.a teckit/libTECkit.a poppler/libpoppler.a libpng/libpng.a)
#xetex_link = $(web2c_objs) $(LIB_FONTCONFIG) $(xetex_web2c_dir)libxetex.a $(xetex_libs) $(LIB_EXPAT) $(xetex_libs_dir)freetype2/libfreetype.a $(xetex_libs_dir)zlib/libz.a $(xetex_web2c_dir)lib/lib.a $(XETEX_BUILD_DIR)texk/kpathsea/.libs/libkpathsea.a -nodefaultlibs -Wl,-Bstatic -lstdc++ -Wl,-Bdynamic -lm -lgcc_eh -lgcc -lc -lgcc_eh -lgcc

# /mnt/c/Users/user/emsdk/upstream/emscripten/em++ -g -O2 -o xetex xetexdir/xetex-xetexextra.o synctexdir/xetex-synctex.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o  libxetex.a texlive-build-wasm/libs/harfbuzz/libharfbuzz.a /texlive-build-wasm/libs/graphite2/libgraphite2.a texlive-build-wasm/libs/teckit/libTECkit.a texlive-build-wasm/libs/libpng/libpng.a texlive-build-wasm/libs/freetype2/libfreetype.a texlive-build-wasm/libs/pplib/libpplib.a texlive-build-wasm/libs/zlib/libz.a libmd5.a lib/lib.a texlive-build-wasm/texk/kpathsea/.libs/libkpathsea.a


# em++ $(EM_LINK_FLAGS) $(EM_LINK_OPT_WORKAROUND_FLAGS) --pre-js xetex.pre.js -o $@ $(xetex_link) -s TOTAL_MEMORY=536870912 -s EXPORTED_RUNTIME_METHODS=[] -s ERROR_ON_UNDEFINED_SYMBOLS=0 -s WASM=0

#for f in ctangle otangle tangle tangleboot tie ctangleboot; do cp --preserve=mode $TEXLIVE_SOURCE_DIR/texlive-build-native/texk/web2c/$f  $TEXLIVE_SOURCE_DIR/texlive-build-wasm/texk/web2c/; done
#for f in fixwrites makecpool splitup web2c; do cp --preserve=mode $TEXLIVE_SOURCE_DIR/texlive-build-native/texk/web2c/web2c/$f  $TEXLIVE_SOURCE_DIR/texlive-build-wasm/texk/web2c/web2c/; done
#$EMMAKE make $MAKEFLAGS $EMDONOTREMAKE xetex
#
#CXX="em++ -s ERROR_ON_UNDEFINED_SYMBOLS=0 $PREFIX/lib/libfontconfig.a $PREFIX/lib/libexpat.a $TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/icu/icu-build/lib/libicuuc.a"
#for f in ctangle otangle tangle tangleboot tie ctangleboot; do cp --preserve=mode $TEXLIVE_SOURCE_DIR/texlive-build-native/texk/web2c/$f  $TEXLIVE_SOURCE_DIR/texlive-build-wasm/texk/web2c/; done
#for f in fixwrites makecpool splitup web2c; do cp --preserve=mode $TEXLIVE_SOURCE_DIR/texlive-build-native/texk/web2c/web2c/$f  $TEXLIVE_SOURCE_DIR/texlive-build-wasm/texk/web2c/web2c/; done
#$EMMAKE make $MAKEFLAGS $EMDONOTREMAKE xetex CXX="$CXX"
