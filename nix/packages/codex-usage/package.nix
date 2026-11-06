{
  writeShellApplication,
  coreutils,
  jq,
}:

# Render Codex ChatGPT-plan rate limits as Waybar custom-module JSON. Query
# Codex's local app-server so it owns authentication and backend routing.
writeShellApplication {
  name = "waybar-codex-usage";
  runtimeInputs = [
    coreutils
    jq
  ];
  text = ''
    unknown() {
      jq -cn --arg tooltip "$1" '{text: "Codex ?", tooltip: $tooltip, class: "unknown"}'
    }

    codex_bin=''${CODEX_BIN:-codex}
    if ! command -v "$codex_bin" >/dev/null 2>&1; then
      unknown "Codex usage unavailable (Codex CLI not found)"
      exit 0
    fi

    coproc codex_server { "$codex_bin" app-server --listen stdio:// 2>/dev/null; }
    server_pid=$!
    server_in=''${codex_server[1]}
    server_out=''${codex_server[0]}
    cleanup() {
      kill "$server_pid" 2>/dev/null || true
      wait "$server_pid" 2>/dev/null || true
    }
    trap cleanup EXIT

    printf '%s\n' '{"method":"initialize","id":1,"params":{"clientInfo":{"name":"waybar-codex-usage","title":"Waybar Codex Usage","version":"1.0"}}}' >&"$server_in"
    initialized=false
    for _ in {1..10}; do
      if IFS= read -r -t 1 -u "$server_out" line; then
        if jq -e '.id == 1 and .result != null' <<< "$line" >/dev/null 2>&1; then
          initialized=true
          break
        fi
      fi
    done
    if [ "$initialized" != true ]; then
      unknown "Codex usage unavailable (app-server initialization failed)"
      exit 0
    fi

    printf '%s\n' '{"method":"initialized","params":{}}' '{"method":"account/rateLimits/read","id":2,"params":{}}' >&"$server_in"
    response=
    for _ in {1..12}; do
      if IFS= read -r -t 1 -u "$server_out" line; then
        if jq -e '.id == 2' <<< "$line" >/dev/null 2>&1; then
          response=$line
          break
        fi
      fi
    done
    if [ -z "$response" ]; then
      unknown "Codex usage unavailable (rate-limit request timed out)"
      exit 0
    fi

    if ! output=$(jq -c '
      def valid_window:
        type == "object" and (.usedPercent | type) == "number";
      def percent($window):
        if $window == null then "—"
        else "\(($window.usedPercent | floor | if . < 0 then 0 elif . > 100 then 100 else . end))%" end;
      def reset($window):
        if ($window.resetsAt | type) == "number" then
          $window.resetsAt | strflocaltime("%a %H:%M")
        else "—" end;
      def duration($window; $fallback):
        if $window == null then $fallback
        elif ($window.windowDurationMins | type) != "number" then $fallback
        elif $window.windowDurationMins >= 1440 then
          "\(($window.windowDurationMins / 1440 | round))d"
        elif $window.windowDurationMins >= 60 then
          "\(($window.windowDurationMins / 60 | round))h"
        else "\($window.windowDurationMins)m" end;

      if .error != null then
        {text: "Codex ?", tooltip: "Codex usage unavailable (Codex account authentication required)", class: "unknown"}
      else
        (.result.rateLimitsByLimitId.codex // .result.rateLimits // {}) as $limits
        | ($limits.primary | if valid_window then . else null end) as $primary
        | ($limits.secondary | if valid_window then . else null end) as $secondary
        | [$primary, $secondary] | map(select(. != null)) as $windows
        | ($windows | map(select((.windowDurationMins // 0) >= 2880))[0] // null) as $long
        | ($windows | map(select((.windowDurationMins // 0) > 0 and (.windowDurationMins // 0) < 2880))[0] // null) as $shortExplicit
        | ($shortExplicit // (if $long == null then $primary else
            ($windows | map(select(.windowDurationMins == null))[0] // null) end)) as $short
        | ($long // $secondary) as $weekly
        | [ $short, $weekly ] | map(select(. != null)) as $shown
        | if ($shown | length) == 0 then
            {text: "Codex ?", tooltip: "Codex usage unavailable (no rate-limit windows returned)", class: "unknown"}
          else
            ($shown | map(.usedPercent) | max) as $max
            | ($shown | map(percent(.)) | join(" · ")) as $text
            | ($shown | map("\(duration(.; "Window")): \(percent(.)) used (resets \(reset(.)))") | join("\n")) as $tooltip
            | {
                text: $text,
                tooltip: $tooltip,
                class: (if $max >= 90 then "critical" elif $max >= 75 then "warning" else "normal" end)
              }
          end
      end
    ' <<< "$response"); then
      unknown "Codex usage unavailable (rate-limit response could not be parsed)"
      exit 0
    fi
    printf '%s\n' "$output"
  '';
}
