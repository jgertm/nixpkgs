{ stdenv, fetchFromGitLab, fetchFromGitHub, buildGoModule, ruby
, bundlerEnv, pkgconfig
# libgit2 + dependencies
, libgit2, openssl, zlib, pcre, http-parser }:

let
  rubyEnv = bundlerEnv rec {
    name = "gitaly-env";
    inherit ruby;
    copyGemFiles = true;
    gemdir = ./.;
    gemset =
      let x = import (gemdir + "/gemset.nix");
      in x // {
        # grpc expects the AR environment variable to contain `ar rpc`. See the
        # discussion in nixpkgs #63056.
        grpc = x.grpc // {
          patches = [ ../fix-grpc-ar.patch ];
          dontBuild = false;
        };
      };
  };
in buildGoModule rec {
  version = "13.6.7";
  pname = "gitaly";

  src = fetchFromGitLab {
    owner = "gitlab-org";
    repo = "gitaly";
    rev = "v${version}";
    sha256 = "1d6vl3p2p825cdyvq8965kvmpqnsahz6f19s7q2ssahmcqxzxw6z";
  };

  vendorSha256 = "15mx5g2wa93sajbdwh58wcspg0n51d1ciwb7f15d0nm5hspz3w9r";

  passthru = {
    inherit rubyEnv;
  };

  buildFlags = [ "-tags=static,system_libgit2" ];
  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ rubyEnv.wrappedRuby libgit2 openssl zlib pcre http-parser ];
  doCheck = false;

  postInstall = ''
    mkdir -p $ruby
    cp -rv $src/ruby/{bin,lib,proto,git-hooks} $ruby
  '';

  outputs = [ "out" "ruby" ];

  meta = with stdenv.lib; {
    homepage = "https://gitlab.com/gitlab-org/gitaly";
    description = "A Git RPC service for handling all the git calls made by GitLab";
    platforms = platforms.linux;
    maintainers = with maintainers; [ roblabla globin fpletz talyz ];
    license = licenses.mit;
  };
}
