-- Turn <Leader> to space
-- vim.g.mapleader = " "

-- Highlight Line Mover
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Cursor stays in middle
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- greatest remap ever
-- (perserve highlight copy and highlight paste value)
vim.keymap.set("x", "<Space>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
-- clipboard copy shortcut
vim.keymap.set({ "n", "v" }, "<Space>y", [["+y]])
vim.keymap.set("n", "<Space>Y", [["+Y]])

-- hotkey for new tab
vim.keymap.set("n", "<Space>t", ":tabnew<CR>")
