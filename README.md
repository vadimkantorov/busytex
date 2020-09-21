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

# copies binaries and TexLive TDS into ./dist
# make dist

# remove build and source completely
make clean
```

### Usage
```shell
# browser version, will serve index.html at http://localhost:8080
python3 serve.py

# local version
export FONTCONFIG_PATH=./dist/fontconfig
export FONTCONFIG_FILE=texlive.conf
export TEXMFCNF=./dist/texmf.cnf
export TEXMFDIST=./dist/texlive/texmf-dist

# node version
build/native/busytex xetex --interaction=nonstopmode --halt-on-error --no-pdf --fmt=build/latex.fmt example.tex
build/native/busytex dvipdfmx example.xdv

### native versions 
build/native/busytex xetex --interaction=nonstopmode --halt-on-error --no-pdf --fmt=build/latex.fmt example.tex
build/native/busytex dvipdfmx example.xdv
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
### TODO
1. publish a pdf to github releases: https://developer.github.com/v3/repos/releases/#create-a-release, https://developer.github.com/v3/repos/releases/#upload-a-release-asset, https://developer.github.com/v3/repos/releases/#update-a-release-asset
2. Store file sha hashes in .git directory
6. arg1/arg2
7. TexLive / xetex.js
8. Ctrl+V, command history
9. Figure out Terminal sizing
10. file tab auto-complete

### Links
https://github.com/RangerMauve/xterm-js-shell

https://github.com/latexjs/latexjs/blob/master/latexjs/Dockerfile

https://stackoverflow.com/questions/61496876/how-can-i-load-a-file-from-a-html-input-into-emscriptens-memfs-file-system

https://github.com/latexjs/latexjs

https://github.com/emscripten-core/emscripten/issues/2040

https://stackoverflow.com/questions/54466870/emscripten-offer-to-download-save-a-generated-memfs-file

https://git-scm.com/docs/gitrepository-layout

https://stackoverflow.com/questions/59983250/there-is-any-standalone-version-of-the-treeview-component-of-vscode

https://stackoverflow.com/questions/32912129/providing-stdin-to-an-emscripten-html-program

https://itnext.io/build-ffmpeg-webassembly-version-ffmpeg-js-part-3-ffmpeg-js-v0-1-0-transcoding-avi-to-mp4-f729e503a397

https://medium.com/codingtown/xterm-js-terminal-2b19ccd2a52

https://jsfiddle.net/pdfjs/wagvs9Lf/

https://mozilla.github.io/pdf.js/examples/index.html#interactive-examples

https://github.com/AREA44/vscode-LaTeX-support

https://registry.npmjs.org/monaco-editor/-/monaco-editor-0.20.0.tgz

https://github.com/lyze/xetex-js

https://tug.org/svn/texlive/trunk/Build/source/

https://github.com/TeX-Live/texlive-source

https://github.com/TeX-Live/xetex

https://github.com/kisonecat/web2js

https://github.com/kisonecat/dvi2html

https://people.math.osu.edu/fowler.291/latex/

https://github.com/manuels/texlive.js/

https://microsoft.github.io/monaco-editor/

https://browsix.org/latex-demo-sync/

https://github.com/tbfleming/em-shell

https://developer.github.com/v3/repos/contents/#create-or-update-file-contents
https://github.com/zrxiv/browserext/blob/master/backend.js
http://www.levibotelho.com/development/commit-a-file-with-the-github-api/

### Install Emscripten
```shell
# https://emscripten.org/docs/getting_started/downloads.html#installation-instructions 
git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
```

### Activate Emscripten
```shell
source ./emsdk_env.sh
```

### Build
```shell
make assets/test.txt assets/test.pdf
make cat.html
```

### Run
```shell
python3 serve.py

open https://localhost:8080
```

