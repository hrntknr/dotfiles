" 全体設定
set fenc=utf-8   " 文字コード
set nocompatible " 互換性設定

" 画面表示の設定

set number         " 行番号を表示する
set cursorline     " カーソル行の背景色を変える
set laststatus=2   " ステータス行を常に表示
set showcmd        " 実行前のコマンドを表示
set cmdheight=1    " メッセージ表示欄を1行確保
set showmatch      " 対応する括弧を強調表示
set helpheight=999 " ヘルプを画面いっぱいに開く
set list           " 不可視文字を表示
syntax on          " シンタックスハイライト
set listchars=tab:»\ ,trail:-,extends:»,precedes:«,nbsp:% " 不可視文字の表示記号指定


" カーソル移動関連の設定
set backspace=indent,eol,start " Backspaceキーの影響範囲に制限を設けない
set whichwrap=b,s,h,l,<,>,[,]  " 行頭行末の左右移動で行をまたぐ
set scrolloff=8                " 上下8行の視界を確保
set sidescrolloff=16           " 左右スクロール時の視界を確保
set sidescroll=1               " 左右スクロールは一文字づつ行う
set virtualedit=onemore        " カーソルを行末の一つ先まで移動可能にする
set keymodel=startsel          " キーモデルを変更


" ファイル処理関連の設定

set confirm    " 保存されていないファイルがあるときは終了前に保存確認
set hidden     " 保存されていないファイルがあるときでも別のファイルを開くことが出来る
set autoread   " 外部でファイルに変更がされた場合は読みなおす
set nobackup   " ファイル保存時にバックアップファイルを作らない
set noswapfile " ファイル編集中にスワップファイルを作らない


" 検索/置換の設定

set hlsearch   " 検索文字列をハイライトする
set incsearch  " インクリメンタルサーチを行う
set ignorecase " 大文字と小文字を区別しない
set smartcase  " 大文字と小文字が混在した言葉で検索を行った場合に限り、大文字と小文字を区別する
set wrapscan   " 最後尾まで検索を終えたら次の検索で先頭に移る
set gdefault   " 置換の時 g オプションをデフォルトで有効にする


" タブ/インデントの設定

set expandtab     " タブ入力を複数の空白入力に置き換える
set tabstop=4     " 画面上でタブ文字が占める幅
set shiftwidth=2  " 自動インデントでずれる幅
set softtabstop=2 " 連続した空白に対してタブキーやバックスペースキーでカーソルが動く幅
set autoindent    " 改行時に前の行のインデントを継続する
set smartindent   " 改行時に入力された行の末尾に合わせて次の行のインデントを増減する


" 補完設定
set wildmode=list:longest        " ファイル名補完
set completeopt=menuone,noinsert " 補完の挙動を修正


" 動作環境との統合関連の設定

set clipboard=unnamed,unnamedplus " OSのクリップボードをレジスタ指定無しで Yank, Put 出来るようにする
set mouse=a                       " マウスの入力を受け付ける
set shellslash                    " Windows でもパスの区切り文字を / にする


" コマンドラインの設定

set wildmenu wildmode=list:longest,full " コマンドラインモードでTABキーによるファイル名補完を有効にする
set history=10000                       " コマンドラインの履歴を10000件保存する


" ビープの設定

set visualbell t_vb= " ビープ音すべてを無効にする
set noerrorbells     " エラーメッセージの表示時にビープを鳴らさない


" プラグインの設定

"dein Scripts-----------------------------

" Required:
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

" Required:
if dein#load_state('~/.cache/dein')
  call dein#begin('~/.cache/dein')

  call dein#add('Shougo/deol.nvim')
  call dein#add('scrooloose/nerdtree')
  call dein#add('Xuyuanp/nerdtree-git-plugin')
  call dein#add('vim-denops/denops.vim')
  call dein#add('Shougo/ddc.vim')
  call dein#add('Shougo/ddc-around')
  call dein#add('Shougo/ddc-matcher_head')
  call dein#add('Shougo/ddc-sorter_rank')
  call dein#add('Shougo/ddc-nvim-lsp')
  call dein#add('williamboman/mason.nvim')
  call dein#add('williamboman/mason-lspconfig.nvim')
  call dein#add('neovim/nvim-lspconfig')
  call dein#add('editorconfig/editorconfig-vim')
  call dein#add('matsui54/denops-signature_help')
  call dein#add('jose-elias-alvarez/null-ls.nvim')
  call dein#add('airblade/vim-gitgutter')

 " Required:
  call dein#end()
  call dein#save_state()
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
else
endif

"End dein Scripts-------------------------

let g:deoplete#enable_at_startup = 1
let NERDTreeShowHidden=1

call ddc#custom#patch_global('sources', ['nvim-lsp', 'around'])
call ddc#custom#patch_global('sourceOptions', {
  \ '_': {
  \   'matchers': ['matcher_head'],
  \   'sorters': ['sorter_rank'],
  \ },
  \ 'around': {
  \   'maxSize': 500,
  \   'mark': 'A',
  \   'matchers': ['matcher_head', 'matcher_length'],
  \ },
  \ 'nvim-lsp': {
  \   'mark': 'lsp',
  \   'forceCompletionPattern': '\.\w*|:\w*|->\w*',
  \ },
  \ })
call ddc#enable()

let g:signature_help_config = {'style': 'labelOnly'}
call signature_help#enable()

lua << EOF
require('mason').setup()
require('mason-lspconfig').setup({
  automatic_installation = true
})
require('mason-lspconfig').setup_handlers {
  function (server_name)
    require('lspconfig')[server_name].setup {
      on_attach = on_attach
    }
  end,
}
local mason_package = require("mason-core.package")
local null_ls = require("null-ls")
local null_sources = {}
for _, package in ipairs(require("mason-registry").get_installed_packages()) do
  local package_categories = package.spec.categories[1]
  if package_categories == mason_package.Cat.Formatter then
    table.insert(null_sources, null_ls.builtins.formatting[package.name])
  end
  if package_categories == mason_package.Cat.Linter then
    table.insert(null_sources, null_ls.builtins.diagnostics[package.name])
  end
end
null_ls.setup({
  sources = null_sources,
})
EOF

command Tree NERDTreeToggle
ab f lua vim.lsp.buf.formatting()
ab gd lua vim.lsp.buf.definition()
ab gi lua vim.lsp.buf.implementation()
inoremap <expr><Tab>  pumvisible() ? "<C-y>" : "<Tab>" " 補完モードのときのTabを確定として扱う

