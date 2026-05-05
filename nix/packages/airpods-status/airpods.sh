#!/usr/bin/env bash
left_label="${1:-L:}"
right_label="${2:-R:}"
output=$(timeout 10 env PYTHONUNBUFFERED=1 /home/erik/dev/AirStatus/result/bin/airstatus 2>/dev/null)

if [ -z "$output" ]; then
    echo '{"text": " ", "tooltip": "AirPods not found", "class": "disconnected"}'
    exit 0
fi

python3 - "$left_label" "$right_label" <<EOF
import json, sys
left_label = sys.argv[1]
right_label = sys.argv[2]

d = json.loads('''$output''')

if d.get("status", 0) == 0:
    print(json.dumps({"text": " ?", "tooltip": "AirPods not found", "class": "disconnected"}))
    sys.exit(0)

left = d["charge"]["left"]
right = d["charge"]["right"]
case = d["charge"]["case"]

def fmt_pct(v):
    return f"{v}%" if v >= 0 else "?"

def charging_icon(charging):
    return "⚡" if charging else ""

left_str  = fmt_pct(left)  + charging_icon(d["charging_left"])
right_str = fmt_pct(right) + charging_icon(d["charging_right"])
case_str  = fmt_pct(case)  + charging_icon(d["charging_case"])

# Use the lower of the two buds as the displayed percentage
valid = [v for v in [left, right] if v >= 0]
min_pct = min(valid) if valid else -1

text = f" {left_label}{left_str} {right_label}{right_str}"

tooltip = f"{d['model']}\\nL: {left_str}  R: {right_str}  Case: {case_str}"

# Class for CSS styling
if min_pct < 0:
    cls = "disconnected"
elif min_pct <= 10:
    cls = "critical"
elif min_pct <= 25:
    cls = "warning"
else:
    cls = "normal"

print(json.dumps({"text": text, "tooltip": tooltip, "class": cls}))
EOF
