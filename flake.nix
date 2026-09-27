{
  inputs = {
    kingstvis.url = "path:./kingstvis";
    kitten-space-agency.url = "path:./kitten-space-agency";
  };

  outputs =
    inputs@{ self, ... }:
    let
      programs = removeAttrs inputs [ "self" ];

      perProgram = builtins.attrValues (
        builtins.mapAttrs (
          name: flake: builtins.mapAttrs (_: pkgs: { ${name} = pkgs.default; }) flake.packages
        ) programs
      );
    in
    {
      packages = builtins.zipAttrsWith (_: builtins.foldl' (a: b: a // b) { }) perProgram;
    };
}
