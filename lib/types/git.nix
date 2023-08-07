{ config, name, lib, ... }:
{
  options = {
    type = lib.mkOption {
      type = lib.types.enum [ "git" ];
      default = "disk";
      internal = true;
      description = "Type";
    };
    src = lib.mkOption {
      type = lib.types.str;
      description = "the repo which should be cloned";
    };
    target = lib.mkOption {
      type = lib.types.str;
      description = "target folder";
      default = name;
    };
    _script = lib.mkOption {
      internal = true;
      readOnly = true;
      type = lib.types.str;
      default = ''
        maybessh git clone ${config.src} "$target"/${config.target}
      '';
      description = "script";
    };
  };
}
