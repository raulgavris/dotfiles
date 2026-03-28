local M = {}

-- Shared attach defaults
local function attach_defaults(cwd)
  return {
    sourceMaps = true,
    pauseForSourceMap = true,
    autoAttachChildProcesses = false,
    attachExistingChildren = false,
    resolveSourceMapLocations = { "**", "!**/node_modules/**" },
    sourceMapPathOverrides = {
      ["webpack:///./~/*"] = (cwd or "${workspaceFolder}") .. "/node_modules/*",
      ["webpack:///./*"] = (cwd or "${workspaceFolder}") .. "/*",
      ["webpack:///*"] = "*",
    },
    skipFiles = { "<node_internals>/**" },
  }
end

--- Get the working directory of a process by PID (macOS + Linux)
local function get_process_cwd(pid)
  local cwd
  if vim.fn.has("mac") == 1 then
    local out = vim.fn.systemlist("lsof -a -p " .. pid .. " -d cwd -Fn 2>/dev/null")
    for _, line in ipairs(out) do
      if line:sub(1, 1) == "n" then
        cwd = line:sub(2)
        break
      end
    end
  else
    cwd = vim.trim(vim.fn.system("readlink -f /proc/" .. pid .. "/cwd 2>/dev/null"))
    if cwd == "" then cwd = nil end
  end
  return cwd
end

--- Detect project root from the current buffer (walks up to find package.json)
local function detect_project_root()
  local buf_path = vim.api.nvim_buf_get_name(0)
  if buf_path ~= "" then
    local root = vim.fs.find({ "package.json", "tsconfig.json" }, {
      path = vim.fs.dirname(buf_path),
      upward = true,
      stop = vim.env.HOME,
    })
    if root[1] then
      return vim.fs.dirname(root[1])
    end
  end
  return nil
end

--- List running Node.js processes for selection
local function pick_node_process(cb)
  local output = vim.fn.systemlist("ps -eo pid,args | grep -E '[n]ode' | grep -v 'grep'")
  local items = {}
  for _, line in ipairs(output) do
    local pid = line:match("^%s*(%d+)")
    if pid then
      table.insert(items, { pid = tonumber(pid), label = vim.trim(line) })
    end
  end

  if #items == 0 then
    vim.notify("[DAP] No Node.js processes found", vim.log.levels.WARN)
    return
  end

  vim.ui.select(items, {
    prompt = "Select Node process to attach:",
    format_item = function(item) return item.label end,
  }, function(choice)
    if choice then cb(choice.pid) end
  end)
end

--- Pick a running Node.js process, enable its inspector via SIGUSR1, then attach
function M.attach_process()
  pick_node_process(function(pid)
    -- Get the process's actual working directory for correct source map resolution
    local cwd = get_process_cwd(pid) or detect_project_root() or vim.fn.getcwd()
    vim.notify("[DAP] Process cwd: " .. cwd, vim.log.levels.INFO)

    -- Send SIGUSR1 to enable the Node.js inspector (same as VS Code)
    local ok, err = pcall(vim.uv.kill, pid, "sigusr1")
    if not ok then
      vim.notify("[DAP] Failed to send SIGUSR1 to pid " .. pid .. ": " .. err, vim.log.levels.ERROR)
      return
    end
    vim.notify("[DAP] Sent SIGUSR1 to pid " .. pid .. " — enabling inspector on port 9229", vim.log.levels.INFO)

    -- Give the inspector a moment to start listening, then attach
    vim.defer_fn(function()
      local config = vim.tbl_extend("force", attach_defaults(cwd), {
        type = "pwa-node",
        request = "attach",
        name = "Attach to Process " .. pid,
        port = 9229,
        cwd = cwd,
      })
      require("dap").run(config)
    end, 500)
  end)
end

--- Attach to a Node.js process listening on port 9229 (node --inspect)
function M.attach_port()
  local cwd = detect_project_root() or vim.fn.getcwd()
  local config = vim.tbl_extend("force", attach_defaults(cwd), {
    type = "pwa-node",
    request = "attach",
    name = "Attach to Port 9229",
    port = 9229,
    cwd = cwd,
  })
  vim.notify("[DAP] Attaching with cwd: " .. cwd, vim.log.levels.INFO)
  require("dap").run(config)
end

return M
