-- ------------------------------------------------------------
-- Bootstrap lazy.nvim
-- ------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git","clone","--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ------------------------------------------------------------
-- Basic Options
-- ------------------------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true 
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 300
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.wrap = false
vim.opt.linebreak = false
vim.opt.sidescroll = 1
vim.opt.sidescrolloff = 1

-- ------------------------------------------------------------
-- Keymaps
-- ------------------------------------------------------------

local function open_in(split)
  return function()
    local tb = require("telescope.builtin")
    tb.find_files({
      attach_mappings = function(prompt_bufnr, map)
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local cmd = split == "v" and "vsplit " or split == "h" and "split " or ""

        map("i", "<CR>", function()
          local sel = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.cmd(cmd .. sel.path)
        end)
        map("n", "<CR>", function()
          local sel = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          vim.cmd(cmd .. sel.path)
        end)

        return true
      end,
    })
  end
end

vim.keymap.set("n", "<Space><Space>", function()
  require("telescope.builtin").find_files()
end)

vim.keymap.set("n", "hh", open_in("v"))
vim.keymap.set("n", "vv", open_in("h"))

vim.keymap.set("n", "<Space><Enter>", function()
  require("telescope.builtin").live_grep()
end)

vim.keymap.set("n", "<Space>tt", "<cmd>ToggleTerm<cr>")

vim.keymap.set("t", "<Esc>", function()
  vim.api.nvim_feedkeys("exit\n", "t", false)
end)

-- ------------------------------------------------------------
-- Plugins
-- ------------------------------------------------------------
require("lazy").setup({

  --------------------------------------------------------
  -- Telescope
  --------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = { "node_modules", ".git/" },
        },
      })
    end,
  },

  --------------------------------------------------------
  -- Floating Terminal
  --------------------------------------------------------
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        direction = "float",
        open_mapping = [[<c-\>]],
        float_opts = { border = "rounded" },
      })
    end,
  },

  --------------------------------------------------------
  -- Commenting
  --------------------------------------------------------
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup({
        toggler = { line = "gcc", block = "gbc" },
        opleader = { line = "gc",  block = "gb"  },
      })
    end,
  },

  --------------------------------------------------------
  -- Themes
  --------------------------------------------------------
  {
    "morhetz/gruvbox",
    priority = 1000,
    dependencies = {
      "folke/tokyonight.nvim",
      "nickkadutskyi/jb.nvim",
      "olivercederborg/poimandres.nvim",
      "kdheepak/monochrome.nvim",
    },
    config = function()
      vim.cmd.colorscheme("gruvbox")
    end,
  },

  --------------------------------------------------------
  -- Treesitter
  --------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ok, ts = pcall(require, "nvim-treesitter.configs")
      if not ok then return end

      ts.setup({
        ensure_installed = { "c","cpp","python","lua","vim","glsl" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  --------------------------------------------------------
  -- LSP (Neovim 0.12)
  --------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()

      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {},
        automatic_installation = false,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()

      ----------------------------------------------------
      -- clangd
      ----------------------------------------------------
      vim.lsp.config.clangd = {
        cmd = { "clangd", "--background-index" },
        filetypes = { "c","cpp","objc","objcpp" },
        root_dir = function(fname)
          return vim.fs.root(fname, {
            "compile_commands.json",
            "compile_flags.txt",
            ".git"
          })
        end,
        capabilities = capabilities,
      }

      ----------------------------------------------------
      -- jedi-language-server
      ----------------------------------------------------
      vim.lsp.config["jedi_language_server"] = {
        cmd = { "jedi-language-server" },
        filetypes = { "python" },
        root_dir = function(fname)
          return vim.fs.root(fname, {
            "pyproject.toml",
            "setup.py",
            ".git"
          })
        end,
        init_options = {
          semanticTokens = { enable = true },
        },
        capabilities = capabilities,
      }

      ----------------------------------------------------
      -- LSP Attach
      ----------------------------------------------------
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end

          -- Kill unwanted Python LSPs
          if client.name == "pyright"
            or client.name == "basedpyright"
            or client.name == "pylsp"
          then
            client.stop()
            return
          end

          -- Enable semantic tokens if supported
          if client.server_capabilities.semanticTokensProvider then
            vim.lsp.semantic_tokens.start(args.buf, client.id)
          end
        end,
      })

      ----------------------------------------------------
      -- Enable LSPs
      ----------------------------------------------------
      vim.lsp.enable("clangd")
      vim.lsp.enable("jedi_language_server")

    end,
  },

})
