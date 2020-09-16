# [WIP] TexLive 2020 compiled with Emscripten into WebAssembly and bundled into a single executable

```shell
# install and activate emscripten
emsdk install 2.0.0 # 5974288502aab433d45f53511e961aaca4079d86
emsdk activate 2.0.0
source ./emsdk/emsdk_env.sh

# clone busytex
git clone https://github.com/vadimkantorov/busytex
cd busytex

# build native tools
make -j8 native

# build TeX Directory Structure (TDS) and latex format file (latex.fmt)
make build/install-tl/install-tl
make build/texlive/profile.input
make build/texlive/texmf-dist
make build/latex.fmt

# build wasm tools
bash build_wasm.sh

# clean
make clean
```

### Portable version
https://dev.to/jochemstoel/bundle-your-node-app-to-a-single-executable-for-windows-linux-and-osx-2c89


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
