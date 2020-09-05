TEXLIVE_TEXMF_URL=ftp://tug.org/texlive/historic/2020/texlive-20200406-texmf.tar.xz 
TEXLIVE_TLPDB_URL=ftp://tug.org/texlive/historic/2020/texlive-20200406-tlpdb-full.tar.gz
TEXLIVE_BASE_URL=http://mirrors.ctan.org/macros/latex/base.zip
TEXLIVE_INSTALLER_URL=http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
TEXLIVE_BASE_NAME=$(basename $TEXLIVE_BASE_URL .zip)

TEXLIVE=$PWD/texlive
ROOT=$PWD
XELATEX_EXE=$PREFIX/bin/xelatex
XETEX_EXE=$PREFIX/bin/xetex

export TEXMFDIST=$PWD/texlive/texmf-dist

mkdir -p $TEXLIVE
echo selected_scheme scheme-basic > $TEXLIVE/profile.input
echo TEXDIR $TEXLIVE >> $TEXLIVE/profile.input
echo TEXMFLOCAL $TEXLIVE/texmf-local >> $TEXLIVE/profile.input
echo TEXMFSYSVAR $TEXLIVE/texmf-var >> $TEXLIVE/profile.input
echo TEXMFSYSCONFIG $TEXLIVE/texmf-config >> $TEXLIVE/profile.input
echo TEXMFVAR $PWD/home/texmf-var >> $TEXLIVE/profile.input
wget --no-clobber $TEXLIVE_INSTALLER_URL
cd $TEXLIVE
tar -xzvf ../install-tl-unx.tar.gz
./install-tl-*/install-tl -profile $TEXLIVE/profile.input
rm -rf bin readme* tlpkg install* *.html texmf-dist/doc texmf-var/web2c

cd $ROOT
wget --no-clobber $TEXLIVE_BASE_URL
mkdir -p latex_format
cd latex_format
unzip -o ../$(basename $TEXLIVE_BASE_URL)
cd $TEXLIVE_BASE_NAME
$XELATEX_EXE -ini -etex unpack.ins
touch hyphen.cfg
$XELATEX_EXE -ini -etex latex.ltx

find $TEXLIVE -type f > texlive.lst 
