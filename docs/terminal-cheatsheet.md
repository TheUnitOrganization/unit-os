# Terminal cheatsheet — kitty, bash, tmux

## kitty
| Key | Does |
|-----|------|
| select with mouse | copies to clipboard automatically |
| `Ctrl + Shift + C` / `V` | copy / paste |
| right-click | paste |
| `Shift + Enter` | newline instead of submitting (Claude Code, REPLs) |
| `Ctrl + +` / `Ctrl + -` / `Ctrl + 0` | font bigger / smaller / reset |

Config: `~/.config/kitty/kitty.conf`

## bash
| Command | Does |
|---------|------|
| `ll` | long listing, hidden files included |
| `vim` / `vi` | both are nvim |
| `lg` | lazygit |
| `cat` | bat (syntax highlighted) |
| `cfg` | cd to ~/.config |
| `z <part-of-a-dir>` | jump to a directory you've visited before (zoxide) |
| `zi` | pick from your visited dirs with fzf |

| Key | Does |
|-----|------|
| `Ctrl + R` | fuzzy-search command history |
| `Ctrl + T` | fuzzy-pick a file into the current command |
| `Alt + C` | fuzzy-cd into a subdirectory |
| `Ctrl + L` | clear screen |
| `Ctrl + A` / `Ctrl + E` | jump to start / end of line |
| `Ctrl + W` | delete the word behind the cursor |
| `Ctrl + U` | delete to start of line |

Config: `~/.bashrc`, prompt in `~/.config/starship.toml`

## tmux
Prefix is `Ctrl + a`. Press it, release, then the next key.

| Key | Does |
|-----|------|
| `Ctrl+a` then `D` | **the dev layout**: agent left, nvim right |
| `Ctrl+a` then `|` | split left/right |
| `Ctrl+a` then `-` | split top/bottom |
| `Ctrl+a` then `h j k l` | move between panes |
| `Ctrl+a` then `H J K L` | resize pane (hold to repeat) |
| `Ctrl+a` then `c` | new window (tab) |
| `Ctrl+a` then `n` / `p` | next / previous window |
| `Ctrl+a` then `1..9` | jump to window N |
| `Ctrl+a` then `,` | rename window |
| `Ctrl+a` then `x` | close pane |
| `Ctrl+a` then `d` | detach (session keeps running) |
| `Ctrl+a` then `r` | reload tmux.conf |
| `Ctrl+a` then `[` | scroll back; `v` select, `y` copy, `q` quit |

| Command | Does |
|---------|------|
| `tmux` | start a session |
| `tmux a` | re-attach to the last session |
| `tmux ls` | list sessions |
| `tmux new -s name` | named session |

Config: `~/.config/tmux/tmux.conf`

## The workflow this is all for
```
tmux                 # start
Ctrl+a  D            # agent pane left, nvim right
Ctrl+a  c            # a new tab per task
Ctrl+a  d            # detach; everything keeps running
tmux a               # come back to it
```

## Other tools
| Command | Does |
|---------|------|
| `lazygit` (`lg`) | full git UI: stage hunks, commit, branch, rebase |
| `btop` | system monitor (vim keys enabled) |
| `yazi` | terminal file manager |
| `fastfetch` | system info |
| `opencode` | terminal coding agent (non-Anthropic models) |
| `rg <text>` | ripgrep: search file contents, fast |
| `fd <name>` | find files by name, fast |
