return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    opts = {
      variant = "main",
      dark_main = true,
      extend_background = true,
      highlight_groups = {
        Normal = { bg = "#1a1b26" },
        NormalNC = { bg = "#1a1b26" },
        NormalFloat = { bg = "#24283b" },
        Float = { bg = "#24283b" },
        FloatBorder = { fg = "#7aa2f7", bg = "#24283b" },
        VertSplit = { fg = "#414868", bg = "#1a1b26" },
        StatusLine = { fg = "#c0caf5", bg = "#1a1b26" },
        StatusLineNC = { fg = "#565f89", bg = "#1a1b26" },
        NonText = { fg = "#414868", bg = "NONE" },
        -- Command line improvements for readability
        Cmdline = { fg = "#c0caf5", bg = "#1a1b26" },
        CmdlineNormal = { fg = "#c0caf5", bg = "#1a1b26" },
        CmdlineBorder = { fg = "#7aa2f7", bg = "#24283b" },
        CmdlinePrompt = { fg = "#7aa2f7", bg = "#24283b" },
        -- Better contrast for other UI elements
        TelescopeBorder = { fg = "#7aa2f7", bg = "#1a1b26" },
        TelescopeTitle = { fg = "#7aa2f7", bg = "#1a1b26" },
        TelescopePromptTitle = { fg = "#bb9af7", bg = "#1a1b26" },
        TelescopePreviewTitle = { fg = "#9ece6a", bg = "#1a1b26" },
        TelescopeSelection = { fg = "#c0caf5", bg = "#24283b" },
        NotifyERRORBorder = { fg = "#f7768e", bg = "#1a1b26" },
        NotifyWARNBorder = { fg = "#e0af68", bg = "#1a1b26" },
        NotifyINFOBorder = { fg = "#7aa2f7", bg = "#1a1b26" },
        NotifyDEBUGBorder = { fg = "#565f89", bg = "#1a1b26" },
        NotifyTRACEBorder = { fg = "#bb9af7", bg = "#1a1b26" },
      }
    },
  },
}
