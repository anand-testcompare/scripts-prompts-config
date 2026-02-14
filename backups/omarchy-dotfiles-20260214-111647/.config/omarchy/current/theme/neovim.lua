return {
    {
        "bjarneo/aether.nvim",
        name = "aether",
        priority = 1000,
        opts = {
            disable_italics = false,
            colors = {
                base00 = "#0a100b",
                base01 = "#5a7a6a",
                base02 = "#0a100b",
                base03 = "#5a7a6a",
                base04 = "#d8ddd9",
                base05 = "#e0e5e1",
                base06 = "#e0e5e1",
                base07 = "#d8ddd9",

                base08 = "#c4a89a",
                base09 = "#d8ccc4",
                base0A = "#d4cba8",
                base0B = "#8aab96",
                base0C = "#9ab8ac",
                base0D = "#8aa8a0",
                base0E = "#b8a8a0",
                base0F = "#e5e0d4",
            },
        },
        config = function(_, opts)
            require("aether").setup(opts)
            vim.cmd.colorscheme("aether")

            require("aether.hotreload").setup()
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "aether",
        },
    },
}
