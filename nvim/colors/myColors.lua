-- myColors – Starship palette + pastel Poimandres accents
local c = {
	bg_dark = "#0F172A",
	bg = "NONE",
	fg = "#E0E6ED",
	fg_dim = "#C9D1D9",
	gray = "#9FA6C1",
	gray_dark = "#525C70",
	blue = "#334155",
	blue_light = "#475569",
	green = "#3EB489",
	cyan = "#7AD1C3", -- softer, greener pastel teal
	yellow = "#DCCFA3", -- muted wheat pastel
	magenta = "#C58BB9",
	red = "#C56565",
}

local function hl(g, s)
	vim.api.nvim_set_hl(0, g, s)
end

vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
	vim.cmd("syntax reset")
end
vim.g.colors_name = "myColors"

---------------------------------------------------------------------------
-- UI ----------------------------------------------------------------------
---------------------------------------------------------------------------
hl("Normal", { fg = c.fg, bg = c.bg })
hl("NormalFloat", { fg = c.fg, bg = "NONE" })
hl("FloatBorder", { fg = c.gray, bg = "NONE" })
hl("CursorLine", { bg = "#1B2433" })
hl("CursorLineNr", { fg = c.green, bold = true })
hl("LineNr", { fg = c.gray })
hl("SignColumn", { bg = c.bg })
hl("VertSplit", { fg = c.gray_dark })
hl("StatusLine", { fg = c.fg, bg = c.blue_light })
hl("StatusLineNC", { fg = c.fg_dim, bg = c.blue })
hl("TabLine", { fg = c.fg_dim, bg = c.bg_dark })
hl("TabLineSel", { fg = c.green, bg = c.blue_light, bold = true })
hl("TabLineFill", { bg = c.bg })

---------------------------------------------------------------------------
-- Syntax ------------------------------------------------------------------
---------------------------------------------------------------------------
hl("Comment", { fg = c.gray, italic = true })
hl("String", { fg = c.cyan })
hl("Constant", { fg = c.green })
hl("Identifier", { fg = c.fg })
hl("Function", { fg = c.magenta, bold = true })
hl("Statement", { fg = c.yellow })
hl("Operator", { fg = c.fg_dim })
hl("PreProc", { fg = c.cyan })
hl("Type", { fg = c.blue_light })
hl("Special", { fg = c.green })
hl("Error", { fg = c.red, bold = true })
hl("WarningMsg", { fg = c.yellow })
hl("Todo", { fg = c.magenta, bold = true })

---------------------------------------------------------------------------
-- LSP / Diagnostics -------------------------------------------------------
---------------------------------------------------------------------------
hl("DiagnosticError", { fg = c.red, bold = true })
hl("DiagnosticWarn", { fg = c.yellow, italic = true })
hl("DiagnosticInfo", { fg = c.cyan })
hl("DiagnosticHint", { fg = c.green })

---------------------------------------------------------------------------
-- Git / Diff --------------------------------------------------------------
---------------------------------------------------------------------------
hl("DiffAdd", { fg = c.green, bg = c.bg_dark })
hl("DiffChange", { fg = c.cyan, bg = c.bg_dark })
hl("DiffDelete", { fg = c.red, bg = c.bg_dark })
hl("DiffText", { fg = c.fg, bg = c.blue })

---------------------------------------------------------------------------
-- Treesitter --------------------------------------------------------------
hl("@variable", { fg = c.fg })
hl("@function", { fg = c.magenta, bold = true })
hl("@string", { fg = c.cyan })
hl("@comment", { fg = c.gray, italic = true })
hl("@keyword", { fg = c.yellow })
hl("@type", { fg = c.blue_light })
hl("@error", { fg = c.red, bold = true })

---------------------------------------------------------------------------
-- Plugin UIs --------------------------------------------------------------
hl("TelescopeNormal", { fg = c.fg, bg = "NONE" })
hl("TelescopeBorder", { fg = c.gray, bg = "NONE" })
hl("TelescopeSelection", { fg = c.green, bold = true })
hl("LazyNormal", { fg = c.fg, bg = "NONE" })

---------------------------------------------------------------------------
-- Terminal palette --------------------------------------------------------
vim.g.terminal_color_0 = c.bg_dark
vim.g.terminal_color_1 = c.red
vim.g.terminal_color_2 = c.green
vim.g.terminal_color_3 = c.yellow
vim.g.terminal_color_4 = c.blue
vim.g.terminal_color_5 = c.magenta
vim.g.terminal_color_6 = c.cyan
vim.g.terminal_color_7 = c.fg_dim
vim.g.terminal_color_8 = c.gray
vim.g.terminal_color_9 = c.red
vim.g.terminal_color_10 = c.green
vim.g.terminal_color_11 = c.yellow
vim.g.terminal_color_12 = c.blue_light
vim.g.terminal_color_13 = c.magenta
vim.g.terminal_color_14 = c.cyan
vim.g.terminal_color_15 = c.fg

return true
