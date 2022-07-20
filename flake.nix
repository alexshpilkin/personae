#!/usr/bin/env -S home-manager --flake

{
	inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
	inputs.nixpkgs.url = "nixpkgs/nixpkgs-unstable";

	outputs = { self, home-manager, nixpkgs }:
		let
			inherit (builtins) elemAt match pathExists readDir;
			inherit (home-manager.lib) homeManagerConfiguration;
			inherit (nixpkgs.lib)
				filterAttrs genAttrs hasSuffix mapAttrs mapAttrs' nameValuePair
				removeSuffix;

			# FIXME copied from machines
			nixPaths = dir:
				let
					isNix = entry: type:
						if type == "directory"
						then pathExists (dir + "/${entry}/default.nix")
						else hasSuffix ".nix" entry;
					toPair = entry: type:
						nameValuePair (removeSuffix ".nix" entry) (dir + "/${entry}");
				in mapAttrs' toPair (filterAttrs isNix (readDir dir));

			mkUser = name: path:
				homeManagerConfiguration {
					pkgs = nixpkgs.legacyPackages.x86_64-linux; # FIXME
					modules = [
						{
							# FIXME system.configurationRevision counterpart?
							home = rec {
								username = elemAt (match "([^@]*)(@.*)?" name) 0;
								homeDirectory = "/home/${username}";
							};
							programs.home-manager.enable = true;
						}
						path
						# FIXME user@host -> user ?
					];
				};

		in {
			homeConfigurations = mapAttrs mkUser (nixPaths ./users);
			devShells = mapAttrs (system: hmpkgs: {
				default = import ./shell.nix {
					inherit (nixpkgs.legacyPackages.${system}) pkgs;
					inherit (hmpkgs) home-manager;
				};
			}) home-manager.packages;
		};
}
