{ fetchurl
, stdenv
, fetchpatch
, substituteAll
, accountsservice
, adwaita-icon-theme
, cheese
, clutter
, clutter-gtk
, colord
, colord-gtk
, cups
, docbook_xsl
, fontconfig
, gdk-pixbuf
, gettext
, glib
, glib-networking
, glibc
, gnome-bluetooth
, gnome-color-manager
, gnome-desktop
, gnome-online-accounts
, gnome-session
, gnome-settings-daemon
, gnome3
, grilo
, grilo-plugins
, gsettings-desktop-schemas
, gsound
, gtk3
, ibus
, libcanberra-gtk3
, libgnomekbd
, libgtop
, libgudev
, libhandy
, libkrb5
, libpulseaudio
, libpwquality
, librsvg
, libsecret
, libsoup
, libwacom
, libxml2
, libxslt
, meson
, modemmanager
, mutter
, networkmanager
, networkmanagerapplet
, libnma
, ninja
, pkgconfig
, polkit
, python3
, samba
, shared-mime-info
, sound-theme-freedesktop
, tracker
, tracker-miners
, tzdata
, udisks2
, upower
, epoxy
, gnome-user-share
, gnome-remote-desktop
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "gnome-control-center";
  version = "3.36.4";

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${stdenv.lib.versions.majorMinor version}/${pname}-${version}.tar.xz";
    sha256 = "0m7pxjgymc7aqqz0vcmlq91nxnwzd1v7v1gdhrfam49krxmk80mc";
  };

  nativeBuildInputs = [
    docbook_xsl
    gettext
    libxslt
    meson
    ninja
    pkgconfig
    python3
    shared-mime-info
    wrapGAppsHook
  ];

  buildInputs = [
    accountsservice
    adwaita-icon-theme
    cheese
    clutter
    clutter-gtk
    colord
    colord-gtk
    epoxy
    fontconfig
    gdk-pixbuf
    glib
    glib-networking
    gnome-bluetooth
    gnome-desktop
    gnome-online-accounts
    gnome-remote-desktop # optional, sharing panel
    gnome-settings-daemon
    gnome-user-share # optional, sharing panel
    grilo
    grilo-plugins # for setting wallpaper from Flickr
    gsettings-desktop-schemas
    gsound
    gtk3
    ibus
    libcanberra-gtk3
    libgtop
    libgudev
    libhandy
    libkrb5
    libnma
    libpulseaudio
    libpwquality
    librsvg
    libsecret
    libsoup
    libwacom
    libxml2
    modemmanager
    mutter # schemas for the keybindings
    networkmanager
    polkit
    samba
    tracker
    tracker-miners # for search locations dialog
    udisks2
    upower
  ];

  patches = [
    (substituteAll {
      src = ./paths.patch;
      gcm = gnome-color-manager;
      gnome_desktop = gnome-desktop;
      inherit glibc libgnomekbd tzdata;
      inherit cups networkmanagerapplet;
    })

    # https://gitlab.gnome.org/GNOME/gnome-control-center/-/issues/1173
    (fetchpatch {
      url = "https://gitlab.gnome.org/GNOME/gnome-control-center/-/commit/27e1140c9d4ad852b4dc6a132a14cd5532d52997.patch";
      sha256 = "nU3szjKfXpRek8hhsxiCJNgMeDeIRK3QVo82D9R+kL4=";
    })
  ];

  postPatch = ''
    chmod +x build-aux/meson/meson_post_install.py # patchShebangs requires executable file
    patchShebangs build-aux/meson/meson_post_install.py
  '';

  mesonFlags = [
    "-Dgnome_session_libexecdir=${gnome-session}/libexec"
  ];

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix XDG_DATA_DIRS : "${sound-theme-freedesktop}/share"
      # Thumbnailers (for setting user profile pictures)
      --prefix XDG_DATA_DIRS : "${gdk-pixbuf}/share"
      --prefix XDG_DATA_DIRS : "${librsvg}/share"
      # WM keyboard shortcuts
      --prefix XDG_DATA_DIRS : "${mutter}/share"
    )
    for i in $out/share/applications/*; do
      substituteInPlace $i --replace "Exec=gnome-control-center" "Exec=$out/bin/gnome-control-center"
    done
  '';

  passthru = {
    updateScript = gnome3.updateScript {
      packageName = pname;
      attrPath = "gnome3.${pname}";
    };
  };

  meta = with stdenv.lib; {
    description = "Utilities to configure the GNOME desktop";
    license = licenses.gpl2Plus;
    maintainers = teams.gnome.members;
    platforms = platforms.linux;
  };
}
