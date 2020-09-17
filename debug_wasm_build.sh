# https://askubuntu.com/questions/492033/fontconfig-error-cannot-load-default-config-file
# https://github.com/Dador/JavascriptSubtitlesOctopus/blob/master/Makefile#L216
export MAKEFLAGS=-j4

SUFFIX=wasm

ROOT=$PWD

TEXLIVE_SOURCE_URL=https://github.com/TeX-Live/texlive-source/archive/9ed922e7d25e41b066f9e6c973581a4e61ac0328.tar.gz
TEXLIVE_SOURCE_NAME=texlive-source-$(basename $TEXLIVE_SOURCE_URL .tar.gz)
TEXLIVE_SOURCE_DIR=$ROOT/$TEXLIVE_SOURCE_NAME
TEXLIVE_BUILD_DIR=$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX
WEB2C_NATIVE_TOOLS_DIR=$TEXLIVE_SOURCE_DIR/texlive-build-native/texk/web2c

EXPAT_SOURCE_URL=https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
EXPAT_SOURCE_NAME=$(basename $EXPAT_SOURCE_URL .tar.gz)
EXPAT_SOURCE_DIR=$ROOT/$EXPAT_SOURCE_NAME
EXPAT_BUILD_DIR=$TEXLIVE_BUILD_DIR/expat-build-$SUFFIX

FONTCONFIG_SOURCE_URL=https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.gz
FONTCONFIG_SOURCE_NAME=$(basename $FONTCONFIG_SOURCE_URL .tar.gz)
FONTCONFIG_SOURCE_DIR=$ROOT/$FONTCONFIG_SOURCE_NAME
FONTCONFIG_CACHE=$TEXLIVE_BUILD_DIR/config-fontconfig-$SUFFIX.cache
FONTCONFIG_BUILD_DIR=$TEXLIVE_BUILD_DIR/fontconfig-build-$SUFFIX


BACKUP=$ROOT/texlive-backup
PREFIX=$ROOT/prefix-$SUFFIX
TEXLIVE_CACHE=$ROOT/config-$SUFFIX.cache
XELATEX_EXE=$PREFIX/bin/xelatex
XETEX_EXE=$PREFIX/bin/xetex

EMROOT=$(dirname $(which emcc))
EMMAKE=emmake
EMCMAKE=emcmake
EMCONFIGURE=emconfigure
TOTAL_MEMORY=536870912
EMCCSKIP_FREETYPE="python3 $ROOT/ccskip.py $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/freetype2/ft-build/apinames --"
EMCCSKIP_XETEX="python3 $ROOT/ccskip.py $WEB2C_NATIVE_TOOLS_DIR/ctangle $WEB2C_NATIVE_TOOLS_DIR/ctangleboot $WEB2C_NATIVE_TOOLS_DIR/web2c/fixwrites $WEB2C_NATIVE_TOOLS_DIR/web2c/splitup $WEB2C_NATIVE_TOOLS_DIR/tangle $WEB2C_NATIVE_TOOLS_DIR/tangleboot $WEB2C_NATIVE_TOOLS_DIR/tie $WEB2C_NATIVE_TOOLS_DIR/web2c/web2c $WEB2C_NATIVE_TOOLS_DIR/otangle $WEB2C_NATIVE_TOOLS_DIR/web2c/makecpool $WEB2C_NATIVE_TOOLS_DIR/xetex --"
EMCCSKIP_ICU="python3 $ROOT/ccskip.py $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/bin/icupkg $TEXLIVE_SOURCE_DIR/texlive-build-native/libs/icu/icu-build/bin/pkgdata --"
EMCCFLAGS_ICU="-s ERROR_ON_UNDEFINED_SYMBOLS=0"
EMCCFLAGS_FONTCONFIG="-Duuid_generate_random=uuid_generate"
EMCCFLAGS_TEXLIVE="-s ERROR_ON_UNDEFINED_SYMBOLS=0"
EMCCFLAGS_EXPAT="-s USE_PTHREADS=0 -s NO_FILESYSTEM=1"
EMCCFLAGS_BIBTEX="-s TOTAL_MEMORY=$TOTAL_MEMORY"
CFLAGS_DVIPDFMX="-Dcheck_for_jpeg=dvipdfmx_check_for_jpeg -Dcheck_for_bmp=dvipdfmx_check_for_bmp -Dcheck_for_png=dvipdfmx_check_for_png"

#mkdir -p $PREFIX $PREFIX/bin
mkdir -p $BACKUP/texk $BACKUP/texk/web2c

wget --no-clobber $TEXLIVE_SOURCE_URL
#tar -xvf $(basename $TEXLIVE_SOURCE_URL)
cd $TEXLIVE_SOURCE_DIR

#mv texk/dviout-util texk/dvipsk texk/xdvik texk/dviljk texk/dvipos texk/dvidvi texk/dvipng texk/dvi2tty texk/dvisvgm texk/dtl texk/gregorio texk/upmendex texk/cjkutils texk/musixtnt texk/tests texk/ttf2pk2 texk/ttfdump texk/makejvf texk/lcdf-typetools $BACKUP/texk || true

mkdir -p $TEXLIVE_BUILD_DIR
cd $TEXLIVE_BUILD_DIR

#echo 'ac_cv_func_getwd=${ac_cv_func_getwd=no}' > $TEXLIVE_CACHE
#CFLAGS="$EMCCFLAGS_TEXLIVE -I$TEXLIVE_SOURCE_DIR/texlive-build-$SUFFIX/libs/icu/include -I$FONTCONFIG_SOURCE_DIR"
#$EMCONFIGURE ../configure                       \
#  --cache-file=$TEXLIVE_CACHE                   \
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
#  --with-banner-add="_BUSY-$SUFFIX" CFLAGS="$CFLAGS" CPPFLAGS="$CFLAGS"
#
#$EMMAKE make $MAKEFLAGS 

#pushd texk/bibtex-x
##$EMMAKE make clean
#$EMMAKE make $MAKEFLAGS -e CFLAGS="$EMCCFLAGS_BIBTEX" -e CXXFLAGS="$EMCCFLAGS_BIBTEX"
#popd
#
## rename extern symbols
#pushd texk/dvipdfm-x
#$EMMAKE make clean
#$EMMAKE make $MAKEFLAGS CC="emcc $CFLAGS_DVIPDFMX" CXX="em++ $CFLAGS_DVIPDFMX"
#popd
#
#for d in libs/teckit libs/harfbuzz libs/graphite2 libs/libpng libs/zlib libs/pplib; do
#    pushd $d
#    $EMMAKE make $MAKEFLAGS
#    popd
#done
#
#pushd libs/freetype2
#$EMMAKE make $MAKEFLAGS CC="$EMCCSKIP_FREETYPE emcc"
#popd
#
#pushd libs/icu
#$EMCONFIGURE $TEXLIVE_SOURCE_DIR/libs/icu/configure CC="$EMCCSKIP_ICU emcc $EMCCFLAGS_ICU" CXX="$EMCCSKIP_ICU em++ $EMCCFLAGS_ICU"
#echo 'all install:' > $TEXLIVE_BUILD_DIR/libs/icu/icu-build/test/Makefile
#$EMMAKE make $MAKEFLAGS -e PKGDATA_OPTS="--without-assembly -O $TEXLIVE_BUILD_DIR/libs/icu/icu-build/data/icupkg.inc" -e CC="$EMCCSKIP_ICU emcc $CFLAGS" -e CXX="$EMCCSKIP_ICU em++ $CFLAGS"
#popd
#
#cd $ROOT
#wget --no-clobber $EXPAT_SOURCE_URL
#tar -xf $(basename $EXPAT_SOURCE_URL)
#mkdir -p $EXPAT_BUILD_DIR
#cd $EXPAT_BUILD_DIR
#$EMCMAKE cmake \
#   -DCMAKE_C_FLAGS="$EMCCFLAGS_EXPAT" \
#   -DCMAKE_INSTALL_PREFIX=$PREFIX \
#   -DEXPAT_BUILD_DOCS=off \
#   -DEXPAT_SHARED_LIBS=off \
#   -DEXPAT_BUILD_EXAMPLES=off \
#   -DEXPAT_BUILD_FUZZERS=off \
#   -DEXPAT_BUILD_TESTS=off \
#   -DEXPAT_BUILD_TOOLS=off \
#   $EXPAT_SOURCE_DIR 
#$EMMAKE make $MAKEFLAGS 
#
#echo > $FONTCONFIG_CACHE
#cd $ROOT
#wget --no-clobber $FONTCONFIG_SOURCE_URL
#tar -xf $(basename $FONTCONFIG_SOURCE_URL)
#mkdir -p $FONTCONFIG_BUILD_DIR
#cd $FONTCONFIG_BUILD_DIR
#patch -d $FONTCONFIG_SOURCE_DIR -Np1 -i $ROOT/0002-fix-fcstats-emscripten.patch 
#echo 'all install:' > $FONTCONFIG_SOURCE_DIR/test/Makefile.in
#FREETYPE_CFLAGS="-I$TEXLIVE_BUILD_DIR/libs/freetype2/ -I$TEXLIVE_BUILD_DIR/libs/freetype2/freetype2"
#FREETYPE_LIBS="-L$TEXLIVE_BUILD_DIR/libs/freetype2/ -lfreetype"
#$EMCONFIGURE $FONTCONFIG_SOURCE_DIR/configure \
#   --cache-file $FONTCONFIG_CACHE \
#   --prefix=$PREFIX \
#   --enable-static \
#   --disable-shared \
#   --disable-docs CFLAGS="$EMCCFLAGS_FONTCONFIG" \
#   --with-expat-includes="$EXPAT_SOURCE_DIR/lib" \
#   --with-expat-lib="$EXPAT_BUILD_DIR" \
#   FREETYPE_CFLAGS="$FREETYPE_CFLAGS" FREETYPE_LIBS="$FREETYPE_LIBS" 
#$EMMAKE make $MAKEFLAGS 
## --sysconfdir=/etc --localstatedir=/var
## --with-default-fonts=/fonts \
#
#pushd $TEXLIVE_BUILD_DIR/texk/dvipdfm-x/
# xdvipdfmx library
#emcc -Dmain='__attribute__((visibility("default"))) busymain_dvipdfmx' -DHAVE_CONFIG_H -I. -I../../../texk/dvipdfm-x  -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/texk -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texk -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/libpng/include -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/zlib/include -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/libpaper/include -DBUILD_DATA_WITHOUT_ASSEMBLY=1 -I/mnt/c/Users/user/xetex2020.js/prefix-wasm/include -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/icu/include -I/mnt/c/Users/user/xetex2020.js/fontconfig-2.13.1 -Wimplicit -Wreturn-type -DBUILD_DATA_WITHOUT_ASSEMBLY=1 -I/mnt/c/Users/user/xetex2020.js/prefix-wasm/include -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/icu/include -I/mnt/c/Users/user/xetex2020.js/fontconfig-2.13.1 -MT dvipdfmx.o -MD -MP -MF $depbase.Tpo -c -o dvipdfmx.o ../../../texk/dvipdfm-x/dvipdfmx.c
#popd
#
## rebuild custom xetex-xetex0.o, because of offsets problems
pushd $TEXLIVE_BUILD_DIR/texk/web2c
#$EMMAKE make $MAKEFLAGS xetex CC="$EMCCSKIP_XETEX emcc" CXX="$EMCCSKIP_XETEX em++"
#cp $TEXLIVE_SOURCE_DIR/texlive-build-native/texk/web2c/*.c $TEXLIVE_BUILD_DIR/texk/web2c
#emcc -DHAVE_CONFIG_H -I. -I../../../texk/web2c -I./w2c  -I$TEXLIVE_BUILD_DIR/texk -I$TEXLIVE_SOURCE_DIR/texk -I../../../texk/web2c/xetexdir  -I$TEXLIVE_BUILD_DIR/libs/freetype2/freetype2 -I$TEXLIVE_BUILD_DIR/libs/teckit/include -I$TEXLIVE_BUILD_DIR/libs/harfbuzz/include -I$TEXLIVE_BUILD_DIR/libs/graphite2/include -DGRAPHITE2_STATIC -I$TEXLIVE_BUILD_DIR/libs/libpng/include -I$TEXLIVE_BUILD_DIR/libs/zlib/include -I$TEXLIVE_BUILD_DIR/libs/pplib/include -I../../../texk/web2c/libmd5   -I../../../texk/web2c/synctexdir -D__SyncTeX__ -DSYNCTEX_ENGINE_H=\"synctex-xetex.h\" -s ERROR_ON_UNDEFINED_SYMBOLS=0 -DELIDE_CODE -I/mnt/c/Users/user/xetex2020.js/prefix-wasm/include -I$TEXLIVE_BUILD_DIR/libs/icu/include -I/mnt/c/Users/user/xetex2020.js/fontconfig-2.13.1 -Wimplicit -Wreturn-type -s ERROR_ON_UNDEFINED_SYMBOLS=0 -DELIDE_CODE -I/mnt/c/Users/user/xetex2020.js/prefix-wasm/include -I$TEXLIVE_BUILD_DIR/libs/icu/include -I$ROOT/fontconfig-2.13.1 -MT xetex-xetex0.o -MD -MP -MF .deps/xetex-xetex0.Tpo -c -o xetex-xetex0.o xetex0.c
#
## xetex library
#emcc -Dmain='__attribute__((visibility("default"))) busymain_xetex' -DHAVE_CONFIG_H -I. -I../../../texk/web2c -I./w2c  -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/texk -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texk -I../../../texk/web2c/xetexdir -DU_STATIC_IMPLEMENTATION -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/icu/include -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/freetype2/freetype2 -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/teckit/include -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/harfbuzz/include -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/graphite2/include -DGRAPHITE2_STATIC -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/libpng/include -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/zlib/include -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/pplib/include -I../../../texk/web2c/libmd5  -I/usr/include/freetype2 -I/usr/include/libpng16 -I/usr/include/freetype2 -I/usr/include/libpng16 -I../../../texk/web2c/synctexdir -D__SyncTeX__ -DSYNCTEX_ENGINE_H=\"synctex-xetex.h\" -DBUILD_DATA_WITHOUT_ASSEMBLY=1 -I/mnt/c/Users/user/xetex2020.js/prefix-wasm/include -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/icu/include -I/mnt/c/Users/user/xetex2020.js/fontconfig-2.13.1 -Wimplicit -Wreturn-type -DBUILD_DATA_WITHOUT_ASSEMBLY=1 -I/mnt/c/Users/user/xetex2020.js/prefix-wasm/include -I/mnt/c/Users/user/xetex2020.js/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texlive-build-wasm/libs/icu/include -I/mnt/c/Users/user/xetex2020.js/fontconfig-2.13.1 -MT xetexdir/xetex-xetexextra.o -MD -MP -MF xetexdir/.deps/xetex-xetexextra.Tpo -c -o xetexdir/xetex-xetexextra.o  $ROOT/texlive-source-9ed922e7d25e41b066f9e6c973581a4e61ac0328/texk/web2c/xetexdir/xetexextra.c
#
#
#XETEX_OBJECTS="xetexdir/xetex-xetexextra.o synctexdir/xetex-synctex.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o libxetex.a"
#XETEX_DEPS="$TEXLIVE_BUILD_DIR/libs/harfbuzz/libharfbuzz.a $TEXLIVE_BUILD_DIR/libs/graphite2/libgraphite2.a $TEXLIVE_BUILD_DIR/libs/teckit/libTECkit.a $TEXLIVE_BUILD_DIR/libs/libpng/libpng.a $TEXLIVE_BUILD_DIR/libs/freetype2/libfreetype.a $TEXLIVE_BUILD_DIR/libs/pplib/libpplib.a $TEXLIVE_BUILD_DIR/libs/zlib/libz.a libmd5.a lib/lib.a $TEXLIVE_BUILD_DIR/texk/kpathsea/.libs/libkpathsea.a $FONTCONFIG_BUILD_DIR/src/.libs/libfontconfig.a $EXPAT_BUILD_DIR/libexpat.a $TEXLIVE_BUILD_DIR/libs/icu/icu-build/lib/libicuuc.a $TEXLIVE_BUILD_DIR/libs/icu/icu-build/lib/libicudata.a" 
#
## xetex binary
#em++ -g -O2 -s ERROR_ON_UNDEFINED_SYMBOLS=0 -s EXPORTED_FUNCTIONS='["_main"]' -s EXPORTED_RUNTIME_METHODS='["callMain","FS"]' -s TOTAL_MEMORY=536870912 -o $ROOT/xelatex.js $XETEX_OBJECTS $XETEX_DEPS -s FORCE_FILESYSTEM=1 -s LZ4=1 -s INVOKE_RUN=0

# busy binary
#XETEX_OBJECTS="xetex-xetex-pool.o  xetexdir/xetex-xetexextra.o   synctexdir/xetex-synctex.o xetex-xetexini.o xetex-xetex0.o xetexdir/libxetex_a-XeTeXFontInst.o xetexdir/libxetex_a-XeTeXFontMgr.o xetexdir/libxetex_a-XeTeXLayoutInterface.o xetexdir/libxetex_a-XeTeXOTMath.o xetexdir/libxetex_a-XeTeX_ext.o xetexdir/libxetex_a-XeTeX_pic.o xetexdir/libxetex_a-trans.o xetexdir/libxetex_a-hz.o xetexdir/libxetex_a-pdfimage.o  xetexdir/libxetex_a-XeTeXFontMgr_FC.o"
#XETEX_DEPS="$TEXLIVE_BUILD_DIR/libs/harfbuzz/libharfbuzz.a $TEXLIVE_BUILD_DIR/libs/graphite2/libgraphite2.a $TEXLIVE_BUILD_DIR/libs/teckit/libTECkit.a $TEXLIVE_BUILD_DIR/libs/libpng/libpng.a $TEXLIVE_BUILD_DIR/libs/freetype2/libfreetype.a  $TEXLIVE_BUILD_DIR/libs/pplib/libpplib.a  $TEXLIVE_BUILD_DIR/texk/web2c/xetexdir/image/libxetex_a-pngimage.o $TEXLIVE_BUILD_DIR/texk/web2c/xetexdir/image/libxetex_a-bmpimage.o $TEXLIVE_BUILD_DIR/texk/web2c/xetexdir/image/libxetex_a-jpegimage.o  $TEXLIVE_BUILD_DIR/libs/zlib/libz.a libmd5.a lib/lib.a $TEXLIVE_BUILD_DIR/texk/kpathsea/.libs/libkpathsea.a $FONTCONFIG_BUILD_DIR/src/.libs/libfontconfig.a $EXPAT_BUILD_DIR/libexpat.a $TEXLIVE_BUILD_DIR/libs/icu/icu-build/lib/libicuuc.a $TEXLIVE_BUILD_DIR/libs/icu/icu-build/lib/libicudata.a" 

#O=$TEXLIVE_BUILD_DIR/texk/dvipdfm-x
#DVIPDF_OBJECTS=" $O/agl.o  $O/cff.o $O/cff_dict.o $O/cid.o $O/cidtype0.o $O/cidtype2.o $O/cmap.o $O/cmap_read.o $O/cmap_write.o $O/cs_type2.o $O/dpxconf.o $O/dpxcrypt.o $O/dpxfile.o $O/dpxutil.o $O/dvi.o $O/dvipdfmx.o $O/epdf.o $O/error.o $O/fontmap.o $O/jp2image.o  $O/jpegimage.o $O/bmpimage.o $O/pngimage.o   $O/mfileio.o $O/numbers.o  $O/mem.o $O/mpost.o $O/mt19937ar.o $O/otl_opt.o $O/pdfcolor.o $O/pdfdev.o $O/pdfdoc.o $O/pdfdraw.o $O/pdfencrypt.o $O/pdfencoding.o $O/pdffont.o $O/pdfnames.o $O/pdfobj.o $O/pdfparse.o $O/pdfresource.o $O/pdfximage.o $O/pkfont.o  $O/pst.o $O/pst_obj.o $O/sfnt.o $O/spc_color.o $O/spc_dvipdfmx.o $O/spc_dvips.o $O/spc_html.o $O/spc_misc.o $O/spc_pdfm.o $O/spc_tpic.o $O/spc_util.o $O/spc_xtx.o $O/specials.o $O/subfont.o $O/t1_char.o $O/t1_load.o $O/tfm.o $O/truetype.o $O/tt_aux.o $O/tt_cmap.o $O/tt_glyf.o $O/tt_gsub.o $O/tt_post.o $O/tt_table.o $O/type0.o $O/type1.o $O/type1c.o $O/unicode.o $O/vf.o $O/xbb.o"
#DVIPDF_DEPS="-I$TEXLIVE_BUILD_DIR/libs/icu/include -I$ROOT/fontconfig-2.13.1 $TEXLIVE_BUILD_DIR/texk/kpathsea/.libs/libkpathsea.a $TEXLIVE_BUILD_DIR/libs/libpng/libpng.a $TEXLIVE_BUILD_DIR/libs/zlib/libz.a $TEXLIVE_BUILD_DIR/libs/libpaper/libpaper.a -lm" 

# file system
#echo > $ROOT/dummy
#python3 $EMROOT/tools/file_packager.py $ROOT/texlive.data --lz4  --use-preload-cache --preload "$ROOT/dummy@/bin/busytex" --preload "$ROOT/fontconfig@/fontconfig" --preload "$ROOT/texmf.cnf@/texmf.cnf" --preload "$ROOT/texlive@/texlive" --preload "$ROOT/latex_format/base/latex.fmt@/xelatex.fmt" --js-output=$ROOT/texlive.js

emcc -g -O2 -s MODULARIZE=1 -s EXPORT_NAME=busytex --pre-js $ROOT/texlive.js -s TOTAL_MEMORY=$TOTAL_MEMORY -s ERROR_ON_UNDEFINED_SYMBOLS=0 -s FORCE_FILESYSTEM=1 -s LZ4=1 -s INVOKE_RUN=0 -s EXPORTED_FUNCTIONS='["_main"]' -s EXPORTED_RUNTIME_METHODS='["callMain","FS", "ENV"]' -o $ROOT/busytex.js  $XETEX_OBJECTS $XETEX_DEPS $DVIPDF_DEPS $DVIPDF_OBJECTS $ROOT/busytex.c #--js-library $ROOT/exit.js

#TEXDIR = ${texliveRoot}
#TEXMFDIST = ${texliveRoot}/texmf-dist
#TEXMFLOCAL = ${texliveRoot}/texmf-local
#TEXMFCONFIG = ${texliveRoot}/texmf-config
#TEXMFSYSCONFIG = ${texliveRoot}/texmf-config
#TEXMFVAR = /home/web_user
#TEXMFOUTPUT = /home/web_user
#TEXMFSYSVAR = /home/web_user
#TEXMF = {!!$TEXMFDIST,!!$TEXMFLOCAL,!!TEXMFCONFIG}`;

#function callMain(args) {
#  var entryFunction = Module['_main'];
#  args = args || [];
#  var argc = args.length+1;
#  var argv = stackAlloc((argc + 1) * 4);
#  HEAP32[argv >> 2] = allocateUTF8OnStack(thisProgram);
#  for (var i = 1; i < argc; i++) {
#    HEAP32[(argv >> 2) + i] = allocateUTF8OnStack(args[i - 1]);
#  }
#  HEAP32[(argv >> 2) + argc] = 0;
#  try {
#    var ret = entryFunction(argc, argv);
#    // In PROXY_TO_PTHREAD builds, we should never exit the runtime below, as execution is asynchronously handed
#    // off to a pthread.
#    // if we're not running an evented main loop, it's time to exit
#      exit(ret, /* implicit = */ true);
#  }
#  catch(e) {
#    if (e instanceof ExitStatus) {
