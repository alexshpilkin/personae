{ config, lib, nix-index, pkgs, ... }:

let
	inherit (builtins) concatStringsSep replaceStrings;
	inherit (lib) mkDefault;
	rootConfig = config;

	kakoune-gdb = pkgs.kakouneUtils.buildKakounePluginFrom2Nix {
		pname = "kakoune-gdb";
		version = "2024-01-08";
		buildInputs = with pkgs; [ perl socat ];
		src = pkgs.fetchFromGitHub {
			owner = "occivink";
			repo = "kakoune-gdb";
			rev = "e4264aa1ba133f6e7188a6e55c2b47ffb40180b6";
			sha256 = "0w4wgi0bn72f8gq5pyjnsc4mi8pix8yid7pd3mx4lr3fz57mcv1h";
		};
		patchPhase = ''
			runHook prePatch
			substituteInPlace gdb.kak \
				--replace ' perl ' ' ${pkgs.perl}/bin/perl ' \
				--replace ' socat ' ' ${pkgs.socat}/bin/socat '
			runHook postPatch
		'';
		meta = {
			description = "gdb integration plugin";
			homepage = "https://github.com/occivink/kakoune-gdb";
		};
	};

	fzf-kak = pkgs.kakounePlugins.fzf-kak.overrideAttrs (final: prev: {
		postPatch = prev.postPatch or "" + ''
			substituteInPlace rc/modules/fzf-file.kak \
				--replace '(find*|ag*|rg*|fd*)' '(find*|*/find*|ag*|*/ag*|rg*|*/rg*|fd*|*/fd*)'
			substituteInPlace rc/modules/fzf-grep.kak \
				--replace '(grep*|rg*)' '(grep|*/grep*|rg*|*/rg*)'
		'';
	});

in {
	imports = [ nix-index ];

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
		if tput hs; then
			PS1='\['`tput tsl`'\u@\h:\w'`tput fsl`'\]'$PS1
		fi
	'';

	systemd.user.sessionVariables._JAVA_OPTIONS = concatStringsSep " " [
		"-Dgradle.user.home=\${XDG_CACHE_HOME:-$HOME/.cache}/gradle"
		"-Djava.util.prefs.userRoot=\${XDG_CONFIG_HOME:-$HOME/.config}/java"
		"-Dmaven.repo.local=\${XDG_CACHE_HOME:-$HOME/.cache}/m2"
	];

	systemd.user.sessionVariables.SSH_AUTH_SOCK =
		let
			unit = config.systemd.user.sockets.gpg-agent-ssh;
			socket = unit.Socket.ListenStream;
			expand = replaceStrings [ "%t" ] [ "\${XDG_RUNTIME_DIR}" ];
		in expand socket;

	programs.direnv = {
		enable = true;
		nix-direnv.enable = true;
	};

	programs.tmux = {
		enable = true;
		baseIndex = 1; # number windows and panes from 1
		escapeTime = 10; # delay for ECMA codes vs ESC key
		extraConfig = ''
			set-option -gu default-terminal # HM defaults to "screen"
			set-option -g mouse on
			set-option -g set-titles on
			set-option -g set-titles-string "#S:#I.#P: #T"
			new-session -A -s default
		'';
	};

	programs.fzf = {
		enable = true;
		tmux.enableShellIntegration = true;
		fileWidgetCommand = "${pkgs.fd}/bin/fd --follow --strip-cwd-prefix --type file --type symlink";
	};

	programs.ripgrep = {
		enable = true;
		arguments = [ "--smart-case" ];
	};

	systemd.user.sessionVariables.EDITOR = mkDefault config.home.sessionVariables.EDITOR;

	programs.kakoune = {
		enable = true;
		defaultEditor = true;
		config.indentWidth = 0; # tabs FTW
		config.showMatching = true; # highlight matching delimiter
		config.ui.assistant = "none"; # disable clippy
		config.ui.enableMouse = true; # (home-manager overrides the default here)
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
				name = "ModuleLoaded"; option = "tmux";
				commands = ''
					hook global RegisterModified '"' %{
						nop %sh{ tmux set-buffer "$kak_main_reg_dquote" }
					}
				'';
			}
			{
				name = "WinCreate"; option = ".*";
				commands = "git show-diff";
			}
			{
				name = "BufReload"; option = ".*";
				commands = "git update-diff";
			}
			{
				name = "BufWritePost"; option = ".*";
				commands = "git update-diff";
			}
			{
				name = "WinSetOption"; option = "filetype=c";
				commands = "lsp-enable-window";
			}
			{
				name = "WinSetOption"; option = "filetype=latex";
				commands = "addhl window/ wrap";
			}
			{
				name = "WinSetOption"; option = "filetype=nix";
				commands = "set-option window tabstop 2";
			}
		];
		config.keyMappings = [
			{ key = "<c-t>"; mode = "normal"; effect = ":fzf-mode<ret>f"; }
			{ key = "u"; mode = "goto"; docstring = "next hunk";
				effect = "<esc>:git next-hunk<ret>"; }
			{ key = "i"; mode = "goto"; docstring = "previous hunk";
				effect = "<esc>:git prev-hunk<ret>"; }
			{ key = "<c-l>"; mode = "normal"; docstring = "toggle breakpoint";
				effect = ":gdb-toggle-breakpoint<ret>"; }
			{ key = "<c-semicolon>"; mode = "normal"; docstring = "step into";
				effect = ":gdb-step<ret>"; }
			{ key = "<c-:>"; mode = "normal"; docstring = "step out";
				effect = ":gdb-finish<ret>"; }
			{ key = "<c-'>"; mode = "normal"; docstring = "step over";
				effect = ":gdb-next<ret>"; }
			{ key = "<c-backspace>"; mode = "normal"; docstring = "continue";
				effect = ":gdb-continue<ret>"; }
			{ key = "<c-|>"; mode = "normal"; docstring = "start";
				effect = ":gdb-start<ret>"; }
			{ key = "f"; mode = "user"; docstring = "fzf";
				effect = ":fzf-mode<ret>"; }
			{ key = "l"; mode = "user"; docstring = "lsp";
			  effect = ":enter-user-mode lsp<ret>"; }
			{ key = "<tab>"; mode = "insert"; docstring = "select next placeholder";
			  effect = "<a-;>:try lsp-snippets-select-next-placeholders catch " +
			           "%{ execute-keys -with-hooks <lt>tab> }<ret>"; }
			{ key = "a"; mode = "object"; docstring = "symbol";
			  effect = "<a-;>lsp-object<ret>"; }
			{ key = "e"; mode = "object"; docstring = "function or method";
			  effect = "<a-;>lsp-object Function Method<ret>"; }
			{ key = "k"; mode = "object"; docstring = "class or interface";
			  effect = "<a-;>lsp-object Class Interface Struct<ret>"; }
			{ key = "d"; mode = "object"; docstring = "error or warning";
			  effect = "<a-;>lsp-diagnostic-object --include-warnings<ret>"; }
			{ key = "D"; mode = "object"; docstring = "error";
			  effect = "<a-;>lsp-diagnostic-object<ret>"; }
		];
		plugins = with pkgs.kakounePlugins; [
			fzf-kak kakoune-lsp kakoune-gdb kakoune-rainbow
		];
		extraConfig = ''
			define-command write-delete-buffer %{ write; delete-buffer }
			alias global wdb write-delete-buffer

			define-command tig %{ terminal tig --all }

			hook global ModuleLoaded fzf-file %{
				set-option global fzf_file_command '${config.programs.fzf.fileWidgetCommand}'
			}

			eval %sh{ ${pkgs.kakounePlugins.kakoune-lsp}/bin/kak-lsp --kakoune -s $kak_session }
			lsp-stop-on-exit-enable
			lsp-inlay-diagnostics-enable global

			add-highlighter global/margin column %opt{autowrap_column} default,rgb:404040
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
			fix = "com --fixup";
			fixup = "commit --fixup";
			kp = "checkout --patch";
			l = "log --pretty=l";
			pre = "preview";
			preview = "diff --staged";
			reb = "rebranch --no-gpg-sign";
			rebranch = "rebase --interactive --autosquash --reset-author-date";
			"rec" = "recommit --no-gpg-sign";
			recommit = "commit --amend --reset-author";
			rew = "rewrite --no-gpg-sign";
			rewrite = "rebase --interactive --autosquash --committer-date-is-author-date";
			rp = "reset --patch";
		};

		# better diffs
		extraConfig.diff.algorithm = "histogram";
		extraConfig.diff.submodule = "log";
		extraConfig.status.submoduleSummary = true;

		# more merge conflicts but better markers
		extraConfig.merge.conflictStyle = "zdiff3";

		# reuse merge conflict resolutions
		extraConfig.rerere.enabled = true;

		# recursive pulls and so on by default
		extraConfig.submodule.recurse = true;

		# only fast-forward pulls
		extraConfig.pull.ff = "only";

		# like "oneline" but with PGP status
		extraConfig.pretty.l = "%C(auto)%h %Cblue%G?%Creset%C(auto)%d %s";

		# triangular workflow setup
		extraConfig.remote.pushDefault = "origin";
		extraConfig.push.default = "current";

		# github pushes
		extraConfig.url."git@github.com:" = {
			pushInsteadOf = "https://github.com/";
		};

		# rewrite notes with their commits
		extraConfig.notes.rewriteRef = "refs/notes/commits";

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

	programs.lieer.enable = true;
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
		borgbackup gnufdisk gptfdisk iftop inetutils psmisc tcpdump # administration
		yubikey-manager # communication
		azure-cli bench binutils-unwrapped.info binutils-unwrapped.man blobfuse breezy cvs cvsps flamegraph fossil gcc-unwrapped.info gcc-unwrapped.man git-absorb git-annex git-annex-utils git-extras git-review hyperfine loc mercurial perf-tools radare2 tig # development
		tealdeer cht-sh # documentation
		binwalk dos2unix exiftool file ffmpeg imagemagick libarchive pdftk unar unrar-wrapper zip # formats
		expect jq httpie maxima moreutils octave pup pv rlwrap simple-http-server wget xmlstarlet yt-dlp # scripting
		fd #ripgrep-all # search
		colordiff editorconfig-core-c wdiff # text
	];
}
