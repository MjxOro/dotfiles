return {
  "nvim-telescope/telescope.nvim",
  keys = {
    -- change a keymap
    { ";f", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
  },
  opts = {
    defaults = {
      initial_mode = "normal",
    },
  },
}
