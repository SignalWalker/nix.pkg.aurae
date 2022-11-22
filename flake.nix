{
  description = "Distributed systems runtime daemon written in Rust.";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    alejandra = {
      url = github:kamadorueda/alejandra;
      inputs.nixpkgs.follows = "nixpkgs";
    };
	crane = {
		url = "github:ipetkov/crane";
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
	crane,
	aurae,
    ...
  }:
    with builtins; let
      std = nixpkgs.lib;
	  systems = [ "x86_64-linux" "aarch64-linux" ];
    in {
      formatter = std.mapAttrs (system: pkgs: pkgs.default) inputs.alejandra.packages;
	  overlays = std.genAttrs systems (system: final: prev: let
	  	cranelib = crane.lib.${system};
		vendorDir = src: cranelib.vendorCargoDeps { cargoLock = "${aurae}/Cargo.lock"; inherit src; };
	  in {
	  	auraed = cranelib.buildPackage {
			src = cranelib.cleanCargoSource "${aurae}/auraed";
			cargoVendorDir = vendorDir "${aurae}/auraed";
			nativeBuildInputs = with final; [ pkgconf ];
			buildInputs = with final; [ protobuf libseccomp dbus ];
		};
		auraescript = cranelib.buildPackage {
			src = cranelib.cleanCargoSource "${aurae}/auraescript";
			cargoVendorDir = vendorDir "${aurae}/auraescript";
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
