-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information

local M = {}

M.floating_terminal = {
  buf = nil,
  win = nil,
  initialized_buffer_to_terminal = false,
}

M.create_floating_terminal = function()
  -- Get the current Neovim UI size
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.floor(ui.width * 0.6) -- 60% of the UI width
  local height = math.floor(ui.height * 0.4) -- 40% of the UI height

  -- Calculate the center position
  local row = math.floor((ui.height - height) / 2)
  local col = math.floor((ui.width - width) / 2)

  if not M.floating_terminal.buf or not vim.api.nvim_buf_is_valid(M.floating_terminal.buf) then
    -- Create a new buffer (hidden, scratch)
    M.floating_terminal.buf = vim.api.nvim_create_buf(false, true)
  end

  -- Window options
  local opts = {
    style = 'minimal',
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    border = 'rounded', -- You can change this to "single", "double", "solid", etc.
  }

  -- create floating window
  M.floating_terminal.win = vim.api.nvim_open_win(M.floating_terminal.buf, true, opts)

  if not M.floating_terminal.initialized_buffer_to_terminal then
    vim.fn.termopen(vim.o.shell)
    M.floating_terminal.initialized_buffer_to_terminal = true
  end

  -- Adjust terminal settings
  vim.api.nvim_command 'startinsert' -- Enter insert mode automatically

  -- Keymap to close the floating window
  vim.api.nvim_buf_set_keymap(M.floating_terminal.buf, 'n', 'q', ':close<CR>', { noremap = true, silent = true })
end

-- Function to hide the floating terminal (without closing the buffer)
M.hide_floating_terminal = function()
  if M.floating_terminal.win and vim.api.nvim_win_is_valid(M.floating_terminal.win) then
    vim.api.nvim_win_hide(M.floating_terminal.win)
    M.floating_terminal.win = nil
  end
end

-- Function to show the floating terminal again
M.show_floating_terminal = function()
  if not (M.floating_terminal.win and vim.api.nvim_win_is_valid(M.floating_terminal.win)) then
    M.create_floating_terminal()
  end
end

M.toggle_floating_terminal = function()
  if M.floating_terminal.win and vim.api.nvim_win_is_valid(M.floating_terminal.win) then
    M.hide_floating_terminal()
  else
    M.show_floating_terminal()
  end
end

return M
