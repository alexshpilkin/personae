{ gnome, pkgs, ... }:

{
	home.stateVersion = "22.05";
	imports = [ gnome ];

	home.packages = with pkgs; [
		bindfs # administration
		android-tools cambalache git-remote-gcrypt gnome-builder # development
	];
}
