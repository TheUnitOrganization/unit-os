# Neovim: the 10 commands

Open this file with `nvim ~/Documents/nvim-cheatsheet.md` and practise on it.
You cannot break it — `u` undoes everything, and undo now survives quitting.

## The 10, in the order worth learning them

| # | Key | What it does |
|---|-----|--------------|
| 1 | `i` … `Esc` | `i` = start typing (INSERT). `Esc` = stop (NORMAL). **This is the whole trick.** In NORMAL mode the letters are commands, not text. |
| 2 | `:w` `:q` `:wq` `:q!` | write / quit / write+quit / quit throwing away changes. Here: `<Space>w` and `<Space>q`. |
| 3 | `h j k l` | left, down, up, right. Same keys move windows in Hyprland (`SUPER+hjkl`) and panes in tmux. |
| 4 | `dd` | delete the whole line (and put it in the clipboard). `3dd` = three lines. |
| 5 | `yy` then `p` | "yank" (copy) a line, `p` pastes it after the cursor, `P` before. |
| 6 | `u` / `Ctrl-r` | undo / redo. |
| 7 | `/word` then `n` | search forward, `n` = next hit, `N` = previous. `Esc` clears the highlight. |
| 8 | `gg` `G` `:42` | jump to top / bottom / line 42. |
| 9 | `w` `b` `0` `$` | next word / back a word / start of line / end of line. |
| 10 | `ciw` | **c**hange **i**nner **w**ord: deletes the word under the cursor and drops you in INSERT. |

## Why #10 is the important one

Vim is a grammar: **verb + noun**.

- verbs: `d` delete, `c` change, `y` yank
- nouns: `w` word, `iw` inner word, `i"` inside quotes, `ip` paragraph, `$` to end of line

They multiply, so these all work without being memorised separately:

```
dw    delete to end of word        d$    delete to end of line
d2w   delete two words             ci"   change what's inside "quotes"
yy    yank a line                  yap   yank a paragraph
cc    change a whole line          di(   delete inside (parens)
```

Learn the 10 above and the rest is combinations.

## Your keys (set in ~/.config/nvim/init.lua)

Leader is **Space**.

| Key | Does |
|-----|------|
| `<Space>w` / `<Space>q` | save / quit |
| `-` | open the file browser (oil) — it's a normal buffer: edit names, `dd` to delete, `:w` to apply |
| `<Space>f` | find files |
| `<Space>g` | grep the whole project |
| `<Space>b` | switch buffer (open file) |
| `<Space>r` | recent files |
| `<Space>gg` | git: status, diff, stage, commit (neogit) |
| `Ctrl-h/j/k/l` | move between splits |
| `K` | hover docs (when an LSP is attached) |
| `gd` | go to definition |

## Escape hatches

- Stuck in some mode you don't recognise? Press `Esc` twice.
- Really stuck? `:q!` then Enter quits without saving.
- `:help <thing>` — and `<Space>h` searches the help.
