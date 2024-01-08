# Bleep-flake

A flake for the Scala build tool Bleep.

# About

A flake for Bleep. A bleeping fast scala build tool!

Bleep is a modern take on a build tool for Scala. Read all about [bleep](https://bleep.build/docs/).

However as it is quite new it is not packaged for nixpkgs. Running GraalVM native-image that does not static link to glibc does not work well on nix and needs to be patched. This flake uses autoPatchelfHook to patch it for Nix on Linux.

Most of the code in this flake is taken from the scala-cli [nixpkg](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/tools/build-managers/scala-cli/default.nix)

Only tested to work on nixOS and i have not tested if bash-completions are installed properly yet as I don't use bash... 

# Current limitations 
There are a couple of limitations because Nix and Bleep try to solve the same issue.

 - Bleep can not manage it's own versions using this flake, see [bug](https://github.com/KristianAN/bleep-flake/issues/2). 
 - Bleep can not manage JDKs with this flake for the same reason as above. Define the JDK in your flake for now.

These are really non-issues when you are using Nix, but it does mean that you can't build bleep with bleep as bleep requires the JDK version to be defined in the bleep.yml.

# Adding it to your flake

It's as simple as adding this flake as an inputs and defining bleep in the outputs

Example:

```nix
{
  description = "bleep";

  inputs = {
     nixpkgs.url = "github:NixOS/nixpkgs";
     bleepSrc.url = "github:KristianAN/bleep-flake"; # The bleep flake
     flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, bleepSrc, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
          bleep = bleepSrc.defaultPackage.${system}; # Your bleep system binary

          jdk = pkgs.jdk17_headless;

          jvmHook = ''
            JAVA_HOME="${jdk}"
          '';
      in {
        devShell = pkgs.mkShell rec {
          buildInputs = [
            bleep # Bleep bleep
            jdk
          ];
          shellHook = jvmHook;          {flake-utils, pkgs, ...}: let
  bleep = flake-utils.lib.eachDefaultSystem (system: {
    defaultPackage = let
      version = "0.0.3";  # Define the version here
      suffix = if pkgs.lib.strings.hasInfix "darwin" system then "-apple-darwin" else "-pc-linux";
    in pkgs.stdenv.mkDerivation rec {
      name = "bleep-${version}";

      nativeBuildInputs = [ pkgs.installShellFiles pkgs.makeWrapper ]
        ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;

      buildInputs = [ pkgs.glibc pkgs.zlib pkgs.stdenv.cc.cc pkgs.coreutils];

      src =
        pkgs.fetchurl {
          url = "https://github.com/oyvindberg/bleep/releases/download/v${version}/bleep-x86_64${suffix}.tar.gz";
          sha256 = "sha256-TbE5D9xHmgskchSj2sT3hTSAJnLsq9ecIEPbiVjdKqQ=";
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
          --bash <(bleep install-tab-completions-bash) \
          --zsh <(bleep install-tab-completions-zsh) \
      '';

      meta = with pkgs.lib; {
        homepage = "https://bleep.build";
        description = "A bleeping fast build tool for the Scala language";
      };
    };
  });
in
  bleep

        };
      });
}
```
If you don't want to add this as a input in your flake you can look at the bleep.nix.example file. Create a nix file in your directory, copy the contents into it, then import the file into your build.
