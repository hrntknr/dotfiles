vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

vim.opt.number = true
vim.opt.laststatus = 3
vim.opt.scrolloff = 2
vim.cmd("nnoremap <ESC><ESC> :nohlsearch<CR>")
vim.cmd("nnoremap <S-Up> 10<Up>")
vim.cmd("nnoremap <S-Down> 10<Down>")
vim.cmd("nnoremap U <C-r>")
vim.cmd("nnoremap <C-w>\" <C-w>s")
vim.cmd("nnoremap <C-w>@ <C-w>s")
vim.cmd("nnoremap <C-w>% <C-w>v")
vim.cmd("tnoremap <C-w><Up> <C-\\><C-n><C-w><Up>")
vim.cmd("tnoremap <C-w><Down> <C-\\><C-n><C-w><Down>")
vim.cmd("tnoremap <C-w><Left> <C-\\><C-n><C-w><Left>")
vim.cmd("tnoremap <C-w><Right> <C-\\><C-n><C-w><Right>")
vim.cmd("tnoremap <C-w>\" <C-\\><C-n><C-w>s")
vim.cmd("tnoremap <C-w>@ <C-\\><C-n><C-w>s")
vim.cmd("tnoremap <C-w>% <C-\\><C-n><C-w>v")
vim.cmd("nnoremap <C-a> ggVG")
vim.cmd("nnoremap <C-d> :below vsplit \\| terminal <CR>i")
vim.cmd("nnoremap <Leader>b <C-^>")
vim.cmd("nnoremap <Leader>sync :below split \\| resize 15 \\| terminal git sync<CR>i")
vim.cmd("nnoremap <Leader>diff :DiffviewOpen<CR>")
vim.cmd("autocmd BufWinEnter,WinEnter term://* startinsert")
vim.cmd("ab sync below split \\| resize 15 \\| terminal git sync<CR>i")

vim.keymap.set("n", "<Leader>f", function()
  vim.lsp.buf.format({ timeout_ms = 2000 })
end, { silent = true, desc = "Format buffer" })

vim.api.nvim_create_autocmd("WinClosed", {
  callback = function(args)
    local winid = tonumber(args.match)
    if not winid then return end

    local ok, buf = pcall(vim.api.nvim_win_get_buf, winid)
    if not ok or not buf then return end

    local ft = vim.bo[buf].filetype

    if ft == "DiffviewFiles" or ft == "DiffviewFileHistory" then
      vim.schedule(function()
        pcall(vim.cmd, "DiffviewClose")
      end)
    end

    if ft == "neo-tree" then
      vim.schedule(function()
        local wins = vim.api.nvim_list_wins()

        for _, w in ipairs(wins) do
          local b = vim.api.nvim_win_get_buf(w)
          local bt = vim.bo[b].buftype
          local ft2 = vim.bo[b].filetype
          local name = vim.api.nvim_buf_get_name(b)
          local modified = vim.bo[b].modified

          local is_empty_noname =
            bt == "" and
            name == "" and
            not modified and
            vim.api.nvim_buf_line_count(b) == 1 and
            vim.api.nvim_buf_get_lines(b, 0, 1, false)[1] == ""

          if not is_empty_noname then
            return
          end
        end

        pcall(vim.cmd, "qa")
      end)
    end
  end,
})

if vim.fn.has('unnamedplus') then
  vim.opt.clipboard = "unnamedplus"
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

local function has_node()
  return vim.fn.executable("node") == 1
end
local function has_npm()
  return vim.fn.executable("npm") == 1
end
local function has_node_npm()
  return has_node() and has_npm()
end

if has_node_npm() then
  vim.cmd("nnoremap <C-l> :Copilot panel<CR>")
end

local lsp_ensure = {
  "lua_ls",
}
if has_node_npm() then
  vim.list_extend(lsp_ensure, {
    "bashls",
    "yamlls",
    "eslint",
    "html",
    "cssls",
    "tailwindcss",
    "jsonls",
  })
end

local null_ls_ensure = {}
if has_node_npm() then
  null_ls_ensure = { "prettier" }
end

local plugins = {
  {
    "navarasu/onedark.nvim",
    config = function()
      local onedark = require("onedark")
      onedark.setup()
      onedark.load()
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local neotree = require("neo-tree")
      neotree.setup({
        enable_git_status = true,
        close_if_last_window = true,
        filesystem = {
          use_libuv_file_watcher = true,
          filtered_items = {
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_by_name = {
              ".git",
              ".DS_Store",
              "thumbs.db",
            },
          },
        },
        default_component_configs = {
          icon = {
            folder_closed = "▸",
            folder_open = "▾",
            folder_empty = "▾",
            default = "-",
          },
          git_status = {
            symbols = {
              added = "+",
              modified = "~",
              deleted = "-",
              renamed = "»",
              untracked = "U",
              ignored = "",
              unstaged = "",
              staged = "",
              conflict = "",
            },
          },
        },
      })
    end,
  },
  {
    "williamboman/mason.nvim",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig"
    },
    opts = {
      ensure_installed = lsp_ensure,
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local lsp_common = require("config.lsp")
      vim.lsp.config("*", {
        capabilities = lsp_common.capabilities,
        on_attach = lsp_common.on_attach,
      })
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-vsnip",
      "hrsh7th/vim-vsnip",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
    },
    config = function()
      local cmp = require("cmp")
      local ok_copilot, copilot_suggestion = pcall(require, "copilot.suggestion")

      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() and cmp.get_active_entry() then
              cmp.select_next_item()
            else
              if ok_copilot and copilot_suggestion.is_visible() then
                copilot_suggestion.accept()
              else
                fallback()
              end
            end
          end, { "i", "s" })
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },
  {
    "jay-babu/mason-null-ls.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim",
    },
    opts = {
      automatic_installation = true,
      automatic_setup = true,
      ensure_installed = null_ls_ensure,
    },
  },
  {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local null_ls = require("null-ls")
      local sources = {}
      if has_node_npm() then
        table.insert(sources, null_ls.builtins.formatting.prettier)
      end
      null_ls.setup({ sources = sources })
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      local gitsigns = require("gitsigns")
      gitsigns.setup({
        signcolumn = false,
        numhl = true,
      })
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      local lualine = require('lualine')
      lualine.setup({
        options = { icons_enabled = false },
      })
    end,
  },
  "editorconfig/editorconfig-vim",
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },
}

if has_node_npm() then
  table.insert(plugins, {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    config = function()
      local copilot = require("copilot")
      copilot.setup({
        suggestion = { auto_trigger = true },
        filetypes = {
          yaml = true,
          markdown = true,
          gitcommit = true,
          gitrebase = true,
        },
      })
    end,
  })
end

require("lazy").setup(plugins)
