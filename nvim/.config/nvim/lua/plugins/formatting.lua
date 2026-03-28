return {
  -- Override conform.nvim to use ONLY biome for JS/TS/JSON filetypes
  -- Prevents prettier from conflicting when biome.json is present
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      -- Biome-only filetypes (no prettier fallback)
      local biome_filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "json",
        "jsonc",
      }

      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(biome_filetypes) do
        opts.formatters_by_ft[ft] = { "biome" }
      end

      -- Only activate biome in projects with biome.json
      opts.formatters = opts.formatters or {}
      opts.formatters.biome = {
        require_cwd = true,
      }
    end,
  },
}
