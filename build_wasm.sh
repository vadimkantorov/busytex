export MAKEFLAGS=-j4

SUFFIX=wasm

ROOT=$PWD

EXPAT_SOURCE_URL=https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
EXPAT_SOURCE_NAME=$(basename $EXPAT_SOURCE_URL .tar.gz)
EXPAT_SOURCE_DIR=$ROOT/$EXPAT_SOURCE_NAME
EXPAT_BUILD_DIR=$EXPAT_SOURCE_DIR/build-$SUFFIX

FONTCONFIG_SOURCE_URL=https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.gz
FONTCONFIG_SOURCE_NAME=$(basename $FONTCONFIG_SOURCE_URL .tar.gz)
FONTCONFIG_SOURCE_DIR=$ROOT/$FONTCONFIG_SOURCE_NAME
FONTCONFIG_BUILD_DIR=$FONTCONFIG_SOURCE_DIR/build-$SUFFIX
FONTCONFIG_CACHE=$ROOT/config-$SUFFIX-fontconfig.cache

TEXLIVE_SOURCE_URL=https://github.com/TeX-Live/texlive-source/archive/9ed922e7d25e41b066f9e6c973581a4e61ac0328.tar.gz
TEXLIVE_SOURCE_NAME=texlive-source-$(basename $TEXLIVE_SOURCE_URL .tar.gz)
TEXLIVE_SOURCE_DIR=$ROOT/$TEXLIVE_SOURCE_NAME
TEXLIVE_BUILD_DIR=$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX
WEB2C_NATIVE_TOOLS_DIR=$TEXLIVE_SOURCE_DIR/texlive-build-native/texk/web2c

BACKUP=$ROOT/texlive-backup
PREFIX=$ROOT/prefix-$SUFFIX
TEXLIVE_CACHE=$ROOT/config-$SUFFIX.cache
XELATEX_EXE=$PREFIX/bin/xelatex
XETEX_EXE=$PREFIX/bin/xetex

EMROOT=$(dirname $(which emcc))
EMMAKE=emmake
EMCMAKE=emcmake
EMCONFIGURE=emconfigure
EMCCSKIP_FREETYPE="python3 $ROOT/ccskip.py $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/freetype2/ft-build/apinames --"
EMCCSKIP_XETEX="python3 $ROOT/ccskip.py $WEB2C_NATIVE_TOOLS_DIR/ctangle $WEB2C_NATIVE_TOOLS_DIR/ctangleboot $WEB2C_NATIVE_TOOLS_DIR/web2c/fixwrites $WEB2C_NATIVE_TOOLS_DIR/web2c/splitup $WEB2C_NATIVE_TOOLS_DIR/tangle $WEB2C_NATIVE_TOOLS_DIR/tangleboot $WEB2C_NATIVE_TOOLS_DIR/tie $WEB2C_NATIVE_TOOLS_DIR/web2c/web2c $WEB2C_NATIVE_TOOLS_DIR/otangle $WEB2C_NATIVE_TOOLS_DIR/web2c/makecpool $WEB2C_NATIVE_TOOLS_DIR/xetex --"
EMCCSKIP_ICU="python3 $ROOT/ccskip.py $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/bin/icupkg $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/bin/pkgdata --"
EMCCFLAGS_ICU="-s ERROR_ON_UNDEFINED_SYMBOLS=0"
EMCCFLAGS_FONTCONFIG="-Duuid_generate_random=uuid_generate"
EMCCFLAGS_TEXLIVE="-s ERROR_ON_UNDEFINED_SYMBOLS=0 -DELIDE_CODE"
EMCCFLAGS_EXPAT="-s USE_PTHREADS=0 -s NO_FILESYSTEM=1 -s NO_EXIT_RUNTIME=1 -s MODULARIZE=1"


mkdir -p $PREFIX $PREFIX/bin
mkdir -p $BACKUP/texk $BACKUP/texk/web2c

wget --no-clobber $TEXLIVE_SOURCE_URL
#tar -xvf $(basename $TEXLIVE_SOURCE_URL)
cd $TEXLIVE_SOURCE_DIR

#mv texk/dviout-util texk/dvipsk texk/xdvik texk/dviljk texk/dvipos texk/dvidvi texk/dvipng texk/dvi2tty texk/dvisvgm texk/dtl texk/gregorio texk/upmendex texk/cjkutils texk/musixtnt texk/tests texk/ttf2pk2 texk/ttfdump texk/makejvf texk/lcdf-typetools $BACKUP/texk || true

mkdir -p $TEXLIVE_BUILD_DIR
cd $TEXLIVE_BUILD_DIR

echo 'ac_cv_func_getwd=${ac_cv_func_getwd=no}' > $TEXLIVE_CACHE
echo > $FONTCONFIG_CACHE
CFLAGS="$EMCCFLAGS_TEXLIVE -I$PREFIX/include -I$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/icu/include -I$FONTCONFIG_SOURCE_DIR"
$EMCONFIGURE ../configure                       \
  --cache-file=$TEXLIVE_CACHE                   \
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
  --with-banner-add="_EM" CFLAGS="$CFLAGS" CPPFLAGS="$CFLAGS"

$EMMAKE make $MAKEFLAGS 
$EMMAKE make $MAKEFLAGS install

 rename extern symbols
pushd texk/dvipdfm-x
EMCC_CFLAGS="-Dcheck_for_jpeg=dvipdfmx_check_for_jpeg -Djpeg_include_image=dvipdfmx_jpeg_include_image -Djpeg_get_bbox=dvipdfmx_jpeg_get_bbox" $EMMAKE make $MAKEFLAGS
popd

for d in libs/teckit libs/harfbuzz libs/graphite2 libs/libpng libs/zlib libs/pplib libs/icu libs/icu/include/unicode; do
    pushd $d
    EMCC_CFLAGS="-Dcheck_for_jpeg=dvipdfmx_check_for_jpeg -Djpeg_include_image=dvipdfmx_jpeg_include_image -Djpeg_get_bbox=dvipdfmx_jpeg_get_bbox" $EMMAKE make $MAKEFLAGS
    popd
done

pushd libs/freetype2
$EMMAKE make $MAKEFLAGS CC="$EMCCSKIP_FREETYPE emcc"
popd

pushd libs/icu
$EMCONFIGURE $TEXLIVE_SOURCE_DIR/libs/icu/configure CC="$EMCCSKIP_ICU emcc $EMCCFLAGS_ICU" CXX="$EMCCSKIP_ICU em++ $EMCCFLAGS_ICU"
echo 'all install:' > $TEXLIVE_BUILD_DIR/libs/icu/icu-build/test/Makefile
$EMMAKE make $MAKEFLAGS -e PKGDATA_OPTS="--without-assembly -O $TEXLIVE_BUILD_DIR/libs/icu/icu-build/data/icupkg.inc" -e CC="$EMCCSKIP_ICU emcc $CFLAGS" -e CXX="$EMCCSKIP_ICU em++ $CFLAGS"
popd

#pushd libs/icu/icu-build
#mkdir -p bin stubdata lib
#cp $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/stubdata/libicudata.a $TEXLIVE_BUILD_DIR/libs/icu/icu-build/stubdata/
#cp --preserve=mode $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/bin/icupkg $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/bin/pkgdata $TEXLIVE_BUILD_DIR/libs/icu/icu-build/bin/
#pushd common
#$EMMAKE make $MAKEFLAGS 
#popd
#pushd i18n
#$EMMAKE make $MAKEFLAGS
#popd

cd $ROOT
wget --no-clobber $EXPAT_SOURCE_URL
tar -xf $(basename $EXPAT_SOURCE_URL)
mkdir -p $EXPAT_BUILD_DIR
cd $EXPAT_BUILD_DIR
$EMCMAKE cmake \
    -DCMAKE_C_FLAGS="$EMCCFLAGS_EXPAT" \
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
echo 'all install:' > $FONTCONFIG_SOURCE_DIR/test/Makefile.in
FREETYPE_CFLAGS="-I$TEXLIVE_BUILD_DIR/libs/freetype2/ -I$TEXLIVE_BUILD_DIR/libs/freetype2/freetype2"
FREETYPE_LIBS="-L$TEXLIVE_BUILD_DIR/libs/freetype2/ -lfreetype"
$EMCONFIGURE ../configure \
    --cache-file $FONTCONFIG_CACHE \
    --prefix=$PREFIX \
    --enable-static \
    --disable-shared \
    --disable-docs CFLAGS="$EMCCFLAGS_FONTCONFIG" \
    --with-expat-includes="$EXPAT_SOURCE_DIR/lib" \
    --with-expat-lib="$EXPAT_BUILD_DIR" \
    FREETYPE_CFLAGS="$FREETYPE_CFLAGS" FREETYPE_LIBS="$FREETYPE_LIBS" 
$EMMAKE make $MAKEFLAGS 
# --sysconfdir=/etc --localstatedir=/var
# --with-default-fonts=/fonts \

cd $TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/texk/web2c
$EMMAKE make $MAKEFLAGS xetex CC="$EMCCSKIP_XETEX emcc" CXX="$EMCCSKIP_XETEX em++"
# rebuild custom xetex-xetex0.o, because of offsets problems
pushd $TEXLIVE_BUILD_DIR/texk/web2c
cp $TEXLIVE_SOURCE_DIR/texlive-build-native/texk/web2c/xetex0.c $TEXLIVE_BUILD_DIR/texk/web2c
emcc -DHAVE_CONFIG_H -I. -I../../../texk/web2c -I./w2c  -I$TEXLIVE_BUILD_DIR/texk -I$TEXLIVE_SOURCE_DIR/texk -I../../../texk/web2c/xetexdir  -I$TEXLIVE_BUILD_DIR/libs/freetype2/freetype2 -I$TEXLIVE_BUILD_DIR/libs/teckit/include -I$TEXLIVE_BUILD_DIR/libs/harfbuzz/include -I$TEXLIVE_BUILD_DIR/libs/graphite2/include -DGRAPHITE2_STATIC -I$TEXLIVE_BUILD_DIR/libs/libpng/include -I$TEXLIVE_BUILD_DIR/libs/zlib/include -I$TEXLIVE_BUILD_DIR/libs/pplib/include -I../../../texk/web2c/libmd5   -I../../../texk/web2c/synctexdir -D__SyncTeX__ -DSYNCTEX_ENGINE_H=\"synctex-xetex.h\" -s ERROR_ON_UNDEFINED_SYMBOLS=0 -DELIDE_CODE -I/mnt/c/Users/user/xetex2020.js/prefix-wasm/include -I$TEXLIVE_BUILD_DIR/libs/icu/include -I/mnt/c/Users/user/xetex2020.js/fontconfig-2.13.1 -Wimplicit -Wreturn-type -s ERROR_ON_UNDEFINED_SYMBOLS=0 -DELIDE_CODE -I/mnt/c/Users/user/xetex2020.js/prefix-wasm/include -I$TEXLIVE_BUILD_DIR/libs/icu/include -I$ROOT/fontconfig-2.13.1 -MT xetex-xetex0.o -MD -MP -MF .deps/xetex-xetex0.Tpo -c -o xetex-xetex0.o xetex0.c
popd


# xdvipdfmx binary
#pushd $TEXLIVE_BUILD_DIR/texk/dvipdfm-x/
#em++ -g -O2 -s ERROR_ON_UNDEFINED_SYMBOLS=0 -Wimplicit -Wreturn-type -I/mnt/c/Users/user/xetex2020.js/prefix-wasm/include -I$TEXLIVE_BUILD_DIR/libs/icu/include -I$ROOT/fontconfig-2.13.1   -o xdvipdfmx agl.o bmpimage.o cff.o cff_dict.o cid.o cidtype0.o cidtype2.o cmap.o cmap_read.o cmap_write.o cs_type2.o dpxconf.o dpxcrypt.o dpxfile.o dpxutil.o dvi.o dvipdfmx.o epdf.o error.o fontmap.o jp2image.o jpegimage.o mem.o mfileio.o mpost.o mt19937ar.o numbers.o otl_opt.o pdfcolor.o pdfdev.o pdfdoc.o pdfdraw.o pdfencrypt.o pdfencoding.o pdffont.o pdfnames.o pdfobj.o pdfparse.o pdfresource.o pdfximage.o pkfont.o pngimage.o pst.o pst_obj.o sfnt.o spc_color.o spc_dvipdfmx.o spc_dvips.o spc_html.o spc_misc.o spc_pdfm.o spc_tpic.o spc_util.o spc_xtx.o specials.o subfont.o t1_char.o t1_load.o tfm.o truetype.o tt_aux.o tt_cmap.o tt_glyf.o tt_gsub.o tt_post.o tt_table.o type0.o type1.o type1c.o unicode.o vf.o xbb.o $TEXLIVE_BUILD_DIR/texk/kpathsea/.libs/libkpathsea.a $TEXLIVE_BUILD_DIR/libs/libpng/libpng.a $TEXLIVE_BUILD_DIR/libs/zlib/libz.a $TEXLIVE_BUILD_DIR/libs/libpaper/libpaper.a -lm 
#popd

#XETEX_OBJECTS="xetexdir/xetex-xetexextra.o synctexdir/xetex-synctex.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o libxetex.a"
#XETEX_DEPS="$TEXLIVE_BUILD_DIR/libs/harfbuzz/libharfbuzz.a $TEXLIVE_BUILD_DIR/libs/graphite2/libgraphite2.a $TEXLIVE_BUILD_DIR/libs/teckit/libTECkit.a $TEXLIVE_BUILD_DIR/libs/libpng/libpng.a $TEXLIVE_BUILD_DIR/libs/freetype2/libfreetype.a $TEXLIVE_BUILD_DIR/libs/pplib/libpplib.a $TEXLIVE_BUILD_DIR/libs/zlib/libz.a libmd5.a lib/lib.a $TEXLIVE_BUILD_DIR/texk/kpathsea/.libs/libkpathsea.a $FONTCONFIG_BUILD_DIR/src/.libs/libfontconfig.a $EXPAT_BUILD_DIR/libexpat.a $TEXLIVE_BUILD_DIR/libs/icu/icu-build/lib/libicuuc.a $TEXLIVE_BUILD_DIR/libs/icu/icu-build/lib/libicudata.a" 
#em++ -g -O2 -s ERROR_ON_UNDEFINED_SYMBOLS=0 -s EXPORTED_FUNCTIONS='["_main"]' -s EXPORTED_RUNTIME_METHODS='["callMain","FS"]' -s TOTAL_MEMORY=536870912 -o $ROOT/xelatex.js $XETEX_OBJECTS $XETEX_DEPS -s FORCE_FILESYSTEM=1 -s LZ4=1 -s INVOKE_RUN=0
#python3 $EMROOT/tools/file_packager.py $ROOT/texlive.data --lz4 --preload "$ROOT/fontconfig@/fontconfig" --preload "$ROOT/texmf.cnf@/texmf.cnf" --preload "$ROOT/texlive@/texlive" --preload "$ROOT/latex_format/base/latex.fmt@/xelatex.fmt" --js-output=$ROOT/texlive.js

# https://askubuntu.com/questions/492033/fontconfig-error-cannot-load-default-config-file
# https://github.com/Dador/JavascriptSubtitlesOctopus/blob/master/Makefile#L216
