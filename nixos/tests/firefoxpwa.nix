import ./make-test-python.nix ({ lib, ... }:

{
  name = "firefoxpwa";
  meta.maintainers = with lib.maintainers; [ camillemndn ];

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ./common/x11.nix ];
      environment.systemPackages = with pkgs; [ firefoxpwa firefox jq ];

      programs.firefox = {
        enable = true;
        nativeMessagingHosts.packages = [ pkgs.firefoxpwa ];
      };

      services.jellyfin.enable = true;
    };

  testScript = ''
    machine.start()

    with subtest("Install the Firefox runtime"):
        machine.succeed("mkdir -p ~/.local/share/firefoxpwa")
        machine.succeed("cp -Lr /run/current-system/sw/lib/firefox ~/.local/share/firefoxpwa/runtime")
        machine.succeed("chmod -R +w ~/.local/share/firefoxpwa/runtime")

    with subtest("Install a progressive web app"):
        machine.wait_for_unit("jellyfin.service")
        machine.wait_for_open_port(8096)
        machine.succeed("firefoxpwa site install http://localhost:8096/web/manifest.json >&2")

    with subtest("Launch the progressive web app"):
        machine.succeed("firefoxpwa site launch $(jq -r < ~/.local/share/firefoxpwa/config.json '.sites | keys[0]') >&2")
        machine.wait_for_window("Jellyfin")
  '';
})
