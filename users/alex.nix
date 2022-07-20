{ lib, pkgs, ... }:

let
	inherit (lib) mkDefault;

in {
	home.extraOutputsToInstall = mkDefault [ "doc" "man" "info" ];

	home.packages = with pkgs; [
		binwalk dos2unix file ffmpeg imagemagick jq libarchive pdftk pup unrar-wrapper zip # formats
		fd fzf nix-index ripgrep ripgrep-all # search
	];
}
