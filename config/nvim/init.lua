-- ~/.config/nvim/init.lua
-- A notepad that happens to be Neovim. ~150 lines, no distro, no magic.
-- Part A: options + keys, works with zero plugins.
-- Part B: three plugins (oil, snacks, neogit) via Neovim 0.12's built-in
--         vim.pack -- no plugin manager to install first.
-- Part C: LSP via built-in vim.lsp.enable.
--
-- Cheatsheet: ~/Documents/nvim-cheatsheet.md

--------------------------------------------------------------------
-- PART A -- the notepad half
--------------------------------------------------------------------
vim.g.mapleader      = " "
vim.g.maplocalleader = " "

local o = vim.o
o.number         = true
o.relativenumber = true      -- makes 5j / 3k obvious; set false if it annoys
o.mouse          = "a"
o.showmode       = false
o.wrap           = false
o.breakindent    = true

o.expandtab   = true         -- spaces, not tabs
o.shiftwidth  = 2
o.tabstop     = 2
o.softtabstop = 2
o.smartindent = true

o.ignorecase = true          -- /foo finds Foo ...
o.smartcase  = true          -- ... but /Foo only finds Foo
o.hlsearch   = true
o.incsearch  = true

o.undofile   = true          -- undo survives closing the file. The single
                             -- biggest reason this beats a notepad.
o.swapfile   = false
o.backup     = false

o.clipboard    = "unnamedplus"  -- y and p use the Wayland clipboard
o.signcolumn   = "yes"          -- stops the text shifting sideways
o.termguicolors = true
o.scrolloff    = 8
o.sidescrolloff = 8
o.splitright   = true
o.splitbelow   = true
o.updatetime   = 250
o.timeoutlen   = 400
o.confirm      = true           -- ask to save instead of refusing to quit
o.cursorline   = true

-- Flash what you just copied, so yanking is visible
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

local map = vim.keymap.set

-- The two that matter most on day one
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Write file" })
map("n", "<leader>q", "<cmd>quit<cr>",  { desc = "Quit" })

-- Esc clears the leftover search highlight
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- Keep the cursor centred when jumping around
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n",     "nzzzv")
map("n", "N",     "Nzzzv")

-- Move selected lines up/down with J/K in visual mode
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- Paste over a selection without losing the clipboard
map("x", "<leader>p", [["_dP]], { desc = "Paste without yanking" })

-- Window navigation: the same hjkl as Hyprland and tmux
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Visual-block mode on Ctrl+Q, because kitty now uses Ctrl+V for paste.
map("n", "<C-q>", "<C-v>", { desc = "Visual block" })

-- Terminal escape
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Leave terminal mode" })

--------------------------------------------------------------------
-- PART B -- three plugins, fetched by vim.pack on first start
--------------------------------------------------------------------
vim.pack.add({
  { src = "https://github.com/sainnhe/gruvbox-material" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },   -- neogit needs this
  { src = "https://github.com/folke/snacks.nvim" },
  { src = "https://github.com/NeogitOrg/neogit" },
})

-- Colorscheme comes from ~/.config/nvim/lua/theme.lua, written by `theme`.
pcall(function()
  local ok, t = pcall(require, "theme")
  local scheme = (ok and t and t.colorscheme) or "gruvbox-material"

  -- A light palette needs this set BEFORE the colorscheme runs, or the
  -- scheme builds its dark variant and then only half-repaints.
  vim.o.background = (ok and t and t.background) or "dark"

  if scheme == "gruvbox-material" then
    vim.g.gruvbox_material_background             = "hard"
    vim.g.gruvbox_material_foreground             = "original"
    vim.g.gruvbox_material_better_performance     = 1
    vim.g.gruvbox_material_transparent_background = 0
    -- Keep the teal/aqua, drop the green: strings come out gold. Only on
    -- dark -- that gold has too little contrast on the light ground.
    if vim.o.background == "dark" then
      vim.g.gruvbox_material_colors_override = { green = { "#d8a657", 214 } }
    else
      vim.g.gruvbox_material_colors_override = {}
    end
  end

  vim.cmd.colorscheme(scheme)
end)

-- oil.nvim -- edit the filesystem like a normal buffer.
-- `-` opens the parent directory. Rename a file by editing the line,
-- delete with dd, then :w to apply.
pcall(function()
  require("oil").setup({
    default_file_explorer = true,
    view_options = { show_hidden = true },
  })
  map("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })
end)

-- snacks.nvim -- picker (files/grep), plus a few quality-of-life bits.
pcall(function()
  local snacks = require("snacks")
  snacks.setup({
    picker    = { enabled = true },
    bigfile   = { enabled = true },   -- don't choke on huge files
    quickfile = { enabled = true },
    notifier  = { enabled = true },
    indent    = { enabled = true },
  })

  map("n", "<leader>f", function() snacks.picker.files() end,      { desc = "Find files" })
  map("n", "<leader>g", function() snacks.picker.grep() end,       { desc = "Grep (ripgrep)" })
  map("n", "<leader>b", function() snacks.picker.buffers() end,    { desc = "Buffers" })
  map("n", "<leader>h", function() snacks.picker.help() end,       { desc = "Help pages" })
  map("n", "<leader>r", function() snacks.picker.recent() end,     { desc = "Recent files" })
end)

-- neogit -- git status, diffs, staging, commits without leaving nvim.
pcall(function()
  require("neogit").setup({})
  map("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Neogit" })
end)

--------------------------------------------------------------------
-- PART C -- LSP, built in. No nvim-lspconfig needed on 0.12.
--------------------------------------------------------------------
-- Add a server: install it, describe it here, then vim.lsp.enable it.
vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".git" },
  settings = { Lua = { diagnostics = { globals = { "vim", "hl" } } } },
})

-- Only enable servers whose binary actually exists, so a missing one is
-- silent instead of an error on every startup.
for _, server in ipairs({ "lua_ls" }) do
  local cmd = (vim.lsp.config[server] or {}).cmd
  if cmd and vim.fn.executable(cmd[1]) == 1 then
    vim.lsp.enable(server)
  end
end

-- LSP keys, bound only once a server actually attaches to the buffer
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(ev)
    local opts = { buffer = ev.buf }
    map("n", "grn", vim.lsp.buf.rename,      opts)
    map("n", "gra", vim.lsp.buf.code_action, opts)
    map("n", "grr", vim.lsp.buf.references,  opts)
    map("n", "gd",  vim.lsp.buf.definition,  opts)
    map("n", "K",   vim.lsp.buf.hover,       opts)
  end,
})

vim.diagnostic.config({
  virtual_text = { prefix = "●" },
  severity_sort = true,
})
