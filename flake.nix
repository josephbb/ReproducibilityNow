{
  description = "R (renv) + Python 3.12 (uv) data analysis environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # System libraries so renv can compile CRAN packages (tidyverse etc.).
      # Day-1 tip: skip this list — edit DESCRIPTION / pyproject.toml instead.
      libs = with pkgs; [
        stdenv.cc.cc.lib
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
      ];
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          # --- what you'll actually use ---
          R
          rPackages.renv # R packages ← renv.lock
          python312
          uv # Python packages ← uv.lock
          cmdstan # Stan backend for brms / cmdstanr

          # System RStudio + Nix R (avoids Nix's broken Electron RStudio).
          (writeShellScriptBin "rstudio" ''
            export RSTUDIO_WHICH_R="${lib.getExe R}"
            exec /usr/bin/rstudio "$@"
          '')

          # --- so renv can build packages from source ---
          gnumake
          gcc
          gfortran
          pkg-config
          pandoc
          cacert
          cmake
        ]
        ++ libs;

        env = {
          UV_PYTHON = "${pkgs.python312}/bin/python3.12";
          UV_PYTHON_DOWNLOADS = "never";
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libs;
          # Point cmdstanr at the Nix-provided CmdStan (don't download another).
          CMDSTAN = "${pkgs.cmdstan}/opt/cmdstan";
          cmdstanr_no_ver_check = "TRUE";
        };

        shellHook = ''
          echo
          echo "  1. uv sync                      # Python (uv.lock)"
          echo "  2. Rscript -e 'renv::restore()' # R (renv.lock)"
          echo "  3. rstudio                      # system GUI + Nix R"
          echo "  4. ./scripts/register-jupyter-kernel.sh   # VS Code Jupyter kernel"
          echo
          echo "  Edit packages in:  pyproject.toml  (Python)"
          echo "                     DESCRIPTION     (R)"
          echo
        '';
      };
    };
}
