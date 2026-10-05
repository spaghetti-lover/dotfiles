return {
  -- add gruvbox
  {
    "ellisonleao/gruvbox.nvim",
    opts = function(_, opts)
      opts.overrides = vim.tbl_extend("force", opts.overrides or {}, {
        DapUIFloatNormal = { link = "NormalFloat" },
        DapUIFloatBorder = { link = "FloatBorder" },
        DapUINormal = { link = "Normal" },
        DapUINormalNC = { link = "NormalNC" },
        NeotestPassed = { link = "DiagnosticOk" },
        NeotestFailed = { link = "DiagnosticError" },
        NeotestRunning = { link = "DiagnosticInfo" },
        NeotestSkipped = { link = "DiagnosticWarn" },
        NeotestUnknown = { link = "Comment" },
        NeotestTest = { link = "Normal" },
        NeotestFile = { link = "Directory" },
        NeotestNamespace = { link = "GruvboxPurple" },
        NeotestAdapterName = { link = "Title" },
        NeotestFocused = { link = "GruvboxYellowBold" },
        NeotestMarked = { link = "GruvboxOrangeBold" },
        NeotestTarget = { link = "GruvboxAqua" },
        NeotestBorder = { link = "FloatBorder" },
        NeotestWinSelect = { link = "Title" },
        NeotestIndent = { link = "Comment" },
        NeotestExpandMarker = { link = "Comment" },
      })

      -- Link controls instead of using DAP UI's fixed colors/backgrounds.
      for name, color in pairs({
        PlayPause = "GruvboxGreen",
        Restart = "GruvboxGreen",
        Stop = "GruvboxRed",
        StepBack = "GruvboxBlue",
        StepInto = "GruvboxBlue",
        StepOut = "GruvboxBlue",
        StepOver = "GruvboxBlue",
      }) do
        opts.overrides["DapUI" .. name] = { link = color }
        opts.overrides["DapUI" .. name .. "NC"] = { link = color }
      end
    end,
  },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
