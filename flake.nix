#!/usr/bin/env -S home-manager --flake

{
	inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
	inputs.nixpkgs.url = "nixpkgs/nixpkgs-unstable";
	inputs.nixpkgs-unfree.url = "github:numtide/nixpkgs-unfree/nixpkgs-unstable";
	inputs.nixpkgs-unfree.inputs.nixpkgs.follows = "nixpkgs";

	outputs = { self, home-manager, nixpkgs, nixpkgs-unfree }:
		let
			inherit (builtins) elemAt match pathExists readDir;
			inherit (home-manager.lib) homeManagerConfiguration;
			inherit (nixpkgs.lib)
				filterAttrs genAttrs hasSuffix mapAttrs mapAttrs' nameValuePair optional
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

			mkModule = name: path: { imports = [ path ]; };

			mkUser = name: path:
				let
					pkgs-unfree = nixpkgs-unfree.legacyPackages.x86_64-linux; # FIXME
					username = elemAt (match "([^@]*)(@.*)?" name) 0;
					userPath = elemAt (match "([^@]*)@.*" (toString path)) 0;
					userFile = userPath + ".nix";
				in homeManagerConfiguration {
					pkgs = nixpkgs.legacyPackages.x86_64-linux; # FIXME
					extraSpecialArgs = self.homeModules // { inherit pkgs-unfree; };
					modules = [
						{
							# FIXME system.configurationRevision counterpart?
							home = {
								inherit username;
								homeDirectory = "/home/${username}";
							};
							programs.home-manager.enable = true;
						}
						path
					] ++ optional (username != name && pathExists userPath) userPath
					  ++ optional (username != name && pathExists userFile) userFile;
				};

		in {
			homeModules = mapAttrs mkModule (nixPaths ./modules);
			homeConfigurations = mapAttrs mkUser (nixPaths ./users);
			devShells = mapAttrs (system: hmpkgs: {
				default = import ./shell.nix {
					inherit (nixpkgs.legacyPackages.${system}) pkgs;
					inherit (hmpkgs) home-manager;
				};
			}) home-manager.packages;
			devShell = mapAttrs (system: shells: shells.default) self.devShells;
		};
}
