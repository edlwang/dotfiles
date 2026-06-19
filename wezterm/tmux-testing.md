# WezTerm tmux-layer test plan

A checklist for exercising the tmux-style multiplexing added to `wezterm.lua`.
WezTerm's own multiplexer (prefix `Ctrl+Space`) and persistence run on every
machine; a real `tmux` (prefix `Ctrl+b`) can coexist alongside it.

- **Prefix (leader):** `Ctrl+Space`. Press and release it, then press the
  command key (a 2 s window). Notation below: `<prefix> %` means
  `Ctrl+Space` then `%`.
- The leader, **all** command keys, and persistence are active on **every**
  machine.
- `tmux`'s own prefix `Ctrl+b` is **never** bound by WezTerm, so it always passes
  straight through to a real tmux (local or over SSH).

> Reload after editing `wezterm.lua`: it auto-reloads on save
> (`automatically_reload_config`), or relaunch WezTerm.

---

## 0. Verify the mux is running

Persistence runs on every machine, so WezTerm should always be attached to its
background mux server. Confirm with:

```sh
# Panes the WezTerm mux knows about; they report the "unix" domain.
wezterm cli list

# Clients attached to the mux server (your GUI shows up here).
wezterm cli list-clients
```

Definitive check: the persistence test in §6 — close the window and reopen; your
panes, layout, and running programs should reattach.

---

## 1. Splits

| Steps | Expected |
| --- | --- |
| `<prefix> %` | New pane **to the right** (WezTerm `SplitHorizontal`) |
| `<prefix> "` | New pane **below** (WezTerm `SplitVertical`) |

Cross-check they match the existing Terminator binds:

| Steps | Expected (identical to above) |
| --- | --- |
| `Ctrl+Shift+E` | New pane to the right |
| `Ctrl+Shift+O` | New pane below |

Quick way to label panes while testing:

```sh
echo "pane $$ — $(hostname) — $(pwd)"
```

---

## 2. Pane navigation, zoom, rotate, resize

Set up a grid first: `<prefix> %` then `<prefix> "` (you now have 3 panes).

| Steps | Expected |
| --- | --- |
| `<prefix> h` / `j` / `k` / `l` | Focus moves Left / Down / Up / Right |
| `<prefix> ←` / `↓` / `↑` / `→` | Same as hjkl |
| `<prefix> o` | Focus cycles to the next pane |
| `<prefix> z` | Active pane zooms to fill the tab; repeat to unzoom |
| `<prefix> Space` | Panes rotate clockwise within the tab |
| `<prefix> x` | Prompts, then closes the active pane |

**Resize sub-mode** (sticky — no need to re-press the prefix between presses):

| Steps | Expected |
| --- | --- |
| `<prefix> r` | Enter resize mode |
| `h` `h` `j` `k` `l` … | Active pane border moves 2 cells per press, repeatedly |
| `Esc` or `q` | Leave resize mode |

---

## 3. Windows (≈ WezTerm tabs)

| Steps | Expected |
| --- | --- |
| `<prefix> c` | New tab |
| `<prefix> n` / `<prefix> p` | Next / previous tab |
| `<prefix> 1` … `<prefix> 9`, `<prefix> 0` | Jump to tab N (0-indexed: `1` = 2nd tab) |
| `<prefix> w` | Tab navigator (fuzzy list of tabs) |
| `<prefix> ,` | Prompt for a new tab title; typing + Enter renames the tab |
| `<prefix> &` | Prompts, then closes the current tab |

---

## 4. Copy mode, paste, command palette

| Steps | Expected |
| --- | --- |
| `<prefix> [` | Enter copy mode; navigate with `hjkl`/arrows, `v`/`Space` to select, `y`/`Enter` to copy, `Esc`/`q` to exit |
| `<prefix> ]` | Pastes the clipboard into the active pane |
| `<prefix> :` | Opens the WezTerm command palette |

Paste round-trip:

```sh
printf 'copy-me-%s\n' "$RANDOM"   # select it in copy mode (y), then <prefix> ]
```

---

## 5. Prefix passthrough

| Steps | Expected |
| --- | --- |
| `<prefix> <prefix>` (`Ctrl+Space` then `Ctrl+Space`) | Sends a literal `Ctrl+Space` to the program in the pane (recovers readline `set-mark`, etc.) |

---

## 6. Persistence — the headline feature

> Behaves like `tmux detach` / `tmux attach`. Survives closing the window, **not**
> a reboot. Active on every machine.

1. Launch WezTerm. Split a couple of panes (`<prefix> %`, `<prefix> "`).
2. Leave durable, observable state in them:
   ```sh
   # pane A: a running process you can recognize on reattach
   top            # (or: watch -n1 date  /  sleep 99999)
   # pane B: shell state that only survives if the process itself survives
   cd /tmp && export PERSIST_TEST="set-at-$(date +%H%M%S)"
   ```
3. Note the layout, then **close the GUI window** (window close / `Alt+F4`).
4. Relaunch WezTerm.

| After reopening | Expected |
| --- | --- |
| Layout & panes | Reattach exactly as left |
| `top` in pane A | Still running |
| `echo $PERSIST_TEST` in pane B | Prints the saved value (same shell process) |

Detach explicitly instead of closing the window:

| Steps | Expected |
| --- | --- |
| `<prefix> d` | Detaches the `unix` domain; the window closes but the mux server keeps the panes alive for the next launch |
| `<prefix> s` | Domain/session launcher lists the **`unix`** domain (attached) alongside `local` |

While detached, confirm the server is still alive from any shell:

```sh
wezterm cli list-clients   # 0 clients while detached, server still running
wezterm cli list           # panes still listed under the "unix" domain
```

---

## 7. Real tmux still works (no conflict)

On a machine with tmux, or after SSHing into a server that has it:

```sh
tmux new -s test
```

| Steps | Expected |
| --- | --- |
| `Ctrl+b c` | tmux creates a window (WezTerm did **not** intercept `Ctrl+b`) |
| `Ctrl+b %` / `Ctrl+b "` | tmux splits |
| `Ctrl+b d` | tmux detaches; `tmux attach -t test` brings it back |
| `<prefix> c` (Ctrl+Space) | Still makes a **WezTerm** tab around tmux — both layers coexist |

Over SSH this is the whole point: `Ctrl+b` reaches the **remote** tmux untouched,
while `Ctrl+Space` continues to drive your **local** WezTerm.

---

## WezTerm and tmux side by side

Both multiplexers are always available and never collide, because they use
different prefixes:

| | WezTerm layer | tmux (if you run it) |
| --- | --- | --- |
| Prefix | `Ctrl+Space` | `Ctrl+b` (untouched by WezTerm) |
| Persistence | Always on (`unix` domain) | Its own sessions |
| Scope | The local WezTerm GUI | The shell it runs in — local, or the remote end of an SSH session |

Running tmux inside a WezTerm pane just nests them: `Ctrl+b` drives tmux,
`Ctrl+Space` drives WezTerm, and each persists independently. Over SSH, `Ctrl+b`
reaches the **remote** tmux while `Ctrl+Space` stays with your **local** WezTerm.

---

## Troubleshooting

- **Symbol keys (`%` `"` `&` `:` `[` `]` `,`) do nothing after the prefix.**
  WezTerm matches bare `key = "%"` by *physical position*, so shifted symbols
  never match. They're bound with the `mapped:` prefix (match by produced
  character) and the shifted ones with and without `SHIFT`. If a new symbol
  binding misbehaves, add it via `leader_symbol(...)` in `wezterm.lua`, not as a
  plain `{ key = "...", mods = L }` entry.
- **Letters/digits work but symbols don't** is the signature of the above; if
  *nothing* after `Ctrl+Space` works, the leader itself isn't firing — check that
  `config.leader` loaded (look for errors via `<prefix> :` → "Show Debug
  Overlay", or run `wezterm` from a terminal to see config errors).

## Quick checklist

- [ ] `<prefix> %` / `"` split right / below (match `Ctrl+Shift+E` / `O`)
- [ ] `<prefix> h/j/k/l` and arrows move focus; `o` cycles
- [ ] `<prefix> z` zoom; `<prefix> Space` rotate; `<prefix> x` close pane
- [ ] `<prefix> r` resize mode is sticky; `Esc`/`q` exits
- [ ] `<prefix> c` / `n` / `p` / `1-9,0` / `w` / `,` / `&` tab ops
- [ ] `<prefix> [` copy, `<prefix> ]` paste, `<prefix> :` palette
- [ ] `<prefix> <prefix>` sends literal `Ctrl+Space`
- [ ] Persistence: close window → reopen → panes + `top` + `$PERSIST_TEST` survive
- [ ] `<prefix> d` detaches / `<prefix> s` shows `unix`
- [ ] `Ctrl+b` reaches real tmux untouched (local or SSH)
