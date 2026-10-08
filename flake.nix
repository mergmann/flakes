{
  inputs = {
    kingstvis.url = "path:./kingstvis";
    kitten-space-agency.url = "path:./kitten-space-agency";
    photocraft.url = "path:./photocraft";
    filmcraft.url = "path:./filmcraft";
  };

  outputs =
    inputs@{ self, ... }:
    let
      programs = removeAttrs inputs [ "self" ];

      nest =
        pkgs:
        let
          rest = removeAttrs pkgs [ "default" ];
        in
        if pkgs ? default then pkgs.default // rest else rest;

      perProgram = builtins.attrValues (
        builtins.mapAttrs (
          name: flake: builtins.mapAttrs (_: pkgs: { ${name} = nest pkgs; }) (flake.packages or { })
        ) programs
      );
    in
    {
      packages = builtins.zipAttrsWith (_: builtins.foldl' (a: b: a // b) { }) perProgram;
    };
}
