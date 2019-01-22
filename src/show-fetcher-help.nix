{ lib, fetcher }:

with lib;

let
  fetcherFun = toExprFun (if typeOf fetcher == "path"
    then { type = "file"; expr = fetcher; }
    else { type = "attr"; expr = pkgs: getAttrFromPath (splitString "." fetcher) pkgs; })
    (import <nixpkgs> { });

  fetcherArgs = let funArgs = functionArgs fetcherFun; in
    partition (name: funArgs.${name}) (attrNames funArgs);

  toOptionList = names: if names != []
    then concatStringsSep "\n" (map (name: "  --${name}") names)
    else "  <none>";

in ''
  The fetcher ${fetcher} produces a fixed-output derivation to use as a source.

  All options can be repeated with the last value taken,
  and can placed both before and after the parameters.

  To keep the usage section simple, the possible fetcher options have not been listed.
  They can be found in their own sections instead.

  Usage:
    nix-prefetch ${fetcher}
                 [ -f <file> | --file <file>
                 | -t <hash-algo> | --type <hash-algo> | --hash-algo <hash-algo>
                 | -h <hash> | --hash <hash>
                 | --fetch-url | --print-path | --force
                 | -q | --quiet | -v | --verbose | -vv | --debug | --skip-hash ]...
                 [hash]
                 [--]
                 ( <fetcher-option>
                   ( -f <file> | --file <file>
                   | -A <attr> | --attr <attr>
                   | -E <expr> | --expr <expr>
                   | <str> ) )...
    nix-prefetch [-v | --verbose | -vv | --debug] ${fetcher} --help

  Fetcher options (required):
  ${toOptionList fetcherArgs.wrong}

  Fetcher options (optional):
  ${toOptionList fetcherArgs.right}

  Options:
    -f, --file       When either an attribute or expression is given it has to be a path to Nixpkgs,
                    otherwise it can be a file directly pointing to a fetcher function or package derivation.
    -t, --type,
        --hash-algo  What algorithm should be used for the output hash of the resulting derivation.
    -h, --hash       When the output hash of the resulting derivation is already known,
                    it can be used to check whether it is already exists within the Nix store.
    --fetch-url      Fetch only the URL. This converts e.g. the fetcher fetchFromGitHub to fetchurl for its URL,
                    and the hash options will be applied to fetchurl instead. The name argument will be copied over.
    --print-path     Print the output path of the resulting derivation.
    --force          Always redetermine the hash, even if the given hash is already determined to be valid.
    -q, --quiet      No additional output.
    -v, --verbose    Verbose output, so it is easier to determine what is being done.
    -vv, --debug     Even more verbose output (meant for debugging purposes).
    --skip-hash      Skip determining the hash (meant for debugging purposes).
    --help           Show help message.
''
