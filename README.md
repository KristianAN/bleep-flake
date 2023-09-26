# Bleep-flake

A flake for the Scala build tool Bleep.

# About

A flake for Bleep. A bleeping fast scala build tool!

Bleep is a modern take on a build tool for Scala. Read all about [bleep](https://bleep.build/docs/).

However as it is quite new it is not packaged for nixpkgs. Running GraalVM native-image that does not static link to glibc does not work well on nix and needs to be patched. This flake uses autoPatchelfHook to patch it for Nix on Linux.

Most of the code in this flake is taken from the scala-cli [nixpkg](https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/tools/build-managers/scala-cli/default.nix)

Only tested to work on nixOS and i have not tested if bash-completions are installed properly yet as I don't use bash... 

# Current limitations 
Bleep can not manage it's own versions using this flake, see [bug](https://github.com/KristianAN/bleep-flake/issues/2). 
Bleep can not manage JDKs with this flake for the same reason as above. Define the JDK in your flake for now. 
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
          shellHook = jvmHook;          
        };
      });
}

