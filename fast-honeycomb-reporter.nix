{pkgs ? import <nixpkgs> {}}:
let src = pkgs.fetchFromGitHub {
    owner  = "marcopolo";
    repo   = "fast-honeycomb-reporter";
    rev    = "8a6dde8949c60cfe159540bbc2b603fdee4ac02f";
    sha256 = "sha256:13v1l96icakvdpihrp5vk88b2lwvwik48qvgrkyii6bl7fjcnc2v";
  };
in
import "${src}/fast-honeycomb-reporter.nix" { inherit pkgs; }