#!/usr/bin/env -S nix develop -f

{ pkgs ? import <nixpkgs> { } # FIXME bootstrap?
, callPackage ? pkgs.callPackage
, home-manager ? callPackage (import <home-manager/home-manager>) { }
, git ? pkgs.git
, jq ? pkgs.jq
}:

pkgs.mkShellNoCC { packages = [ git home-manager jq ]; }
