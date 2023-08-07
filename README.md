kpop is a library to populate a filesystem. it generates a shellscript which can populate a directory.
kpop is configured with nix, the output is a shellscript which takes the directory to populate as $1.
$1 can be in the style of ssh://user@host:/some/path. in this case kpop populates the target via ssh

example code:

```nix
{
  kpop,
  ...
}:
kpop.write {
  "/srv/http/my-webblog" = {
    imports = [kpop.path];
    src = ./myBlog; # copies into nix-store
  };
  "/srv/http/my-isos" = {
    imports = [kpop.path];
    owner = "nginx";
    group = "nginx";
    mode = "u=rwXg=rwXo-rwX";
    src = "${toString ./.}/my-downloaded-isos"; # does not copy into the store
  };
  "/srv/http/nixos.iso" = {
    imports = [kpop.curl];
    src = "http://nixos.org/isos/nixos-minimal.iso";
    owner = "nginx";
  };
  "/srv/http/my-generated-iso" = {
    imports = [kpop.derivation];
    gcroot = "my-iso.gcroot";
    src = pkgs.writeText "this-should-be-an-iso.md" ''
      hello please pretend this is an iso
    '';
  };
  "/srv/http/stockholm" = {
    imports = [kpop.git];
    src = "https://cgit.krebsco.de/stockholm";
  };
  "/srv/http/stooockholm" = {
    imports = [kpop.symlink];
    target = "/srv/http/stockholm";
  };
  "/srv/http/something-we-cant-precalculate" = {
    imports = [kpop.script];
    script = pkgs.writers.writeDash "do_cool_stuff" ''
      ${pkgs.curl}/bin/curl http://localhost:3000/some-stats.json |
        ${pkgs.jq}/bin/jq '.[] | select('somestat')' > "$out"
    '';
  };
  "/var/lib/secrets" = {
    imports = [kpop.passwordstore];
    src = "$HOME/.password-store/hosts/somemagichost";
    name = "hosts/somemagichost";
  };
}
...
```

kpop can also be used by via the libs directly

```nix
  ... some nixos config ...
  systemd.services.nginx.serviceConfig.ExecStartPre = [
    (pkgs.writeScript "populate-stockholm" ''
      ${kpop.lib.git {
        src = "https://cgit.krebsco.de/stockholm"
      }} "/srv/http/stockholm"
    )
  ];
```

some more examples

```nix
  ... some nixos config ...
  systemd.services.my-weather-service = {
    ...
    serviceConfig.ExecStartPre = [
      "+$(pkgs.writers.writeDash "get_secrets" ''
        ${kpop.write {
          "/weather.token" = {
            type = "age";
            src = "/var/lib/crypted_secrets/myServer/weather-api-token";
          };
        }} "/run/weather/api-token"
      '';
    ];
  };
```
