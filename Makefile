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
EMROOT := $(dir $(shell which emcc))

TEXLIVE_BUILD_DIR=$(ROOT)/build/wasm/texlive
WEB2C_NATIVE_TOOLS_DIR=$(ROOT)/build/native/texlive/texk/web2c
FONTCONFIG_BUILD_DIR=$(ROOT)/build/wasm/fontconfig
EXPAT_BUILD_DIR=$(ROOT)/build/wasm/expat

PREFIX_wasm = $(ROOT)/build/wasm/prefix
PREFIX_native = $(ROOT)/build/native/prefix

MAKE_wasm = emmake make
CMAKE_wasm = emcmake cmake
CONFIGURE_wasm = emconfigure
AR_wasm = emar
MAKE_native = make
CMAKE_native = cmake
AR_native = $(AR)

TOTAL_MEMORY = 536870912
SKIP = all install:

CACHE_native_texlive = $(ROOT)/build/native-texlive.cache
CACHE_wasm_texlive = $(ROOT)/build/wasm-texlive.cache
CACHE_native_fontconfig = $(ROOT)/build/native-fontconfig.cache
CACHE_wasm_fontconfig = $(ROOT)/build/wasm-fontconfig.cache

CFLAGS_XDVIPDFMX = -Dmain='__attribute__((visibility(\"default\"))) busymain_dvipdfmx' -Dcheck_for_jpeg=dvipdfmx_check_for_jpeg -Dcheck_for_bmp=dvipdfmx_check_for_bmp -Dcheck_for_png=dvipdfmx_check_for_png -Dseek_absolute=dvidpfmx_seek_absolute -Dseek_relative=dvidpfmx_seek_relative -Dseek_end=dvidpfmx_seek_end -Dtell_position=dvidpfmx_tell_position -Dfile_size=dvidpfmx_file_size -Dmfgets=dvipdfmx_mfgets -Dwork_buffer=dvipdfmx_work_buffer -Dget_unsigned_byte=dvipdfmx_get_unsigned_byte -Dget_unsigned_pair=dvipdfmx_get_unsigned_pair
CFLAGS_BIBTEX = -Dmain='__attribute__((visibility(\"default\"))) busymain_bibtex' -Dinitialize=bibtex_initialize -Deoln=bibtex_eoln -Dlast=bibtex_last -Dhistory=bibtex_history -Dbad=bibtex_bad -Dxchr=bibtex_xchr -Dbuffer=bibtex_buffer -Dclose_file=bibtex_close_file -Dusage=bibtex_usage
CFLAGS_XETEX = -Dmain='__attribute__((visibility(\"default\"))) busymain_xetex'

CFLAGS_wasm_bibtex = -s TOTAL_MEMORY=$(TOTAL_MEMORY)
CFLAGS_wasm_texlive = -s ERROR_ON_UNDEFINED_SYMBOLS=0 -I$(ROOT)/build/wasm/texlive/libs/icu/include -I$(ROOT)/source/fontconfig
CFLAGS_wasm_icu = -s ERROR_ON_UNDEFINED_SYMBOLS=0
# bug: https://github.com/emscripten-core/emscripten/issues/12093
CFLAGS_wasm_fontconfig = -Duuid_generate_random=uuid_generate
CFLAGS_wasm_fontconfig_FREETYPE = -I$(ROOT)/build/wasm/texlive/libs/freetype2/ -I$(ROOT)/build/wasm/texlive/libs/freetype2/freetype2/
LIBS_wasm_fontconfig_FREETYPE = -L$(ROOT)/build/wasm/texlive/libs/freetype2/ -lfreetype

CFLAGS_native_texlive = -I$(ROOT)/build/native/texlive/libs/icu/include -I$(ROOT)/source/fontconfig
CFLAGS_native_fontconfig_FREETYPE = -I$(ROOT)/build/native/texlive/libs/freetype2/ -I$(ROOT)/build/native/texlive/libs/freetype2/freetype2/
LIBS_native_fontconfig_FREETYPE = -L$(ROOT)/build/native/texlive/libs/freetype2/ -lfreetype
PKGDATAFLAGS_wasm_icu = --without-assembly -O $(ROOT)/build/wasm/texlive/libs/icu/icu-build/data/icupkg.inc

CCSKIP_wasm_icu = python3 $(ROOT)/ccskip.py $(ROOT)/build/native/texlive/libs/icu/icu-build/bin/icupkg $(ROOT)/build/native/texlive/libs/icu/icu-build/bin/pkgdata --
CCSKIP_wasm_freetype2 = python3 $(ROOT)/ccskip.py $(ROOT)/build/native/texlive/libs/freetype2/ft-build/apinames --
CCSKIP_wasm_xetex = python3 $(ROOT)/ccskip.py $(addprefix $(ROOT)/build/native/texlive/texk/web2c/, ctangle otangle tangle tangleboot ctangleboot tie xetex) $(addprefix $(ROOT)/build/native/texlive/texk/web2c/web2c/, fixwrites makecpool splitup web2c) --

OPTS_wasm_icu_configure = CC="$(CCSKIP_wasm_icu) emcc $(CFLAGS_wasm_icu)" CXX="$(CCSKIP_wasm_icu) em++ $(CFLAGS_wasm_icu)"
OPTS_wasm_icu_make = -e PKGDATA_OPTS="$(PKGDATAFLAGS_wasm_icu)" -e CC="$(CCSKIP_wasm_icu) emcc $(CFLAGS_wasm_icu)" -e CXX="$(CCSKIP_wasm_icu) em++ $(CFLAGS_wasm_icu)"
OPTS_wasm_bibtex = -e CFLAGS="$(CFLAGS_BIBTEX) $(CFLAGS_wasm_bibtex)" -e CXXFLAGS="$(CFLAGS_BIBTEX) $(CFLAGS_wasm_bibtex)"
OPTS_wasm_freetype2 = CC="$(CCSKIP_wasm_freetype2) emcc"
OPTS_wasm_xetex = CC="$(CCSKIP_wasm_xetex) emcc $(CFLAGS_XETEX)" CXX="$(CCSKIP_wasm_xetex) em++ $(CFLAGS_XETEX)"
OPTS_wasm_xdvipdfmx= CC="emcc $(CFLAGS_XDVIPDFMX)" CXX="em++ $(CFLAGS_XDVIPDFMX)"
OPTS_native_xdvipdfmx= CC="$(CC) $(CFLAGS_XDVIPDFMX)" CXX="$(CXX) $(CFLAGS_XDVIPDFMX)"

OBJ_XETEX = libmd5.a lib/lib.a synctexdir/xetex-synctex.o xetex-xetexini.o xetex-xetex0.o xetex-xetex-pool.o xetexdir/xetex-xetexextra.o libxetex.a
OBJ_DVIPDF = texlive/texk/dvipdfm-x/xdvipdfmx.a
OBJ_BIBTEX = texlive/texk/bibtex-x/bibtex8.a
OBJ_DEPS = texlive/libs/harfbuzz/libharfbuzz.a texlive/libs/graphite2/libgraphite2.a texlive/libs/teckit/libTECkit.a texlive/libs/libpng/libpng.a texlive/libs/freetype2/libfreetype.a texlive/libs/pplib/libpplib.a texlive/libs/zlib/libz.a texlive/libs/libpaper/libpaper.a texlive/libs/icu/icu-build/lib/libicuuc.a texlive/libs/icu/icu-build/lib/libicudata.a texlive/texk/kpathsea/.libs/libkpathsea.a fontconfig/src/.libs/libfontconfig.a expat/libexpat.a 
INCLUDE_DEPS = texlive/libs/icu/include fontconfig

all:
	make texlive
	make native
	make tds
	make wasm

source/texlive.downloaded source/expat.downloaded source/fontconfig.downloaded:
	mkdir -p $(basename $@)
	wget --no-clobber $(URL_$(notdir $(basename $@))) -O "$(basename $@).tar.gz" || true
	tar -xf "$(basename $@).tar.gz" --strip-components=1 --directory="$(basename $@)"
	touch $@

source/fontconfig.patched: source/fontconfig.downloaded
	patch -d $(basename $<) -Np1 -i $(ROOT)/0002-fix-fcstats-emscripten.patch
	echo "$(SKIP)" > source/fontconfig/test/Makefile.in 
	touch $@

source/texlive.patched: source/texlive.downloaded
	rm -rf $(addprefix source/texlive/, texk/upmendex texk/dviout-util texk/dvipsk texk/xdvik texk/dviljk texk/dvipos texk/dvidvi texk/dvipng texk/dvi2tty texk/dvisvgm texk/dtl texk/gregorio texk/cjkutils texk/musixtnt texk/tests texk/ttf2pk2 texk/ttfdump texk/makejvf texk/lcdf-typetools) || true
	#for texprog in texk/dviout-util texk/dvipsk texk/xdvik texk/dviljk texk/dvipos texk/dvidvi texk/dvipng texk/dvi2tty texk/dvisvgm texk/dtl texk/gregorio texk/upmendex texk/cjkutils texk/musixtnt texk/tests texk/ttf2pk2 texk/ttfdump texk/makejvf texk/lcdf-typetools; do echo "$(SKIP)" > $(ROOT)/$</$$texprog/Makefile.in ; done
	touch $@

build/%/texlive.configured: source/texlive.patched
	mkdir -p $(basename $@)
	echo 'ac_cv_func_getwd=$${ac_cv_func_getwd=no}' > $(CACHE_$*_texlive) 
	cd $(basename $@) &&                        \
	$(CONFIGURE_$*) $(ROOT)/source/texlive/configure		\
	  --cache-file=$(CACHE_$*_texlive)  		\
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
		CFLAGS="$(CFLAGS_$*_texlive)"		\
	  CPPFLAGS="$(CFLAGS_$*_texlive)" &&   \
	$(MAKE_$*) 
	touch $@

build/wasm/texlive/libs/icu/icu-build/lib/libicuuc.a : build/wasm/texlive.configured build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata
	cd build/wasm/texlive/libs/icu && \
	$(CONFIGURE_wasm) $(ROOT)/source/texlive/libs/icu/configure $(OPTS_wasm_icu_configure) && \
	$(MAKE_wasm) $(OPTS_wasm_icu_make) && \
	echo "$(SKIP)" > icu-build/test/Makefile && \
	$(MAKE_wasm) -C icu-build  $(OPTS_wasm_icu_make) 

build/native/texlive/libs/icu/icu-build/lib/libicuuc.a build/native/texlive/libs/icu/icu-build/lib/libicudata.a build/native/texlive/libs/icu/icu-build/bin/icupkg build/native/texlive/libs/icu/icu-build/bin/pkgdata : build/native/texlive.configured
	$(MAKE_native) -C build/native/texlive/libs/icu 
	$(MAKE_native) -C build/native/texlive/libs/icu/icu-build 

build/wasm/texlive/libs/freetype2/libfreetype.a: build/wasm/texlive.configured build/native/texlive/libs/freetype2/libfreetype.a
	cd $(dir $@) && $(MAKE_wasm) $(OPTS_wasm_freetype2)

build/%/texlive/libs/teckit/libTECkit.a build/%/texlive/libs/harfbuzz/libharfbuzz.a build/%/texlive/libs/graphite2/libgraphite2.a build/%/texlive/libs/libpng/libpng.a build/%/texlive/libs/libpaper/libpaper.a build/%/texlive/libs/zlib/libz.a build/%/texlive/libs/pplib/libpplib.a build/%/texlive/libs/freetype2/libfreetype.a: build/%/texlive build/%/texlive.configured
	$(MAKE_$*) -C $(dir $@)  

build/%/expat/libexpat.a: source/expat.downloaded
	mkdir -p $(dir $@) && cd $(dir $@) && \
	$(CMAKE_$*)  \
	   -DEXPAT_BUILD_DOCS=off \
	   -DEXPAT_SHARED_LIBS=off \
	   -DEXPAT_BUILD_EXAMPLES=off \
	   -DEXPAT_BUILD_FUZZERS=off \
	   -DEXPAT_BUILD_TESTS=off \
	   -DEXPAT_BUILD_TOOLS=off \
	   $(ROOT)/$(basename $<) 
	$(MAKE_$*) -C $(dir $@)

build/%/fontconfig/src/.libs/libfontconfig.a: source/fontconfig.patched build/%/expat/libexpat.a build/%/texlive/libs/freetype2/libfreetype.a
	mkdir -p $(dir $@) && cd $(dir $@) && \
	$(CONFIGURE_$*) $(ROOT)/$(basename $<)/configure \
	   --cache-file=$(CACHE_$*_fontconfig)		 \
	   --prefix=$(PREFIX_$*) \
	   --enable-static \
	   --disable-shared \
	   --disable-docs \
	   --with-expat-includes="$(ROOT)/source/expat/lib" \
	   --with-expat-lib="$(ROOT)/build/$*/expat" \
	   CFLAGS="$(CFLAGS_$*_fontconfig)" FREETYPE_CFLAGS="$(CFLAGS_$*_fontconfig_FREETYPE)" FREETYPE_LIBS="$(LIBS_$*_fontconfig_FREETYPE)" && \
	$(MAKE_$*)  

################################################################################################################

build/native/texlive/texk/dvipdfm-x/xdvipdfmx build/native/texlive/texk/bibtex-x/bibtex8: build/native/texlive.configured
	$(MAKE_native) -C $(dir $@) clean
	$(MAKE_native) -C $(dir $@)
	
build/wasm/texlive/texk/dvipdfm-x/xdvipdfmx.a: build/wasm/texlive.configured
	$(MAKE_wasm) -C $(dir $@) clean
	$(MAKE_wasm) -C $(dir $@) $(OPTS_wasm_$(notdir $(basename $@)))
	$(AR_wasm) -crs $@ $(dir $@)/*.o

build/wasm/texlive/texk/dvipdfm-x/bibtex8.a: build/wasm/texlive.configured
	#TODO: set CSFINPUT=/bibtex
	$(MAKE_wasm) -C $(dir $@) clean
	$(MAKE_wasm) -C $(dir $@) $(OPTS_wasm_$(notdir $(basename $@)))
	$(AR_wasm) -crs $@ $(dir $@)/bibtex8-*.o

build/wasm/texlive/texk/web2c/libxetex.a: build/wasm/texlive.configured
	# copying generated C files from native version, since string offsets are off
	# many more object files are produced
	$(MAKE_wasm) -C $(dir $@) clean
	mkdir -p build/wasm/texlive/texk/web2c
	cp build/native/texlive/texk/web2c/*.c build/wasm/texlive/texk/web2c
	$(MAKE_wasm) -C $(dir $@) synctexdir/xetex-synctex.o xetex $(OPTS_wasm_xetex)

build/native/texlive/texk/web2c/xetex: 
	$(MAKE_native) -C $(dir $@) xetex 


################################################################################################################

build/install-tl/install-tl:
	mkdir -p $(dir $@)
	wget --no-clobber $(URL_TEXLIVE_INSTALLER) -P source || true
	tar -xf "source/$(notdir $(URL_TEXLIVE_INSTALLER))" --strip-components=1 --directory="$(dir $@)"

build/fontconfig/texlive.conf:
	mkdir -p $(dir $@)
	echo '<?xml version="1.0"?>' > $@
	echo '<!DOCTYPE fontconfig SYSTEM "fonts.dtd">' >> $@
	echo '<fontconfig>' >> $@
	echo '<dir>/texlive/texmf-dist/fonts/opentype</dir>' >> $@
	echo '<dir>/texlive/texmf-dist/fonts/type1</dir>' >> $@
	echo '</fontconfig>' >> $@

build/texlive/profile.input:
	mkdir -p $(dir $@)
	echo selected_scheme scheme-basic > $@
	echo TEXDIR $(ROOT)/$(dir $@) >> $@
	echo TEXMFLOCAL $(ROOT)/$(dir $@)/texmf-local >> $@
	echo TEXMFSYSVAR $(ROOT)/$(dir $@)/texmf-var >> $@
	echo TEXMFSYSCONFIG $(ROOT)/$(dir $@)/texmf-config >> $@
	echo TEXMFVAR $(ROOT)/$(dir $@)/home/texmf-var >> $@

build/texlive/texmf-dist: build/install-tl/install-tl build/texlive/profile.input
	# https://www.tug.org/texlive/doc/install-tl.html
	mkdir -p $(dir $@)
	TEXLIVE_INSTALL_NO_RESUME=1 $< -profile build/texlive/profile.input
	rm -rf $(addprefix $(dir $@)/, bin readme* tlpkg install* *.html texmf-dist/doc texmf-var/web2c)

build/format/latex.fmt: build/native/texlive/texk/web2c/xetex build/texlive/texmf-dist 
	mkdir -p $(dir $@)
	rm $(dir $@)/* || true
	wget --no-clobber $(URL_TEXLIVE_BASE) -P source || true
	unzip -o -j $(notdir $(URL_TEXLIVE_BASE)) -d $(dir $@)
	TEXMFCNF=$(ROOT) TEXMFDIST=build/texlive/texmf-dist $< -interaction=nonstopmode -output-directory=$(dir $@) -ini -etex unpack.ins 
	touch hyphen.cfg 
	TEXMFCNF=$(ROOT) TEXMFDIST=build/texlive/texmf-dist $< -interaction=nonstopmode -output-directory=$(dir $@) -ini -etex latex.ltx

build/wasm/texlive.data: build/format/latex.fmt build/texlive/texmf-dist build/fontconfig/texlive.conf build/texmf.cnf
	#https://github.com/emscripten-core/emscripten/issues/12214
	mkdir -p $(dir $@)
	echo > build/empty
	# --use-preload-cache
	python3 $(EMROOT)/tools/file_packager.py $@ --js-output=build/wasm/texlive.js --lz4 \
		--preload build/empty@/bin/busytex \
		--preload build/fontconfig/texlive.conf@/fontconfig/texlive.conf \
		--preload build/texmf.cnf@/texmf.cnf \
		--preload build/texlive@/texlive \
		--preload source/texlive/texk/bibtex-x/csf@/bibtex \
		--preload build/empty@/hello \
		--preload $<@/latex.fmt
		

build/texmf.cnf: build/texlive/texmf-dist
	cp $</web2c/texmf.cnf $@

################################################################################################################

build/wasm/busytex.js:
	emcc -s ALLOW_MEMORY_GROWTH=1 -s MODULARIZE=1 -s ASSERTIONS=1 -s EXPORT_NAME=busytex -o $@ -g -O2 --pre-js build/wasm/texlive.js -s TOTAL_MEMORY=$(TOTAL_MEMORY) -s ERROR_ON_UNDEFINED_SYMBOLS=0 -s FORCE_FILESYSTEM=1 -s LZ4=1 -s INVOKE_RUN=0 -s EXPORTED_FUNCTIONS='["_main"]' -s EXPORTED_RUNTIME_METHODS='["callMain","FS", "ENV", "allocateUTF8OnStack"]' -lm $(addprefix build/wasm/texlive/texk/web2c/, $(OBJ_XETEX)) $(addprefix build/wasm/, $(OBJ_DVIPDF) $(OBJ_BIBTEX) $(OBJ_DEPS)) $(addprefix -Ibuild/wasm/, $(INCLUDE_DEPS)) busytex.c

################################################################################################################

texlive:
	make source/texlive.downloaded
	make source/texlive.patched

native: 
	#make build/native/texlive.configured
	#make build/native/texlive/libs/libpng/libpng.a 
	#make build/native/texlive/libs/libpaper/libpaper.a 
	#make build/native/texlive/libs/zlib/libz.a 
	#make build/native/texlive/libs/teckit/libTECkit.a 
	#make build/native/texlive/libs/harfbuzz/libharfbuzz.a 
	#make build/native/texlive/libs/graphite2/libgraphite2.a 
	#make build/native/texlive/libs/pplib/libpplib.a 
	#make build/native/texlive/libs/freetype2/libfreetype.a 
	#make build/native/texlive/libs/icu/icu-build/lib/libicuuc.a 
	#make build/native/texlive/libs/icu/icu-build/lib/libicudata.a
	#make build/native/texlive/libs/icu/icu-build/bin/icupkg 
	#make build/native/texlive/libs/icu/icu-build/bin/pkgdata 
	#make build/native/expat/libexpat.a
	#make build/native/fontconfig/src/.libs/libfontconfig.a
	# busy 
	#make build/native/texlive/texk/web2c/xetex
	make build/native/texlive/texk/dvipdfm-x/xdvipdfmx
	make build/native/texlive/texk/bibtex-x/bibtex8
	#make build/native/busytex

tds:
	make build/install-tl/install-tl
	make build/texlive/profile.input
	make build/texlive/texmf-dist
	make build/format/latex.fmt
	make build/texmf.cnf
	make build/fontconfig/texlive.conf
	make build/wasm/texlive.data

wasm:
	#make build/wasm/texlive.configured
	#make build/wasm/texlive/libs/libpng/libpng.a 
	#make build/wasm/texlive/libs/libpaper/libpaper.a 
	#make build/wasm/texlive/libs/zlib/libz.a 
	#make build/wasm/texlive/libs/teckit/libTECkit.a 
	#make build/wasm/texlive/libs/harfbuzz/libharfbuzz.a 
	#make build/wasm/texlive/libs/graphite2/libgraphite2.a 
	#make build/wasm/texlive/libs/pplib/libpplib.a 
	#make build/wasm/texlive/libs/freetype2/libfreetype.a 
	#make build/wasm/texlive/libs/icu/icu-build/lib/libicuuc.a 
	#make build/wasm/texlive/libs/icu/icu-build/lib/libicudata.a
	#make build/wasm/expat/libexpat.a
	#make build/wasm/fontconfig/src/.libs/libfontconfig.a
	## busy
	#make build/wasm/texlive/texk/dvipdfm-x/bibtex8.a
	#make build/wasm/texlive/texk/dvipdfm-x/xdvipdfmx.a
	#make build/wasm/texlive/texk/web2c/libxetex.a
	make build/wasm/busytex.js

clean_tds:
	rm -rf build/texlive

clean_native:
	rm -rf build/native

clean_format:
	rm -rf build/format

clean_dist:
	rm -rf dist

clean:
	rm -rf build source

dist:
	mkdir -p $@
	cp build/wasm/busytex.js build/wasm/texlive.data build/wasm/busytex.wasm  $@
	#cp -r build/native/busytex build/texlive build/texmf.cnf build/fontconfig $@

.PHONY:	dist install all texlive tds native wasm clean clean_tds clean_dist clean_native clean_format
