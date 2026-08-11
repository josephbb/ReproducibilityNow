{
  description = "R (renv) + Python 3.12 (uv) data analysis environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin" # Apple Silicon
        "x86_64-darwin" # Intel Mac
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          inherit (pkgs) lib;

          # System libraries so renv can compile CRAN packages (tidyverse etc.).
          # Day-1 tip: skip this list — edit DESCRIPTION / pyproject.toml instead.
          libs =
            with pkgs;
            [
              zlib
              openssl
              curl
              libxml2
              libpng
              libjpeg
              libtiff
              libwebp
              freetype
              fontconfig
              harfbuzz
              fribidi
              icu
              xz
              bzip2
              pcre2
              libuv
              gettext
              glib
            ]
            ++ lib.optionals pkgs.stdenv.isLinux [
              stdenv.cc.cc.lib
            ];
        in
        {
          default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                # --- what you'll actually use ---
                R
                rPackages.renv # R packages ← renv.lock
                python312
                uv # Python packages ← uv.lock
                cmdstan # Stan backend for brms / cmdstanr
                just

                # --- so renv can build packages from source ---
                gnumake
                gfortran
                pkg-config
                pandoc
                cacert
                cmake
              ]
              ++ lib.optionals pkgs.stdenv.isLinux [
                gcc
                # System RStudio + Nix R (avoids Nix's broken Electron RStudio).
                (writeShellScriptBin "rstudio" ''
                  export RSTUDIO_WHICH_R="${lib.getExe R}"
                  exec /usr/bin/rstudio "$@"
                '')
              ]
              ++ libs;

            env = {
              UV_PYTHON = "${pkgs.python312}/bin/python3.12";
              UV_PYTHON_DOWNLOADS = "never";
              SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
              # Point cmdstanr at the Nix-provided CmdStan (don't download another).
              CMDSTAN = "${pkgs.cmdstan}/opt/cmdstan";
              cmdstanr_no_ver_check = "TRUE";
              # Headers/libs for compiling CRAN packages under Nix.
              CPATH = lib.makeSearchPath "include" libs;
              LIBRARY_PATH = lib.makeLibraryPath libs;
              PKG_CONFIG_PATH = lib.makeSearchPath "lib/pkgconfig" libs;
              PKG_CPPFLAGS = "-I${pkgs.gettext}/include";
              # Force link flags for packages (e.g. textshaping) whose configure
              # otherwise drops fribidi/harfbuzz when glib.pc is incomplete.
              PKG_LIBS = "-L${pkgs.gettext}/lib -lintl -L${pkgs.fribidi}/lib -lfribidi -L${pkgs.harfbuzz}/lib -lharfbuzz -L${pkgs.freetype}/lib -lfreetype";
              R_MAKEVARS_USER = pkgs.writeText "R_Makevars" ''
                PKG_CPPFLAGS += -I${pkgs.gettext}/include
                PKG_LIBS += -L${pkgs.gettext}/lib -lintl -L${pkgs.fribidi}/lib -lfribidi -L${pkgs.harfbuzz}/lib -lharfbuzz -L${pkgs.freetype}/lib -lfreetype
              '';
            }
            // lib.optionalAttrs pkgs.stdenv.isLinux {
              LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libs;
            }
            // lib.optionalAttrs pkgs.stdenv.isDarwin {
              DYLD_FALLBACK_LIBRARY_PATH = lib.makeLibraryPath libs;
            };

            shellHook = ''
              # Prefer Nix R/Python over Homebrew/CRAN in /usr/local (login shells).
              export PATH="${
                lib.makeBinPath [
                  pkgs.R
                  pkgs.python312
                  pkgs.uv
                  pkgs.just
                  pkgs.cmdstan
                ]
              }:$PATH"

              echo
              echo "  nix develop shell ready on ${system}"
              echo
              echo "  1. uv sync                      # Python (uv.lock)"
              echo "  2. Rscript -e 'renv::restore()' # R (renv.lock)"
              echo "     or: just sync / just reproduce"
              ${
                if pkgs.stdenv.isLinux then
                  ''echo "  3. rstudio                      # system GUI + Nix R"''
                else
                  ''echo "  3. open RStudio.app             # set RSTUDIO_WHICH_R to Nix R if needed"''
              }
              echo "  4. ./scripts/register-jupyter-kernel.sh   # VS Code Jupyter kernel"
              echo
              echo "  Edit packages in:  pyproject.toml  (Python)"
              echo "                     DESCRIPTION     (R)"
              echo
              echo "  Run analysis:      just py | just ipynb | just r | just rmd"
              echo "  Using R:           $(command -v R)"
              echo
            '';
          };
        }
      );
    };
}
