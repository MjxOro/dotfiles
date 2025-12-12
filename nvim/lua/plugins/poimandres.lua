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

    -- Set highlight groups to be 80% transparent specifically for this theme
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

    for _, group in ipairs(groups) do
      vim.api.nvim_set_hl(0, group, {
        -- bg = "#383F52", -- Slightly more visible than #2E3440
        -- fg = "#D8DEE9", -- Light color for better contrast
        bg = "#5C6A94", -- Very prominent highlight
        fg = "#FFFFFF", -- Pure white text
      })
    end

    -- Create an autocommand to ensure these settings persist when colorscheme changes
    vim.api.nvim_create_autocmd("ColorScheme", {
      pattern = "poimandres",
      callback = function()
        -- Re-apply the same highlighting settings when colorscheme is reapplied
        for _, group in ipairs(groups) do
          vim.api.nvim_set_hl(0, group, {
            -- bg = "#383F52",
            -- fg = "#D8DEE9",
            bg = "#5C6A94", -- Very prominent highlight
            fg = "#FFFFFF", -- Pure white text
          })
        end
      end,
    })
  end,
}
