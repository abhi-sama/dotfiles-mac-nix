-- Neovim config (nix-managed via files/.config/nvim, live-editable).
-- A lean, practical starter kit centered on Neogit (a Magit-style git UI).
-- Edit this file, save, and restart nvim to apply - no nix rebuild needed.

-- Leader key MUST be set before lazy.nvim loads.
vim.g.mapleader = " "        -- Space is the leader
vim.g.maplocalleader = " "

-- A few sane defaults.
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.clipboard = "unnamedplus"  -- share the macOS clipboard
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.undofile = true            -- persistent undo across sessions

-- Bootstrap lazy.nvim (the plugin manager). It self-installs on first launch.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Colorscheme: Catppuccin (Mocha). priority=1000 so it loads first.
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({ flavour = "mocha" })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Neogit: Magit-style git UI. <Space>gg opens the status buffer.
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",   -- required by Neogit (and Telescope)
      "sindrets/diffview.nvim",  -- rich diffs from the Neogit status buffer
    },
    config = true,
    keys = {
      { "<leader>gg", function() require("neogit").open() end, desc = "Neogit status" },
    },
  },

  -- Gitsigns: git change markers in the sign column + inline blame.
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({ current_line_blame = true })
    end,
  },

  -- Telescope: fuzzy finder. Uses fd (find_files) and ripgrep (live_grep),
  -- both already installed on this machine.
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", function() require("telescope.builtin").find_files() end, desc = "Find files" },
      { "<leader>fg", function() require("telescope.builtin").live_grep() end,  desc = "Live grep" },
      { "<leader>fb", function() require("telescope.builtin").buffers() end,    desc = "Buffers" },
      { "<leader>fh", function() require("telescope.builtin").help_tags() end,  desc = "Help tags" },
    },
  },

  -- Treesitter: better syntax highlighting. Parsers compile on install
  -- (needs a C compiler; macOS: `xcode-select --install` if missing).
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "nix", "bash",
          "markdown", "markdown_inline", "json", "yaml",
          "python", "javascript",
        },
        auto_install = true,
        highlight = { enable = true },
      })
    end,
  },

  -- Lualine: statusline (renders nerd-font icons from your Hack font).
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({ options = { theme = "catppuccin" } })
    end,
  },

  -- which-key: popup showing available keybindings as you type a prefix.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = true,
  },
}, {
  -- None of our plugins need luarocks; disabling it silences the
  -- hererocks/luarocks checkhealth error and warnings.
  rocks = { enabled = false },
})
