# $@ is lhs
# $^ is rhs
# $* is captured %

URL_texlive = https://github.com/TeX-Live/texlive-source/archive/9ed922e7d25e41b066f9e6c973581a4e61ac0328.tar.gz
URL_expat = https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
URL_fontconfig = https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.gz

ROOT := $(CURDIR)

PREFIX_wasm = prefix/wasm
PREFIX_native = prefix/native

MAKE_wasm = emmake
CMAKE_wasm = emcmake 
CONFIGURE_wasm = emconfigure 

#CFLAGS_FREETYPE = "-I$TEXLIVE_BUILD_DIR/libs/freetype2/ -I$TEXLIVE_BUILD_DIR/libs/freetype2/freetype2"
#LIBS_FREETYPE = "-L$TEXLIVE_BUILD_DIR/libs/freetype2/ -lfreetype"

CFLAGS_wasm_expat = -s USE_PTHREADS=0 -s NO_FILESYSTEM=1

source/texlive source/expat source/fontconfig:
	wget --no-clobber $(URL_$(notdir $@)) -O "$@.tar.gz" || true
	mkdir -p "$@" && tar -xf "$@.tar.gz" --strip-components=1 --directory="$@"

build/%/expat/libexpat.a: source/expat 
	mkdir -p $(dir $@) && \
	cd $(dir $@) && \
	$(CMAKE_$*) cmake \
	   -DCMAKE_INSTALL_PREFIX="$(PREFIX_$*)" \
	   -DCMAKE_C_FLAGS="$(CFLAGS_$*_$(notdir $^))" \
	   -DEXPAT_BUILD_DOCS=off \
	   -DEXPAT_SHARED_LIBS=off \
	   -DEXPAT_BUILD_EXAMPLES=off \
	   -DEXPAT_BUILD_FUZZERS=off \
	   -DEXPAT_BUILD_TESTS=off \
	   -DEXPAT_BUILD_TOOLS=off \
	   $(ROOT)/$^ && \
	$(MAKE_$*) make $(MAKEFLAGS)

build/%/fontconfig/libfontconfig.a: source/fontconfig
	echo hi
	#cd $FONTCONFIG_BUILD_DIR
	#patch -d $FONTCONFIG_SOURCE_DIR -Np1 -i $(ROOT)/0002-fix-fcstats-emscripten.patch 
	#echo 'all install:' > $FONTCONFIG_SOURCE_DIR/test/Makefile.in
	#$(CONFIGURE_$*) $FONTCONFIG_SOURCE_DIR/configure \
	#   --cache-file $FONTCONFIG_CACHE \
	#   --prefix=$PREFIX \
	#   --enable-static \
	#   --disable-shared \
	#   --disable-docs CFLAGS="$EMCCFLAGS_FONTCONFIG" \
	#   --with-expat-includes="$EXPAT_SOURCE_DIR/lib" \
	#   --with-expat-lib="$EXPAT_BUILD_DIR" \
	#   FREETYPE_CFLAGS="$FREETYPE_CFLAGS" FREETYPE_LIBS="$FREETYPE_LIBS" \
	#$(MAKE_$*) make $(MAKEFLAGS) 

clean_native_expat:
	rm -rf build/native/expat

.PHONY:
	clean_native/expat
