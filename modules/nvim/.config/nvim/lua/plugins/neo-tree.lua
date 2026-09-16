return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    keys = {
      -- LazyVim maps this to LazyVim.root(), which is derived from the current
      -- buffer, so a stray file from another project drags the tree with it.
      -- Pin it to the cwd instead; <leader>E already does the same.
      {
        "<leader>fe",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Explorer NeoTree (cwd)",
      },
      { "<leader>e", "<leader>fe", desc = "Explorer NeoTree (cwd)", remap = true },
    },
    opts = {
      filesystem = {
        -- LazyVim defaults to false, which lets the tree stay pinned to the
        -- first project it opened even after :cd elsewhere.
        bind_to_cwd = true,
        cwd_target = { sidebar = "tab", current = "window" },
        -- Opening a file outside the cwd would otherwise move the tree root to it.
        follow_current_file = { enabled = false },
      },
    },
  },
}
