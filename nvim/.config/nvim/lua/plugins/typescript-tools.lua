return {
	"pmizio/typescript-tools.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"neovim/nvim-lspconfig",
	},
	ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
	opts = {
		settings = {
			-- spawn additional tsserver instance for type checking
			separate_diagnostic_server = true,
			-- "change"|"insert_leave" - when to update diagnostics
			publish_diagnostic_on = "insert_leave",
			-- array of strings (file patterns) - don't show diagnostics for these
			expose_as_code_action = {
				"fix_all",
				"add_missing_imports",
				"remove_unused",
				"remove_unused_imports",
				"organize_imports",
			},
			-- tsserver config
			tsserver_path = nil,
			tsserver_plugins = {},
			tsserver_max_memory = "auto",
			tsserver_format_options = {},
			tsserver_file_preferences = {
				includeInlayParameterNameHints = "all",
				includeInlayParameterNameHintsWhenArgumentMatchesName = false,
				includeInlayFunctionParameterTypeHints = true,
				includeInlayVariableTypeHints = true,
				includeInlayVariableTypeHintsWhenTypeMatchesName = false,
				includeInlayPropertyDeclarationTypeHints = true,
				includeInlayFunctionLikeReturnTypeHints = true,
				includeInlayEnumMemberValueHints = true,
				includeCompletionsForModuleExports = true,
				quotePreference = "auto",
			},
			-- inlay hints (Neovim 0.10+)
			tsserver_locale = "en",
			complete_function_calls = true,
			include_completions_with_insert_text = true,
		},
	},
}
