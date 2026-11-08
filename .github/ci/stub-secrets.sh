#!/usr/bin/env bash
# CI has no git-crypt key (public repo, and the key can't be rotated). Every
# tracked nix/secrets file but the .gitattributes exceptions must be git-crypt
# ciphertext here (catches a commit made from a clone without git-crypt set
# up), and secrets.yaml must be sops-encrypted. Each encrypted file is swapped
# for .github/ci/<name>-stub.nix; the dirty tracked files are what the flake
# evaluates.
set -u
status=0
for f in $(git ls-files nix/secrets); do
  name=$(basename "$f")
  case $name in
    .gitattributes | .sops.yaml) continue ;;
    secrets.yaml)
      grep -q '^sops:' "$f" || { echo "::error file=$f::not sops-encrypted"; status=1; }
      continue
      ;;
  esac
  stub=".github/ci/${name%.nix}-stub.nix"
  if ! cmp -s -n 10 <(printf '\0GITCRYPT\0') "$f"; then
    echo "::error file=$f::committed in plaintext (not git-crypt encrypted)"
    status=1
  elif [ -f "$stub" ]; then
    cp "$stub" "$f"
  else
    echo "::error file=$f::encrypted, but $stub is missing"
    status=1
  fi
done
exit "$status"
