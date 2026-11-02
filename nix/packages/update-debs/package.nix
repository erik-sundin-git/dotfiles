{
  writeShellApplication,
  curl,
  dpkg,
  git,
  jq,
}:

# Refreshes every nix/packages/*/source.json (packages fetched from an
# unversioned "latest" URL). Skips the download when the server's etag is
# unchanged. Prints one line per version/hash change on stdout; progress
# goes to stderr. Exits non-zero if any package failed, after updating the
# rest. Run from inside the repo: `nix run .#update-debs`.
writeShellApplication {
  name = "update-debs";
  runtimeInputs = [
    curl
    dpkg
    git
    jq
  ];
  text = ''
    root=$(git rev-parse --show-toplevel)

    # One package's failure (vendor outage, bad download) must not stop the
    # others. errexit is off inside a function called from `if`/`||`, so every
    # step returns explicitly.
    update_one() {
      local src=$1 name url old_version old_hash old_etag etag prefetch hash version
      name=$(basename "$(dirname "$src")")
      url=$(jq -r .url "$src") || return 1
      old_version=$(jq -r .version "$src") || return 1
      old_hash=$(jq -r .hash "$src") || return 1
      old_etag=$(jq -r '.etag // ""' "$src") || return 1

      etag=$(curl -fsSIL "$url" | grep -i '^etag:' | tail -n1 | cut -d' ' -f2- | tr -d '\r' || true)
      if [[ -n "$etag" && "$etag" == "$old_etag" ]]; then
        echo "$name: unchanged ($old_version)" >&2
        return 0
      fi

      echo "$name: fetching $url" >&2
      prefetch=$(nix store prefetch-file --json "$url") || return 1
      hash=$(jq -r .hash <<<"$prefetch") || return 1
      # Drop epoch and Debian build/revision suffixes: 1:1.2.3~45-1 -> 1.2.3
      version=$(dpkg-deb -f "$(jq -r .storePath <<<"$prefetch")" Version | sed -E 's/^[0-9]+://; s/[~+-].*//') || return 1
      if [[ -z "$version" ]]; then
        echo "$name: could not read the package version" >&2
        return 1
      fi

      jq --arg v "$version" --arg h "$hash" --arg e "$etag" \
        '.version = $v | .hash = $h | .etag = $e' "$src" >"$src.tmp" || return 1
      mv "$src.tmp" "$src" || return 1

      if [[ "$hash" != "$old_hash" ]]; then
        echo "$name: $old_version -> $version"
      else
        echo "$name: unchanged ($version), etag refreshed" >&2
      fi
    }

    failed=0
    for src in "$root"/nix/packages/*/source.json; do
      if ! update_one "$src"; then
        echo "FAILED: $(basename "$(dirname "$src")")" >&2
        rm -f "$src.tmp"
        failed=1
      fi
    done
    exit "$failed"
  '';
}
