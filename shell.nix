#!/usr/bin/env -S nix develop -f

{ pkgs ? import <nixpkgs> { } # FIXME bootstrap?
, callPackage ? pkgs.callPackage
, home-manager ? callPackage (import <home-manager/home-manager>) { }
, mkShellNoCC ? pkgs.mkShellNoCC
}:

mkShellNoCC { packages = [ home-manager ]; }
