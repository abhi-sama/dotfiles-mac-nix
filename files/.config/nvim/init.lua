-- Neovim config (nix-managed via files/.config/nvim, live-editable).
-- Minimal setup focused on Neogit, a Magit-style git UI for Neovim.

-- Leader key MUST be set before lazy.nvim loads.
vim.g.mapleader = " "        -- Space is the leader
vim.g.maplocalleader = " "

-- A few sane defaults.
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.clipboard = "unnamedplus"  -- share the macOS clipboard

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

-- Plugins.
require("lazy").setup({
  {
    "NeogitOrg/neogit",
    dependencies = {
      "nvim-lua/plenary.nvim",   -- required by Neogit
      "sindrets/diffview.nvim",  -- rich diffs from the Neogit status buffer
    },
    config = true,               -- run require("neogit").setup({})
    keys = {
      -- <Space>gg opens the Neogit status screen (stage, commit, push, etc.)
      { "<leader>gg", function() require("neogit").open() end, desc = "Neogit status" },
    },
  },
})
