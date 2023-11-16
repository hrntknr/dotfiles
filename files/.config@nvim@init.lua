vim.cmd("nnoremap <S-Up> <C-u>")
vim.cmd("nnoremap <S-Down> <C-d>")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    {
      "nvim-neo-tree/neo-tree.nvim",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "3rd/image.nvim",
      },
      config = function()
        require("neo-tree").setup({
          close_if_last_window = true,
          enable_git_status = true,
          filesystem = {
            filtered_items = {
              hide_dotfiles = false,
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
                untracked = "",
                ignored = "",
                unstaged = "",
                staged = "",
                conflict = "",
              },
            },
          },
        })
        vim.api.nvim_create_autocmd("VimEnter", {
          pattern = { "*" },
          command = "Neotree",
        })
      end
    },
    {
      "neovim/nvim-lspconfig",
      dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
      },
      config = function()
        local lspconfig = require('lspconfig')
        local mason = require("mason")
        local mason_lspconfig = require('mason-lspconfig')
        mason.setup()
        mason_lspconfig.setup({
          automatic_installation = true,
        })
        mason_lspconfig.setup_handlers({
          function(server_name)
            lspconfig[server_name].setup({})
          end
        })
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('UserLspConfig', {}),
          callback = function(ev)
            local opts = { buffer = ev.buf }
            vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
            vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
          end,
        })
        vim.cmd("ab f lua vim.lsp.buf.format()")
        vim.api.nvim_create_autocmd("BufWritePre", {
          pattern = { "*" },
          callback = function()
            vim.lsp.buf.format {
              async = false,
            }
          end
        })
      end
    },
    {
      "hrsh7th/nvim-cmp",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
      },
      config = function()
        local cmp = require("cmp")
        cmp.setup({
          mapping = cmp.mapping.preset.insert({
            ['<ESC>'] = cmp.mapping.abort(),
            ['<C-e>'] = cmp.mapping.abort(),
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
            ['<TAB>'] = cmp.mapping.confirm({ select = true }),
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp" },
          }),
        })
      end
    },
    "editorconfig/editorconfig-vim",
    "github/copilot.vim",
  }
})
