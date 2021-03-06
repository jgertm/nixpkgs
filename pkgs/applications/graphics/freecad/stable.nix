{ stdenv, mkDerivation, fetchFromGitHub, fetchpatch, cmake, ninja, coin3d,
xercesc, ode, eigen, qtbase, qttools, qtwebkit, wrapQtAppsHook,
opencascade-occt, gts, hdf5, vtk, medfile, zlib, python3Packages, swig,
gfortran, libXmu, soqt, libf2c, libGLU, makeWrapper, pkgconfig, mpi ? null }:

assert mpi != null;

let
  pythonPackages = python3Packages;
in mkDerivation rec {
  pname = "freecad";
  version = "0.18.4";

  src = fetchFromGitHub {
    owner = "FreeCAD";
    repo = "FreeCAD";
    rev = version;
    sha256 = "1phs9a0px5fnzpyx930cz39p5dis0f0yajxzii3c3sazgkzrd55s";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkgconfig
    pythonPackages.pyside2-tools
    wrapQtAppsHook
  ];

  buildInputs = [
    cmake coin3d xercesc ode eigen opencascade-occt gts
    zlib swig gfortran soqt libf2c makeWrapper mpi vtk hdf5 medfile
    libGLU libXmu qtbase qttools qtwebkit
  ] ++ (with pythonPackages; [
    matplotlib pycollada shiboken2 pyside2 pyside2-tools pivy python boost
  ]);

  patches = [
    # Fix missing app icon on Wayland. Has been upstreamed and should be safe to
    # remove in versions >= 0.19
    (fetchpatch {
      url = "https://github.com/FreeCAD/FreeCAD/commit/c4d2a358ca125d51d059dfd72dcbfba326196dfc.patch";
      sha256 = "0yqc9zrxgi2c2xcidm8wh7a9yznkphqvjqm9742qm5fl20p8gl4h";
    })
    # Fix build with Qt >= 5.15
    (fetchpatch {
      url = "https://github.com/FreeCAD/FreeCAD/commit/b2882c699b1444efadd9faee36855a965ac6a215.patch";
      sha256 = "sha256:1fs43a5aaqziaa1iicppfjd68kklmk9qrcncxs8hx2dl429z2lzv";
    })
  ];

  cmakeFlags = [
    "-DBUILD_QT5=ON"
    "-DSHIBOKEN_INCLUDE_DIR=${pythonPackages.shiboken2}/include"
    "-DSHIBOKEN_LIBRARY=Shiboken2::libshiboken"
    ("-DPYSIDE_INCLUDE_DIR=${pythonPackages.pyside2}/include"
      + ";${pythonPackages.pyside2}/include/PySide2/QtCore"
      + ";${pythonPackages.pyside2}/include/PySide2/QtWidgets"
      + ";${pythonPackages.pyside2}/include/PySide2/QtGui"
      )
    "-DPYSIDE_LIBRARY=PySide2::pyside2"
  ];

  # This should work on both x86_64, and i686 linux
  preBuild = ''
    export NIX_LDFLAGS="-L${gfortran.cc}/lib64 -L${gfortran.cc}/lib $NIX_LDFLAGS";
  '';

  # Their main() removes PYTHONPATH=, and we rely on it.
  preConfigure = ''
    sed '/putenv("PYTHONPATH/d' -i src/Main/MainGui.cpp

    qtWrapperArgs+=(--prefix PYTHONPATH : "$PYTHONPATH")
  '';

  qtWrapperArgs = [
    "--set COIN_GL_NO_CURRENT_CONTEXT_CHECK 1"
  ];

  postFixup = ''
    mv $out/share/doc $out
  '';

  meta = with stdenv.lib; {
    description = "General purpose Open Source 3D CAD/MCAD/CAx/CAE/PLM modeler";
    homepage = "https://www.freecadweb.org/";
    license = licenses.lgpl2Plus;
    maintainers = with maintainers; [ viric gebner ];
    platforms = platforms.linux;
  };
}
