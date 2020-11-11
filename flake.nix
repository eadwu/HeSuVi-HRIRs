{
  description = "eadwu.github.io flake";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs = { type = "github"; owner = "NixOS"; repo = "nixpkgs"; };

  # Flake compatability shim
  inputs.flake-compat = { type = "github"; owner = "edolstra"; repo = "flake-compat"; flake = false; };

  # Source tree(s)
  inputs.hesuvi_convert-src = { type = "git"; url = "https://gist.github.com/2519179722432fc00be57ffb5155715f.git"; flake = false; };

  outputs = { self, nixpkgs, ... }@inputs:
    let

      # Helper function to map across all inputs, excluding nixpkgs
      forAllInputs = f: nixpkgs.lib.mapAttrs f (builtins.removeAttrs inputs [ "nixpkgs" ]);

      # Generate a user-friendly version numer.
      versions = forAllInputs (_: input: builtins.substring 0 8 input.lastModifiedDate);

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs {
        inherit system;
        config = { };
        overlays = [
          self.overlay
        ];
      });

    in

    {

      # A Nixpkgs overlay.
      overlay = final: prev:
        with final.pkgs;
        {

          hesuvi_convert =
            stdenv.mkDerivation {
              pname = "hesuvi_convert";
              version = versions.hesuvi_convert-src;

              src = inputs.hesuvi_convert-src;

              buildPhase = ''
                runHook preBuild
                gcc -o hesuvi_convert hesuvi_convert.c
                runHook postBuild
              '';

              installPhase = ''
                runHook preInstall
                mkdir -p $out/bin
                cp hesuvi_convert $out/bin
                runHook postInstall
              '';
            };


        };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system:
        (with nixpkgsFor.${system};
          {
            inherit hesuvi_convert;
          })
        );

      # Development environment
      devShell = forAllSystems (system:
        with nixpkgsFor.${system};
        mkShell {
          buildInputs = [ hesuvi_convert ];
        });

      # Tests run by 'nix flake check' and by Hydra.
      checks = forAllSystems (system: self.packages.${system});

    };
}
