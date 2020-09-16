# $@ is lhs
# $< is rhs
# $* is captured % (pattern)

URL_texlive = https://github.com/TeX-Live/texlive-source/archive/9ed922e7d25e41b066f9e6c973581a4e61ac0328.tar.gz
URL_expat = https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
URL_fontconfig = https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.92.tar.gz

URL_TEXLIVE_TEXMF = ftp://tug.org/texlive/historic/2020/texlive-20200406-texmf.tar.xz 
URL_TEXLIVE_TLPDB = ftp://tug.org/texlive/historic/2020/texlive-20200406-tlpdb-full.tar.gz
URL_TEXLIVE_BASE = http://mirrors.ctan.org/macros/latex/base.zip
URL_TEXLIVE_INSTALLER = http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz

ROOT := $(CURDIR)

PREFIX_wasm = $(ROOT)/prefix/wasm
PREFIX_native = $(ROOT)/prefix/native

MAKE_wasm = emmake
CMAKE_wasm = emcmake
CONFIGURE_wasm = emconfigure

TOTAL_MEMORY = 536870912
SKIP = all install:

CACHE_native_texlive = $(ROOT)/build/native-texlive.cache
CACHE_wasm_texlive = $(ROOT)/build/wasm-texlive.cache
CACHE_native_fontconfig = $(ROOT)/build/native-fontconfig.cache
CACHE_wasm_fontconfig = $(ROOT)/build/wasm-fontconfig.cache

CFLAGS_wasm_expat = -s USE_PTHREADS=0 -s NO_FILESYSTEM=1
CFLAGS_wasm_bibtex = -s TOTAL_MEMORY=$(TOTAL_MEMORY)
CFLAGS_wasm_texlive = -I$(ROOT)/build/wasm/texlive/libs/icu/include -I$(ROOT)/source/fontconfig -s ERROR_ON_UNDEFINED_SYMBOLS=0
CFLAGS_native_texlive = -I$(ROOT)/build/native/texlive/libs/icu/include -I$(ROOT)/source/fontconfig

CFLAGS_wasm_icu = -s ERROR_ON_UNDEFINED_SYMBOLS=0
CFLAGS_wasm_fontconfig = -Duuid_generate_random=uuid_generate
CFLAGS_FREETYPE_wasm_fontconfig = -I$(ROOT)/build/wasm/texlive/libs/freetype2/ -I$(ROOT)/build/wasm/texlive/libs/freetype2/freetype2/
LIBS_FREETYPE_wasm_fontconfig = -L$(ROOT)/build/wasm/texlive/libs/freetype2/ -lfreetype
CFLAGS_FREETYPE_native_fontconfig = -I$(ROOT)/build/native/texlive/libs/freetype2/ -I$(ROOT)/build/native/texlive/libs/freetype2/freetype2/
LIBS_FREETYPE_native_fontconfig = -L$(ROOT)/build/native/texlive/libs/freetype2/ -lfreetype

CCSKIP_wasm_icu = python3 $(ROOT)/ccskip.py "$(ROOT)/build/native/texlive/libs/icu/icu-build/bin/icupkg" "$(ROOT)/build/native/texlive/libs/icu/icu-build/bin/pkgdata" --
CCSKIP_wasm_freetype2 = python3 $(ROOT)/ccskip.py "$(ROOT)/build/native/texlive/libs/freetype2/ft-build/apinames" --
CCSKIP_wasm_xetex = python3 $(ROOT)/ccskip.py $(addprefix $(ROOT)/build/native/texlive/texk/web2c, ctangle otangle tangle tangleboot ctangleboot tieweb2c) $(addprefix $(ROOT)/build/native/texlive/texk/web2c/web2c, fixwrites makecpool splitup web2c) --

OPTS_wasm_freetype2 = CC="$(CCSKIP_wasm_freetype2) emcc"
OPTS_wasm_bibtex = -e CFLAGS="$(CFLAGS_wasm_bibtex)" -e CXXFLAGS="$(CFLAGS_wasm_bibtex)"
OPTS_wasm_icu_configure = CC="$(CCSKIP_wasm_icu) emcc $(CFLAGS_wasm_icu)" CXX="$(CCSKIP_wasm_icu) em++ $(CFLAGS_wasm_icu)"
OPTS_wasm_icu_make = -e PKGDATA_OPTS="--without-assembly -O $(ROOT)/build/wasm/texlive/libs/icu/icu-build/data/icupkg.inc" -e CC="$(CCSKIP_wasm_icu) emcc $(CFLAGS_wasm_icu)" -e CXX="$(CCSKIP_wasm_icu) em++ $(CFLAGS_wasm_icu)"
OPTS_wasm_xetex = CC="$(CCSKIP_wasm_xetex) emcc" CXX="$(CCSKIP_wasm_xetex) em++"

source/texlive source/expat source/fontconfig:
	wget --no-clobber $(URL_$(notdir $@)) -O "$@.tar.gz" || true
	mkdir -p "$@" && tar -xf "$@.tar.gz" --strip-components=1 --directory="$@"

source/fontconfig.patched: source/fontconfig
	patch -d $< -Np1 -i 0002-fix-fcstats-emscripten.patch
	echo "$(SKIP)" > $</test/Makefile.in 
	touch $@

source/texlive.patched: source/texlive
	rm -rf $</texk/upmendex
	#for texprog in texk/dviout-util texk/dvipsk texk/xdvik texk/dviljk texk/dvipos texk/dvidvi texk/dvipng texk/dvi2tty texk/dvisvgm texk/dtl texk/gregorio texk/upmendex texk/cjkutils texk/musixtnt texk/tests texk/ttf2pk2 texk/ttfdump texk/makejvf texk/lcdf-typetools; do echo "$(SKIP)" > $(ROOT)/$</$$texprog/Makefile.in ; done
	touch $@

build/%/texlive/configured: source/texlive source/texlive.patched
	echo 'ac_cv_func_getwd=$${ac_cv_func_getwd=no}' > $(CACHE_$*_$(notdir $<)) 
	mkdir -p $(dir $@) && cd $(dir $@) && 		\
	$(CONFIGURE_$*) $(ROOT)/$</configure		\
	  --cache-file=$(CACHE_$*_$(notdir $<))		\
	  --prefix="$(PREFIX_$*)"					\
	  --enable-dump-share						\
	  --enable-static							\
	  --enable-xetex							\
	  --enable-dvipdfm-x						\
	  --enable-icu								\
	  --enable-freetype2						\
	  --disable-shared							\
	  --disable-multiplatform					\
	  --disable-native-texlive-build			\
	  --disable-all-pkgs						\
	  --without-x								\
	  --without-system-cairo					\
	  --without-system-gmp						\
	  --without-system-graphite2				\
	  --without-system-harfbuzz					\
	  --without-system-libgs					\
	  --without-system-libpaper					\
	  --without-system-mpfr						\
	  --without-system-pixman					\
	  --without-system-poppler					\
	  --without-system-xpdf						\
	  --without-system-icu						\
	  --without-system-fontconfig				\
	  --without-system-freetype2				\
	  --without-system-libpng					\
	  --without-system-zlib						\
	  --with-banner-add="_BUSY$*"				\
		CFLAGS="$(CFLAGS_$*_$(notdir $<))"		\
	  CPPFLAGS="$(CFLAGS_$*_$(notdir $<))" &&   \
	$(MAKE_$*) make $(MAKEFLAGS)  				
	touch $@

build/%/texlive/texk/bibtex-x/bibtexu : build/%/texlive/configured
	cd $(dir $@) && \
	$(MAKE_$*) make $(MAKEFLAGS) clean && \
	$(MAKE_$*) make $(MAKEFLAGS) $(OPTS_$*_bibtex)

## rename extern symbols
#pushd texk/dvipdfm-x
#$EMMAKE make clean
#$EMMAKE make $MAKEFLAGS CC="emcc $CFLAGS_DVIPDFMX" CXX="em++ $CFLAGS_DVIPDFMX"

build/wasm/texlive/libs/icu/icu-build/lib/libicuuc.a : build/wasm/texlive/configured build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata
	cd build/wasm/texlive/libs/icu && \
	$(CONFIGURE_wasm) $(ROOT)/source/texlive/libs/icu/configure $(OPTS_wasm_icu_configure) && \
	$(MAKE_wasm) make -C build/wasm/texlive/libs/icu $(MAKEFLAGS) $(OPTS_wasm_icu_make) && \
	echo "$(SKIP)" > build/wasm/texlive/libs/icu/icu-build/test/Makefile && \
	make -C build/native/texlive/libs/icu/icu-build $(MAKEFLAGS)

build/native/texlive/libs/icu/icu-build/lib/libicuuc.a build/native/texlive/libs/icu/icu-build/lib/libicudata.a build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata : build/native/texlive/configured
	make -C build/native/texlive/libs/icu $(MAKEFLAGS)
	make -C build/native/texlive/libs/icu/icu-build $(MAKEFLAGS)

build/wasm/texlive/libs/libs/freetype2/libfreetype.a: build/wasm/texlive/configured build/native/texlive/libs/freetype2/libfreetype.a
	$(MAKE_wasm) make -C $(dir $@) $(MAKEFLAGS) $(OPTS_wasm_freetype2)

build/%/texlive/libs/teckit/libTECkit.a build/%/texlive/libs/harfbuzz/libharfbuzz.a build/%/texlive/libs/graphite2/libgraphite2.a build/%/texlive/libs/libpng/libpng.a build/%/texlive/libs/zlib/libz.a build/%/texlive/libs/pplib/libpplib.a build/%/texlive/libs/freetype2/libfreetype.a: build/%/texlive/configured
	$(MAKE_$*) make -C $(dir $@) $(MAKEFLAGS) 

build/%/expat/libexpat.a: source/expat
	mkdir -p $(dir $@) && cd $(dir $@) && \
	$(CMAKE_$*) cmake \
	   -DCMAKE_INSTALL_PREFIX="$(PREFIX_$*)" \
	   -DCMAKE_C_FLAGS="$(CFLAGS_$*_$(notdir $<))" \
	   -DEXPAT_BUILD_DOCS=off \
	   -DEXPAT_SHARED_LIBS=off \
	   -DEXPAT_BUILD_EXAMPLES=off \
	   -DEXPAT_BUILD_FUZZERS=off \
	   -DEXPAT_BUILD_TESTS=off \
	   -DEXPAT_BUILD_TOOLS=off \
	   $(ROOT)/$< && \
	$(MAKE_$*) make $(MAKEFLAGS)

build/%/fontconfig/libfontconfig.a: source/fontconfig build/%/expat/libexpat.a build/%/texlive/libs/freetype2/libfreetype.a
	mkdir -p $(dir $@) && cd $(dir $@) && \
	$(CONFIGURE_$*) $(ROOT)/$</configure \
	   --cache-file=$(CACHE_$*_$(notdir $<))		 \
	   --prefix=$(PREFIX_$*) \
	   --enable-static \
	   --disable-shared \
	   --disable-docs \
	   --with-expat-includes="$(ROOT)/source/expat/lib" \
	   --with-expat-lib="$(ROOT)/build/$*/expat" \
	   CFLAGS="$(CFLAGS_$*_$(notdir $<))" FREETYPE_CFLAGS="$(CFLAGS_FREETYPE_$*_$(notdir $<))" FREETYPE_LIBS="$(LIBS_FREETYPE_$*_$(notdir $<))" && \
	$(MAKE_$*) make $(MAKEFLAGS)

build/%/texlive/texk/web2c/xetex: \
	build/%/texlive/libs/teckit/libTECkit.a \
	build/%/texlive/libs/harfbuzz/libharfbuzz.a \
	build/%/texlive/libs/graphite2/libgraphite2.a \
	build/%/texlive/libs/libpng/libpng.a \
	build/%/texlive/libs/zlib/libz.a \
	build/%/texlive/libs/pplib/libpplib.a \
	build/%/texlive/libs/freetype2/libfreetype.a \
	build/%/texlive/libs/icu/icu-build/lib/libicuuc.a \
	build/%/expat/libexpat.a \
	build/%/fontconfig/libfontconfig.a 
	$(MAKE_$*) make -C $(dir $@) $(MAKEFLAGS) xetex $(OPTS_$*_$(notdir $<))

build/install-tl/install-tl:
	wget --no-clobber $(URL_TEXLIVE_INSTALLER) -P source || true
	mkdir -p "$@" && tar -xf "source/$(notdir $(URL_TEXLIVE_INSTALLER))" --strip-components=1 --directory="build/install-tl"

build/texlive/profile.input:
	mkdir -p $(dir $@)
	echo selected_scheme scheme-basic > $@
	echo TEXDIR $(ROOT)/$(dir $@) >> $@
	echo TEXMFLOCAL $(ROOT)/$(dir $@)/texmf-local >> $@
	echo TEXMFSYSVAR $(ROOT)/$(dir $@)/texmf-var >> $@
	echo TEXMFSYSCONFIG $(ROOT)/$(dir $@)/texmf-config >> $@
	echo TEXMFVAR $(ROOT)/$(dir $@)/home/texmf-var >> $@

build/texlive/texmf-dist: build/install-tl/install-tl build/texlive/profile.input
	cd build/texlive && \
	$(ROOT)/build/install-tl/install-tl -profile profile.input && \
	rm -rf bin readme* tlpkg install* *.html texmf-dist/doc texmf-var/web2c
	#TEXLIVE_INSTALL_PREFIX=/opt/texlive ./install-tl

source/base:
	wget --no-clobber $(URL_TEXLIVE_BASE) -O $@.zip || true
	unzip $@.zip -d source

build/format/xetex.fmt:  build/texlive/texmf-dist source/base 
	mkdir -p $(ROOT)/build/format
	cd source/base && \
	TEXMFCNF=$(ROOT) TEXMFDIST=$(ROOT)/build/texlive/texmf-dist $(ROOT)/build/native/texlive/texk/web2c/xetex -interaction=nonstopmode -output-directory=$(ROOT)/build/format -ini -etex unpack.ins && \
	touch hyphen.cfg && \
	TEXMFCNF=$(ROOT) TEXMFDIST=$(ROOT)/build/texlive/texmf-dist $(ROOT)/build/native/texlive/texk/web2c/xetex -interaction=nonstopmode -output-directory=$(ROOT)/build/format -ini -etex latex.ltx

native: \
	build/native/texlive/libs/icu/icu-build/lib/libicuuc.a \
	build/native/texlive/libs/icu/icu-build/lib/libicudata.a \
	build/native/texlive/libs/icu/icu-build/bin/icupkg \
	build/native/texlive/libs/icu/icu-build/bin/pkgdata \
	build/native/texlive/libs/teckit/libTECkit.a \
	build/native/texlive/libs/harfbuzz/libharfbuzz.a \
	build/native/texlive/libs/graphite2/libgraphite2.a \
	build/native/texlive/libs/libpng/libpng.a \
	build/native/texlive/libs/zlib/libz.a \
	build/native/texlive/libs/pplib/libpplib.a \
	build/native/texlive/libs/freetype2/libfreetype.a \
	build/native/expat/libexpat.a \
	build/native/fontconfig/libfontconfig.a \
	build/native/texlive/texk/web2c/xetex
	echo native tools built

wasm: \
	build/wasm/texlive/libs/icu/icu-build/lib/libicuuc.a \
	build/wasm/texlive/libs/icu/icu-build/lib/libicudata.a \
	build/wasm/texlive/libs/icu/icu-build/bin/icupkg \
	build/wasm/texlive/libs/icu/icu-build/bin/pkgdata \
	build/wasm/texlive/libs/teckit/libTECkit.a \
	build/wasm/texlive/libs/harfbuzz/libharfbuzz.a \
	build/wasm/texlive/libs/graphite2/libgraphite2.a \
	build/wasm/texlive/libs/libpng/libpng.a \
	build/wasm/texlive/libs/zlib/libz.a \
	build/wasm/texlive/libs/pplib/libpplib.a \
	build/wasm/texlive/libs/freetype2/libfreetype.a \
	build/wasm/expat/libexpat.a \
	build/wasm/fontconfig/libfontconfig.a 
	echo wasm tools built

clean_native:
	rm -rf build/native

clean_format:
	rm -rf build/format

clean:
	rm -rfbuild

.PHONY:
	native clean clean_native clean_format
