-- myColors – Minimal Poimandres-inspired theme
local c = {
	-- Background colors (Poimandres-inspired)
	bg = "NONE", -- Transparent background
	bg_dark = "#1B1E2A", -- Darker background for UI elements
	bg_light = "#242838", -- Lighter background for UI elements

	-- Foreground colors (minimal palette)
	fg = "#B4C5E4", -- Main foreground (Poimandres-inspired)
	fg_dim = "#8B92A8", -- Dimmed foreground
	fg_bright = "#E0E6ED", -- Bright foreground

	-- Minimal color palette (semantic focus)
	gray = "#4A5067", -- Gray for comments and UI
	blue = "#6B7DBB", -- Blue for functions and identifiers
	blue_dark = "#566094", -- Darker blue for types
	green = "#5DE4C7", -- Variable color
	string = "#98FBCB",
	yellow = "#E3C88A", -- Yellow for warnings and special
	red = "#E06C75", -- Red for errors and deletions
	purple = "#C678DD", -- Purple (minimal use)
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
hl("NormalFloat", { fg = c.fg, bg = c.bg })
hl("FloatBorder", { fg = c.gray, bg = c.bg })
hl("CursorLine", { bg = c.bg_light })
hl("CursorLineNr", { fg = c.blue, bold = true })
hl("LineNr", { fg = c.gray })
hl("SignColumn", { bg = c.bg })
hl("VertSplit", { fg = c.gray })
hl("StatusLine", { fg = c.fg, bg = c.bg_dark })
hl("StatusLineNC", { fg = c.fg_dim, bg = c.bg_dark })
hl("TabLine", { fg = c.fg_dim, bg = c.bg_dark })
hl("TabLineSel", { fg = c.blue, bg = c.bg_light, bold = true })
hl("TabLineFill", { bg = c.bg_dark })
hl("WinSeparator", { fg = c.gray })

---------------------------------------------------------------------------
-- Syntax ------------------------------------------------------------------
---------------------------------------------------------------------------
hl("Comment", { fg = "#6B7280", italic = true }) -- Lighter comment color for visibility
hl("String", { fg = c.string }) -- Using the string color
hl("Constant", { fg = c.fg })
hl("Number", { fg = c.fg })
hl("Boolean", { fg = c.fg })
hl("Identifier", { fg = c.fg })
hl("Function", { fg = c.blue })
hl("Statement", { fg = c.green }) -- Using the variable color
hl("Operator", { fg = c.fg })
hl("Keyword", { fg = c.green }) -- Using the variable color
hl("PreProc", { fg = c.blue_dark })
hl("Type", { fg = c.blue_dark }) -- Darker types to put focus on code
hl("Special", { fg = c.yellow })
hl("Error", { fg = c.red, bold = true })
hl("WarningMsg", { fg = c.yellow })
hl("Todo", { fg = c.green, bold = true }) -- Using the variable color

---------------------------------------------------------------------------
-- LSP / Diagnostics -------------------------------------------------------
---------------------------------------------------------------------------
hl("DiagnosticError", { fg = c.red })
hl("DiagnosticWarn", { fg = c.yellow })
hl("DiagnosticInfo", { fg = c.blue })
hl("DiagnosticHint", { fg = c.green }) -- Using the variable color
hl("DiagnosticUnderlineError", { fg = c.red, underline = true })
hl("DiagnosticUnderlineWarn", { fg = c.yellow, underline = true })
hl("DiagnosticUnderlineInfo", { fg = c.blue, underline = true })
hl("DiagnosticUnderlineHint", { fg = c.green, underline = true }) -- Using the variable color

---------------------------------------------------------------------------
-- Git / Diff --------------------------------------------------------------
---------------------------------------------------------------------------
hl("DiffAdd", { fg = c.green, bg = c.bg_dark }) -- Using the variable color
hl("DiffChange", { fg = c.blue, bg = c.bg_dark })
hl("DiffDelete", { fg = c.red, bg = c.bg_dark })
hl("DiffText", { fg = c.fg, bg = c.bg_light })

---------------------------------------------------------------------------
-- Treesitter --------------------------------------------------------------
hl("@variable", { fg = c.green }) -- Using the variable color
hl("@variable.builtin", { fg = c.green }) -- Using the variable color
hl("@function", { fg = c.blue })
hl("@function.builtin", { fg = c.blue })
hl("@function.macro", { fg = c.green }) -- Using the variable color
hl("@string", { fg = c.string }) -- Using the string color
hl("@string.escape", { fg = c.yellow })
hl("@string.special", { fg = c.yellow })
hl("@comment", { fg = "#6B7280", italic = true }) -- Lighter comment color
hl("@keyword", { fg = c.green }) -- Using the variable color
hl("@keyword.function", { fg = c.green }) -- Using the variable color
hl("@keyword.operator", { fg = c.green }) -- Using the variable color
hl("@operator", { fg = c.fg })
hl("@type", { fg = c.blue_dark }) -- Darker types to put focus on code
hl("@type.builtin", { fg = c.blue_dark })
hl("@type.qualifier", { fg = c.green }) -- Using the variable color
hl("@constant", { fg = c.fg })
hl("@constant.builtin", { fg = c.blue })
hl("@constant.macro", { fg = c.green }) -- Using the variable color
hl("@namespace", { fg = c.blue_dark })
hl("@symbol", { fg = c.yellow })
hl("@property", { fg = c.fg })
hl("@field", { fg = c.fg })
hl("@parameter", { fg = c.fg })
hl("@parameter.reference", { fg = c.fg })
hl("@text", { fg = c.fg })
hl("@text.strong", { fg = c.fg, bold = true })
hl("@text.emphasis", { fg = c.fg, italic = true })
hl("@text.underline", { fg = c.fg, underline = true })
hl("@text.strike", { fg = c.fg, strikethrough = true })
hl("@text.title", { fg = c.blue, bold = true })
hl("@text.literal", { fg = c.string }) -- Using the string color
hl("@text.uri", { fg = c.blue, underline = true })
hl("@text.reference", { fg = c.yellow })
hl("@text.todo", { fg = c.green, bold = true }) -- Using the variable color
hl("@text.note", { fg = c.blue })
hl("@text.warning", { fg = c.yellow })
hl("@text.danger", { fg = c.red })
hl("@text.diff.add", { fg = c.green }) -- Using the variable color
hl("@text.diff.delete", { fg = c.red })
hl("@tag", { fg = c.green }) -- Using the variable color
hl("@tag.attribute", { fg = c.blue })
hl("@tag.delimiter", { fg = c.gray })
hl("@error", { fg = c.red })

---------------------------------------------------------------------------
-- File Explorer (NvimTree, etc.) ------------------------------------------
-- Minimal colors for file icons with transparent background
hl("NvimTreeFolderIcon", { fg = c.blue }) -- Changed from cyan to minimal blue
hl("NvimTreeFolderName", { fg = c.blue })
hl("NvimTreeOpenedFolderName", { fg = c.blue, bold = true })
hl("NvimTreeEmptyFolderName", { fg = c.gray })
hl("NvimTreeNormal", { fg = c.fg, bg = c.bg })
hl("NvimTreeNormalNC", { fg = c.fg, bg = c.bg })
hl("NvimTreeRootFolder", { fg = c.green, bold = true }) -- Using the variable color
hl("NvimTreeSpecialFile", { fg = c.yellow })
hl("NvimTreeExecFile", { fg = c.green }) -- Using the variable color
hl("NvimTreeImageFile", { fg = c.gray })
hl("NvimTreeIndentMarker", { fg = c.gray })

-- Common file explorer highlight groups
hl("Directory", { fg = c.blue }) -- General directory color
hl("FolderIcon", { fg = c.blue }) -- Alternative folder icon highlight

-- If you use Telescope file browser
hl("TelescopePreviewFile", { fg = c.fg })
hl("TelescopePreviewDirectory", { fg = c.blue }) -- Changed from cyan to minimal blue
hl("TelescopePreviewBlock", { fg = c.blue })
hl("TelescopePreviewBorder", { fg = c.gray })
hl("TelescopePreviewTitle", { fg = c.string }) -- Using the string color

---------------------------------------------------------------------------
-- Plugin UIs --------------------------------------------------------------
hl("TelescopeNormal", { fg = c.fg, bg = c.bg })
hl("TelescopeBorder", { fg = c.gray, bg = c.bg })
hl("TelescopeSelection", { fg = c.blue, bg = c.bg_light, bold = true })
hl("TelescopeMatching", { fg = c.yellow, bold = true })
hl("TelescopePromptPrefix", { fg = c.blue })
hl("TelescopePromptTitle", { fg = c.blue })
hl("TelescopeResultsTitle", { fg = c.fg })
hl("TelescopePreviewTitle", { fg = c.string }) -- Using the string color
hl("LazyNormal", { fg = c.fg, bg = c.bg })
hl("LazyButton", { fg = c.fg, bg = c.bg_dark })
hl("LazyButtonActive", { fg = c.blue, bg = c.bg_light })
hl("LazyH1", { fg = c.blue, bg = c.bg_light, bold = true })

---------------------------------------------------------------------------
-- Terminal palette --------------------------------------------------------
vim.g.terminal_color_0 = c.bg_dark
vim.g.terminal_color_1 = c.red
vim.g.terminal_color_2 = c.green -- Using the variable color
vim.g.terminal_color_3 = c.yellow
vim.g.terminal_color_4 = c.blue
vim.g.terminal_color_5 = c.purple
vim.g.terminal_color_6 = c.blue -- Using blue instead of cyan for terminal
vim.g.terminal_color_7 = c.fg_dim
vim.g.terminal_color_8 = c.gray
vim.g.terminal_color_9 = c.red
vim.g.terminal_color_10 = c.green -- Using the variable color
vim.g.terminal_color_11 = c.yellow
vim.g.terminal_color_12 = c.blue
vim.g.terminal_color_13 = c.purple
vim.g.terminal_color_14 = c.blue -- Using blue instead of cyan for terminal
vim.g.terminal_color_15 = c.fg

return true
