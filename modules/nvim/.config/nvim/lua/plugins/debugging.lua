return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "debugpy" } },
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    -- Mason owns debugpy installation; avoid racing its in-progress install.
    opts = { automatic_installation = { exclude = { "python" } } },
  },
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>dc",
        function()
          local dap = require("dap")
          if not dap.session() then
            vim.cmd.wall()
          end
          dap.continue()
        end,
        desc = "Run/Continue",
      },
      {
        "<leader>td",
        function()
          vim.cmd.wall()
          require("neotest").run.run({ strategy = "dap" })
        end,
        desc = "Debug Nearest Test",
      },
    },
  },
  {
    "rcarriga/nvim-dap-ui",
    opts = {
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.4 },
            { id = "watches", size = 0.2 },
            { id = "stacks", size = 0.2 },
            { id = "breakpoints", size = 0.2 },
          },
          size = 38,
          position = "left",
        },
        {
          elements = {
            { id = "repl", size = 0.5 },
            { id = "console", size = 0.5 },
          },
          size = 10,
          position = "bottom",
        },
      },
      floating = { border = "rounded", max_width = 0.8, max_height = 0.8 },
    },
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    opts = {
      virt_text_pos = "eol",
      all_frames = false,
    },
  },
  {
    "nvim-neotest/neotest",
    opts = {
      adapters = {
        ["neotest-python"] = {
          python = function(root)
            local python = require("venv-selector").python()
            if python then
              return { python }
            end
            return require("neotest-python.base").get_python_command(root)
          end,
        },
      },
      output = { open_on_run = false },
      summary = { open = "botright vsplit | vertical resize 38" },
      floating = { border = "rounded", max_width = 0.8, max_height = 0.8 },
    },
  },
}
