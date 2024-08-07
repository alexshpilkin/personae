{ config, graphical, pkgs, ... }:

{
	imports = [ graphical ];

	systemd.user.sessionVariables = config.home.sessionVariables; # FIXME is this correct?

	programs.bash.enableVteIntegration = true;

	services.gnome-keyring.enable = true;

	services.gpg-agent.pinentryPackage = pkgs.pinentry-gnome3;

	home.packages = with pkgs; with gnomeExtensions; [
		gparted pika-backup # administration
		evolution fractal gnome.polari transmission_4-gtk # communication
		ghex gitg meld # development
		amberol celluloid easyeffects gnome.gnome-sound-recorder kooha parlatype pitivi # multimedia
		dconf-editor gnome.gnome-shell-extensions gnome-tweaks helvum # settings
		hibernate-status-button keep-awake night-theme-switcher syncthing-indicator weather # shell
		foliate # text
	];
}
