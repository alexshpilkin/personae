{ config, lib, pkgs, ... }:

let
	inherit (builtins) replaceStrings;
	inherit (lib) mkDefault;
	rootConfig = config;

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

	systemd.user.sessionVariables.SSH_AUTH_SOCK =
		let
			unit = config.systemd.user.sockets.gpg-agent-ssh;
			socket = unit.Socket.ListenStream;
			expand = replaceStrings [ "%t" ] [ "\${XDG_RUNTIME_DIR}" ];
		in "\${SSH_AUTH_SOCK:-${expand socket}}";

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

	services.gnome-keyring.components = [ "secrets" ];

	programs.gpg.enable = true;
	programs.gpg.homedir = "${config.xdg.dataHome}/gnupg";
	programs.gpg.settings = rec {
		default-key = "73E9AA114B3A894B";

		cert-digest-algo = "SHA512";
		personal-cipher-preferences = "AES256 AES192 AES";
		personal-digest-preferences = "SHA512 SHA384 SHA256 SHA224";
		personal-compress-preferences = "BZIP2 ZLIB ZIP Uncompressed";
		default-preference-list =
			personal-digest-preferences + " " +
			personal-cipher-preferences + " " +
			personal-compress-preferences;

		disable-cipher-algo = [ "3DES" "BLOWFISH" "CAMELLIA128" "CAMELLIA192" "CAMELLIA256" "CAST5" "IDEA" "TWOFISH" ];
		weak-digest = [ "RIPEMD160" "SHA1" ];
		disable-pubkey-algo = [ "ELG" "DSA" ];
		require-cross-certification = true; # future default

		auto-key-retrieve = true;
		keyserver = "hkp://keys.gnupg.net";
		#keyserver = "ldap://keyserver.pgp.com";
		#keyserver = "hkp://pgp.mit.edu";

		charset = "utf-8"; # future default
		greeting = false;
	};

	services.gpg-agent.enable = true;
	services.gpg-agent.enableSshSupport = true;

	programs.lieer = {
		enable = true;
		# local_trash_tag support is post 1.3
		package = pkgs.lieer.overrideAttrs (old: {
			src = pkgs.fetchFromGitHub {
				owner = "gauteh";
				repo = "lieer";
				rev = "11c792fbf416aedb0466f64973e29e1f4aed4916"; # master 2022-06-29
				sha256 = "0fw9vjcr2l9qkiilzibq0h88jfmlpgm6zzra9klpkyg8l3n3mcgw";
			};
		});
	};
	programs.notmuch = {
		enable = true;
		new.tags = [ "new" ];
		hooks.preNew = ''
			${config.programs.lieer.package}/bin/gmi sync \
				-C ${config.accounts.email.accounts.gmail.maildir.absPath}
		'';
	};
	programs.alot = {
		enable = true;
		settings.theme = "tomorrow";
	};

	accounts.email.maildirBasePath = "Mail";
	accounts.email.accounts.gmail = { config, ... }: {
		primary = true;

		userName = "ashpilkin@gmail.com";
		address = "ashpilkin@gmail.com";
		aliases = [ "alex.shpilkin@gmail.com" "alex@sheaf.site" ];
		flavor = "gmail.com";

		realName = "Alexander Shpilkin";
		gpg = {
			key = rootConfig.programs.gpg.settings.default-key;
			signByDefault = true;
		};

		maildir.path = ".";
		lieer = {
			enable = true;
			settings.ignore_tags = [ "new" ];
			settings.local_trash_tag = "deleted";
		};
		notmuch.enable = true;
		alot.sendMailCommand =
			"${rootConfig.programs.lieer.package}/bin/gmi send -t " +
			"-C ${config.maildir.absPath}";
	};

	services.syncthing.enable = true;

	home.packages = with pkgs; [
		gnufdisk gptfdisk inetutils psmisc tcpdump # administration
		yubikey-manager # communication
		bench binutils-unwrapped.info binutils-unwrapped.man breezy cvs cvsps fossil gcc-unwrapped.info gcc-unwrapped.man git-annex git-annex-utils hyperfine mercurial radare2 tig # development
		tealdeer cht-sh # documentation
		binwalk dos2unix file ffmpeg imagemagick libarchive pdftk unrar-wrapper zip # formats
		jq httpie maxima moreutils octave pup pv rlwrap simple-http-server wget youtube-dl # scripting
		fd nix-index ripgrep ripgrep-all # search
		colordiff editorconfig-core-c wdiff # text
	];
}
