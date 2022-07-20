{ gnome, pkgs, pkgs-unfree, ... }:

{
	home.stateVersion = "22.05";
	imports = [ gnome ];

	home.packages = with pkgs; [
		bindfs # administration
		pkgs-unfree.android-studio android-tools cambalache git-remote-gcrypt gnome-builder # development
	];
}
