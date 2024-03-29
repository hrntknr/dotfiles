vim.g.mapleader = " "
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
vim.cmd("nnoremap <C-l> :Copilot panel<CR>")
vim.cmd("nnoremap <C-a> ggVG")
vim.cmd("nnoremap <C-d> :below vsplit \\| terminal <CR>i")
vim.cmd("nnoremap <Leader>b <C-^>")
vim.cmd("nnoremap <Leader>sync :below split \\| resize 15 \\| terminal git sync<CR>i")
vim.cmd("autocmd BufWinEnter,WinEnter term://* startinsert")
vim.cmd("ab sync below split \\| resize 15 \\| terminal git sync<CR>i")

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

require("lazy").setup({
  git = {
    filter = false,
  },
  spec = {
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
        "3rd/image.nvim",
      },
      config = function()
        local neotree = require("neo-tree")
        neotree.setup({
          enable_git_status = true,
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
      dependencies = {
        "neovim/nvim-lspconfig",
        "williamboman/mason-lspconfig.nvim",
        "nvimtools/none-ls.nvim",
      },
      config = function()
        local lspconfig = require('lspconfig')
        local mason = require("mason")
        local mason_lspconfig = require('mason-lspconfig')
        local mason_package = require("mason-core.package")
        local mason_registry = require("mason-registry")
        local null_ls = require("null-ls")
        mason.setup()
        mason_lspconfig.setup({
          automatic_installation = true,
        })
        mason_lspconfig.setup_handlers({
          function(server_name)
            lspconfig[server_name].setup({})
          end,
        })
        local null_sources = {}
        for _, package in ipairs(mason_registry.get_installed_packages()) do
          local package_categories = package.spec.categories[1]
          if package_categories == mason_package.Cat.Formatter then
            if null_ls.builtins.formatting[package.name] then
              table.insert(null_sources, null_ls.builtins.formatting[package.name])
            end
          end
          if package_categories == mason_package.Cat.Linter then
            if null_ls.builtins.diagnostics[package.name] then
              table.insert(null_sources, null_ls.builtins.diagnostics[package.name])
            end
          end
        end
        null_ls.setup({
          sources = null_sources,
        })
        vim.cmd("ab f lua vim.lsp.buf.format()")
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
        vim.cmd("ab W noautocmd w")
        vim.api.nvim_create_autocmd("BufWritePre", {
          pattern = { "*" },
          callback = function()
            vim.lsp.buf.format({
              async = false,
            })
          end,
        })
      end,
    },
    {
      "hrsh7th/nvim-cmp",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-vsnip",
        "hrsh7th/vim-vsnip",
      },
      config = function()
        local cmp = require("cmp")
        local copilot_suggestion = require("copilot.suggestion")
        cmp.setup({
          mapping = cmp.mapping.preset.insert({
            ['<C-e>'] = cmp.mapping.abort(),
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() and cmp.get_active_entry() then
                cmp.select_next_item()
              else
                if copilot_suggestion.is_visible() then
                  copilot_suggestion.accept()
                else
                  fallback()
                end
              end
            end, { "i", "s" })
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp" },
          }),
          snippet = {
            expand = function(args)
              vim.fn["vsnip#anonymous"](args.body)
            end,
          }
        })
      end,
    },
    {
      "editorconfig/editorconfig-vim",
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
    },
    {
      "nvim-lualine/lualine.nvim",
      config = function()
        local lualine = require('lualine')
        lualine.setup({
          options = {
            icons_enabled = false,
          },
        })
      end,
    },
    {
      "iamcco/markdown-preview.nvim",
      cmd = {
        "MarkdownPreviewToggle",
        "MarkdownPreview",
        "MarkdownPreviewStop",
      },
      ft = {
        "markdown",
      },
      build = function()
        vim.fn["mkdp#util#install"]()
      end,
      config = function()
        vim.g.mkdp_preview_options = {
          disable_sync_scroll = 1,
        }
      end,
    },
    {
      "lambdalisue/suda.vim",
      config = function()
        vim.cmd("ab w!! SudaWrite")
      end,
    },
    {
      "voldikss/vim-translator",
      init = function()
        vim.g.translator_default_engines = { "google" }
        vim.g.translator_target_lang = "ja"
      end,
      config = function()
        vim.cmd("nmap <silent> tw <Plug>TranslateW")
        vim.cmd("vmap <silent> tw <Plug>TranslateWV")
        vim.cmd("nmap <silent> tr <Plug>TranslateR")
        vim.cmd("vmap <silent> tr <Plug>TranslateRV")
      end,
    },
    {
      "zbirenbaum/copilot.lua",
      config = function()
        local copilot = require("copilot")
        copilot.setup({
          suggestion = {
            auto_trigger = true,
          },
          filetypes = {
            yaml = true,
            markdown = true,
            gitcommit = true,
            gitrebase = true,
          },
        })
      end,
    },
    "editorconfig/editorconfig-vim",
  }
})
