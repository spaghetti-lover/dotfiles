-- Toggle .jsonl buffers between one record per line and pretty-printed JSON.
-- The file on disk always stays one record per line.
vim.treesitter.language.register("json", "jsonl")

local function jq(args, lines)
  local result = vim.system(vim.list_extend({ "jq" }, args), { stdin = table.concat(lines, "\n") }):wait()
  if result.code ~= 0 then
    return nil, result.stderr
  end
  return vim.split(result.stdout, "\n", { trimempty = true })
end

-- In jq's pretty output each record starts at column 0 with anything but a closing bracket.
local function record_starts(lines)
  local starts = {}
  for i, line in ipairs(lines) do
    if line:match("^[^%s%]}]") then
      table.insert(starts, i)
    end
  end
  return starts
end

local function set_lines_without_undo(buf, lines)
  local modified = vim.bo[buf].modified
  local undolevels = vim.bo[buf].undolevels
  vim.bo[buf].undolevels = -1
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].undolevels = undolevels
  vim.bo[buf].modified = modified
end

-- Compact lines from before the pretty view, restored on toggle back if nothing was edited.
local originals = {}

local function toggle_pretty(buf)
  local pretty = vim.b[buf].jsonl_pretty
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local original = originals[buf]
  originals[buf] = nil
  local out, err
  if pretty and original and original.tick == vim.b[buf].changedtick then
    out = original.lines
  else
    out, err = jq(pretty and { "-c", "." } or { "." }, lines)
  end
  if not out then
    vim.notify("jsonl: jq failed:\n" .. err, vim.log.levels.ERROR)
    return
  end

  -- Keep the cursor on the same record across the switch.
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local record = row
  if pretty then
    record = #vim.tbl_filter(function(start)
      return start <= row
    end, record_starts(lines))
  end

  set_lines_without_undo(buf, out)
  vim.b[buf].jsonl_pretty = not pretty
  if not pretty then
    originals[buf] = { lines = lines, tick = vim.b[buf].changedtick }
  end

  local target = pretty and record or (record_starts(out)[record] or 1)
  vim.api.nvim_win_set_cursor(0, { math.max(target, 1), 0 })
  vim.cmd("normal! zz")
end

local group = vim.api.nvim_create_augroup("jsonl_pretty", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "jsonl",
  callback = function(ev)
    vim.keymap.set("n", "<leader>uj", function()
      toggle_pretty(ev.buf)
    end, { buffer = ev.buf, desc = "Toggle JSONL Pretty View" })

    vim.api.nvim_create_autocmd("BufWriteCmd", {
      group = group,
      buffer = ev.buf,
      callback = function(write_ev)
        local lines = vim.api.nvim_buf_get_lines(write_ev.buf, 0, -1, false)
        if vim.b[write_ev.buf].jsonl_pretty then
          local compact, err = jq({ "-c", "." }, lines)
          if not compact then
            vim.notify("jsonl: not written, invalid JSON:\n" .. err, vim.log.levels.ERROR)
            return
          end
          lines = compact
        end
        vim.fn.writefile(lines, write_ev.match)
        vim.bo[write_ev.buf].modified = false
      end,
    })
  end,
})
