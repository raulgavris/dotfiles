-- VS Code-style Source Control panel for the left sidebar
-- Shows branch info, action buttons, staged/unstaged/untracked file sections

local M = {}
local ns = vim.api.nvim_create_namespace("git_panel")
local panel_buf = nil
local file_map = {}   -- line_nr → { file, section }
local action_map = {} -- line_nr → function
local commit_map = {} -- line_nr → commit hash

-- Nerd Font icons (lazy-init since vim.fn isn't available at parse time in all contexts)
local I
local function icons()
  if I then return I end
  local c = vim.fn.nr2char
  I = {
    branch    = c(0xE725),  -- nf-dev-git_branch
    commit    = c(0xF417),  -- nf-oct-git_commit
    commit_all= c(0xF0843), -- nf-md-check_all
    amend     = c(0xF0900), -- nf-md-pencil_outline
    push      = c(0xF0CD8), -- nf-md-cloud_upload_outline
    pull      = c(0xF0CD6), -- nf-md-cloud_download_outline
    fetch     = c(0xF04E6), -- nf-md-sync
    stash     = c(0xF01BC), -- nf-md-package_down
    stash_pop = c(0xF01BD), -- nf-md-package_up
    generate  = c(0xF0D0),  -- nf-fa-magic
    merge     = c(0xF0BF2), -- nf-md-source_merge
  }
  return I
end

local function find_editor_win()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) then
      local cfg = vim.api.nvim_win_get_config(win)
      local b = vim.api.nvim_win_get_buf(win)
      if (not cfg.relative or cfg.relative == "")
        and vim.bo[b].buftype == "" then
        return win
      end
    end
  end
end

-- Track current side-by-side diff buffers for joint close
local diff_bufs = {}

-- Close any existing diff views (side-by-side + gitsigns)
local function close_diff()
  -- Close side-by-side diff buffers/windows
  for _, b in ipairs(diff_bufs) do
    if vim.api.nvim_buf_is_valid(b) then
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_buf(w) == b then
          pcall(vim.api.nvim_win_close, w, true)
        end
      end
      pcall(vim.api.nvim_buf_delete, b, { force = true })
    end
  end
  diff_bufs = {}
  -- Close gitsigns diff windows
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(w) then
      local b = vim.api.nvim_win_get_buf(w)
      local name = vim.api.nvim_buf_get_name(b)
      if name:match("^gitsigns://") then
        pcall(vim.api.nvim_win_close, w, true)
        pcall(vim.api.nvim_buf_delete, b, { force = true })
      end
    end
  end
  pcall(vim.cmd, "diffoff!")
end

-- Global handler for diff view close button
function _G.CloseDiffView(_minwid, _clicks, button, _mods)
  if button == "l" then
    vim.schedule(close_diff)
  end
end

-- Spinning progress notification — single notification, replaced in-place
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_counter = 0
local function start_spinner(msg)
  spinner_counter = spinner_counter + 1
  local notify_id = "git_panel_spinner_" .. spinner_counter
  local tick = 0
  local timer = vim.uv.new_timer()
  timer:start(0, 200, vim.schedule_wrap(function()
    tick = tick + 1
    local seconds = math.floor(tick / 5)
    local frame = spinner_frames[(tick % #spinner_frames) + 1]
    local elapsed = seconds > 0 and string.format(" (%ds)", seconds) or ""
    vim.notify(frame .. " " .. msg .. elapsed, vim.log.levels.INFO, { id = notify_id, replace = notify_id })
  end))
  return timer
end

-- ── Git actions (exposed on M for menu/keymap access) ──

local function do_commit()
  vim.ui.input({ prompt = "Commit message: " }, function(msg)
    if not msg or msg == "" then return end
    local spinner = start_spinner("Committing")
    vim.fn.jobstart({ "git", "commit", "-m", msg }, {
      stdout_buffered = true, stderr_buffered = true,
      on_exit = function(_, code)
        vim.schedule(function()
          spinner:stop(); spinner:close()
          if code == 0 then
            vim.notify("Committed: " .. msg, vim.log.levels.INFO)
          else
            vim.notify("Commit failed (nothing staged?)", vim.log.levels.WARN)
          end
          M.refresh()
        end)
      end,
    })
  end)
end

local function do_commit_all()
  vim.ui.input({ prompt = "Commit all — message: " }, function(msg)
    if not msg or msg == "" then return end
    local spinner = start_spinner("Staging & committing")
    vim.fn.system({ "git", "add", "-A" })
    vim.fn.jobstart({ "git", "commit", "-m", msg }, {
      stdout_buffered = true, stderr_buffered = true,
      on_exit = function(_, code)
        vim.schedule(function()
          spinner:stop(); spinner:close()
          if code == 0 then
            vim.notify("Committed all: " .. msg, vim.log.levels.INFO)
          else
            vim.notify("Commit failed", vim.log.levels.WARN)
          end
          M.refresh()
        end)
      end,
    })
  end)
end

local function do_amend()
  local spinner = start_spinner("Amending")
  vim.fn.jobstart({ "git", "commit", "--amend", "--no-edit" }, {
    stdout_buffered = true, stderr_buffered = true,
    on_exit = function(_, code)
      vim.schedule(function()
        spinner:stop(); spinner:close()
        if code == 0 then
          vim.notify("Amended last commit", vim.log.levels.INFO)
        else
          vim.notify("Amend failed", vim.log.levels.WARN)
        end
        M.refresh()
      end)
    end,
  })
end

local function do_push()
  local spinner = start_spinner("Pushing")
  vim.fn.jobstart({ "git", "push" }, {
    stdout_buffered = true, stderr_buffered = true,
    on_exit = function(_, code)
      vim.schedule(function()
        spinner:stop(); spinner:close()
        vim.notify(code == 0 and "Pushed" or "Push failed", code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
        M.refresh()
      end)
    end,
  })
end

local function do_pull()
  local spinner = start_spinner("Pulling")
  vim.fn.jobstart({ "git", "pull", "--rebase" }, {
    stdout_buffered = true, stderr_buffered = true,
    on_exit = function(_, code)
      vim.schedule(function()
        spinner:stop(); spinner:close()
        vim.notify(code == 0 and "Pulled" or "Pull failed (conflicts?)", code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
        M.refresh()
      end)
    end,
  })
end

local function do_fetch()
  local spinner = start_spinner("Fetching")
  vim.fn.jobstart({ "git", "fetch", "--all", "--prune" }, {
    stdout_buffered = true, stderr_buffered = true,
    on_exit = function(_, code)
      vim.schedule(function()
        spinner:stop(); spinner:close()
        vim.notify(code == 0 and "Fetched" or "Fetch failed", code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR)
        M.refresh()
      end)
    end,
  })
end

local function do_stash()
  local spinner = start_spinner("Stashing")
  vim.fn.jobstart({ "git", "stash" }, {
    stdout_buffered = true, stderr_buffered = true,
    on_exit = function(_, code)
      vim.schedule(function()
        spinner:stop(); spinner:close()
        vim.notify(code == 0 and "Stashed" or "Nothing to stash", code == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
        M.refresh()
      end)
    end,
  })
end

local function do_stash_pop()
  local spinner = start_spinner("Popping stash")
  vim.fn.jobstart({ "git", "stash", "pop" }, {
    stdout_buffered = true, stderr_buffered = true,
    on_exit = function(_, code)
      vim.schedule(function()
        spinner:stop(); spinner:close()
        vim.notify(code == 0 and "Stash popped" or "No stash to pop", code == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
        M.refresh()
      end)
    end,
  })
end

local function do_commit_generated()
  -- Check for merge/cherry-pick/revert context — use git's prepared message directly
  local git_dir = vim.fn.system("git rev-parse --git-dir 2>/dev/null"):gsub("%s+$", "")
  if git_dir ~= "" then
    for _, msg_file in ipairs({ "MERGE_MSG", "SQUASH_MSG" }) do
      local path = git_dir .. "/" .. msg_file
      if vim.fn.filereadable(path) == 1 then
        local raw = vim.fn.readfile(path)
        -- Strip comment lines (# ...) that git adds
        local clean = {}
        for _, line in ipairs(raw) do
          if not line:match("^#") then table.insert(clean, line) end
        end
        local msg = table.concat(clean, "\n"):gsub("%s+$", "")
        if msg ~= "" then
          vim.ui.input({ prompt = "Commit message: ", default = msg }, function(final)
            if not final or final == "" then return end
            local sp = start_spinner("Committing")
            vim.fn.jobstart({ "git", "commit", "-m", final }, {
              stdout_buffered = true, stderr_buffered = true,
              on_exit = function(_, c)
                vim.schedule(function()
                  sp:stop(); sp:close()
                  if c == 0 then
                    vim.notify("Committed: " .. final, vim.log.levels.INFO)
                  else
                    vim.notify("Commit failed", vim.log.levels.WARN)
                  end
                  M.refresh()
                end)
              end,
            })
          end)
          return
        end
      end
    end
  end

  -- Get staged diff; fall back to unstaged if nothing is staged
  local diff = vim.fn.system("git diff --cached")
  if vim.v.shell_error ~= 0 or diff:gsub("%s+", "") == "" then
    diff = vim.fn.system("git diff")
  end
  if diff:gsub("%s+", "") == "" then
    vim.notify("No changes to generate a message for", vim.log.levels.WARN)
    return
  end

  if vim.fn.executable("claude") ~= 1 then
    vim.notify("Claude CLI not found — install it for AI commit messages", vim.log.levels.ERROR)
    return
  end

  local spinner = start_spinner("AI generating commit message")

  -- Build prompt — include commitlint config if present in the project
  local prompt = "Generate a single concise git commit message for this diff. "
  local git_root = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null"):gsub("%s+$", "")
  local commitlint_config = nil
  if git_root ~= "" then
    for _, name in ipairs({ "commitlint.config.js", "commitlint.config.ts", "commitlint.config.cjs", ".commitlintrc.js", ".commitlintrc.json", ".commitlintrc.yml" }) do
      local path = git_root .. "/" .. name
      if vim.fn.filereadable(path) == 1 then
        commitlint_config = table.concat(vim.fn.readfile(path), "\n")
        break
      end
    end
  end
  if commitlint_config then
    prompt = prompt .. "Follow the commitlint rules from this config EXACTLY:\n" .. commitlint_config .. "\n\n"
  else
    prompt = prompt .. "Use conventional commit format (type: description). "
  end
  prompt = prompt .. "Output ONLY the message text, nothing else. No quotes, no markdown, no explanation."
  local job_id = vim.fn.jobstart({ "claude", "-p", "--model", "haiku", prompt }, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, code, _)
      vim.schedule(function()
        spinner:stop()
        spinner:close()
        if code ~= 0 then
          vim.notify("Failed to generate commit message", vim.log.levels.ERROR)
          return
        end
      end)
    end,
    on_stdout = function(_, data)
      vim.schedule(function()
        local msg = table.concat(data, ""):gsub("^%s+", ""):gsub("%s+$", "")
        -- Strip markdown fences/backticks if present
        msg = msg:gsub("^```%w*\n?", ""):gsub("\n?```$", ""):gsub("^`", ""):gsub("`$", "")
        if msg == "" then
          vim.notify("Empty response from Claude", vim.log.levels.WARN)
          return
        end
        vim.ui.input({ prompt = "Commit message: ", default = msg }, function(final)
          if not final or final == "" then return end
          vim.fn.jobstart({ "git", "commit", "-m", final }, {
            stdout_buffered = true, stderr_buffered = true,
            on_exit = function(_, c)
              vim.schedule(function()
                if c == 0 then
                  vim.notify("Committed: " .. final, vim.log.levels.INFO)
                else
                  vim.notify("Commit failed (nothing staged?)", vim.log.levels.WARN)
                end
                M.refresh()
              end)
            end,
          })
        end)
      end)
    end,
  })
  if job_id > 0 then
    vim.fn.chansend(job_id, diff)
    vim.fn.chanclose(job_id, "stdin")
  end
end

-- Resolve all conflicted files with AI in a single job, then review one by one
local function resolve_conflicts_with_ai(files)
  local results = {}
  local spinner = start_spinner(string.format("AI resolving %d file(s)", #files))

  local prompt = "You are a merge conflict resolver. You receive multiple files with git merge conflict markers "
    .. "(<<<<<<< ======= >>>>>>>). Resolve all conflicts by choosing the best combination of both sides.\n\n"
    .. "Output in this EXACT format for EACH file (in the same order as input):\n"
    .. "=== FILE: <filepath> ===\n"
    .. "```\n<resolved file content>\n```\n"
    .. "CHANGES:\n- <one bullet per conflict explaining what you kept and why>\n\n"
    .. "Process EVERY file. Do NOT skip any file. Do NOT add commentary outside this format."

  local function on_all_done()
    spinner:stop(); spinner:close()

    -- Present results one by one for review
    local idx = 0
    local accepted = 0
    local skipped = 0

    local function review_next()
      idx = idx + 1
      if idx > #files then
        local msg
        if skipped == 0 then
          msg = string.format("All %d conflict(s) resolved!", accepted)
        elseif accepted == 0 then
          msg = string.format("Skipped all %d conflict(s)", skipped)
        else
          msg = string.format("Resolved %d, skipped %d conflict(s)", accepted, skipped)
        end
        vim.notify(msg, skipped == 0 and vim.log.levels.INFO or vim.log.levels.WARN)
        M.refresh()
        return
      end

      local file = files[idx]
      local res = results[file]

      if not res or res.error then
        vim.notify("AI resolution failed for " .. file .. " — skipping", vim.log.levels.ERROR)
        skipped = skipped + 1
        review_next()
        return
      end

      -- Show side-by-side diff: original (conflicted) vs resolved
      local win = find_editor_win()
      if win then vim.api.nvim_set_current_win(win) end

      vim.cmd("edit " .. vim.fn.fnameescape(file))
      local orig_win = vim.api.nvim_get_current_win()
      vim.cmd("diffthis")

      vim.cmd("vertical rightbelow new")
      local resolved_buf = vim.api.nvim_get_current_buf()
      local resolved_win = vim.api.nvim_get_current_win()
      vim.api.nvim_buf_set_lines(resolved_buf, 0, -1, false, res.rlines)
      vim.bo[resolved_buf].buftype = "nofile"
      vim.bo[resolved_buf].bufhidden = "wipe"
      vim.bo[resolved_buf].swapfile = false
      vim.bo[resolved_buf].modifiable = false
      local ft = vim.filetype.match({ filename = file }) or ""
      if ft ~= "" then vim.bo[resolved_buf].filetype = ft end
      vim.api.nvim_buf_set_name(resolved_buf, "AI Resolution: " .. vim.fn.fnamemodify(file, ":t"))
      vim.cmd("diffthis")

      -- Build float content
      local explanation_lines = {}
      table.insert(explanation_lines, string.format("AI Resolution (%d/%d): %s", idx, #files, vim.fn.fnamemodify(file, ":t")))
      table.insert(explanation_lines, string.rep("─", 40))
      if res.explanation ~= "" then
        for _, el in ipairs(vim.split(res.explanation, "\n", { plain = true })) do
          table.insert(explanation_lines, el)
        end
      else
        table.insert(explanation_lines, "No explanation provided")
      end
      table.insert(explanation_lines, "")
      table.insert(explanation_lines, string.rep("─", 40))
      table.insert(explanation_lines, "[a] Accept & stage    [s] Skip    [q] Skip")

      local float_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, explanation_lines)
      vim.bo[float_buf].modifiable = false
      vim.bo[float_buf].bufhidden = "wipe"

      local width = math.min(80, math.floor(vim.o.columns * 0.7))
      local height = 0
      for _, l in ipairs(explanation_lines) do
        height = height + math.max(1, math.ceil(vim.fn.strdisplaywidth(l) / width))
      end
      height = math.min(height, math.floor(vim.o.lines * 0.6))

      local float_win = vim.api.nvim_open_win(float_buf, true, {
        relative = "editor",
        row = math.floor((vim.o.lines - height) / 2),
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        title = string.format(" AI Merge Review (%d/%d) ", idx, #files),
        title_pos = "center",
      })
      vim.wo[float_win].wrap = true
      vim.wo[float_win].linebreak = true

      local float_ns = vim.api.nvim_create_namespace("git_panel_float")
      pcall(vim.api.nvim_buf_add_highlight, float_buf, float_ns, "Title", 0, 0, -1)
      pcall(vim.api.nvim_buf_add_highlight, float_buf, float_ns, "WinBarNC", 1, 0, -1)
      pcall(vim.api.nvim_buf_add_highlight, float_buf, float_ns, "WinBarNC", #explanation_lines - 2, 0, -1)
      pcall(vim.api.nvim_buf_add_highlight, float_buf, float_ns, "Special", #explanation_lines - 1, 0, -1)

      local decided = false
      local function decide(accept)
        if decided then return end
        decided = true

        pcall(function()
          if vim.api.nvim_win_is_valid(float_win) then vim.api.nvim_win_close(float_win, true) end
        end)
        pcall(function()
          if vim.api.nvim_buf_is_valid(float_buf) then vim.api.nvim_buf_delete(float_buf, { force = true }) end
        end)
        pcall(function()
          if vim.api.nvim_win_is_valid(orig_win) then
            vim.api.nvim_set_current_win(orig_win)
            vim.cmd("diffoff")
          end
        end)
        pcall(function()
          if vim.api.nvim_win_is_valid(resolved_win) then vim.api.nvim_win_close(resolved_win, true) end
        end)
        pcall(function()
          if vim.api.nvim_buf_is_valid(resolved_buf) then vim.api.nvim_buf_delete(resolved_buf, { force = true }) end
        end)

        if accept then
          vim.fn.writefile(res.rlines, file)
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf):match(vim.pesc(file) .. "$") then
              vim.api.nvim_buf_call(buf, function() vim.cmd("edit!") end)
              break
            end
          end
          vim.fn.system({ "git", "add", "--", file })
          accepted = accepted + 1
          vim.notify("Resolved & staged: " .. file, vim.log.levels.INFO)
        else
          skipped = skipped + 1
          vim.notify("Skipped: " .. file, vim.log.levels.INFO)
        end
        review_next()
      end

      local kopts = { buffer = float_buf, nowait = true, silent = true }
      vim.keymap.set("n", "a", function() decide(true) end, kopts)
      vim.keymap.set("n", "<cr>", function() decide(true) end, kopts)
      vim.keymap.set("n", "s", function() decide(false) end, kopts)
      vim.keymap.set("n", "q", function() decide(false) end, kopts)
      vim.keymap.set("n", "<esc>", function() decide(false) end, kopts)
    end

    review_next()
  end

  -- Build combined input with all conflicted files
  local input_parts = {}
  for _, file in ipairs(files) do
    local content = table.concat(vim.fn.readfile(file), "\n")
    table.insert(input_parts, "=== FILE: " .. file .. " ===\n" .. content)
  end
  local full_input = table.concat(input_parts, "\n\n")

  -- Single Claude job for all files
  local output_lines = {}
  local stderr_lines = {}
  local job_id = vim.fn.jobstart({ "claude", "-p", "--model", "haiku" }, {
    stdout_buffered = true, stderr_buffered = true,
    on_stdout = function(_, data) output_lines = data end,
    on_stderr = function(_, data) stderr_lines = data end,
    on_exit = function(_, code)
      vim.schedule(function()
        if code ~= 0 then
          spinner:stop(); spinner:close()
          local err = table.concat(stderr_lines or {}, "\n"):gsub("%s+$", "")
          vim.notify("AI merge resolution failed" .. (err ~= "" and (": " .. err) or ""), vim.log.levels.ERROR)
          return
        end

        -- Parse per-file results from single response
        local raw_output = table.concat(output_lines, "\n")
        for _, file in ipairs(files) do
          local marker = "=== FILE: " .. file .. " ==="
          local section_start = raw_output:find(marker, 1, true)
          if section_start then
            local after = raw_output:sub(section_start + #marker)
            local fence_start = after:find("```[%w]*\n")
            local fence_end = after:find("\n```", (fence_start or 0) + 3)
            local resolved, explanation = nil, ""
            if fence_start and fence_end and fence_end > fence_start then
              local cs = after:find("\n", fence_start) + 1
              resolved = after:sub(cs, fence_end - 1)
              local after_fence = after:sub(fence_end + 4)
              local next_file = after_fence:find("=== FILE:", 1, true)
              local changes_text = next_file and after_fence:sub(1, next_file - 1) or after_fence
              explanation = changes_text:gsub("^%s*\n*", ""):gsub("%s+$", "")
              if explanation ~= "" then
                explanation = explanation:gsub("^CHANGES:%s*\n?", "")
              end
            end
            if resolved and resolved:gsub("%s+", "") ~= "" then
              results[file] = {
                resolved = resolved,
                rlines = vim.split(resolved, "\n", { plain = true }),
                explanation = explanation,
              }
            else
              results[file] = { error = true }
            end
          else
            results[file] = { error = true }
          end
        end

        on_all_done()
      end)
    end,
  })
  if job_id > 0 then
    vim.fn.chansend(job_id, prompt .. "\n\n" .. full_input)
    vim.fn.chanclose(job_id, "stdin")
  end
end

local function do_ai_merge()
  if vim.fn.executable("claude") ~= 1 then
    vim.notify("Claude CLI not found — install it for AI merge", vim.log.levels.ERROR)
    return
  end

  -- Check if there are already unresolved conflicts
  local conflicts = vim.fn.systemlist("git diff --name-only --diff-filter=U 2>/dev/null")
  if #conflicts > 0 and conflicts[1] ~= "" then
    -- Conflicts already exist — offer to resolve them
    vim.ui.select({ "Resolve with AI", "Cancel" }, {
      prompt = #conflicts .. " conflicted file(s) — resolve with AI?",
    }, function(choice)
      if choice ~= "Resolve with AI" then return end
      resolve_conflicts_with_ai(conflicts)
    end)
    return
  end

  -- No conflicts — pick a branch to merge
  local branches_raw = vim.fn.systemlist("git branch -a --no-merged 2>/dev/null")
  local branches = {}
  for _, b in ipairs(branches_raw) do
    local name = b:gsub("^%s+", ""):gsub("^%*%s*", "")
    if name ~= "" and not name:match("HEAD") then
      table.insert(branches, name)
    end
  end

  if #branches == 0 then
    vim.notify("No unmerged branches found", vim.log.levels.WARN)
    return
  end

  vim.ui.select(branches, { prompt = "Merge branch:" }, function(branch)
    if not branch then return end
    vim.notify("Merging " .. branch .. "...", vim.log.levels.INFO)
    vim.fn.jobstart({ "git", "merge", branch }, {
      stdout_buffered = true, stderr_buffered = true,
      on_exit = function(_, code)
        vim.schedule(function()
          if code == 0 then
            vim.notify("Merged " .. branch .. " (no conflicts)", vim.log.levels.INFO)
            M.refresh()
            return
          end
          -- Check if there are now conflicts to resolve
          local new_conflicts = vim.fn.systemlist("git diff --name-only --diff-filter=U 2>/dev/null")
          if #new_conflicts > 0 and new_conflicts[1] ~= "" then
            vim.ui.select({ "Resolve with AI", "Abort merge" }, {
              prompt = #new_conflicts .. " conflict(s) after merge — resolve with AI?",
            }, function(choice)
              if choice == "Resolve with AI" then
                resolve_conflicts_with_ai(new_conflicts)
              elseif choice == "Abort merge" then
                vim.fn.system("git merge --abort")
                vim.notify("Merge aborted", vim.log.levels.INFO)
                M.refresh()
              end
            end)
          else
            vim.notify("Merge failed", vim.log.levels.ERROR)
            M.refresh()
          end
        end)
      end,
    })
  end)
end

-- Public API for menu/keymaps
M.commit     = do_commit
M.commit_all = do_commit_all
M.amend      = do_amend
M.push       = do_push
M.pull       = do_pull
M.fetch      = do_fetch
M.stash      = do_stash
M.stash_pop  = do_stash_pop
M.commit_generated = do_commit_generated
M.ai_merge   = do_ai_merge

-- ── Render ──

local refreshing = false
local refresh_version = 0

function M.refresh()
  if not panel_buf or not vim.api.nvim_buf_is_valid(panel_buf) then return end
  if refreshing then return end
  refreshing = true
  refresh_version = refresh_version + 1
  local my_version = refresh_version

  -- Branch info (synchronous — instant for local git)
  local branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("%s+$", "")
  if branch == "" then branch = "detached" end
  local sync = ""
  local counts = vim.fn.system("git rev-list --left-right --count HEAD...@{u} 2>/dev/null"):gsub("%s+$", "")
  if vim.v.shell_error == 0 and counts ~= "" then
    local a, b = counts:match("(%d+)%s+(%d+)")
    if a and b then sync = "  ↑" .. a .. " ↓" .. b end
  end

  -- Collect both git status and graph, write buffer once
  local status_data = nil
  local graph_data = nil
  local results_pending = 2

  local function on_both_done()
    results_pending = results_pending - 1
    if results_pending > 0 then return end

    vim.schedule(function()
      refreshing = false
      -- Stale — a newer refresh was requested while we waited
      if my_version ~= refresh_version then return end
      if not panel_buf or not vim.api.nvim_buf_is_valid(panel_buf) then return end

      local lines, hls = {}, {}
      file_map = {}
      action_map = {}
      commit_map = {}

      local ic = icons()

      -- Branch line
      table.insert(lines, "  " .. ic.branch .. " " .. branch .. sync)
      table.insert(hls, { #lines, "Function" })

      -- Separator
      table.insert(lines, "  " .. string.rep("─", 30))
      table.insert(hls, { #lines, "WinBarNC" })

      -- Action buttons (icon + label, shortcut right-aligned)
      local actions = {
        { icon = ic.commit,     label = "Commit",      key = "c", fn = do_commit },
        { icon = ic.generate,   label = "AI Commit",   key = "g", fn = do_commit_generated },
        { icon = ic.commit_all, label = "Commit All",  key = "C", fn = do_commit_all },
        { icon = ic.amend,      label = "Amend",       key = "a", fn = do_amend },
        { icon = ic.push,       label = "Push",        key = "p", fn = do_push },
        { icon = ic.pull,       label = "Pull",        key = "P", fn = do_pull },
        { icon = ic.fetch,      label = "Fetch",       key = "f", fn = do_fetch },
        { icon = ic.stash,      label = "Stash",       key = "z", fn = do_stash },
        { icon = ic.stash_pop,  label = "Stash Pop",   key = "Z", fn = do_stash_pop },
        { icon = ic.merge,     label = "AI Merge",    key = "m", fn = do_ai_merge },
      }
      for _, act in ipairs(actions) do
        local text = "  " .. act.icon .. " " .. act.label
        local pad = math.max(1, 30 - vim.fn.strdisplaywidth(text) - #act.key)
        table.insert(lines, text .. string.rep(" ", pad) .. act.key)
        action_map[#lines] = act.fn
        table.insert(hls, { #lines, "Special" })
      end

      -- Separator
      table.insert(lines, "  " .. string.rep("─", 30))
      table.insert(hls, { #lines, "WinBarNC" })

      -- Parse file status
      local staged, unstaged, untracked, conflicts = {}, {}, {}, {}
      if status_data then
        for _, line in ipairs(status_data) do
          if line ~= "" then
            local x, y = line:sub(1, 1), line:sub(2, 2)
            local raw = line:sub(4)
            local file = raw:match("^.+ -> (.+)$") or raw
            local xy = x .. y
            if x == "U" or y == "U" or xy == "AA" or xy == "DD" then
              table.insert(conflicts, { st = xy, file = file })
            elseif x == "?" then
              table.insert(untracked, { st = "?", file = file })
            else
              if x ~= " " then table.insert(staged, { st = x, file = file }) end
              if y ~= " " then table.insert(unstaged, { st = y, file = file }) end
            end
          end
        end
      end

      -- File sections
      local function section(title, items, hl, hints)
        if #items == 0 then return end
        table.insert(lines, "")
        table.insert(lines, title .. " (" .. #items .. ")")
        table.insert(hls, { #lines, "Title" })
        if hints then
          table.insert(lines, "  " .. hints)
          table.insert(hls, { #lines, "Comment" })
        end
        for _, item in ipairs(items) do
          table.insert(lines, "  " .. item.st .. "  " .. item.file)
          file_map[#lines] = { file = item.file, section = title }
          table.insert(hls, { #lines, hl })
        end
      end

      if #conflicts > 0 then
        table.insert(lines, "")
        table.insert(lines, "Merge Conflicts (" .. #conflicts .. ")")
        table.insert(hls, { #lines, "DiagnosticError" })
        table.insert(lines, "  i=incoming e=current D=diff")
        table.insert(hls, { #lines, "Comment" })
        for _, item in ipairs(conflicts) do
          table.insert(lines, "  " .. item.st .. "  " .. item.file)
          file_map[#lines] = { file = item.file, section = "Merge Conflicts" }
          table.insert(hls, { #lines, "DiagnosticError" })
        end
      end
      section("Staged Changes", staged, "DiffAdd", "u=unstage D=diff")
      section("Changes", unstaged, "DiffChange", "s=stage d=discard D=diff")
      section("Untracked", untracked, "Comment", "s=stage d=delete")

      if #conflicts == 0 and #staged == 0 and #unstaged == 0 and #untracked == 0 then
        table.insert(lines, "")
        table.insert(lines, "  No changes")
        table.insert(hls, { #lines, "Comment" })
      end

      -- Git graph
      if graph_data then
        table.insert(lines, "")
        table.insert(lines, "  " .. string.rep("─", 30))
        table.insert(hls, { #lines, "WinBarNC" })
        table.insert(lines, "")
        table.insert(lines, "Graph")
        table.insert(hls, { #lines, "Title" })

        for _, raw in ipairs(graph_data) do
          if raw ~= "" then
            table.insert(lines, " " .. raw)
            local ln = #lines
            local hash = raw:match("[%*|/\\%s]-[%*]%s+(%x%x%x%x%x%x%x+)")
            if hash then
              commit_map[ln] = hash
            end
            if raw:match("%*") and hash then
              table.insert(hls, { ln, "Keyword" })
            elseif raw:match("[|/\\]") then
              table.insert(hls, { ln, "Comment" })
            end
          end
        end
      end

      -- Single buffer write
      local cursor = nil
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == panel_buf then
          cursor = vim.api.nvim_win_get_cursor(win)
          break
        end
      end

      vim.bo[panel_buf].modifiable = true
      vim.api.nvim_buf_set_lines(panel_buf, 0, -1, false, lines)
      vim.bo[panel_buf].modifiable = false

      vim.api.nvim_buf_clear_namespace(panel_buf, ns, 0, -1)
      for _, h in ipairs(hls) do
        pcall(vim.api.nvim_buf_add_highlight, panel_buf, ns, h[2], h[1] - 1, 0, -1)
      end

      -- Finer-grained graph highlights
      for ln, hash in pairs(commit_map) do
        local line_text = lines[ln] or ""
        local hash_start = line_text:find(hash, 1, true)
        if hash_start then
          pcall(vim.api.nvim_buf_add_highlight, panel_buf, ns,
            "Number", ln - 1, hash_start - 1, hash_start - 1 + #hash)
        end
        local dec_start, dec_end = line_text:find("%b()")
        if dec_start then
          pcall(vim.api.nvim_buf_add_highlight, panel_buf, ns,
            "Function", ln - 1, dec_start - 1, dec_end)
        end
        if hash_start and hash_start > 2 then
          pcall(vim.api.nvim_buf_add_highlight, panel_buf, ns,
            "Special", ln - 1, 0, hash_start - 2)
        end
      end

      -- Restore cursor position
      if cursor then
        local max_line = vim.api.nvim_buf_line_count(panel_buf)
        cursor[1] = math.min(cursor[1], max_line)
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == panel_buf then
            pcall(vim.api.nvim_win_set_cursor, win, cursor)
            break
          end
        end
      end
    end)
  end

  -- Fire both async jobs in parallel
  vim.fn.jobstart({ "git", "status", "--porcelain", "-u" }, {
    stdout_buffered = true,
    on_stdout = function(_, data) status_data = data end,
    on_exit = function() on_both_done() end,
  })

  vim.fn.jobstart({
    "git", "log", "--graph", "--oneline", "--decorate", "--all",
    "--color=never", "-n", "30", "--format=%h %d %s",
  }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 and data[#data] == "" then
        table.remove(data) -- strip trailing empty
      end
      if data and #data > 0 then graph_data = data end
    end,
    on_exit = function() on_both_done() end,
  })
end

-- ── Keymaps ──

local function setup_keymaps()
  local o = { buffer = panel_buf, nowait = true, silent = true }

  -- Enter: action buttons, file diff, or commit details
  vim.keymap.set("n", "<cr>", function()
    local line = vim.fn.line(".")
    if action_map[line] then
      action_map[line]()
      return
    end
    local entry = file_map[line]
    if entry then
      close_diff()
      local win = find_editor_win()
      if win then vim.api.nvim_set_current_win(win) end
      vim.cmd("edit " .. vim.fn.fnameescape(entry.file))
      vim.schedule(function() pcall(vim.cmd, "Gitsigns diffthis") end)
      return
    end
    local hash = commit_map[line]
    if hash then
      -- Show commit diff in editor
      local win = find_editor_win()
      if win then vim.api.nvim_set_current_win(win) end
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_win_set_buf(win or 0, buf)
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].bufhidden = "wipe"
      vim.bo[buf].filetype = "git"
      vim.fn.jobstart({ "git", "show", "--stat", "--patch", hash }, {
        stdout_buffered = true,
        on_stdout = function(_, data)
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(buf) then
              vim.api.nvim_buf_set_lines(buf, 0, -1, false, data)
              vim.bo[buf].modifiable = false
            end
          end)
        end,
      })
      return
    end
  end, o)

  -- Open file without diff
  vim.keymap.set("n", "o", function()
    local entry = file_map[vim.fn.line(".")]
    if not entry then return end
    close_diff()
    local win = find_editor_win()
    if win then vim.api.nvim_set_current_win(win) end
    vim.cmd("edit " .. vim.fn.fnameescape(entry.file))
  end, o)

  -- Side-by-side diff
  vim.keymap.set("n", "D", function()
    local entry = file_map[vim.fn.line(".")]
    if not entry then return end
    close_diff()
    local win = find_editor_win()
    if win then vim.api.nvim_set_current_win(win) end

    local left_lines, right_lines, left_name, right_name
    local ft = vim.filetype.match({ filename = entry.file }) or ""

    if entry.section == "Staged Changes" then
      left_lines = vim.fn.systemlist("git show " .. vim.fn.shellescape("HEAD:" .. entry.file) .. " 2>/dev/null")
      right_lines = vim.fn.systemlist("git show " .. vim.fn.shellescape(":" .. entry.file) .. " 2>/dev/null")
      left_name = "HEAD: " .. vim.fn.fnamemodify(entry.file, ":t")
      right_name = "Staged: " .. vim.fn.fnamemodify(entry.file, ":t")
    elseif entry.section == "Changes" then
      left_lines = vim.fn.systemlist("git show " .. vim.fn.shellescape(":" .. entry.file) .. " 2>/dev/null")
      if vim.v.shell_error ~= 0 then
        left_lines = vim.fn.systemlist("git show " .. vim.fn.shellescape("HEAD:" .. entry.file) .. " 2>/dev/null")
      end
      right_lines = vim.fn.readfile(entry.file)
      left_name = "Index: " .. vim.fn.fnamemodify(entry.file, ":t")
      right_name = "Working: " .. vim.fn.fnamemodify(entry.file, ":t")
    elseif entry.section == "Merge Conflicts" then
      left_lines = vim.fn.systemlist("git show " .. vim.fn.shellescape(":2:" .. entry.file) .. " 2>/dev/null")
      right_lines = vim.fn.systemlist("git show " .. vim.fn.shellescape(":3:" .. entry.file) .. " 2>/dev/null")
      left_name = "Ours: " .. vim.fn.fnamemodify(entry.file, ":t")
      right_name = "Theirs: " .. vim.fn.fnamemodify(entry.file, ":t")
    else
      return
    end

    -- Left buffer (old version)
    local buf_l = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf_l, 0, -1, false, left_lines or {})
    vim.bo[buf_l].buftype = "nofile"
    vim.bo[buf_l].bufhidden = "wipe"
    vim.bo[buf_l].modifiable = false
    if ft ~= "" then vim.bo[buf_l].filetype = ft end
    pcall(vim.api.nvim_buf_set_name, buf_l, left_name)
    local win_l = win or vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win_l, buf_l)
    vim.cmd("diffthis")

    -- Right buffer (new version)
    vim.cmd("vertical rightbelow new")
    local win_r = vim.api.nvim_get_current_win()
    local buf_r = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(buf_r, 0, -1, false, right_lines or {})
    vim.bo[buf_r].buftype = "nofile"
    vim.bo[buf_r].bufhidden = "wipe"
    vim.bo[buf_r].modifiable = false
    if ft ~= "" then vim.bo[buf_r].filetype = ft end
    pcall(vim.api.nvim_buf_set_name, buf_r, right_name)
    vim.cmd("diffthis")

    -- Track for joint close
    diff_bufs = { buf_l, buf_r }

    -- Winbar with close button on both sides
    local close_btn = "%=%@v:lua.CloseDiffView@%#TabLine# × %X"
    vim.wo[win_l].winbar = "%#TabLineSel# " .. left_name .. " " .. close_btn
    vim.wo[win_r].winbar = "%#TabLineSel# " .. right_name .. " " .. close_btn

    -- q and Ctrl+W close both sides
    for _, b in ipairs({ buf_l, buf_r }) do
      local kopts = { buffer = b, nowait = true, silent = true }
      vim.keymap.set("n", "q", close_diff, kopts)
      vim.keymap.set("n", "<C-w>", close_diff, kopts)
    end
  end, o)

  -- File actions
  vim.keymap.set("n", "s", function()
    local entry = file_map[vim.fn.line(".")]
    if not entry then return end
    vim.fn.system({ "git", "add", "--", entry.file })
    M.refresh()
  end, o)

  vim.keymap.set("n", "u", function()
    local entry = file_map[vim.fn.line(".")]
    if not entry then return end
    vim.fn.system({ "git", "reset", "HEAD", "--", entry.file })
    M.refresh()
  end, o)

  vim.keymap.set("n", "d", function()
    local entry = file_map[vim.fn.line(".")]
    if not entry then return end
    vim.ui.select({ "Yes", "No" }, {
      prompt = "Discard changes to " .. vim.fn.fnamemodify(entry.file, ":t") .. "?",
    }, function(choice)
      if choice == "Yes" then
        if entry.section == "Untracked" then
          vim.fn.delete(entry.file)
        else
          vim.fn.system({ "git", "checkout", "--", entry.file })
        end
        M.refresh()
      end
    end)
  end, o)

  -- Merge conflict actions
  vim.keymap.set("n", "i", function()
    local entry = file_map[vim.fn.line(".")]
    if not entry or entry.section ~= "Merge Conflicts" then return end
    vim.fn.system({ "git", "checkout", "--theirs", "--", entry.file })
    vim.fn.system({ "git", "add", "--", entry.file })
    vim.notify("Accepted incoming: " .. entry.file, vim.log.levels.INFO)
    M.refresh()
  end, o)

  vim.keymap.set("n", "e", function()
    local entry = file_map[vim.fn.line(".")]
    if not entry or entry.section ~= "Merge Conflicts" then return end
    vim.fn.system({ "git", "checkout", "--ours", "--", entry.file })
    vim.fn.system({ "git", "add", "--", entry.file })
    vim.notify("Accepted current: " .. entry.file, vim.log.levels.INFO)
    M.refresh()
  end, o)

  vim.keymap.set("n", "S", function()
    vim.fn.system({ "git", "add", "-A" })
    M.refresh()
  end, o)

  vim.keymap.set("n", "U", function()
    vim.fn.system({ "git", "reset", "HEAD" })
    M.refresh()
  end, o)

  -- Git actions (keyboard shortcuts matching the button labels)
  vim.keymap.set("n", "c", do_commit, o)
  vim.keymap.set("n", "g", do_commit_generated, o)
  vim.keymap.set("n", "C", do_commit_all, o)
  vim.keymap.set("n", "a", do_amend, o)
  vim.keymap.set("n", "p", do_push, o)
  vim.keymap.set("n", "P", do_pull, o)
  vim.keymap.set("n", "f", do_fetch, o)
  vim.keymap.set("n", "z", do_stash, o)
  vim.keymap.set("n", "Z", do_stash_pop, o)
  vim.keymap.set("n", "m", do_ai_merge, o)

  -- Refresh / Close
  vim.keymap.set("n", "r", M.refresh, o)
  vim.keymap.set("n", "R", M.refresh, o)
  vim.keymap.set("n", "q", function()
    if _G.sidebar_show_files then _G.sidebar_show_files() end
  end, o)
end

-- ── Open / Close ──

function M.open()
  if panel_buf and vim.api.nvim_buf_is_valid(panel_buf) then
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == panel_buf then
        M.refresh()
        return
      end
    end
    vim.cmd("topleft vsplit")
    vim.api.nvim_set_current_buf(panel_buf)
    M.refresh()
    return
  end

  panel_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[panel_buf].filetype = "git_panel"
  vim.bo[panel_buf].buftype = "nofile"
  vim.bo[panel_buf].bufhidden = "hide"
  vim.bo[panel_buf].swapfile = false

  setup_keymaps()

  vim.cmd("topleft vsplit")
  vim.api.nvim_set_current_buf(panel_buf)
  M.refresh()
end

function M.close()
  if not panel_buf or not vim.api.nvim_buf_is_valid(panel_buf) then return end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == panel_buf then
      pcall(vim.api.nvim_win_hide, win)
    end
  end
end

-- Debounced refresh — all auto-refresh sources go through here
local git_watchers = {}
local refresh_debounce_timer = nil

local function debounced_refresh()
  if not panel_buf then return end
  if refresh_debounce_timer then
    refresh_debounce_timer:stop()
    refresh_debounce_timer:close()
  end
  refresh_debounce_timer = vim.uv.new_timer()
  refresh_debounce_timer:start(500, 0, vim.schedule_wrap(function()
    if refresh_debounce_timer then
      refresh_debounce_timer:stop()
      refresh_debounce_timer:close()
      refresh_debounce_timer = nil
    end
    if panel_buf and vim.api.nvim_buf_is_valid(panel_buf) then
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == panel_buf then
          M.refresh()
          return
        end
      end
    end
  end))
end

-- Auto-refresh when files change or returning from terminal (git CLI)
vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained", "TermClose", "TermLeave" }, {
  callback = debounced_refresh,
})

local function setup_git_watchers()
  -- Stop existing watchers
  for _, w in ipairs(git_watchers) do
    pcall(function() w:stop() w:close() end)
  end
  git_watchers = {}

  local git_dir = vim.fn.system("git rev-parse --git-dir 2>/dev/null"):gsub("%s+$", "")
  if vim.v.shell_error ~= 0 or git_dir == "" then return end

  -- Watch key git files that change on most operations
  local watch_targets = {
    git_dir .. "/index",      -- stage/unstage/commit
    git_dir .. "/HEAD",       -- checkout/merge/rebase
    git_dir .. "/FETCH_HEAD", -- fetch/pull
    git_dir .. "/MERGE_HEAD", -- merge in progress
    git_dir .. "/refs",       -- branch/tag changes
  }

  for _, target in ipairs(watch_targets) do
    if vim.fn.isdirectory(target) == 1 or vim.fn.filereadable(target) == 1 then
      local w = vim.uv.new_fs_event()
      local ok = pcall(function()
        w:start(target, { recursive = true }, function(err)
          if not err then debounced_refresh() end
        end)
      end)
      if ok then
        table.insert(git_watchers, w)
      end
    end
  end
end

-- Start watchers on first load and when changing directories
setup_git_watchers()
vim.api.nvim_create_autocmd("DirChanged", {
  callback = setup_git_watchers,
})

return M
