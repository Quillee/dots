# Convert Hyprland config from hyprlang to native Lua

## Objective
Migrate `~/.config/hypr/hyprland.conf` (old hyprlang `.conf` syntax) to the
**native Lua** config `~/.config/hypr/hyprland.lua`, split into modular files
loaded with `require()`. No codegen, no build step — Hyprland reads the Lua
directly.

## Key facts (verified on this machine)
- **Hyprland 0.55.0** is installed. As of 0.55, hyprlang is *deprecated in favor
  of Lua*. (Old `.conf` still loads for now, but Lua is the path forward.)
- Config entry point: `~/.config/hypr/hyprland.lua`. Override with `--config`/`-c`.
- **Hot reload**: config reloads the moment you save. `hyprctl reload` also works.
  No manual reload step needed.
- **Splitting files**: use Lua `require()`. Each `require()`d file is its own
  scope, so an error in one file doesn't kill the others. Paths are relative to
  `hyprland.lua`; `/` or `.` both work as separators:
  ```lua
  require("conf/keybinds")    -- ~/.config/hypr/conf/keybinds.lua
  require("conf.autostart")   -- same idea, dot separator
  ```
- **Autocomplete / type stubs** ship at `/usr/share/hypr/stubs/hl.meta.lua`.
  Wire up the LSP with a `.luarc.json` at the config root:
  ```json
  { "workspace": { "library": ["/usr/share/hypr/stubs"] } }
  ```
- **Reference example**: `/usr/share/hypr/hyprland.lua` (full annotated sample).
- **Local wiki** (0.55 Lua syntax) lives at
  `~/.config/hypr/hyprland-wiki/content/`. Relevant pages: `Configuring/Start.md`,
  `Configuring/Basics/{Binds,Dispatchers,Variables,Window-Rules,Autostart}.md`.

## The `hl` API (what you need for this config)
Everything hangs off the global `hl` table. Core calls:
- `hl.config({ ... })` — set variables/options (general, decoration, input,
  group, misc, …). Nested tables map to the old `category { sub { key = val } }`.
- `hl.bind(keys, dispatcher, opts?)` — keybind. `keys` is a string like
  `"SUPER + SHIFT + Q"`; empty mod = just the key (`"XF86AudioPlay"`).
- `hl.dsp.*` — dispatcher factories (passed as the 2nd arg to `hl.bind`, or to
  `hl.dispatch`). A Lua function can also be used as a dispatcher.
- `hl.define_submap(name, reset_or_fn, fn?)` — submaps.
- `hl.window_rule({ name=, match={...}, ... })` — window rules.
- `hl.on("hyprland.start", function() ... end)` — run things at startup
  (replaces `exec-once`).
- `hl.exec_cmd(cmd)` / `hl.dsp.exec_cmd(cmd)` — run a shell command.
- `hl.env(name, value)` — environment variables.
- Bind flags via 3rd arg table: `{ repeating = true, locked = true, mouse = true,
  release = true, ... }`. `binde` ≈ `{ repeating = true }`. `bindm` ≈ `{ mouse = true }`.

## Mapping: current `hyprland.conf` → native Lua
| Old hyprlang | New Lua |
|---|---|
| `$mainMod = SUPER` | `local mainMod = "SUPER"` |
| `$terminal = kitty` etc. | `local terminal = "kitty"` (plain Lua locals) |
| `exec-once = waybar` | `hl.on("hyprland.start", function() hl.exec_cmd("waybar") end)` |
| `bind = $mainMod, Return, exec, $terminal` | `hl.bind(mainMod.." + Return", hl.dsp.exec_cmd(terminal))` |
| `killactive` | `hl.dsp.window.close()` |
| `fullscreen, 0` | `hl.dsp.window.fullscreen(...)` — **verify arg shape in Dispatchers.md** |
| `togglefloating` | `hl.dsp.window.float({ action = "toggle" })` |
| `cyclenext` | `hl.dsp.window.cycle_next()` |
| `movefocus, l/d/u/r` | `hl.dsp.focus({ direction = "left"/"down"/"up"/"right" })` |
| `movewindow, l/d/u/r` | `hl.dsp.window.move({ direction = ... })` — **verify directional arg** |
| `workspace, N` | `hl.dsp.focus({ workspace = N })` |
| `movetoworkspace, N` | `hl.dsp.window.move({ workspace = N })` |
| `workspace, e+1 / e-1` | `hl.dsp.focus({ workspace = "e+1" })` / `"e-1"` |
| `submap = resize` … `submap = reset` | `hl.define_submap("resize", ...)` + `hl.dsp.submap(...)` — **see Binds.md submap section** |
| `binde = , H, resizeactive, -20 0` | `hl.bind("H", hl.dsp.window.resize(...), { repeating = true })` — **verify resize arg** |
| `bindm = $mainMod, mouse:272, movewindow` | `hl.bind(mainMod.." + mouse:272", hl.dsp.window.drag(), { mouse = true })` |
| `bindm = $mainMod, mouse:273, resizewindow` | `hl.bind(mainMod.." + mouse:273", hl.dsp.window.resize(), { mouse = true })` |
| `togglegroup` | `hl.dsp.group.toggle()` |
| `changegroupactive, f / b` | `hl.dsp.group.next()` / `hl.dsp.group.prev()` |
| `windowrule = tile, class:^(steam_app_\d+)$` | `hl.window_rule({ match = { class = "^(steam_app_\\d+)$" }, ... })` — **map `tile` to the right field** |

### Group styling block → `hl.config`
The old `group { col.* ; groupbar { ... } }` becomes (config keys confirmed in
`/usr/share/hypr/stubs/hl.meta.lua`):
```lua
hl.config({
  group = {
    col = {
      border_active   = "rgba(ebbcbaff)",
      border_inactive = "rgba(484456ff)",
    },
    groupbar = {
      font_family = "FiraCode Nerd Font SemiBold",
      font_size   = 11,
      height      = 18,
      text_color  = "rgba(26233aff)",
      col = {
        active   = "rgba(ebbcbaff)",
        inactive = "rgba(7c7b88ff)",
      },
    },
  },
})
```

## Proposed file layout
```
~/.config/hypr/
  hyprland.lua            # entry: locals + require() the modules below
  .luarc.json            # points LSP at /usr/share/hypr/stubs
  conf/
    autostart.lua        # hl.on("hyprland.start", ...)
    keybinds.lua         # apps, focus/move (loops), workspaces (loop), media, screenshots, groups
    submaps.lua          # resize submap
    windowrules.lua      # steam tile rule
    look.lua             # hl.config group/groupbar styling
```
Use Lua loops for the repetitive directional + workspace binds (the example
config at `/usr/share/hypr/hyprland.lua` shows the `for i = 1, 10` workspace
pattern).

## Open items to confirm against the wiki before finalizing
1. Exact arg shape for `hl.dsp.window.fullscreen` (old `fullscreen, 0`).
2. Directional `hl.dsp.window.move({ direction = ... })` vs workspace move.
3. `resizeactive` deltas → `hl.dsp.window.resize` argument form.
4. Submap definition: `hl.define_submap` signature + how binds attach to it.
5. `windowrule = tile` → which `hl.window_rule` field expresses "tile".
→ All answerable from `Configuring/Basics/Dispatchers.md`, `Binds.md`,
  `Window-Rules.md` in the local wiki, plus the stub file.

## Cleanup
A previous (wrong) attempt assumed Hyprland had no Lua and built a codegen
pipeline. Delete it before starting:
```
~/.config/hypr/lua/            # emit.lua, init.lua, config/*.lua
~/.config/hypr/build.sh        # if present
```
The real `hyprland.conf` is preserved in git history if you need to diff the
original 156-line config while porting.

## Source config to port
`~/.config/hypr/hyprland.conf` (current hyprlang config, 156 lines).
