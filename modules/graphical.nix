{ pkgs, ... }:

{
	home.packages = with pkgs; [
		signal-desktop tdesktop # communication
		gentium gentium-book-basic ibm-plex inconsolata iosevka monaspace mplus-outline-fonts.githubRelease paratype-pt-sans roboto # fonts
		darktable # multimedia
		wl-clipboard # scripting
		# FIXME kiwix
		libreoffice # text
	];

	programs.tmux.extraConfig = ''
		set-option -s copy-command wl-copy
	'';
}
