return {
    "nvim-treesitter/nvim-treesitter",
    -- 'main' is the rewrite and is now upstream's default branch. Differences that
    -- shaped the config below: no nvim-treesitter.configs, parsers install into
    -- stdpath('data')/site instead of the plugin dir, highlight/indent are opt-in
    -- per buffer, and there is no ensure_installed/auto_install option.
    -- Needs the tree-sitter CLI (>= 0.26.1) on PATH; `brew install tree-sitter`.
    branch = "main",
    lazy = false, -- upstream does not support lazy-loading this branch
    build = ":TSUpdate",
    config = function()
        local ts = require("nvim-treesitter")
        ts.setup({ install_dir = vim.fn.stdpath("data") .. "/site" })

        local ensure_installed = {
            "c",
            "lua",
            "vim",
            "javascript",
            "typescript",
            "tsx",
            "html",
            "go",
            "gomod",
            "gowork",
            "gosum",
            "java",
            "json",
            "zig",
            "http",
            "yaml",
            "sql",
            "gotmpl",
            "comment",
            -- xcodebuild.nvim needs this to read Quick-framework test results
            "swift",
        }

        -- Cached so the FileType handler below doesn't glob the parser dir on every
        -- buffer; refreshed whenever we install something.
        local installed = {}
        local function refresh_installed()
            installed = {}
            for _, lang in ipairs(ts.get_installed("parsers")) do
                installed[lang] = true
            end
        end
        refresh_installed()

        local missing = vim.tbl_filter(function(lang)
            return not installed[lang]
        end, ensure_installed)
        if #missing > 0 then
            ts.install(missing):await(vim.schedule_wrap(refresh_installed))
        end

        -- master enabled highlight and indent globally; on main every buffer opts in.
        -- The install branch stands in for the old auto_install = true.
        local requested = {}
        local function start(buf, lang)
            if not vim.api.nvim_buf_is_valid(buf) then
                return
            end
            if not pcall(vim.treesitter.start, buf, lang) then
                return
            end
            vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end

        vim.api.nvim_create_autocmd("FileType", {
            group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
            callback = function(ev)
                -- compound filetypes ('yaml.docker-compose') have no parser of their
                -- own, so fall back to the leading component
                local lang = vim.treesitter.language.get_lang(ev.match)
                    or vim.treesitter.language.get_lang(ev.match:match("^[^.]+") or "")
                if not lang then
                    return
                end
                if installed[lang] then
                    start(ev.buf, lang)
                elseif not requested[lang] and vim.tbl_contains(ts.get_available(), lang) then
                    -- one attempt per language per session, so a parser that fails to
                    -- build doesn't get retried on every buffer of that filetype
                    requested[lang] = true
                    ts.install(lang):await(vim.schedule_wrap(function()
                        refresh_installed()
                        if installed[lang] then
                            start(ev.buf, lang)
                        end
                    end))
                end
            end,
        })
    end,
}
