local M = {}

local state = { bufnr = nil }

local function ensure_buf(opts)
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
    return state.bufnr
  end
  local bufnr = vim.api.nvim_create_buf(false, true)
  state.bufnr = bufnr
  vim.api.nvim_buf_set_name(bufnr, opts.name or "[Translate]")
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = opts.filetype or ""
  return bufnr
end

local function open_right_win(bufnr, opts)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      vim.api.nvim_set_current_win(win)
      return win
    end
  end
  vim.cmd("botright vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, bufnr)
  if type(opts.width) == "number" then
    pcall(vim.api.nvim_win_set_width, win, opts.width)
  end
  return win
end

local function to_lines(result)
  if result == nil then
    return {}
  end

  if type(result) == "string" then
    return vim.split(result, "\n", { plain = true })
  end

  if type(result) == "table" then
    local lines = {}
    for _, v in ipairs(result) do
      if type(v) == "string" then
        table.insert(lines, v)
      elseif type(v) == "table" then
        table.insert(lines, table.concat(vim.tbl_map(tostring, v), " "))
      else
        table.insert(lines, tostring(v))
      end
    end
    return lines
  end

  return { tostring(result) }
end

function M.cmd(result, _pos, opts)
  opts = opts or {}
  local bufnr = ensure_buf(opts)
  open_right_win(bufnr, opts)

  local lines = to_lines(result)

  vim.bo[bufnr].modifiable = true
  if opts.append then
    local last = vim.api.nvim_buf_line_count(bufnr)
    if last > 1 or (last == 1 and (vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or "") ~= "") then
      vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "", "---", "" })
    end
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
  else
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  end
  vim.bo[bufnr].modifiable = false
end

return M
