-- Gemini client: asks for a simulated execution trace as structured JSON.
local M = {}

local ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent"

local function name_value_list()
  return {
    type = "ARRAY",
    items = {
      type = "OBJECT",
      properties = { name = { type = "STRING" }, value = { type = "STRING" } },
      required = { "name", "value" },
    },
  }
end

local SCHEMA = {
  type = "OBJECT",
  properties = {
    branch = { type = "STRING", description = "One sentence: which path this trace takes." },
    inputs = name_value_list(),
    assumptions = {
      type = "ARRAY",
      items = { type = "STRING" },
      description = "Values assumed for external calls (DB, HTTP, files, clock, other functions).",
    },
    steps = {
      type = "ARRAY",
      items = {
        type = "OBJECT",
        properties = {
          line = { type = "INTEGER" },
          changes = name_value_list(),
          note = { type = "STRING", description = "Short; only for branch decisions, loop exits, returns, raises." },
        },
        required = { "line", "changes" },
      },
    },
    result = { type = "STRING", description = "Return value repr, or the raised exception." },
  },
  required = { "branch", "inputs", "steps", "result" },
}

local SYSTEM = [[
You simulate the execution of ONE Python function so a developer can understand its data flow without running it.

Rules:
- Invent concrete, realistic, internally consistent inputs that drive execution down the requested path.
- Execute the function in your head, statement by statement, exactly like CPython would. Be precise: the values you
  report must be what the code would actually produce for those inputs.
- Emit one step per executed statement inside the target function, in execution order. Loop bodies repeat once per
  iteration. Use the absolute line numbers from the listing (the number before the "|").
- Do not step into other functions. When the target calls something external (other functions, methods, DB, HTTP,
  files, time, randomness), pick a plausible return value, use it, and list it in "assumptions".
- "changes": variables bound or mutated by that statement with their NEW value as a short Python repr
  (truncate long collections with ...). Use attribute/item paths for mutations, e.g. "self.count" or "cfg['retries']".
  Leave it empty when nothing changes.
- "note": only on branch decisions (say which way and why, e.g. "age < 0 -> True"), loop exits, returns and raises.
  Keep it under 60 characters.
- The last step is the return/raise (or the last executed line when the function falls off the end).
]]

local function number_lines(lines, first)
  local out = {}
  for i, line in ipairs(lines) do
    out[i] = string.format("%5d| %s", first + i - 1, line)
  end
  return table.concat(out, "\n")
end

---@param ctx { filename: string, lines: string[], first_line: integer, func_name: string, start_line: integer, end_line: integer, branch: string? }
function M.build_prompt(ctx)
  local branch = ctx.branch and ctx.branch ~= "" and ctx.branch
    or "the happy path (the most common successful execution)"
  return table.concat({
    string.format("File: %s", ctx.filename),
    "```python",
    number_lines(ctx.lines, ctx.first_line),
    "```",
    "",
    string.format("Target function: `%s` (lines %d-%d).", ctx.func_name, ctx.start_line, ctx.end_line),
    string.format("Path to simulate: %s", branch),
    "Only emit steps whose line is within the target function's range.",
  }, "\n")
end

---@param opts { model: string, api_key: string, timeout: integer }
---@param prompt string
---@param cb fun(err: string?, trace: table?)
function M.request(opts, prompt, cb)
  local body = vim.json.encode({
    systemInstruction = { parts = { { text = SYSTEM } } },
    contents = { { role = "user", parts = { { text = prompt } } } },
    generationConfig = {
      temperature = 0.2,
      responseMimeType = "application/json",
      responseSchema = SCHEMA,
    },
  })

  local cmd = {
    "curl",
    "-sS",
    "-X",
    "POST",
    string.format(ENDPOINT, opts.model),
    "-H",
    "Content-Type: application/json",
    "-H",
    "x-goog-api-key: " .. opts.api_key,
    "--data-binary",
    "@-",
  }

  vim.system(cmd, { stdin = body, text = true, timeout = opts.timeout }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        return cb(string.format("curl failed (%d): %s", res.code, vim.trim(res.stderr or "")))
      end
      cb(M.parse_response(res.stdout))
    end)
  end)
end

---@return string? err, table? trace
function M.parse_response(stdout)
  local ok, resp = pcall(vim.json.decode, stdout, { luanil = { object = true, array = true } })
  if not ok or type(resp) ~= "table" then
    return "invalid response from Gemini: " .. tostring(stdout):sub(1, 200)
  end
  if resp.error then
    return "Gemini error: " .. (resp.error.message or vim.inspect(resp.error))
  end
  local text = vim.tbl_get(resp, "candidates", 1, "content", "parts", 1, "text")
  if not text then
    local reason = vim.tbl_get(resp, "candidates", 1, "finishReason")
      or vim.tbl_get(resp, "promptFeedback", "blockReason")
      or "no content"
    return "Gemini returned no trace (" .. reason .. ")"
  end
  local ok_trace, trace = pcall(vim.json.decode, text, { luanil = { object = true, array = true } })
  if not ok_trace or type(trace) ~= "table" or type(trace.steps) ~= "table" then
    return "could not parse trace JSON: " .. text:sub(1, 200)
  end
  return nil, trace
end

return M
