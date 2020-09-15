URL_texlive = https://github.com/TeX-Live/texlive-source/archive/9ed922e7d25e41b066f9e6c973581a4e61ac0328.tar.gz
URL_expat = https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
URL_fontconfig = https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.1.tar.gz

ROOT := $(CURDIR)

PREFIX_wasm = prefix/wasm
PREFIX_native = prefix/native

MAKE_native = make
CMAKE_native = cmake

MAKE_wasm = emmake make
CMAKE_wasm = emcmake cmake

CFLAGS_wasm_expat = -s USE_PTHREADS=0 -s NO_FILESYSTEM=1

source/texlive source/expat source/fontconfig:
	wget --no-clobber $(URL_$(notdir $@)) -O "$@.tar.gz" || true
	mkdir -p "$@" && tar -xf "$@.tar.gz" --strip-components=1 --directory="$@"

build/%/expat/libexpat.a: source/expat 
	mkdir -p $(dir $@) && \
	cd $(dir $@) && \
	$(CMAKE_$*) \
	   -DCMAKE_INSTALL_PREFIX="$(PREFIX_$*)" \
	   -DCMAKE_C_FLAGS="$(CFLAGS_$*_$(notdir $^))" \
	   -DEXPAT_BUILD_DOCS=off \
	   -DEXPAT_SHARED_LIBS=off \
	   -DEXPAT_BUILD_EXAMPLES=off \
	   -DEXPAT_BUILD_FUZZERS=off \
	   -DEXPAT_BUILD_TESTS=off \
	   -DEXPAT_BUILD_TOOLS=off \
	   $(ROOT)/$^ && \
	$(MAKE_$*) $(MAKEFLAGS)

clean_native_expat:
	rm -rf build/native/expat

.PHONY:
	clean_native/expat
