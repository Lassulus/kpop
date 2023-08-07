{
  description = "populate a filesystem";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, ... }:
    {
      lib = import ./lib {
        inherit (nixpkgs) lib;
      };
    };
}
