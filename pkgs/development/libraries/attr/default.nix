{ stdenv, fetchurl, gettext }:

# Note: this package is used for bootstrapping fetchurl, and thus
# cannot use fetchpatch! All mutable patches (generated by GitHub or
# cgit) that are needed here should be included directly in Nixpkgs as
# files.

stdenv.mkDerivation rec {
  name = "attr-2.4.48";

  src = fetchurl {
    url = "mirror://savannah/attr/${name}.tar.gz";
    sha256 = "1rr4adzwax4bzr2c00f06zcsljv5y6p9wymz1g89ww7cb2rp5bay";
  };

  outputs = [ "bin" "dev" "out" "man" "doc" ];

  nativeBuildInputs = [ gettext ];

  patches = [
    # fix fakechroot: https://github.com/dex4er/fakechroot/issues/57
    ./syscall.patch
  ];

  postPatch = ''
    for script in install-sh include/install-sh; do
      patchShebangs $script
    done
  '';

  meta = with stdenv.lib; {
    homepage = "https://savannah.nongnu.org/projects/attr/";
    description = "Library and tools for manipulating extended attributes";
    platforms = platforms.linux;
    license = licenses.gpl2Plus;
  };
}
