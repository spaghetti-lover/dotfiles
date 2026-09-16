return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    ft = { "markdown", "codecompanion" },
    opts = {
      code = {
        sign = false,
        -- Soft colour block, no heavy border: `hide` conceals the ``` fences
        -- so only the background marks the block.
        border = "hide",
        width = "block",
        left_pad = 1,
        right_pad = 1,
      },
      heading = {
        sign = false,
        -- Drop the background bands. The defaults borrow the diff colors --
        -- a solid bright yellow bar on H1 and error-red on H4 -- which read
        -- badly against the transparent background set in plugin/after.
        -- An empty list is the supported "no background" value.
        backgrounds = {},
      },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      Snacks.toggle({
        name = "Render Markdown",
        get = require("render-markdown").get,
        set = require("render-markdown").set,
      }):map("<leader>um")
    end,
  },
}
