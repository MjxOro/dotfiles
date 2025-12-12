return {
	"lervag/vimtex",
	lazy = false, -- We don't want to lazy load VimTeX
	-- tag = "v2.15", -- Uncomment to pin to a specific release

	init = function()
		-- VIEWER CONFIGURATION (ZATHURA)
		-- Set Zathura as the primary viewer for VimTeX
		vim.g.vimtex_view_method = "zathura"

		-- Optional: If Zathura doesn't launch or sync correctly, you might need
		-- to explicitly define the command. However, Homebrew's `zathura`
		-- binary is usually sufficient and in your PATH.
		-- If you bundled Zathura into an application bundle via `convert-into-app.sh`,
		-- you might need this (though less common for direct CLI use):
		-- vim.g.vimtex_view_general_viewer = "open -a Zathura"

		-- Make Zathura regain focus when recompiling the PDF.
		-- This is very useful when using continuous compilation (e.g., latexmk).
		vim.g.vimtex_view_general_focus_always = 1

		-- COMPILER CONFIGURATION (LUALATEX)
		-- Set the compiler method to latexmk.
		-- Latexmk is highly recommended as it handles multiple compilation passes
		-- (for bibliography, table of contents, etc.) and cleanup automatically.
		vim.g.vimtex_compiler_method = "latexmk"

		-- Configure latexmk to use LuaLaTeX as the default engine.
		-- The `_` key means it applies to all .tex files unless overridden.
		vim.g.vimtex_compiler_latexmk_engines = {
			_ = "-lualatex", -- Use lualatex for all .tex files
			-- If you needed to mix engines (e.g., pdflatex for some files),
			-- you could do: tex = 'pdflatex',
		}

		-- OTHER USEFUL VIMTEX SETTINGS (General)
		-- Use the quickfix list for compilation errors and warnings.
		-- This allows you to jump directly to errors.
		vim.g.vimtex_quickfix_method = "latexlog"

		-- Enable default VimTeX insert mode mappings (e.g., auto-closing environments).
		vim.g.vimtex_imaps_enabled = 1

		-- Enable default VimTeX normal mode mappings (e.g., `\ll` for compile, `\lv` for view).
		vim.g.vimtex_mappings_enabled = 1
	end,
}
