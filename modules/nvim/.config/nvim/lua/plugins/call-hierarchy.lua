return {
  {
    "retran/meow.yarn.nvim",
    dependencies = { "MunifTanjim/nui.nvim" },
    cmd = "MeowYarn",
    keys = {
      { "gal", "<cmd>MeowYarn last<cr>", desc = "Last Call Hierarchy" },
    },
    opts = {
      window = {
        width = 0.85,
        height = 0.8,
        border = "rounded",
        layout = "horizontal",
        preview_height_ratio = 0.45,
      },
      expand_depth = 1,
      keep_open_on_jump = false,
    },
    config = function(_, opts)
      require("meow.yarn").setup(opts)

      local Hierarchy = require("meow.yarn.hierarchy")
      local new = Hierarchy.new
      Hierarchy.new = function(self, ...)
        local win = vim.api.nvim_get_current_win()
        local buf = vim.api.nvim_get_current_buf()
        local view = vim.fn.winsaveview()
        local tree = new(self, ...)
        local unmount = tree.unmount
        tree.unmount = function(instance)
          local mounted = instance:is_valid()
          unmount(instance)
          if mounted and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
            vim.api.nvim_set_current_win(win)
            vim.fn.winrestview(view)
          end
        end
        return tree
      end
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ["*"] = {
          keys = {
            {
              "gai",
              "<cmd>MeowYarn call callers<cr>",
              desc = "Incoming Call Tree",
              has = "callHierarchy/incomingCalls",
            },
            {
              "gao",
              "<cmd>MeowYarn call callees<cr>",
              desc = "Outgoing Call Tree",
              has = "callHierarchy/outgoingCalls",
            },
          },
        },
      },
    },
  },
}
