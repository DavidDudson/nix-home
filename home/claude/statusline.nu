#!/usr/bin/env nu

# Claude Code status line
let data = $in | from json

let model = $data | get -i model.id | default "?"
let ctx = $data | get -i context_window.used_percentage | default 0
let five_h = $data | get -i rate_limits.five_hour.used_percentage | default 0
let weekly = $data | get -i rate_limits.seven_day.used_percentage | default 0
let cost = $data | get -i cost.total_cost_usd | default 0 | into string -d 2
let added = $data | get -i cost.total_lines_added | default 0
let removed = $data | get -i cost.total_lines_removed | default 0
let duration_ms = $data | get -i cost.total_duration_ms | default 0
let mins = ($duration_ms / 60000 | math floor)
let over_200k = $data | get -i exceeds_200k_tokens | default false

# ANSI colors
let reset = (ansi reset)
let dim = (ansi grey)
let green = (ansi green)
let yellow = (ansi yellow)
let red = (ansi red)
let cyan = (ansi cyan)
let magenta = (ansi magenta)
let blue = (ansi blue)
let bold = (ansi attr_bold)

# Color based on percentage thresholds
def color-pct [pct: any] {
    let p = ($pct | into int -i | default 0)
    if $p < 50 { (ansi green) } else if $p < 80 { (ansi yellow) } else { (ansi red) }
}

let ctx_color = (color-pct $ctx)
let five_h_color = (color-pct $five_h)
let weekly_color = (color-pct $weekly)

let duration_str = if $mins < 60 {
    $"($mins)m"
} else {
    $"($mins / 60 | math floor)h($mins mod 60)m"
}

let warn = if $over_200k { $" ($red)⚠ >200k!($reset)" } else { "" }

let parts = [
    $"($bold)($magenta)🤖 ($model)($reset)"
    $"($dim)│($reset) ($blue)📐 ($ctx_color)($ctx)%($reset)($warn)"
    $"($dim)│($reset) ($cyan)⏱ ($five_h_color)($five_h)%($reset)"
    $"($dim)│($reset) ($cyan)📅 ($weekly_color)($weekly)%($reset)"
    $"($dim)│($reset) ($green)+($added)($reset)($red)-($removed)($reset)"
    $"($dim)│($reset) ($blue)⏳ ($duration_str)($reset)"
    $"($dim)│($reset) ($yellow)💰 $($cost)($reset)"
]

$parts | str join " "
