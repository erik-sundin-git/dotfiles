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
# goes to stderr. Run from inside the repo: `nix run .#update-debs`.
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

    for src in "$root"/nix/packages/*/source.json; do
      name=$(basename "$(dirname "$src")")
      url=$(jq -r .url "$src")
      old_version=$(jq -r .version "$src")
      old_hash=$(jq -r .hash "$src")
      old_etag=$(jq -r '.etag // ""' "$src")

      etag=$(curl -fsSIL "$url" | grep -i '^etag:' | tail -n1 | cut -d' ' -f2- | tr -d '\r' || true)
      if [[ -n "$etag" && "$etag" == "$old_etag" ]]; then
        echo "$name: unchanged ($old_version)" >&2
        continue
      fi

      echo "$name: fetching $url" >&2
      prefetch=$(nix store prefetch-file --json "$url")
      hash=$(jq -r .hash <<<"$prefetch")
      # Drop epoch and Debian build/revision suffixes: 1:1.2.3~45-1 -> 1.2.3
      version=$(dpkg-deb -f "$(jq -r .storePath <<<"$prefetch")" Version | sed -E 's/^[0-9]+://; s/[~+-].*//')

      jq --arg v "$version" --arg h "$hash" --arg e "$etag" \
        '.version = $v | .hash = $h | .etag = $e' "$src" >"$src.tmp"
      mv "$src.tmp" "$src"

      if [[ "$hash" != "$old_hash" ]]; then
        echo "$name: $old_version -> $version"
      else
        echo "$name: unchanged ($version), etag refreshed" >&2
      fi
    done
  '';
}
