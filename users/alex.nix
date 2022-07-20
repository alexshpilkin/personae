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

			define-command tig %{ terminal tig --all }
		'';
	};

	programs.git = {
		enable = true;
		package = pkgs.gitFull;
		lfs.enable = true;

		userName = "Alexander Shpilkin";
		userEmail = "ashpilkin@gmail.com";

		aliases = {
			abt = "rebase --abort";
			con = "rebase --continue";
			an = "add --intent-to-add";
			ap = "add --patch";
			com = "commit --no-gpg-sign";
			l = "log --pretty=l";
			pre = "preview";
			preview = "diff --staged";
			reb = "rebranch --no-gpg-sign";
			rebranch = "reset --interactive --reset-author-date";
			"rec" = "recommit --no-gpg-sign";
			recommit = "commit --amend --reset-author";
			rew = "rewrite --no-gpg-sign";
			rewrite = "rebase --interactive --committer-date-is-author-date";
		};

		# more merge conflicts but better markers
		extraConfig.merge.conflictStyle = "diff3";

		# like "oneline" but with PGP status
		extraConfig.pretty.l = "%C(auto)%h %Cblue%G?%Creset%C(auto)%d %s";

		# triangular workflow setup
		extraConfig.remote.pushDefault = "origin";
		extraConfig.push.default = "current";

		# nags
		extraConfig.advice.detachedHead = false;
		extraConfig.init.defaultBranch = "master";
	};

	home.packages = with pkgs; [
		gnufdisk gptfdisk inetutils psmisc tcpdump # administration
		bench breezy cvs cvsps fossil git-annex git-annex-utils hyperfine mercurial radare2 tig # development
		tealdeer cht-sh # documentation
		binwalk dos2unix file ffmpeg imagemagick libarchive pdftk unrar-wrapper zip # formats
		jq httpie maxima moreutils octave pup pv rlwrap simple-http-server wget # scripting
		fd nix-index ripgrep ripgrep-all # search
		colordiff editorconfig-core-c wdiff # text
	];
}
