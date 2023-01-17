local status, telescope = pcall(require, "telescope")
if (not status) then return end
local actions = require('telescope.actions')
local builtin = require("telescope.builtin")

local function telescope_buffer_dir()
    return vim.fn.expand('%:p:h')
end

local fb_actions = require "telescope".extensions.file_browser.actions

telescope.setup {
    defaults = {
        mappings = {
            n = {
                ["q"] = actions.close
            },
        },
    },
    extensions = {
        file_browser = {
            initial_mode = "normal",
            theme = "dropdown",
            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
            mappings = {
                ["i"] = {
                    -- your custom insert mode mappings
                },
                ["n"] = {
                    -- your custom normal mode mappings
                    ["N"] = fb_actions.create,
                    ["m"] = fb_actions.move,
                    ["D"] = fb_actions.remove,
                    ["r"] = fb_actions.rename
                },
            },
        },
    },
}

telescope.load_extension("file_browser")

vim.keymap.set('n', ';;',
    function()
        builtin.find_files({
            no_ignore = false,
            hidden = true
        })
    end)

vim.keymap.set('n', ';r', function()
    builtin.live_grep()
end)

vim.keymap.set("n", ";f", function()
    telescope.extensions.file_browser.file_browser({
        path = "%:p:h",
        cwd = telescope_buffer_dir(),
        respect_gitignore = false,
        hidden = true,
        grouped = true,
    })
end)
