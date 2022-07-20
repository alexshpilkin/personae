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

	programs.direnv.enable = true;

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

	home.sessionVariables.EDITOR = "kak";
	programs.kakoune = {
		enable = true;
		config.indentWidth = 0; # tabs FTW
		config.showMatching = true; # highlight matching delimiter
		config.ui.assistant = "none"; # disable clippy
		config.ui.setTitle = true; # update terminal title
		config.hooks = [
			{
				name = "BufNewFile"; option = ".*";
				commands = "editorconfig-load";
			}
			{
				name = "BufOpenFile"; option = ".*";
				commands = "editorconfig-load";
			}
			# open windows rather than panes
			#{
			#	name = "ModuleLoaded"; option = "tmux";
			#	commands = "alias global terminal tmux-terminal-window";
			#}
			#{
			#	name = "ModuleLoaded"; option = "tmux-repl";
			#	commands = "alias global repl-new tmux-repl-window";
			#}
			{
				name = "WinSetOption"; option = "filetype=nix";
				commands = "set-option window tabstop 2";
			}
		];
		config.keyMappings = [
			{ key = "<c-p>"; mode = "normal"; effect = ":fzf-mode<ret>"; }
		];
		plugins = with pkgs.kakounePlugins; [ fzf-kak kakoune-rainbow ];
		extraConfig = ''
			define-command write-delete-buffer %{ write; delete-buffer }
			alias global wdb write-delete-buffer
		'';
	};

	home.packages = with pkgs; [
		binwalk dos2unix file ffmpeg imagemagick jq libarchive pdftk pup unrar-wrapper zip # formats
		fd nix-index ripgrep ripgrep-all # search
		editorconfig-core-c # text
	];
}
