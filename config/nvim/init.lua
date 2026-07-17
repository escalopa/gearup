-- gearup Neovim config — tuned for navigating HUGE codebases.
--
-- Philosophy: never index the whole repo. Everything is on-demand and
-- ripgrep/fzf-powered, plus "pinned files" (harpoon) for the 4-5 files
-- you're actually working on right now.
--
-- Leader is Space. Press Space and wait — which-key shows what's available.

-- ============================================================ options ======
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local o = vim.opt
o.number = true
o.relativenumber = true      -- makes 5j / 12k jumps obvious
o.signcolumn = "yes"
o.cursorline = true
o.termguicolors = true
o.splitright = true
o.splitbelow = true
o.ignorecase = true
o.smartcase = true           -- smart search: lowercase = insensitive
o.undofile = true            -- persistent undo across sessions
o.swapfile = false
o.updatetime = 250
o.scrolloff = 6
o.clipboard = "unnamedplus"  -- yank goes to system clipboard
o.completeopt = { "menu", "menuone", "noselect" }
o.grepprg = "rg --vimgrep --smart-case"
o.grepformat = "%f:%l:%c:%m"

-- Go: tabs, 4-wide (gofmt style)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "go",
  callback = function()
    vim.bo.tabstop, vim.bo.shiftwidth, vim.bo.expandtab = 4, 4, false
  end,
})

-- ====================================================== core keymaps ======
local map = vim.keymap.set
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "clear search highlight" })
map("n", "<leader>w", "<cmd>write<CR>", { desc = "save file" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "quit window" })
map("n", "[q", "<cmd>cprev<CR>", { desc = "prev quickfix item" })
map("n", "]q", "<cmd>cnext<CR>", { desc = "next quickfix item" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "next diagnostic" })
map("n", "<leader>e", vim.diagnostic.open_float, { desc = "show diagnostic" })
-- keep the cursor centered on big jumps
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- =========================================================== lazy.nvim ======
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  -- ---- looks ---------------------------------------------------------------
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function() vim.cmd.colorscheme("tokyonight-night") end,
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = { options = { theme = "tokyonight", globalstatus = true } },
  },

  -- ---- discoverability: press a key prefix and see your options ------------
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>f", group = "find (fzf)" },
        { "<leader>g", group = "git" },
        { "<leader>c", group = "code/lsp" },
        { "<leader>h", group = "harpoon pins" },
        { "<leader>x", group = "diagnostics (trouble)" },
      },
    },
  },

  -- ---- THE navigation layer: fzf-lua ----------------------------------------
  -- fzf-lua streams results from fd/rg: no indexing, instant even on
  -- million-line repos. This is the main way you move around.
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      files = { fd_opts = "--type f --hidden --exclude .git" },
      grep  = { rg_opts = "--column --line-number --no-heading --color=always "
                       .. "--smart-case --hidden -g '!.git'" },
    },
    keys = {
      { "<leader>ff", "<cmd>FzfLua files<CR>",                 desc = "find files" },
      { "<leader>fg", "<cmd>FzfLua live_grep<CR>",             desc = "live grep (whole repo)" },
      { "<leader>fw", "<cmd>FzfLua grep_cword<CR>",            desc = "grep word under cursor" },
      { "<leader>fd", "<cmd>FzfLua files cwd=%:p:h<CR>",       desc = "files near current file" },
      { "<leader>fG", "<cmd>FzfLua live_grep cwd=%:p:h<CR>",   desc = "grep near current file" },
      { "<leader>fb", "<cmd>FzfLua buffers<CR>",               desc = "open buffers" },
      { "<leader>fo", "<cmd>FzfLua oldfiles cwd_only=true<CR>", desc = "recent files (this project)" },
      { "<leader>fr", "<cmd>FzfLua resume<CR>",                desc = "resume last search" },
      { "<leader>fs", "<cmd>FzfLua lsp_document_symbols<CR>",  desc = "symbols in file" },
      { "<leader>fS", "<cmd>FzfLua lsp_live_workspace_symbols<CR>", desc = "symbols in workspace" },
    },
  },

  -- ---- pinned files: harpoon ---------------------------------------------------
  -- In a huge repo you touch thousands of files but WORK in 4-5.
  -- Pin them; jump with Space-1..4. Pins are saved per project.
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()
      map("n", "<leader>ha", function() harpoon:list():add() end,
        { desc = "pin current file" })
      map("n", "<leader>hh", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
        { desc = "pinned files menu" })
      for i = 1, 4 do
        map("n", "<leader>" .. i, function() harpoon:list():select(i) end,
          { desc = "go to pin " .. i })
      end
    end,
  },

  -- ---- file system as a buffer: oil ---------------------------------------------
  -- Press "-" to see the current file's directory; edit it like text
  -- (rename = edit line, delete = dd). Great for exploring unfamiliar dirs.
  {
    "stevearc/oil.nvim",
    opts = { view_options = { show_hidden = true } },
    keys = { { "-", "<cmd>Oil<CR>", desc = "browse parent directory" } },
  },

  -- ---- seamless tmux/nvim pane movement -------------------------------------
  { "christoomey/vim-tmux-navigator" },

  -- ---- in-file jumps: flash ---------------------------------------------------
  -- Press s + two characters: labels appear on every match; press a label
  -- to teleport. The fastest way to move within what you can see.
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end,       desc = "flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "flash select scope" },
    },
  },

  -- ---- diagnostics as a list: trouble -----------------------------------------
  -- One panel for every error/warning in the workspace; great after a
  -- refactor when 14 files have red squiggles.
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>",              desc = "workspace diagnostics" },
      { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "buffer diagnostics" },
      { "<leader>xq", "<cmd>Trouble qflist toggle<CR>",                   desc = "quickfix list" },
    },
  },

  -- ---- surround: cs"' ds( ysiw" ----------------------------------------------
  { "kylechui/nvim-surround", event = "VeryLazy", opts = {} },

  -- ---- git ----------------------------------------------------------------------
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function bmap(mode, l, r, desc)
          map(mode, l, r, { buffer = bufnr, desc = desc })
        end
        bmap("n", "]h", gs.next_hunk, "next git hunk")
        bmap("n", "[h", gs.prev_hunk, "prev git hunk")
        bmap("n", "<leader>gp", gs.preview_hunk, "preview hunk")
        bmap("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "blame line")
        bmap("n", "<leader>gr", gs.reset_hunk, "reset hunk")
      end,
    },
  },

  -- ---- treesitter: fast, accurate highlighting ----------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "go", "gomod", "gowork", "gosum", "lua", "bash",
                             "json", "yaml", "proto", "sql", "dockerfile", "markdown" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- ---- LSP: gopls, tuned for big repos --------------------------------------------
  {
    "neovim/nvim-lspconfig",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local caps = require("cmp_nvim_lsp").default_capabilities()

      -- ---- machine-local gopls override (optional, never committed) --------
      -- Some machines need a special gopls (company monorepos often ship a
      -- patched build). Drop a `lua/gearup_local.lua` next to this init.lua —
      -- it's gitignored — returning { cmd=..., root_dir=..., settings=... }
      -- (or nil to use the defaults below).
      local ok_local, local_gopls = pcall(require, "gearup_local")
      if not ok_local or type(local_gopls) ~= "table" then
        local_gopls = nil
      end

      -- Stock gopls, tuned for big repos.
      local gopls_opts = {
        capabilities = caps,
        settings = {
          gopls = {
            gofumpt = true,
            staticcheck = false,        -- heavy on huge repos; golangci-lint covers it
            completionBudget = "250ms", -- never let completion block typing
            symbolScope = "workspace",  -- don't sweep all of GOPATH for symbols
            directoryFilters = {        -- skip what you never want indexed
              "-**/node_modules", "-**/.git", "-bazel-bin", "-bazel-out",
            },
            analyses = { unusedparams = true, nilness = true, unusedwrite = true },
            hints = { parameterNames = true },
          },
        },
      }
      if local_gopls then
        for k, v in pairs(local_gopls) do gopls_opts[k] = v end
      end

      require("lspconfig").gopls.setup(gopls_opts)

      -- LSP keymaps (buffer-local, on attach). fzf-lua renders the lists,
      -- so "find references" in a huge repo is a fuzzy-searchable picker.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local function bmap(keys, fn, desc)
            map("n", keys, fn, { buffer = ev.buf, desc = desc })
          end
          bmap("gd", "<cmd>FzfLua lsp_definitions<CR>",     "go to definition")
          bmap("gr", "<cmd>FzfLua lsp_references<CR>",      "find references")
          bmap("gI", "<cmd>FzfLua lsp_implementations<CR>", "find implementations")
          bmap("K",  vim.lsp.buf.hover,                     "hover docs")
          bmap("<leader>cr", vim.lsp.buf.rename,            "rename symbol")
          bmap("<leader>ca", vim.lsp.buf.code_action,       "code action")
        end,
      })

      -- format + organize imports on save (the Go way)
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*.go",
        callback = function()
          vim.lsp.buf.format({ timeout_ms = 2000 })
          vim.lsp.buf.code_action({
            context = { only = { "source.organizeImports" }, diagnostics = {} },
            apply = true,
          })
        end,
      })
    end,
  },

  -- ---- completion --------------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args) require("luasnip").lsp_expand(args.body) end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
        }),
        sources = cmp.config.sources(
          { { name = "nvim_lsp" }, { name = "luasnip" } },
          { { name = "buffer" }, { name = "path" } }
        ),
      })
    end,
  },
}, {
  ui = { border = "rounded" },
})
