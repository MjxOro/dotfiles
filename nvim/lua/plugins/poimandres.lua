-- Lua
return {
  "olivercederborg/poimandres.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("poimandres").setup({
      disable_background = true,
      disable_float_background = true,
      sidebar = "transparent",
      dim_nc_background = true,
      -- leave this setup function empty for default config
      -- or refer to the configuration section
      -- for configuration options
    })

    -- Apply colorscheme first

    -- Keep word highlights readable and theme-agnostic
    local groups = {
      "CursorWord",
      "MiniCursorword",
      "MiniCursorwordCurrent",
      "IlluminatedWordText",
      "IlluminatedWordRead",
      "IlluminatedWordWrite",
      "LspReferenceText",
      "LspReferenceRead",
      "LspReferenceWrite",
    }

    local highlight_opts = {
      underline = true,
      fg = "NONE",
      bg = "NONE",
    }

    for _, group in ipairs(groups) do
      vim.api.nvim_set_hl(0, group, highlight_opts)
    end

    -- Create an autocommand to ensure these settings persist when colorscheme changes
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "poimandres",
      callback = function()
        -- Re-apply the same highlighting settings when colorscheme is reapplied
        for _, group in ipairs(groups) do
          vim.api.nvim_set_hl(0, group, highlight_opts)
        end
      end,
    })
  end,
}
