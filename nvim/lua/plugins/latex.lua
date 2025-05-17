return {
  {
    "lervag/vimtex",
    lazy = false,
    config = function()
      -- Use pdflatex directly instead of latexmk
      vim.g.vimtex_compiler_method = "pdflatex"

      -- Configure pdflatex options
      vim.g.vimtex_compiler_pdflatex = {
        options = {
          "-synctex=1",
          "-interaction=nonstopmode",
          "-file-line-error",
        },
      }

      -- PDF viewer configuration
      vim.g.vimtex_view_method = "general"
      vim.g.vimtex_view_general_viewer = "open"
    end,
  },
}
