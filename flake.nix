{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      perSystem = { config, self', inputs', pkgs, system, ... }: let
        overlays = [ (import inputs.rust-overlay) ];
        pkgs = import inputs.nixpkgs {
          inherit system overlays;
        };
      in {
        packages = {
          default = pkgs.rustPlatform.buildRustPackage rec {
            pname = "vlnr";
            version = "0.1.3";

            src = ./.;

            cargoLock = {
              lockFile = ./Cargo.lock;
            };

            nativeBuildInputs = with pkgs; [
              pkg-config
            ];

            buildInputs = with pkgs; [
              iptables
            ];

            shellHook = ''
              export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath buildInputs}"
            '';
          };
          
          vlnr = self'.packages.default;
        };

        devShells.default = pkgs.mkShell rec {
          buildInputs = with pkgs; [
            rust-bin.stable.latest.default
            rust-analyzer
            pkg-config
            clang
            systemdLibs
          ];
          shellHook = ''
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath buildInputs}"
          '';
        };
      };
    };
}
