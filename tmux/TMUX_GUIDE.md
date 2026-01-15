# 🚀 Tmux Configuration Guide

**Quick Reference:** Press `prefix` + `H` to view this guide anytime!

---

## 🎯 Prefix Key

Your prefix is: **`Ctrl-a`** (not the default `Ctrl-b`)

---

## ⌨️ Custom Keybindings

### **Sessions & Workspaces**

| Key | Action | Description |
|-----|--------|-------------|
| `prefix` + `f` | **Workspace Creator** | Multi-repo workspace - select multiple repos with Tab, name workspace, auto-creates windows |
| `prefix` + `Ctrl-f` | **🔥 Quick Sessionizer** | Instantly jump to any project - searches all project dirs, creates session if needed |
| `prefix` + `s` | **Session Switcher** | Enhanced fzf session picker with preview - if multiple windows, picks specific window. Ctrl-X to kill inline |
| `prefix` + `N` | **Quick Notes** | Popup scratch pad for quick notes (`~/notes/scratch.md`) |
| `prefix` + `K` | **Kill Sessions** | Multi-select sessions to kill with Tab. Shows preview before deletion |
| `prefix` + `X` | **Kill Current** | Kill current session (with confirmation) |
| `prefix` + `Q` | **Kill Server** | Kill entire tmux server - all sessions (with confirmation) |
| `prefix` + `Space` | Last Window | Jump to previously used window |
| `Ctrl-a Ctrl-a` | Last Session | Jump to previously used session |

### **Windows**

| Key | Action | Description |
|-----|--------|-------------|
| `prefix` + `c` | New Window | Creates new window in current directory |
| `prefix` + `,` | Rename Window | Rename current window |
| `prefix` + `w` | Window List | Show all windows across all sessions |
| `Alt-1` to `Alt-5` | Jump to Window | Quick jump to window 1-5 |
| `prefix` + `<` | Swap Left | Move window left |
| `prefix` + `>` | Swap Right | Move window right |

### **Panes**

| Key | Action | Description |
|-----|--------|-------------|
| `prefix` + `\|` | Split Vertical | Split pane vertically (side by side) |
| `prefix` + `\\` | Split Vertical Full | Split vertical across full height |
| `prefix` + `-` | Split Horizontal | Split pane horizontally (top/bottom) |
| `prefix` + `_` | Split Horizontal Full | Split horizontal across full width |
| `Ctrl-h/j/k/l` | Navigate Panes | Vim-style pane navigation (works with vim-tmux-navigator) |
| `Ctrl-↑/↓/←/→` | **Resize Panes** | Resize panes WITHOUT prefix! Fast resizing |
| `prefix` + `z` | Zoom Pane | Toggle pane fullscreen |
| `prefix` + `x` | Kill Pane | Kill current pane (with confirmation) |
| `prefix` + `q` | Show Pane Numbers | Show pane numbers (3 second display) |
| `prefix` + `S` | **Sync Panes** | Toggle typing in all panes at once |
| `Alt-1` to `Alt-5` | **Quick Layouts** | Even-H, Even-V, Main-H, Main-V, Tiled |

### **Copy Mode (Vi Keys)**

| Key | Action | Description |
|-----|--------|-------------|
| `prefix` + `[` | **Enter Copy Mode** | Start vi-style text selection |
| `h/j/k/l` | Navigate | Vim keys to move cursor (in copy mode) |
| `v` | Start Selection | Begin selecting text (like vim visual mode) |
| `V` | Line Selection | Select entire lines |
| `Ctrl-v` | Rectangle Selection | Visual block mode (like vim) |
| `y` | Copy to Clipboard | Copy selection and exit (uses macOS pbcopy) |
| `prefix` + `]` | Paste | Paste from tmux buffer |
| `q` or `Esc` | Exit Copy Mode | Leave copy mode without copying |

### **System**

| Key | Action | Description |
|-----|--------|-------------|
| `prefix` + `r` | Reload Config | Reload tmux.conf - shows "Reloaded!" message |
| `prefix` + `H` | **This Guide** | Opens this help documentation |
| `prefix` + `?` | Key Bindings | Show all keybindings (built-in tmux help) |
| `prefix` + `:` | Command Prompt | Enter tmux commands directly |
| `prefix` + `C` | **Clear History** | Clear screen AND scrollback history (fresh start) |
| `prefix` + `Ctrl-l` | Clear Screen | Clear screen AND scrollback history |

### **Logging & Massive Output**

| Key | Action | Description |
|-----|--------|-------------|
| `prefix` + `P` | **Save Pane to File** | Save current pane contents (100k lines) to file (KEEPS file) |
| `prefix` + `O` | **Start Logging** | Start logging + auto-opens file in Cursor! (Shift-o) |
| `prefix` + `o` | **Stop & Delete** | Stop logging AND delete the log file (cleanup) |
| `/` | Search in Copy Mode | Search forward in copy mode (after `prefix` + `[`) |
| `?` | Search Backward | Search backward in copy mode |
| `n` / `N` | Next/Prev Match | Navigate search results in copy mode |

### **Resurrect (Save/Restore)**

| Key | Action | Description |
|-----|--------|-------------|
| `prefix` + `Ctrl-s` | **Manual Save** | Force save tmux state NOW (shows "Saving..." message) |
| `prefix` + `Ctrl-r` | **Manual Restore** | Force restore from last save |

> **Note:** Auto-save happens every 5 minutes automatically!

---

## 🛠️ Custom Scripts

### **1. Workspace Creator** (`~/.tmux/workspace.sh`)

**What it does:**
- Select multiple repos from zoxide history
- Name your workspace (or use default from first repo)
- Creates tmux session with one window per repo
- Navigates to git root if in git repo
- Auto-switches to new workspace

**Usage:**
1. Press `prefix` + `f`
2. Use Tab to multi-select repos from zoxide list
3. Press Enter
4. Type workspace name (or press Enter for default)
5. Done! You're now in your new workspace

**Example:**
```
Select: backend, frontend, admin (with Tab)
Name: myproject
Result: Session "myproject" with 3 windows
```

### **2. Quick Sessionizer** (`~/.tmux/sessionizer.sh`) 🔥

**What it does:**
- Blazing fast project jumper (inspired by ThePrimeagen)
- Searches all your project directories (configurable)
- Creates session if doesn't exist, switches if it does
- Session name = directory basename
- Perfect for quick context switching

**Usage:**
1. Press `prefix` + `Ctrl-f`
2. Type to filter projects
3. Press Enter - instantly in that project!

**Workflow:**
```bash
# You're in session A, need to quickly jump to another project
prefix + Ctrl-f → type "backend" → Enter → now in backend session

# Next day, jump back
prefix + Ctrl-f → type "frontend" → Enter → switches to existing session
```

**Configuration:**
Edit `~/.tmux/sessionizer.sh` to add your project directories:
```bash
PROJECT_DIRS=(
    "$HOME/Projects"
    "$HOME/Projects/pws"
    "$HOME/work"
    # Add your paths here
)
```

**Why use this over workspace creator?**
- **Sessionizer**: Single projects, super fast, keyboard-centric
- **Workspace Creator**: Multi-repo workspaces, more structured setup

### **3. Smart Session Switcher** (`~/.tmux/switchsession.sh`)

**What it does:**
- Lists all sessions with window count and status
- Preview shows windows in each session
- If session has multiple windows, lets you pick specific window
- Excludes current session from list

**Usage:**
1. Press `prefix` + `s`
2. Type to search, arrow keys to navigate
3. Press Enter to switch
4. If multiple windows: pick which window to jump to
5. Press **Ctrl-X** to kill a session instead of switching

### **4. Batch Session Killer** (`~/.tmux/killsession.sh`)

**What it does:**
- Multi-select sessions to delete
- Preview shows what's in each session
- Safe: current session is excluded

**Usage:**
1. Press `prefix` + `K` (Shift + k)
2. Use **Tab** to select multiple sessions
3. Press Enter to kill all selected
4. Confirm if prompted

### **4. Smart Terminal Entry** (`~/.tmux/attach-or-create.sh`)

**What it does:**
- When you open a terminal, intelligently attaches to tmux
- If sessions exist: shows fzf picker
- If no sessions: creates "main"
- Cancel picker (Ctrl-C): creates new "main" session

**Usage:**
- Just open a terminal! It runs automatically
- Or type `t` from command line

---

## 🔄 Resurrect & Continuum

### **What Are They?**

**Resurrect** = Manual save/restore tool
**Continuum** = Automation layer (auto-save + auto-restore)

### **Your Configuration:**

```bash
✅ Auto-save every 5 minutes
✅ Auto-restore on tmux start
✅ Auto-start tmux on Mac boot
✅ Save pane contents (text visible in panes)
✅ Save vim/nvim sessions
```

### **How It Works:**

```
You work in tmux
         ↓
Auto-saves every 5 min (background)
         ↓
Saved to: ~/.local/share/tmux/resurrect/
         ↓
Computer restarts/tmux closes
         ↓
Start tmux → Auto-restores everything!
         ↓
All sessions, windows, panes restored ✨
```

### **Manual Controls:**

- **Save NOW:** `prefix` + `Ctrl-s` (useful before risky operations)
- **Restore NOW:** `prefix` + `Ctrl-r` (restore from last save)

### **What Gets Saved:**

✅ Sessions, windows, panes
✅ Window/pane layouts
✅ Working directories
✅ Pane contents (what's visible on screen)
✅ Window names

❌ Running processes (backend servers, etc.)
❌ SSH connections
❌ Active state of programs

### **Important: Processes Are NOT Restored**

If you have a backend server running in a window and it crashes:
- Resurrect saves the **layout** and **directory**
- It does NOT restart the backend process
- After restore, you'll be in the right directory, ready to run your command again

**This is by design and actually safer!** You wouldn't want crashed services auto-restarting.

---

## 🎓 Advanced Features & Workflows

### **Copy Mode Workflow**

**Scenario:** You see an error message you want to copy

```bash
# 1. Enter copy mode
prefix + [

# 2. Navigate to error using vim keys
j j j j k k  # Move down/up

# 3. Start selection at beginning of error
v

# 4. Move cursor to select text
j j j  # Select multiple lines

# 5. Copy to clipboard
y

# 6. Paste anywhere (in tmux)
prefix + ]

# Or paste outside tmux (Cmd+V in any app!)
```

**Pro Tips:**
- Mouse drag to select (auto-copies on release)
- Search in copy mode: `/` then type search term
- Jump to line: `:line_number`
- Navigate fast: `Ctrl-d/u` (half-page down/up), `gg` (top), `G` (bottom)

---

### **Pane Synchronization**

**Scenario:** Update packages on 4 different servers

```bash
# 1. Create workspace for your servers
prefix + f
# Select: server1, server2, server3, server4

# 2. In each window, SSH to the server
ssh user@server1.com

# 3. Split window into 2 panes (optional)
prefix + |

# 4. Enable pane synchronization
prefix + S
# Status shows: "Panes sync: ON"

# 5. Type once, execute everywhere
sudo apt update && sudo apt upgrade -y
# All servers update simultaneously! 🚀

# 6. Disable sync when done
prefix + S
# Status shows: "Panes sync: OFF"
```

**Use Cases:**
- Multi-server deployments
- Database migrations across replicas
- Log monitoring (tail -f on multiple servers)
- Parallel testing

---

### **Quick Pane Resizing**

**No prefix needed - super fast!**

```bash
# Create some panes
prefix + |
prefix + -

# Resize immediately with Ctrl + arrows
Ctrl-Right Ctrl-Right  # Make current pane wider
Ctrl-Down Ctrl-Down    # Make current pane taller

# Perfect for:
# - Making log pane smaller
# - Giving editor more space
# - Adjusting to content
```

---

### **Quick Layout Switching**

**Instantly arrange panes:**

```bash
# You have 4 panes in random layout
# Quick fixes:

Alt-1  # Even horizontal (all side-by-side)
Alt-2  # Even vertical (all stacked)
Alt-3  # Main horizontal (one big top)
Alt-4  # Main vertical (one big left)
Alt-5  # Tiled (perfect grid)

# Cycle through to find best layout!
```

**Common Workflows:**

**Code + Logs + Tests:**
```bash
# 1. Create 3 panes
prefix + -  (horizontal split)
prefix + |  (split bottom pane)

# 2. Arrange
Alt-3  # Main horizontal
# Top: Editor (big)
# Bottom left: Logs
# Bottom right: Tests
```

**Multi-server Dashboard:**
```bash
# 1. Create 4 panes
prefix + | prefix + - Ctrl-h prefix + -

# 2. Perfect grid
Alt-5  # Tiled layout
# All same size, perfect for monitoring
```

---

### **Handling Massive Logs (100k+ lines)**

**Problem:** Web server outputs 100,000+ lines - hard to search/copy

**Configuration:**
- ✅ History limit: 100,000 lines (increased from 50k)
- ✅ New keybindings for logging

**Solution 1: Save Pane to File**

```bash
# Server running with tons of output
npm run dev
# ... 100k lines ...

# Save entire pane history to file
prefix + P
# Prompt: "Save pane to:"
~/logs/server-output.txt

# Now search the file
grep "ERROR" ~/logs/server-output.txt
grep -C 5 "crash" ~/logs/server-output.txt  # 5 lines context
vim ~/logs/server-output.txt  # Then use /search
```

**Solution 2: Auto-Logging (Best!)**

```bash
# BEFORE running server:
# Start logging
prefix + O (Shift-o)
# Shows: "Logging STARTED: ... (opened in Cursor)"
# ✨ Log file automatically opens in Cursor!

# Run server - everything auto-saves!
npm run dev
# Watch output in real-time in Cursor editor!

# In another pane, monitor errors (optional)
tail -f ~/logs/tmux-pane-*.log | grep ERROR

# Stop logging when done (auto-deletes log)
prefix + o (lowercase)
# Shows: "Logging STOPPED (log deleted)"

# Note: If you want to KEEP the log, use prefix + P to save it before stopping!
```

**Solution 3: Use tee Command**

```bash
# Best practice for long-running processes
npm run dev 2>&1 | tee ~/logs/server.log

# Benefits:
# ✅ See output in real-time
# ✅ All output saved to file
# ✅ Can grep while running
# ✅ No memory limits!

# Advanced with timestamps
npm run dev 2>&1 | ts '%Y-%m-%d %H:%M:%S' | tee ~/logs/server-$(date +%Y%m%d-%H%M%S).log
```

**Full-Stack Dev Workflow:**

```bash
# Window 1: Backend
prefix + O  # Start logging (Shift-o)
npm run dev:backend

# Window 2: Frontend
prefix + O  # Start logging (Shift-o)
npm run dev:frontend

# Window 3: Split for monitoring
prefix + |

# Left pane: Backend errors in real-time
tail -f ~/logs/tmux-pane-1-*.log | grep --color ERROR

# Right pane: Frontend errors
tail -f ~/logs/tmux-pane-2-*.log | grep --color ERROR

# All output saved + monitored! 🚀
```

**Searching Massive Logs:**

```bash
# Method 1: In tmux copy mode
prefix + [
/search-term  # Search forward
?search-term  # Search backward
n / N         # Next/previous match

# Method 2: Grep the saved file (faster!)
grep -n "ERROR" ~/logs/output.txt
grep -B 5 -A 5 "crash" ~/logs/output.txt

# Method 3: Interactive with vim
vim ~/logs/output.txt
:set hlsearch    # Highlight matches
/search          # Search
n / N            # Navigate matches
:q               # Quit

# Method 4: Use less
less ~/logs/output.txt
/pattern         # Search
n / N            # Navigate
g / G            # Jump to top/bottom
q                # Quit
```

**Pro Tips:**
- Use `tee` for long-running processes (best practice)
- Use `prefix + O` (start) / `prefix + o` (stop) when you forget tee
- Use `prefix + P` to save after the fact
- Search files with `grep` - much faster than tmux copy mode
- Use `tail -f` to monitor logs in real-time

---

## 🚨 Troubleshooting

### **Problem: Pane is Stuck/Frozen**

**Symptoms:**
- Can't type commands
- Terminal seems frozen
- Process crashed but pane is unresponsive

**Solution:**
```bash
# Option 1: Force kill and respawn pane
prefix + :
respawn-pane -k

# Option 2: Try force-quit first
Ctrl-C (multiple times)
Ctrl-Z
Ctrl-D

# Option 3: Kill pane and create new one
prefix + x  (kill pane)
prefix + | or -  (create new pane)
```

### **Problem: Too Many Sessions**

**Symptoms:**
- Sessions named: 0, 1, 2, 3... 13
- Hard to track which session is which

**Solution:**
- Use `prefix` + `K` to batch delete old sessions
- Always use `prefix` + `f` to create named workspaces
- Use `t` command instead of `tmux` directly

### **Problem: Resurrect Not Saving**

**Check:**
```bash
# 1. Check if files are being created
ls -lah ~/.local/share/tmux/resurrect/

# 2. Force a manual save
prefix + Ctrl-s

# 3. Check tmux version (should be 2.0+)
tmux -V

# 4. Verify plugins are installed
ls ~/.tmux/plugins/
```

### **Problem: Sessions Not Auto-Restoring**

**Check:**
```bash
# Verify setting in tmux.conf
grep continuum-restore ~/.tmux.conf
# Should show: set -g @continuum-restore 'on'

# Check if resurrect files exist
ls ~/.local/share/tmux/resurrect/last

# Try manual restore
prefix + Ctrl-r
```

---

## 📂 File Locations

| What | Where |
|------|-------|
| **Config** | `~/.tmux.conf` |
| **Scripts** | `~/.tmux/*.sh` |
| **Plugins** | `~/.tmux/plugins/` |
| **Saves** | `~/.local/share/tmux/resurrect/` |
| **This Guide** | `~/Projects/dotfiles/tmux/TMUX_GUIDE.md` |

---

## 🎨 Plugins Installed

1. **TPM** - Tmux Plugin Manager
2. **resurrect** - Manual save/restore
3. **continuum** - Auto save/restore
4. **themepack** - Theme collection
5. **vim-tmux-navigator** - Seamless vim/tmux pane navigation
6. **onedark-theme** - Current active theme
7. **tmux-yank** - Better clipboard integration
8. **tmux-fzf** - Additional fzf integrations
9. **tmux-prefix-highlight** - Shows when prefix/copy/sync mode is active

---

## 🎨 Visual Features & Status Bar

### **Active Pane Highlighting**
- **Active pane**: Orange border (`colour208`)
- **Inactive panes**: Dark gray border (`colour238`)
- Makes it crystal clear which pane has focus

### **Auto-Renaming Windows**
Windows automatically rename based on current directory:
```
~/Projects/backend → window name: "backend"
~/work/frontend → window name: "frontend"
```
You can still manually rename with `prefix` + `,`

### **Status Bar Indicators**

Your status bar shows (right side):

```
[PREFIX] | CPU: 15% | MEM: 8.2GB | 🔋 85% | username | 02:30 PM | 15-01-2026
```

**Indicators:**
- **PREFIX** - Shows when prefix is active (blue), copy mode (magenta), or sync mode (red)
- **CPU** - Current CPU usage percentage
- **MEM** - Memory usage in GB
- **Battery** - Charging status and percentage
- **Time & Date** - 12-hour format with day-month-year

**Prefix Highlight States:**
- 🔵 **PREFIX** (blue) - Prefix key pressed, waiting for command
- 🟣 **COPY** (magenta) - In copy mode
- 🔴 **SYNC** (red) - Panes synchronized (typing in all panes)

### **Quick Notes**
Press `prefix` + `N` for instant scratch pad:
- Opens in popup window
- Saved to `~/notes/scratch.md`
- Perfect for TODO lists, quick notes, copy-paste buffer
- Survives across sessions

---

## 💡 Pro Tips

### **Workflow Recommendations:**

1. **Master the Quick Sessionizer (🔥 Most Powerful):**
   - `prefix` + `Ctrl-f` → Instant project switching
   - No need to remember session names or navigate directories
   - Just type part of project name → Enter → you're there!
   - Perfect for rapid context switching during development

2. **Use workspaces for multi-repo projects:**
   - `prefix` + `f` → Select project repos → Name it
   - One session per project, multiple windows per session
   - Example: "ecommerce" workspace with backend, frontend, admin windows

3. **Quick notes for copy-paste workflows:**
   - `prefix` + `N` → Instant scratch pad
   - Paste API responses, error messages, TODO items
   - Persists across sessions - always available

4. **Name your sessions meaningfully:**
   - Good: "backend-api", "client-work", "personal"
   - Bad: "0", "1", "test", "asdf"
   - Or let Sessionizer auto-name from directory!

5. **Manual save before risky operations:**
   ```bash
   prefix + Ctrl-s  # Before system update, before major changes, etc.
   ```

6. **Keep sessions organized:**
   - Use `prefix` + `K` regularly to clean up old sessions
   - Use `prefix` + `s` to jump between sessions quickly

7. **Leverage auto-restore:**
   - Don't worry about crashes or reboots
   - Everything auto-saves every 5 minutes
   - Just restart and continue working

8. **Handle massive logs properly:**
   - Long-running server? Use: `npm run dev 2>&1 | tee ~/logs/server.log`
   - Forgot tee? Start logging: `prefix + O`, stop: `prefix + o`
   - Need to search 100k lines? Save to file: `prefix + P`

9. **Customize project search paths:**
   - Edit `~/.tmux/sessionizer.sh`
   - Add your work directories to `PROJECT_DIRS` array
   - Sessionizer will find all projects recursively

10. **Watch the status bar:**
    - PREFIX indicator shows what mode you're in
    - Orange border = active pane
    - Check CPU/Memory when system feels slow
   - Search files with `grep` - much faster than scrolling

### **Keyboard Shortcuts Muscle Memory:**

- **Session:** `prefix` + `s` (switch) or `f` (new workspace)
- **Window:** `Alt-1` through `Alt-5` (quick jump to windows)
- **Panes:** `Ctrl-h/j/k/l` (navigate), `prefix` + `|/-` (split)
- **Resize:** `Ctrl` + arrows (no prefix!)
- **Copy:** `prefix` + `[` (enter), `v` (select), `y` (copy)
- **Search:** `/` (in copy mode)
- **Sync:** `prefix` + `S` (type in all panes)
- **Layouts:** `Alt-1` to `Alt-5` (quick pane arrangements)
- **Logging:** `prefix` + `O` (start), `prefix` + `o` (stop), `prefix` + `P` (save)
- **Save:** `prefix` + `Ctrl-s` (manual save)

---

## 🔗 Useful Resources

- [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
- [Resurrect GitHub](https://github.com/tmux-plugins/tmux-resurrect)
- [Continuum GitHub](https://github.com/tmux-plugins/tmux-continuum)
- [Your Dotfiles](~/Projects/dotfiles/)

---

**Last Updated:** January 2026
**Config Version:** Custom enhanced setup with fzf integration

---

*Press `q` to close this guide*
