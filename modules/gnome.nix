{ graphical, pkgs, ... }:

{
	imports = [ graphical ];

	home.packages = with pkgs; with gnomeExtensions; [
		deja-dup gparted pika-backup # administration
		evolution fractal gnome.polari transmission-gtk # communication
		cambalache gnome.ghex gitg gnome-builder meld # development
		celluloid gnome.gnome-sound-recorder kooha lollypop pitivi pulseeffects-pw # multimedia
		gnome.dconf-editor gnome.gnome-shell-extensions gnome.gnome-tweaks # settings
		hibernate-status-button syncthing-indicator # shell
		foliate # text
	];
}
