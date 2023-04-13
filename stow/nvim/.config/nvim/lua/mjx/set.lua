-- Cursor
-- vim.opt.guicursor = ""
-- Line number
vim.opt.nu = true
vim.opt.relativenumber = true

-- vim.opt.smartindent = true

-- Vim Search
vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.o.autoindent = true

-- Set default tab width to 4 spaces
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- Set specific tab width for JavaScript, TypeScript, JSX, TSX, Python, and Lua files
vim.cmd('autocmd FileType javascript setlocal tabstop=2 shiftwidth=2')
vim.cmd('autocmd FileType typescript setlocal tabstop=2 shiftwidth=2')
vim.cmd('autocmd FileType jsx setlocal tabstop=2 shiftwidth=2')
vim.cmd('autocmd FileType tsx setlocal tabstop=2 shiftwidth=2')
vim.cmd('autocmd FileType lua setlocal tabstop=2 shiftwidth=2')

