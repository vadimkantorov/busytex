# [WIP] TexLive 2020 compiled with Emscripten into WebAssembly and bundled into a single executable

### Installation
```shell
# install and activate emscripten
git clone https://github.com/emscripten-core/emsdk
pushd emsdk
./emsdk install 2.0.0
./emsdk activate 2.0.0
source emsdk_env.sh
popd

# clone busytex
git clone https://github.com/vadimkantorov/busytex
cd busytex

# set make parallelism
export MAKEFLAGS=-j8

# download and patch texlive source
make texlive

# build native tools
make native

# build TeX Directory Structure (TDS) and latex format file (latex.fmt)
make tds

# build wasm tools
make wasm

# installs into ./install
# make install

# clean if needed
make clean # removes build and install directories
```

### Usage
```shell
# browser busy version, will serve index.html at http://localhost:8080
python3 serve.py

# node busy version
# TODO

# node regu version
# TODO

### native versions ###

export FONTCONFIG_PATH=./install/fontconfig
export FONTCONFIG_FILE=texlive.conf
export TEXMFCNF=./install/texmf.cnf
export TEXMFDIST=./install/texlive/texmf-dist

# native busy version
build/native/busytex xetex --interaction=nonstopmode --halt-on-error --no-pdf --fmt=build/latex.fmt example.tex
build/native/busytex dvipdfmx example.xdv

# native norm version
build/native/texlive/texk/web2c/xetex --interaction=nonstopmode --halt-on-error --no-pdf --fmt=build/latex.fmt example.tex
build/native/texlive/texk/dvipdfm-x/xdvipdfmx example.xdv
###

```

### References
1. [texlive.js](https://github.com/manuels/texlive.js/)
2. [xetex.js](https://github.com/lyze/xetex-js)
3. [dvi2html](https://github.com/kisonecat/dvi2html), [web2js](https://github.com/kisonecat/web2js)
4. [SwiftLaTeX](https://github.com/SwiftLaTeX/SwiftLaTeX)
5. [JavascriptSubtitlesOctopus](https://github.com/Dador/JavascriptSubtitlesOctopus)
6. fontconfig patch [1](https://github.com/Dador/JavascriptSubtitlesOctopus/blob/master/build/patches/fontconfig/0002-fix-fcstats-emscripten.patch) and [2](https://github.com/lyze/xetex-js/blob/master/fontconfig-fcstat.c.patch)

### Links
https://github.com/dmonad/pdftex.js

http://www.readytext.co.uk/?p=3590

https://github.com/skalogryz/wasmbin

https://ctan.org/tex-archive/systems/unix/tex-fpc?lang=en

https://www.tomaz.me/2014/01/08/detecting-which-process-is-creating-a-file-using-ld-preload-trick.html

http://avf.sourceforge.net/

https://arxiv.org/pdf/1908.10740.pdf

https://github.com/jacereda/fsatrace

https://github.com/fritzw/ld-preload-open/blob/master/path-mapping.c

https://adared.ch/unionfs_by_intercept/

https://gist.github.com/przemoc/571086
