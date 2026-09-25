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
      window = {
        mappings = {
          ["i"] = function(state)
            if vim.fn.executable("pngpaste") ~= 1 then
              vim.notify("pngpaste is required; install it with: brew install pngpaste", vim.log.levels.ERROR)
              return
            end

            local node = state.tree:get_node()
            if not node then
              return
            end

            local directory = node:get_id()
            if node.type ~= "directory" then
              directory = vim.fn.fnamemodify(directory, ":h")
            end

            vim.ui.input({ prompt = "Image name: ", default = "image.png" }, function(name)
              if not name or name == "" then
                return
              end

              if not name:lower():match("%.png$") then
                name = name .. ".png"
              end

              local output = directory .. "/" .. name
              vim.fn.system({ "pngpaste", output })

              if vim.v.shell_error ~= 0 then
                vim.notify("Could not paste an image from the clipboard", vim.log.levels.ERROR)
                return
              end

              vim.notify("Saved image: " .. output)
              require("neo-tree.sources.manager").refresh("filesystem")
            end)
          end,
        },
      },
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
