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

# build native tools
make native

# build TeX Directory Structure (TDS) and latex format file (latex.fmt)
make build/install-tl/install-tl
make build/texlive/profile.input
make build/texlive/texmf-dist
make source/base
make build/format/latex.fmt

# build wasm tools
make wasm
make build/fontconfig/texlive.conf
make build/texlive.data

# clean
make clean
```

### Usage
```shell
BUSYTEX=build/native/busytex
LATEXFMT=build/latex.fmt

$BUSYTEX xetex --interaction=nonstopmode --halt-on-error --no-pdf --fmt=$LATEXFMT example.tex
$BUSYTEX dvipdfmx example.xdv
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
