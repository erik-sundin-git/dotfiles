{
  writeShellApplication,
  curl,
  jq,
}:

# Claude subscription limits from the (undocumented) endpoint behind /usage,
# as waybar custom-module JSON ({text, tooltip, class}). Used by waybar and the
# EXWM bar. Claude Code owns the token refresh; an expired token just shows
# "?" (resets_at lands just under the minute, hence the +30 s rounding).
writeShellApplication {
  name = "waybar-claude-usage";
  runtimeInputs = [
    curl
    jq
  ];
  text = ''
    creds="$HOME/.claude/.credentials.json"
    # No output hides the module (not logged in)
    [ -r "$creds" ] || exit 0
    token=$(jq -r '.claudeAiOauth.accessToken // empty' "$creds")
    [ -n "$token" ] || exit 0

    if ! usage=$(curl -sf -m 10 https://api.anthropic.com/api/oauth/usage \
      -H "Authorization: Bearer $token" \
      -H "anthropic-beta: oauth-2025-04-20"); then
      jq -cn '{text: "󰚩 ?", tooltip: "Claude usage unavailable (token expired? run claude)", class: "unknown"}'
      exit 0
    fi

    jq -c '
      def pct: (.utilization // 0) | floor;
      def resets: if .resets_at then
          .resets_at | sub("\\.[0-9]+"; "") | sub("\\+00:00$"; "Z")
          | fromdateiso8601 + 30 | strflocaltime("%a %H:%M")
        else "—" end;
      (.five_hour | pct) as $s | (.seven_day | pct) as $w
      | ([$s, $w] | max) as $m
      | {
          text: "󰚩 \($s)% · \($w)%",
          tooltip: "Session: \($s)% (resets \(.five_hour | resets))\nWeekly: \($w)% (resets \(.seven_day | resets))",
          class: (if $m >= 90 then "critical" elif $m >= 75 then "warning" else "normal" end)
        }
    ' <<< "$usage"
  '';
}
