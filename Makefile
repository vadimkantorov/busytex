MAKE_native = make
CMAKE_native = cmake

EXPAT_SOURCE_URL = https://github.com/libexpat/libexpat/releases/download/R_2_2_9/expat-2.2.9.tar.gz
PREFIX = prefix
ROOT := $(CURDIR)

source/expat:
	wget --no-clobber $(EXPAT_SOURCE_URL) -O source/expat.tar.gz || true
	mkdir -p source/expat || true
	tar -xf source/expat.tar.gz --strip-components=1 --directory source/expat

build/%/expat/libexpat.a: source/expat 
	mkdir -p $(dir $@) && cd $(dir $@) 
	$(CMAKE_$*) \
	   -DCMAKE_INSTALL_PREFIX="$(PREFIX_$*)" \
	   -DEXPAT_BUILD_DOCS=off \
	   -DEXPAT_SHARED_LIBS=off \
	   -DEXPAT_BUILD_EXAMPLES=off \
	   -DEXPAT_BUILD_FUZZERS=off \
	   -DEXPAT_BUILD_TESTS=off \
	   -DEXPAT_BUILD_TOOLS=off \
	   $(ROOT)/source/expat 
	
	$(MAKE_$*) $(MAKEFLAGS)
