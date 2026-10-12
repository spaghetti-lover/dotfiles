-- Local review comments for code Atlas cannot see: untracked or
-- never-committed files, agent-generated diffs, scratch buffers. Atlas owns
-- PR/MR review (`<leader>ga`, comments that travel back to GitHub or GitLab);
-- this owns the pass you do before anything is pushed, and hands the result
-- to an agent instead of to a forge.
--
-- Storage is in-memory on purpose: comments are session-scoped, so there is
-- no `.code-review/` directory to gitignore, and the file backend's
-- thread-resolve silently no-ops once a thread has a reply. `minimal`
-- output is one `path:L12-18: text` line per comment — the shape an agent
-- reads best; `<leader>ccy` puts it on the system clipboard.
--
-- The plugin's own `<leader>r*` maps are disabled wholesale. The keys below
-- reuse Atlas's review verbs so one muscle memory covers both reviewers:
-- `c` comment, `r` reply, `x` resolve, `d` delete, `l` list, `p` preview.
-- `:CodeReviewSetStatus` is deliberately not exposed — it requires a module
-- that does not exist upstream.
return {
	"choplin/code-review.nvim",
	cmd = {
		"CodeReviewComment",
		"CodeReviewShowComment",
		"CodeReviewReply",
		"CodeReviewResolve",
		"CodeReviewDeleteComment",
		"CodeReviewList",
		"CodeReviewPreview",
		"CodeReviewCopy",
		"CodeReviewSave",
		"CodeReviewClear",
	},

	init = function()
		local group = vim.api.nvim_create_augroup("CodeReviewSpec", { clear = true })

		-- `minimal` output cannot round-trip: the preview buffer is `acwrite`,
		-- and its BufWriteCmd re-parses the buffer with the detailed-markdown
		-- parser, so a reflex `:w` replaces the review with nothing. Drop the
		-- write handler (registered just after the User event, hence the
		-- schedule) and make the buffer honest.
		vim.api.nvim_create_autocmd("User", {
			group = group,
			pattern = "CodeReviewPreviewEnter",
			callback = function(args)
				local buf = args.data and args.data.buf
				if not buf then
					return
				end
				vim.schedule(function()
					if vim.api.nvim_buf_is_valid(buf) then
						vim.api.nvim_clear_autocmds({ event = "BufWriteCmd", buffer = buf })
						vim.bo[buf].modifiable = false
					end
				end)
			end,
			desc = "Make the code-review preview read-only",
		})

		-- Indicators are only drawn at mutation time, and the plugin wires its
		-- own re-render autocmd for the `file` backend only -- on `memory` any
		-- `:e`, buffer wipe or session restore silently blanks every marker.
		vim.api.nvim_create_autocmd({ "BufWinEnter", "BufReadPost" }, {
			group = group,
			callback = function()
				-- Probe `package.loaded` rather than require: the spec is lazy
				-- and this must not load the plugin on every buffer.
				local comment = package.loaded["code-review.comment"]
				local state = package.loaded["code-review.state"]
				if not comment or not state or #state.get_comments() == 0 then
					return
				end
				comment.update_indicators()
			end,
			desc = "Re-render code-review indicators",
		})

		-- Both groups ship as `default` links to `Comment`, so a review marker
		-- is drawn in the same dim grey as source comments. Re-link them to the
		-- hint diagnostic groups, and re-apply on `ColorScheme` because loading
		-- one wipes non-default highlights (catppuccin loads after `init`).
		local function highlights()
			vim.api.nvim_set_hl(0, "CodeReviewSign", { link = "DiagnosticSignHint" })
			vim.api.nvim_set_hl(0, "CodeReviewVirtualText", { link = "DiagnosticVirtualTextHint" })
		end

		highlights()

		vim.api.nvim_create_autocmd("ColorScheme", {
			group = group,
			callback = highlights,
			desc = "Keep code-review indicators legible across colorschemes",
		})
	end,

	opts = {
		output = { format = "minimal" },
		comment = { storage = { backend = "memory" } },
		keymaps = false,
		ui = {
			-- gitsigns owns `▎` in the same one-column gutter and this plugin
			-- places its signs at priority 100, so an unstyled review marker
			-- hides a git change while looking like one.
			signs = { text = "󰆉" },
		},
	},

	keys = {
		{
			"<leader>ccc",
			function()
				-- Normal mode: a count widens the captured context by N lines
				-- either side of the cursor. Visual mode ignores it.
				require("code-review").add_comment(vim.v.count > 0 and vim.v.count or nil)
			end,
			mode = { "n", "x" },
			desc = "Add review comment",
		},
		{
			"<leader>ccs",
			function()
				require("code-review").show_comment_at_cursor()
			end,
			desc = "Show comment at cursor",
		},
		{
			"<leader>ccr",
			function()
				require("code-review").reply_to_comment_at_cursor()
			end,
			desc = "Reply to comment",
		},
		{
			"<leader>ccx",
			function()
				require("code-review").resolve_thread_at_cursor()
			end,
			desc = "Resolve thread",
		},
		{
			"<leader>ccd",
			function()
				require("code-review").delete_comment_at_cursor()
			end,
			desc = "Delete comment at cursor",
		},
		{
			"<leader>ccl",
			function()
				require("code-review").list_comments()
			end,
			desc = "List review threads",
		},
		{
			"<leader>ccp",
			function()
				require("code-review").preview()
			end,
			desc = "Preview review",
		},
		{
			"<leader>ccy",
			function()
				require("code-review").copy()
			end,
			desc = "Copy review to clipboard",
		},
		{
			"<leader>ccw",
			function()
				require("code-review").save()
			end,
			desc = "Write review to file",
		},
		{
			"<leader>ccX",
			function()
				require("code-review").clear()
			end,
			desc = "Clear all review comments",
		},
	},
}
