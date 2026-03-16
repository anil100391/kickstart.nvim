local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local conf = require('telescope.config').values

local function get_user_commits()
  local handle = io.popen 'git log --author=anils@altair.com --pretty=format:"%h %s"'
  local result = nil

  if handle then
    result = handle:read '*a'
    handle:close()
  else
    print 'Error: Unable to run git log command.'
    return {}
  end

  local commits = {}
  for line in result:gmatch '[^\r\n]+' do
    table.insert(commits, line)
  end
  return commits
end

local function split_lines(str)
  local t = {}
  for line in str:gmatch '([^\n]*)\n?' do
    table.insert(t, line)
  end
  return t
end

local function get_gitlab_base_url()
  local handle = io.popen 'git config --get remote.origin.url'
  local origin_url = handle:read '*a'
  handle:close()

  origin_url = origin_url:gsub('\n', '') -- trim newline

  -- Convert SSH or HTTPS Git URL to web URL
  if origin_url:match '^git@' then
    -- Convert SSH URL: git@gitlab.com:group/project.git → https://gitlab.com/group/project
    origin_url = origin_url:gsub('git@(.-):(.*)%.git', 'https://%1/%2')
  elseif origin_url:match '^https://' then
    -- Trim .git from the end if present
    origin_url = origin_url:gsub('%.git$', '')
  end

  return origin_url
end

local function draft_email(commit_hash)
  local handle = io.popen('git show -s --format="%H%n%B" ' .. commit_hash)
  local commit_info = handle:read '*a'
  handle:close()

  local lines = split_lines(commit_info)
  local commit_id = lines[1]
  local commit_msg = vim.list_slice(lines, 2)

  local commit_url = get_gitlab_base_url() .. '/-/commit/' .. commit_id

  local email_lines = {
    'stidev@altair.com',
    'inspib2026 integration',
    '',
    'Integrated fix for the following',
    commit_msg[1] .. ': ' .. commit_id,
    commit_url,
  }

  vim.list_extend(email_lines, {
    '',
    'Thanks',
    'Anil',
  })

  vim.cmd 'new'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, email_lines)
end

local function commit_picker()
  local commits = get_user_commits()
  pickers
    .new({}, {
      prompt_title = 'Select a Commit',
      finder = finders.new_table {
        results = commits,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()[1]
          local commit_hash = selection:match '^(%w+)'
          draft_email(commit_hash)
        end)
        return true
      end,
    })
    :find()
end

return {
  show_my_commits = commit_picker,
}
