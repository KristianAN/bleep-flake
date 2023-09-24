{
  description = "A bleeping fast scala build tool!";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system: {
      defaultPackage = let
        pkgs = import nixpkgs { inherit system; };
        version = "0.0.2";  # Define the version here
        suffix = if pkgs.lib.strings.hasInfix "darwin" system then "-apple-darwin" else "-pc-linux";
        in pkgs.stdenv.mkDerivation rec {
          name = "bleep-${version}";

          nativeBuildInputs = [ pkgs.installShellFiles pkgs.makeWrapper ]
            ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;

          buildInputs = [ pkgs.glibc pkgs.zlib pkgs.stdenv.cc.cc ];

          src =
            pkgs.fetchurl {
              url = "https://github.com/oyvindberg/bleep/releases/download/v${version}/bleep-x86_64${suffix}.tar.gz";
              sha256 = "sha256-iu0wV8cFHf74qZKzvM7n4D8wH5ZPBU7U3VV/Nz8ESZw=";
            };

          unpackPhase = ''
            runHook preUnpack
            tar -xf $src
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall
            install -Dm755 bleep $out/bin/.bleep-wrapped
            makeWrapper $out/bin/.bleep-wrapped $out/bin/bleep \
              --argv0 "$out/bin/bleep"
            runHook postInstall
          '';

          dontAutoPatchelf = true;

          postFixup = pkgs.lib.optionalString pkgs.stdenv.isLinux ''
            autoPatchelf $out
          '' + ''
            mkdir temp
            cp $out/bin/.bleep-wrapped temp/bleep
            PATH="./temp:$PATH"

            installShellCompletion --cmd bleep \
              --bash <(bleep install-completions-bash) \
              --zsh <(bleep install-completions-zsh) \
          '';

          meta = with pkgs.lib; {
            homepage = "https://bleep.build";
            description = "A bleeping fast build tool for the Scala language";
          };
        };
    });
}
