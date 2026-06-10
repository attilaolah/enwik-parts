{
  description = "ENWIK9 URLs playground";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      perSystem = {pkgs, ...}: let
        enwik9 = pkgs.fetchzip {
          url = "https://mattmahoney.net/dc/enwik9.zip";
          stripRoot = false;
          hash = "sha256-8mcyEe3WEBZviKGxkE+RQYH86t46WhpYVMy+rxdArJI=";
        };

        urls-txt =
          pkgs.runCommand "urls.txt" {
            nativeBuildInputs = with pkgs; [ripgrep];
          } ''
            rg -oPU '\[((?:https?|ftp):[^\]\s]*)(?:[ \t\r\n][^\]]*)?\]' \
              -r '$1' \
              "${enwik9}/enwik9" >"$out"
          '';

        urls = pkgs.stdenv.mkDerivation {
          pname = "urls";
          version = "1.0.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [zig];
          dontConfigure = true;
          dontInstall = true;
          meta.mainProgram = "urls";

          buildPhase = ''
            runHook preBuild
            export HOME="$TMPDIR"
            export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-global-cache"
            export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-local-cache"
            export ENWIK9_URLS="${urls-txt}"
            zig build --prefix "$out" -Doptimize=ReleaseSafe
            runHook postBuild
          '';
        };

        urls-test = pkgs.writeShellApplication {
          name = "urls-test";
          runtimeInputs = with pkgs; [podman coreutils];
          text = ''
            set -euo pipefail

            expected_sha256="$(sha256sum "${urls-txt}" | cut -d' ' -f1)"
            binary_path="${pkgs.lib.getExe urls}"
            rootfs="$(mktemp -d)"
            trap 'rm -rf "$rootfs"' EXIT

            actual_sha256="$(
              podman run --rm --rootfs \
                --mount "type=bind,src=$binary_path,target=/urls,ro" \
                "$rootfs" \
                /urls | sha256sum | cut -d' ' -f1
            )"

            if [ "$actual_sha256" != "$expected_sha256" ]; then
              echo "FAIL: checksum mismatch" >&2
              echo "expected: $expected_sha256" >&2
              echo "actual:   $actual_sha256" >&2
              exit 1
            fi

            echo "OK: $actual_sha256"
          '';
        };
      in {
        packages = {
          inherit enwik9 urls-txt urls urls-test;
          default = urls;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            zig
            ripgrep
          ];
          ENWIK9 = "${enwik9}/enwik9";
          ENWIK9_URLS = "${urls-txt}";
          shellHook = ''
            export ZIG_GLOBAL_CACHE_DIR="$PWD/.zig-global-cache"
            export ZIG_LOCAL_CACHE_DIR="$PWD/.zig-cache"
            mkdir -p "$ZIG_GLOBAL_CACHE_DIR" "$ZIG_LOCAL_CACHE_DIR"
          '';
        };

        apps.urls-test = {
          type = "app";
          program = pkgs.lib.getExe urls-test;
        };
      };
    };
}
