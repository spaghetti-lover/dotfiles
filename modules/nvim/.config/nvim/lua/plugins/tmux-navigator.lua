return {
	"christoomey/vim-tmux-navigator",
	config = function()
		-- These need to be <C-h> etc. The bare 'C-h' form maps the literal
		-- three-character sequence C, -, h, so the maps were inert and
		-- navigation only worked via the plugin's own default mappings.
		vim.keymap.set("n", "<C-h>", ":TmuxNavigateLeft<CR>", { silent = true })
		vim.keymap.set("n", "<C-j>", ":TmuxNavigateDown<CR>", { silent = true })
		vim.keymap.set("n", "<C-k>", ":TmuxNavigateUp<CR>", { silent = true })
		vim.keymap.set("n", "<C-l>", ":TmuxNavigateRight<CR>", { silent = true })
	end,
}
