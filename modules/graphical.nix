{ pkgs, pkgs-unfree, ... }:

{
	home.packages = with pkgs; [
		pkgs-unfree.slack tdesktop pkgs-unfree.zoom-us # communication
		pkgs-unfree.android-studio # development
		gentium gentium-book-basic ibm-plex inconsolata iosevka paratype-pt-sans roboto pkgs-unfree.vistafonts # fonts
		darktable # multimedia
		wl-clipboard # scripting
		kiwix libreoffice pkgs-unfree.masterpdfeditor4 # text
	];
}
