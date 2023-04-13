{ config, graphical, pkgs, ... }:

{
	imports = [ graphical ];

	systemd.user.sessionVariables = config.home.sessionVariables; # FIXME is this correct?

	programs.bash.enableVteIntegration = true;

	services.gnome-keyring.enable = true;

	services.gpg-agent.pinentryFlavor = "gnome3";

	home.packages = with pkgs; with gnomeExtensions; [
		gparted pika-backup # administration
		evolution fractal gnome.polari transmission-gtk # communication
		gnome.ghex gitg meld # development
		celluloid easyeffects gnome.gnome-sound-recorder kooha lollypop parlatype pitivi # multimedia
		gnome.dconf-editor gnome.gnome-shell-extensions gnome.gnome-tweaks # settings
		hibernate-status-button keep-awake night-theme-switcher syncthing-indicator weather # shell
		foliate # text
	];
}
