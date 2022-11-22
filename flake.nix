{
  description = "Distributed systems runtime daemon written in Rust.";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    alejandra = {
      url = github:kamadorueda/alejandra;
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      url = github:nix-community/naersk;
      inputs.nixpkgs.follows = "nixpkgs";
    };
	aurae = {
		url = "github:aurae-runtime/aurae";
		flake = false;
	};
  };
  outputs = inputs @ {
    self,
    nixpkgs,
	naersk,
	aurae,
    ...
  }:
    with builtins; let
      std = nixpkgs.lib;
	  systems = [ "x86_64-linux" "aarch64-linux" ];
    in {
      formatter = std.mapAttrs (system: pkgs: pkgs.default) inputs.alejandra.packages;
	  overlays = std.genAttrs systems (system: final: prev: let
	  	nlib = naersk.lib.${system};
		# vendorDir = src: cranelib.vendorCargoDeps { cargoLock = "${aurae}/Cargo.lock"; inherit src; };
	  in {
	  	auraed = nlib.buildPackage {
			pname = "auraed";
			src = aurae;
			targets = [ "aurae" ];
			cargoBuildOptions = base: base ++ [ "-p" "auraed" ];
			nativeBuildInputs = with final; [ pkgconf ];
			buildInputs = with final; [ protobuf libseccomp dbus ];
		};
		auraescript = nlib.buildPackage {
			pname = "auraescript";
			src = aurae;
			targets = [ "auraescript" ];
			cargoBuildOptions = base: base ++ [ "-p" "auraescript" ];
			nativeBuildInputs = with final; [ pkgconf ];
			buildInputs = with final; [ protobuf libseccomp dbus ];
		};
	  });
	  packages = mapAttrs (system: overlay: let
	  	pkgs = import nixpkgs {
			localSystem = builtins.currentSystem or system;
			crossSystem = system;
			overlays = [ overlay ];
		};
	  in {
	  	inherit (pkgs) auraed auraescript;
	  }) self.overlays;
    };
}
