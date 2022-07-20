{ lib, pkgs, ... }:

let
	inherit (lib) mkDefault;

in {
	home.extraOutputsToInstall = mkDefault [ "doc" "man" "info" ];

	programs.bash.enable = true;
	programs.bash.historyControl = [ "ignoredups" "ignorespace" ];

	programs.bash.initExtra = ''
		reset='\['`tput sgr0`'\]'
		if [ "$NO_COLOR" ]; then
			color=; reset=
		elif [ `id -u` -eq 0 ]; then
			color='\['`tput setaf 1`'\]' # red
		else
			color='\['`tput setaf 3`'\]' # yellow
		fi
		PS1=$color'\u@\h:\w\$ '$reset
		PS2=$color'> '$reset
		PS3=$color''$reset
		PS4=$color'+ '$reset
	'';

	programs.tmux = {
		enable = true;
		baseIndex = 1; # number windows and panes from 1
		escapeTime = 10; # delay for ECMA codes vs ESC key
		newSession = true; # create session on attach
		extraConfig = ''
			set-option -g mouse on
			# FIXME set-option -s copy-command wl-copy
		'';
	};

	programs.fzf = {
		enable = true;
		tmux.enableShellIntegration = true;
	};

	home.packages = with pkgs; [
		binwalk dos2unix file ffmpeg imagemagick jq libarchive pdftk pup unrar-wrapper zip # formats
		fd nix-index ripgrep ripgrep-all # search
	];
}
