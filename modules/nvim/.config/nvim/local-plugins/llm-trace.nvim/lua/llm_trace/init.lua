-- Step through an LLM-simulated execution of the Python function under the cursor.
local gemini = require("llm_trace.gemini")

local api = vim.api
local M = {}

M.config = {
  model = "gemini-3.8-flash",
  api_key_env = "GEMINI_API_KEY",
  timeout = 120000,
  -- Larger files only send the target function, without the surrounding module.
  max_context_lines = 1500,
  keys = { next = "n", prev = "p", quit = "q", input = "i" },
}

local ns = api.nvim_create_namespace("llm_trace")
local augroup = "LlmTraceSession"
local state = nil
local pending = false

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "LlmTrace" })
end

local function set_highlights()
  api.nvim_set_hl(0, "LlmTraceCurrentLine", { link = "Visual", default = true })
  api.nvim_set_hl(0, "LlmTraceValue", { link = "Comment", default = true })
  api.nvim_set_hl(0, "LlmTraceCurrentValue", { link = "DiagnosticVirtualTextInfo", default = true })
  api.nvim_set_hl(0, "LlmTraceNote", { link = "DiagnosticVirtualTextWarn", default = true })
  api.nvim_set_hl(0, "LlmTraceLabel", { link = "DiagnosticVirtualTextHint", default = true })
end

local function one_line(s)
  return (tostring(s or ""):gsub("%s*\n%s*", " "))
end

local function contains_yield(node)
  for child in node:iter_children() do
    local t = child:type()
    if t == "yield" then
      return true
    end
    -- A yield inside a nested scope does not make the target a generator.
    if t ~= "function_definition" and t ~= "lambda" and t ~= "class_definition" and contains_yield(child) then
      return true
    end
  end
  return false
end

---@return { name: string, start_line: integer, end_line: integer }?, string?
local function find_function(buf, row, col)
  local ok, parser = pcall(vim.treesitter.get_parser, buf, "python")
  if not ok or not parser then
    return nil, "Python treesitter parser is not installed"
  end
  parser:parse()

  local node = vim.treesitter.get_node({ bufnr = buf, pos = { row, col }, ignore_injections = true })
  while node and node:type() ~= "function_definition" do
    node = node:parent()
  end
  if not node then
    return nil, "cursor is not inside a Python function"
  end

  local first = node:child(0)
  if first and first:type() == "async" then
    return nil, "async functions are not supported yet"
  end
  local body = node:field("body")[1]
  if body and contains_yield(body) then
    return nil, "generators are not supported yet"
  end

  local name_node = node:field("name")[1]
  local srow, _, erow = node:range()
  return {
    name = name_node and vim.treesitter.get_node_text(name_node, buf) or "?",
    start_line = srow + 1,
    end_line = erow + 1,
  }
end

local function current_step()
  return state.steps[state.step]
end

local function format_changes(changes)
  local parts = {}
  for _, c in ipairs(changes or {}) do
    parts[#parts + 1] = string.format("%s = %s", one_line(c.name), one_line(c.value))
  end
  return table.concat(parts, ", ")
end

local function close_float()
  if state.float_win and api.nvim_win_is_valid(state.float_win) then
    api.nvim_win_close(state.float_win, true)
  end
  state.float_win = nil
end

local function open_float()
  if state.float_win and api.nvim_win_is_valid(state.float_win) then
    return
  end
  local t = state.trace
  local keys = M.config.keys
  local lines = { "Path: " .. one_line(t.branch), "", "Fake input:" }
  for _, input in ipairs(t.inputs or {}) do
    lines[#lines + 1] = string.format("  %s = %s", one_line(input.name), one_line(input.value))
  end
  if t.assumptions and #t.assumptions > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Assumed:"
    for _, a in ipairs(t.assumptions) do
      lines[#lines + 1] = "  • " .. one_line(a)
    end
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "Result: " .. one_line(t.result)
  lines[#lines + 1] = string.format("%s/%s step · %s input · %s quit", keys.next, keys.prev, keys.input, keys.quit)

  local win_width = api.nvim_win_get_width(state.win)
  local width = 20
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  width = math.min(width, math.max(20, math.floor(win_width * 0.5)))
  local height = 0
  for _, l in ipairs(lines) do
    height = height + math.max(1, math.ceil(vim.fn.strdisplaywidth(l) / width))
  end

  local fbuf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_lines(fbuf, 0, -1, false, lines)
  vim.bo[fbuf].bufhidden = "wipe"
  state.float_win = api.nvim_open_win(fbuf, false, {
    relative = "win",
    win = state.win,
    anchor = "NE",
    row = 0,
    col = win_width,
    width = width,
    height = math.min(height, api.nvim_win_get_height(state.win) - 2),
    style = "minimal",
    border = "rounded",
    title = " [simulated] ",
    title_pos = "center",
    focusable = false,
    noautocmd = true,
  })
  vim.wo[state.float_win].wrap = true
end

local function render()
  local buf = state.buf
  api.nvim_buf_clear_namespace(buf, ns, 0, -1)

  -- Each visited line shows the values it last assigned and the note from its latest visit, so loops read like a
  -- debugger's locals.
  local changes, notes, visits = {}, {}, {}
  for i = 1, state.step do
    local st = state.steps[i]
    if #st.changes > 0 then
      changes[st.line] = st.changes
    end
    notes[st.line] = st.note
    visits[st.line] = (visits[st.line] or 0) + 1
  end

  local cur = current_step()
  for line in pairs(visits) do
    local is_current = line == cur.line
    local chunks = {}
    local text = format_changes(changes[line])
    if text ~= "" then
      chunks[#chunks + 1] = { "  -- " .. text, is_current and "LlmTraceCurrentValue" or "LlmTraceValue" }
    end
    if notes[line] and notes[line] ~= "" then
      chunks[#chunks + 1] = { "  " .. one_line(notes[line]), is_current and "LlmTraceNote" or "LlmTraceValue" }
    end
    if visits[line] > 1 then
      chunks[#chunks + 1] = { string.format("  (×%d)", visits[line]), "LlmTraceValue" }
    end
    if is_current and state.step == #state.steps then
      chunks[#chunks + 1] = { "  ⟶ " .. one_line(state.trace.result), "LlmTraceNote" }
    end
    if #chunks > 0 then
      api.nvim_buf_set_extmark(buf, ns, line - 1, 0, { virt_text = chunks, virt_text_pos = "eol" })
    end
  end

  -- The label rides on the current line so it is always on screen.
  api.nvim_buf_set_extmark(buf, ns, cur.line - 1, 0, {
    line_hl_group = "LlmTraceCurrentLine",
    virt_text = { { string.format(" [simulated] %d/%d ", state.step, #state.steps), "LlmTraceLabel" } },
    virt_text_pos = "right_align",
  })

  if api.nvim_win_is_valid(state.win) then
    local text = api.nvim_buf_get_lines(buf, cur.line - 1, cur.line, false)[1] or ""
    api.nvim_win_set_cursor(state.win, { cur.line, math.max(0, (text:find("%S") or 1) - 1) })
  end

  if state.show_input then
    open_float()
  else
    close_float()
  end
end

local function go(delta)
  local target = state.step + delta
  if target < 1 or target > #state.steps then
    notify(target < 1 and "at first step" or "at last step: " .. one_line(state.trace.result))
    return
  end
  if state.step == 1 and delta > 0 then
    state.show_input = false
  end
  state.step = target
  render()
end

local function map(lhs, fn, desc)
  local prev = vim.fn.maparg(lhs, "n", false, true)
  if prev.buffer == 1 then
    state.saved_maps[#state.saved_maps + 1] = prev
  end
  state.mapped[#state.mapped + 1] = lhs
  vim.keymap.set("n", lhs, fn, { buffer = state.buf, nowait = true, desc = "LlmTrace: " .. desc })
end

function M.stop()
  if not state then
    return
  end
  close_float()
  local s = state
  state = nil
  pcall(api.nvim_del_augroup_by_name, augroup)
  if api.nvim_buf_is_valid(s.buf) then
    api.nvim_buf_clear_namespace(s.buf, ns, 0, -1)
    for _, lhs in ipairs(s.mapped) do
      pcall(vim.keymap.del, "n", lhs, { buffer = s.buf })
    end
    for _, m in ipairs(s.saved_maps) do
      vim.fn.mapset("n", false, m)
    end
  end
end

---Display a trace (as returned by Gemini) for `func` in `buf`.
function M.show(buf, func, trace)
  M.stop()

  local steps = {}
  for _, st in ipairs(trace.steps or {}) do
    local line = tonumber(st.line)
    if line and line >= func.start_line and line <= func.end_line then
      steps[#steps + 1] = { line = math.floor(line), changes = st.changes or {}, note = st.note }
    end
  end
  if #steps == 0 then
    return notify("trace has no steps inside " .. func.name .. "()", vim.log.levels.ERROR)
  end
  local dropped = #(trace.steps or {}) - #steps
  if dropped > 0 then
    notify(string.format("ignored %d step(s) outside %s()", dropped, func.name), vim.log.levels.WARN)
  end

  local win = api.nvim_get_current_buf() == buf and api.nvim_get_current_win() or vim.fn.bufwinid(buf)
  state = {
    buf = buf,
    win = win,
    func = func,
    trace = trace,
    steps = steps,
    step = 1,
    show_input = true,
    mapped = {},
    saved_maps = {},
  }

  local keys = M.config.keys
  map(keys.next, function()
    go(1)
  end, "next step")
  map(keys.prev, function()
    go(-1)
  end, "previous step")
  map(keys.input, function()
    state.show_input = not state.show_input
    render()
  end, "toggle fake input")
  map(keys.quit, M.stop, "quit")

  local group = api.nvim_create_augroup(augroup, { clear = true })
  api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    buffer = buf,
    callback = function()
      M.stop()
      notify("buffer edited, trace cleared", vim.log.levels.WARN)
    end,
  })
  api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, { group = group, buffer = buf, callback = M.stop })

  render()
end

---Generate and show a trace for the function under the cursor.
---@param branch string? free-form description of the path to take; empty means happy path
function M.trace(branch)
  if pending then
    return notify("a trace is already being generated", vim.log.levels.WARN)
  end
  local buf = api.nvim_get_current_buf()
  if vim.bo[buf].filetype ~= "python" then
    return notify("only Python is supported", vim.log.levels.ERROR)
  end
  local api_key = os.getenv(M.config.api_key_env)
  if not api_key or api_key == "" then
    return notify("$" .. M.config.api_key_env .. " is not set", vim.log.levels.ERROR)
  end

  local cursor = api.nvim_win_get_cursor(0)
  local func, err = find_function(buf, cursor[1] - 1, cursor[2])
  if not func then
    return notify(err, vim.log.levels.ERROR)
  end
  M.stop()

  local lines, first_line = api.nvim_buf_get_lines(buf, 0, -1, false), 1
  if #lines > M.config.max_context_lines then
    lines, first_line = vim.list_slice(lines, func.start_line, func.end_line), func.start_line
  end
  local prompt = gemini.build_prompt({
    filename = vim.fn.fnamemodify(api.nvim_buf_get_name(buf), ":."),
    lines = lines,
    first_line = first_line,
    func_name = func.name,
    start_line = func.start_line,
    end_line = func.end_line,
    branch = branch,
  })

  pending = true
  local tick = api.nvim_buf_get_changedtick(buf)
  notify(string.format("simulating %s() — %s …", func.name, branch ~= "" and branch or "happy path"))
  gemini.request(
    { model = M.config.model, api_key = api_key, timeout = M.config.timeout },
    prompt,
    function(req_err, trace)
      pending = false
      if req_err then
        return notify(req_err, vim.log.levels.ERROR)
      end
      if not api.nvim_buf_is_valid(buf) then
        return
      end
      if api.nvim_buf_get_changedtick(buf) ~= tick then
        return notify("buffer changed while generating, run :LlmTrace again", vim.log.levels.WARN)
      end
      M.show(buf, func, trace)
    end
  )
end

M._find_function = find_function

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  set_highlights()
  api.nvim_create_autocmd("ColorScheme", {
    group = api.nvim_create_augroup("LlmTraceHighlights", { clear = true }),
    callback = set_highlights,
  })
  api.nvim_create_user_command("LlmTrace", function(o)
    M.trace(o.args)
  end, { nargs = "*", desc = "Simulate the function under the cursor (optional: describe the branch)" })
  api.nvim_create_user_command("LlmTraceStop", M.stop, { desc = "Clear the simulated trace" })
end

return M
