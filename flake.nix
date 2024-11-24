{
  description = "Verilog dev env";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        # Python package with required dependencies
        pythonEnv = pkgs.python39.withPackages (ps: with ps; [
        ]);

        # Base build inputs common to all systems
        baseBuildInputs = with pkgs; [
          gtkwave
          icestorm
          nextpnr
          pythonEnv
          verilator
          verilog
          yosys
        ];

        # Conditionally add packages if the system is not Darwin
        buildInputs = baseBuildInputs ++
          pkgs.lib.optionals (!pkgs.stdenv.isDarwin) [
            # these packages don't work correctly on Darwin
            pkgs.verible
            pkgs.xdot
          ];
      in
      {
        devShell = pkgs.mkShell {
          inherit buildInputs;
        };
      }
    );
}
