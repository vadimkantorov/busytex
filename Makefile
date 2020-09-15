# $@ is lhs
# $< $^ is rhs
# $* is captured % (pattern)

URL_texlive = https://github.com/TeX-Live/texlive-source/archive/9ed922e7d25e41b066f9e6c973581a4e61ac0328.tar.gz
URL_expat = https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
URL_fontconfig = https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.gz

ROOT := $(CURDIR)

PREFIX_wasm = $(ROOT)/prefix/wasm
PREFIX_native = $(ROOT)/prefix/native

MAKE_wasm = emmake
CMAKE_wasm = emcmake
CONFIGURE_wasm = emconfigure

CFLAGS_wasm_expat = -s USE_PTHREADS=0 -s NO_FILESYSTEM=1

CFLAGS_wasm_fontconfig = -Duuid_generate_random=uuid_generate
LIBS_FREETYPE_wasm_fontconfig = -L$(ROOT)/build/wasm/texlive/libs/freetype2/ -lfreetype
CFLAGS_FREETYPE_wasm_fontconfig = -I$(ROOT)/build/wasm/texlive/libs/freetype2/ -I$(ROOT)/build/wasm/texlive/libs/freetype2/
LIBS_FREETYPE_native_fontconfig = -L$(ROOT)/build/native/texlive/libs/freetype2/ -lfreetype
CFLAGS_FREETYPE_native_fontconfig = -I$(ROOT)/build/native/texlive/libs/freetype2/ -I$(ROOT)/build/native/texlive/libs/freetype2/

CFLAGS_wasm_texlive = -I$(ROOT)/build/wasm/texlive/libs/icu/include -I$(ROOT)/source/fontconfig
CFLAGS_native_texlive = -I$(ROOT)/build/native/texlive/libs/icu/include -I$(ROOT)/source/fontconfig
# $EMCCFLAGS_TEXLIVE

CACHE_native_texlive = $(ROOT)/build/native-texlive.cache
CACHE_wasm_texlive = $(ROOT)/build/native-texlive.cache

source/texlive source/expat source/fontconfig:
	wget --no-clobber $(URL_$(notdir $@)) -O "$@.tar.gz" || true
	mkdir -p "$@" && tar -xf "$@.tar.gz" --strip-components=1 --directory="$@"
   
build/%/texlive/Makefile: source/texlive
	mkdir -p $(dir $@) && cd $(dir $@) && \
	echo > $(CACHE_$*_$(notdir $<)) && \
	$(CONFIGURE_$*) $(ROOT)/$</configure			\
	  --cache-file=$(CACHE_$*_$(notdir $<))		 \
	  --prefix="$(PREFIX_$*)"					   \
	  --enable-dump-share						   \
	  --enable-static							   \
	  --enable-xetex								\
	  --enable-dvipdfm-x							\
	  --enable-icu								  \
	  --enable-freetype2							\
	  --disable-shared							  \
	  --disable-multiplatform					   \
	  --disable-native-texlive-build				\
	  --disable-all-pkgs							\
	  --without-x								   \
	  --without-system-cairo						\
	  --without-system-gmp						  \
	  --without-system-graphite2					\
	  --without-system-harfbuzz					 \
	  --without-system-libgs						\
	  --without-system-libpaper					 \
	  --without-system-mpfr						 \
	  --without-system-pixman					   \
	  --without-system-poppler					  \
	  --without-system-xpdf						 \
	  --without-system-icu						  \
	  --without-system-fontconfig				   \
	  --without-system-freetype2					\
	  --without-system-libpng					   \
	  --without-system-zlib						 \
	  --with-banner-add="_BUSY$*"				   \
		CFLAGS="$(CFLAGS_$*_$(notdir $<))"		  \
	  CPPFLAGS="$(CFLAGS_$*_$(notdir $<))"


build/%/expat/libexpat.a: source/expat
	mkdir -p $(dir $@) && cd $(dir $@) && \
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

build/%/fontconfig/libfontconfig.a: source/fontconfig build/%/texlive/libs/freetype2/libfreetype.a
	#patch -d $FONTCONFIG_SOURCE_DIR -Np1 -i $(ROOT)/0002-fix-fcstats-emscripten.patch
	#echo 'all install:' > $FONTCONFIG_SOURCE_DIR/test/Makefile.in
	mkdir -p $(dir $@) && cd $(dir $@) && \
	$(CONFIGURE_$*) $(ROOT)/$</configure \
	   --prefix=$(PREFIX_$*) \
	   --enable-static \
	   --disable-shared \
	   --disable-docs \
	   --with-expat-includes="$(ROOT)/source/expat/lib" \
	   --with-expat-lib="$(ROOT)/build/$*/expat" \
	   CFLAGS="$(CFLAGS_$*_$(notdir $<))" FREETYPE_CFLAGS="$(CFLAGS_FREETYPE_$*_$(notdir $<))" FREETYPE_LIBS="$(LIBS_FREETYPE_$*_$(notdir $<))" && \	$(MAKE_$*) make $(MAKEFLAGS)

clean_native:
	rm -rf build/native/expat build/native/fontconfig

build_native: build/native/expat/libexpat.a build/native/fontconfig/libfontconfig.a
	echo Native tools built

.PHONY:
	clean_native/expat
