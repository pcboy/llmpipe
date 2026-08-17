{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        ruby = pkgs.ruby_3_4;
        gems = pkgs.bundlerEnv {
          name = "ruby-env";
          inherit ruby;
          gemdir = ./.;
        };
        version = pkgs.lib.removePrefix "LLMP::VERSION = '" (
          pkgs.lib.removeSuffix "'\n" (pkgs.lib.readFile ./lib/llmp/version.rb)
        );
        llmp = pkgs.buildRubyGem {
          gemName = "llmp";
          inherit version ruby;
          src = ./.;
          propagatedBuildInputs = [ gems ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            gems
            (lib.lowPrio gems.wrappedRuby)
            rubyPackages.solargraph
            bashInteractive
            (bundix.override {
              bundler = bundler.override {
                inherit ruby;
              };
            })
          ];
        };
        packages.default = llmp;
      }
    );
}
