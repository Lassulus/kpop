{ lib ? import <nixpkgs/lib>
}:
  let kpopLib = {

    # main function, takes an attrset of paths and kpop values and returns the populate script
    write = cfg: (lib.evalModules {
      modules = [
        ({ config, ... }: {
          options.kpop.tree = lib.mkOption {
            type = lib.types.attrsOf (kpopLib.subType {
              types = kpopLib.types;
            });
          };
          options.kpop._script = lib.mkOption {
            type = lib.types.str;
            default = ''
              set -efu
              set -x # for debugging
              if echo "$1" | grep -q '^ssh://'; then
                ssh_connection=$(echo "$1" | grep -oP 'ssh://[^/]+')
                target=$(echo "$1" | grep -oP 'ssh://[^/]+\K.*')
              else
                target=$1
              fi
              maybessh() {
                if [ -z ''${ssh_connection:-} ]; then
                  eval "$@"
                else
                  ssh "$ssh_connection" -- "$@"
                fi
              }
              ${lib.concatMapStringsSep "\n" (x: x._script) (lib.attrValues config.kpop.tree)}
            '';
          };
          config.kpop.tree = cfg;
        })
      ];
    }).config.kpop._script;

    # like lib.types.oneOf but instead of a list takes an attrset
    # uses the field "type" to find the correct type in the attrset
    subType = { types, extraArgs ? {} }: lib.mkOptionType rec {
      name = "subType";
      description = "one of ${lib.concatStringsSep "," (lib.attrNames types)}";
      check = x: if x ? type then types.${x.type}.check x else throw "No type option set in:\n${lib.generators.toPretty {} x}";
      merge = loc: lib.foldl' (res: def: types.${def.value.type}.merge loc [
        # we add a dummy root parent node to render documentation
        (lib.recursiveUpdate { value._module.args = extraArgs; } def)
      ]) { };
      nestedTypes = types;
    };

    # import all tge types from the types directory
    types = lib.listToAttrs (
      map
        (file: lib.nameValuePair
          (lib.removeSuffix ".nix" file)
          (lib.types.submodule [ ./types/${file} ])
        )
        (lib.attrNames (builtins.readDir ./types))
    );
  };
in kpopLib
