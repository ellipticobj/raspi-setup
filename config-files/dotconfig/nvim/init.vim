call plug#begin()

" core utils
Plug 'tpope/vim-sensible'       " better defaults
Plug 'tpope/vim-commentary'     " easier commenting
Plug 'tpope/vim-surround'       " surround selections
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'         " fzf integration
Plug 'mileszs/ack.vim'          " code searching

" navigation
Plug 'christoomey/vim-tmux-navigator' " better tmux navigation
Plug 'preservim/nerdtree'       " file explorer

" ui enhancements
Plug 'itchyny/lightline.vim'    " lightweight status line
Plug 'norcalli/nvim-colorizer.lua' " color highlighter
Plug 'ap/vim-buftabline'        " buffer management

" syntax/lsp
Plug 'neoclide/coc.nvim', { 'branch': 'release' } " intellisense
Plug 'sheerun/vim-polyglot'     " better syntax highlighting

" languages
Plug 'rust-lang/rust.vim'
Plug 'python-mode/python-mode', { 'for': 'python', 'branch': 'develop' }
Plug 'dense-analysis/ale'

call plug#end()

source /home/luna/.config/nvim/coc-config.vim

" ======== language-specific settings ========
" rust
autocmd FileType rust nmap <leader>rr :Cargo run<CR>
autocmd FileType rust nmap <leader>rt :Cargo test<CR>
autocmd FileType rust nmap <leader>cb :Cargo build<CR>
let g:rustfmt_autosave = 1

" python
autocmd FileType python setlocal expandtab shiftwidth=4 softtabstop=4
let g:python_highlight_all = 1

" bash
let g:ale_sh_shellcheck_options = '-x'

" =============== key mappings ===============
nnoremap <silent> <C-p> :Files<CR>
nnoremap <silent> <C-f> :Rg<CR>
nnoremap <silent> <C-b> :Buffers<CR>
nnoremap <silent> <C-n> :NERDTreeToggle<CR>
nnoremap <silent> <C-h> :bp<CR>
nnoremap <silent> <C-l> :bn<CR>

" ============ window management ============
nnoremap <silent> <C-j> <C-w>j
nnoremap <silent> <C-k> <C-w>k
nnoremap <silent> <C-h> <C-w>h
nnoremap <silent> <C-l> <C-w>l

" ================= settings ================
let g:coc_disable_startup_warning = 1
let mapleader = "\<Space>"
set number relativenumber
set hidden
set termguicolors " true color support
set scrolloff=5
set tabstop=4 shiftwidth=4 expandtab
syntax enable

noremap <leader>w :w<CR>
noremap <leader>q :q<CR>
noremap <leader>e :CocCommand explorer<CR>
noremap <leader>g :CocDiagnostics<CR>

" ============== plugin config =============
let g:lightline = { 'colorscheme': 'wombat' }

let NERDTreeShowHidden=1
let NERDTreeMinimalUI=1

inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
