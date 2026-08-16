return {
	"ray-x/go.nvim",
	dependencies = { -- optional packages
		"ray-x/guihua.lua",
		"neovim/nvim-lspconfig",
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		require("go").setup()

		-- go.nvim's health check hardcodes telescope in its plugin list, but the only
		-- code that would use it (setup_telescope in go/dap.lua) is never called. We
		-- run fzf-lua, so filter that one warning plus the "Not all plugin installed"
		-- aggregate it triggers, instead of installing a dead dependency.
		-- go/health.lua binds `local warn = health.warn` at load time, so the global is
		-- swapped only long enough for that module to capture the wrapper.
		package.loaded["go.health"] = nil
		local health = vim.health
		local warn, start = health.warn, health.start
		local other_warns = false
		health.start = function(...)
			other_warns = false
			return start(...)
		end
		health.warn = function(msg, ...)
			if type(msg) == "string" then
				if msg:match("^telescope: not installed") then
					return
				end
				if msg == "Not all plugin installed" and not other_warns then
					return
				end
			end
			other_warns = true
			return warn(msg, ...)
		end
		require("go.health")
		health.warn, health.start = warn, start
	end,
	event = { "CmdlineEnter" },
	ft = { "go", "gomod" },
	build = ':lua require("go.install").update_all_sync()', -- if you need to install/update all binaries
}
