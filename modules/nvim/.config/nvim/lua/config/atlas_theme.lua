local M = {}

local function color(field, ...)
  for _, name in ipairs({ ... }) do
    local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    if ok and hl[field] then
      return hl[field]
    end
  end
end

local function set(name, opts)
  vim.api.nvim_set_hl(0, name, opts)
end

local function link(name, target)
  set(name, { link = target })
end

function M.apply()
  local foreground = color("fg", "Normal", "NormalFloat")
  local background = color("bg", "Normal", "NormalFloat") or (vim.o.background == "light" and 0xffffff or 0x000000)
  local footer_background = color("bg", "StatusLine", "Pmenu", "NormalFloat", "Normal")

  local accents = {
    positive = color("fg", "DiagnosticOk", "String", "Normal"),
    info = color("fg", "DiagnosticInfo", "Function", "Normal"),
    warning = color("fg", "DiagnosticWarn", "Statement", "Normal"),
    error = color("fg", "DiagnosticError", "Error", "Normal"),
    note = color("fg", "DiagnosticHint", "Special", "Normal"),
    muted = color("fg", "Comment", "LineNr", "Normal"),
    title = color("fg", "Title", "Identifier", "Normal"),
  }

  for name, target in pairs({
    AtlasBorder = "FloatBorder",
    AtlasTabInactive = "CursorLine",
    AtlasTextMuted = "Comment",
    AtlasLogDebug = "Comment",
    AtlasDiffAddLine = "DiffAdd",
    AtlasDiffChangeLine = "DiffChange",
    AtlasDiffRemoveLine = "DiffDelete",
    AtlasDiffDeleteFiller = "Comment",
  }) do
    link(name, target)
  end

  for name, style in pairs({
    AtlasGitHubTheme = { fg = accents.title, bold = true },
    AtlasGitLabTheme = { fg = accents.warning, bold = true },
    AtlasBitbucketTheme = { fg = accents.info, bold = true },
    AtlasJiraTheme = { fg = accents.note, bold = true },
    AtlasColumnHeader = { fg = accents.title, bold = true },
    AtlasSectionHeader = { fg = accents.title, bold = true, underline = true },
    AtlasTextMutedStrikethrough = { fg = accents.muted, strikethrough = true },
    AtlasTextPositive = { fg = accents.positive },
    AtlasTextNote = { fg = accents.note, bold = true },
    AtlasTextWarning = { fg = accents.warning, bold = true },
    AtlasLogInfo = { fg = accents.info },
    AtlasLogWarn = { fg = accents.warning },
    AtlasLogError = { fg = accents.error },
    AtlasLogCommand = { fg = accents.info },
    AtlasJiraKey = { fg = accents.info, bold = true },
    AtlasIssueOpen = { fg = accents.positive, bold = true },
    AtlasIssueClosed = { fg = accents.note, bold = true },
    AtlasPROpen = { fg = accents.positive },
    AtlasPRMerged = { fg = accents.info },
    AtlasPRDeclined = { fg = accents.error },
    AtlasPRDraft = { fg = accents.warning },
  }) do
    set(name, style)
  end

  set("AtlasLogErrorLine", {
    fg = accents.error,
    bg = color("bg", "DiagnosticVirtualTextError"),
  })
  set("AtlasLogGroup", { fg = accents.title, bg = color("bg", "CursorLine"), bold = true })
  set("AtlasFooterBackground", { bg = footer_background })
  set("AtlasFooterText", { fg = accents.muted, bg = footer_background })
  set("AtlasFooterActive", { fg = foreground, bg = footer_background, bold = true })

  for name, accent in pairs({
    AtlasFooterInfo = "info",
    AtlasFooterNote = "note",
    AtlasFooterWarning = "warning",
    AtlasFooterError = "error",
    AtlasFooterSuccess = "positive",
  }) do
    set(name, { fg = accents[accent], bg = footer_background, bold = true })
  end

  for name, accent in pairs({
    AtlasChipActive = "info",
    AtlasRelatedChip = "muted",
    AtlasIssueOpenChip = "positive",
    AtlasIssueClosedChip = "note",
    AtlasPROpenChip = "positive",
    AtlasPRMergedChip = "info",
    AtlasPRDeclinedChip = "error",
    AtlasPRDraftChip = "warning",
    AtlasJiraChipStoryPoints = "error",
    AtlasJiraChipDueDate = "warning",
    AtlasJiraChipParent = "note",
  }) do
    set(name, { fg = background, bg = accents[accent], bold = true })
  end

  link("AtlasJiraEpic", "AtlasLogWarn")

  local dynamic_sources = {
    "DiagnosticInfo",
    "Type",
    "String",
    "DiagnosticWarn",
    "Statement",
    "Special",
    "Function",
    "Identifier",
    "Constant",
    "DiagnosticError",
    "DiagnosticOk",
  }
  for index, source in ipairs(dynamic_sources) do
    local name = string.format("%02d", index)
    local accent = color("fg", source, "Normal")
    set("AtlasDynColor" .. name, { fg = accent })
    set("AtlasDynBgColor" .. name, { fg = background, bg = accent })
  end
end

return M
