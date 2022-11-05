{ pkgs, pkgs-unfree, ... }:

{
	home.packages = with pkgs; [
		signal-desktop tdesktop pkgs-unfree.zoom-us # communication
		gentium gentium-book-basic ibm-plex inconsolata iosevka paratype-pt-sans roboto pkgs-unfree.vistafonts # fonts
		darktable # multimedia
		wl-clipboard # scripting
		kiwix libreoffice pkgs-unfree.masterpdfeditor4 # text
	];
}
