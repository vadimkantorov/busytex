ROOT := $(CURDIR)

EXPAT_SOURCE_URL = https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz

PREFIX_wasm = prefix/wasm
PREFIX_native = prefix/native

MAKE_native = make
CMAKE_native = cmake

MAKE_wasm = emmake make
CMAKE_wasm = emcmake cmake

CFLAGS_wasm_expat = -s USE_PTHREADS=0 -s NO_FILESYSTEM=1

source/expat:
	wget --no-clobber $(EXPAT_SOURCE_URL) -O source/expat.tar.gz || true
	mkdir -p source/expat || true
	tar -xf source/expat.tar.gz --strip-components=1 --directory=source/expat

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
