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

        # Base build inputs common to all systems
        baseBuildInputs = with pkgs; [
          gtkwave
          nextpnr
          verilator
          verilog
          yosys
        ];

        # Conditionally add verible if the system is not Darwin
        buildInputs = baseBuildInputs ++ pkgs.lib.optionals (!pkgs.stdenv.isDarwin) [ pkgs.verible ];
      in
      {
        devShell = pkgs.mkShell {
          inherit buildInputs;
        };
      }
    );
}
