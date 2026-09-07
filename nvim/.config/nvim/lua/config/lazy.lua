require("lazy").setup({
  spec = {
    -- LazyVim core
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- LazyVim extras
    { import = "lazyvim.plugins.extras.lang.typescript" },
    { import = "lazyvim.plugins.extras.lang.go" },
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.formatting.biome" },
    { import = "lazyvim.plugins.extras.ai.codeium" },

    -- User plugins
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false, -- always use latest git commit
  },
  checker = { enabled = true }, -- check for plugin updates
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
