#!/usr/bin/env nu

let data = open --raw /dev/stdin | from json

let model = $data | get -o model.id | default "?"
let ctx = $data | get -o context_window.used_percentage | default 0
let five_h = $data | get -o rate_limits.five_hour.used_percentage | default 0
let weekly = $data | get -o rate_limits.seven_day.used_percentage | default 0
let cost = $data | get -o cost.total_cost_usd | default 0 | into string --decimals 2
let added = $data | get -o cost.total_lines_added | default 0
let removed = $data | get -o cost.total_lines_removed | default 0
let duration_ms = $data | get -o cost.total_duration_ms | default 0
let mins = $duration_ms / 60000 | math floor
let over_200k = $data | get -o exceeds_200k_tokens | default false

let reset = ansi reset
let dim = ansi grey
let green = ansi green
let red = ansi red
let cyan = ansi cyan
let magenta = ansi magenta
let blue = ansi blue
let yellow = ansi yellow
let bold = ansi attr_bold

let ctx_i = try { $ctx | into int } catch { 0 }
let ctx_color = if $ctx_i < 50 { ansi green } else if $ctx_i < 80 { ansi yellow } else { ansi red }
let fh_i = try { $five_h | into int } catch { 0 }
let five_h_color = if $fh_i < 50 { ansi green } else if $fh_i < 80 { ansi yellow } else { ansi red }
let wk_i = try { $weekly | into int } catch { 0 }
let weekly_color = if $wk_i < 50 { ansi green } else if $wk_i < 80 { ansi yellow } else { ansi red }

let duration_str = if $mins < 60 {
    $"($mins)m"
} else {
    $"($mins / 60 | math floor)h($mins mod 60)m"
}

let warn = if $over_200k { $" ($red)⚠ >200k!($reset)" } else { "" }

[
    $"($bold)($magenta)🤖 ($model)($reset)"
    $"($dim)│($reset) ($blue)📐 ($ctx_color)($ctx)%($reset)($warn)"
    $"($dim)│($reset) ($cyan)⏱ ($five_h_color)($five_h)%($reset)"
    $"($dim)│($reset) ($cyan)📅 ($weekly_color)($weekly)%($reset)"
    $"($dim)│($reset) ($green)+($added)($reset)($red)-($removed)($reset)"
    $"($dim)│($reset) ($blue)⏳ ($duration_str)($reset)"
    $"($dim)│($reset) ($yellow)💰 $($cost)($reset)"
] | str join " "
