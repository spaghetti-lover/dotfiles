return {
    {
        -- both repos moved from williamboman/ to mason-org/ with the 2.0 release
        "mason-org/mason.nvim",
        config = function()
            require("mason").setup()
        end,
    },
    {
        "mason-org/mason-lspconfig.nvim",
        lazy = false,
        -- v2 needs mason set up first, and lspconfig >= 2.0 present
        dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
        opts = {
            -- v2 enables every installed server through vim.lsp.enable() by default.
            -- The list at the bottom of this file is curated on purpose, so keep the
            -- automatic pass off and let that list stay the single source of truth.
            automatic_enable = false,
            -- manually install packages that do not exist in this list please.
            -- everything enabled in vim.lsp.enable() below should be listed here,
            -- otherwise the server is configured but its binary never gets installed.
            ensure_installed = {
                "zls",
                "gopls",
                "ts_ls",
                "eslint",
                "tailwindcss",
                "svelte",
                "yamlls",
                "bashls",
                "buf_ls",
                "docker_compose_language_service",
            },
        },
    },
    {
        "neovim/nvim-lspconfig",
        lazy = false,
        config = function()
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

            -- docker_compose_language_service only ever attaches to the compound
            -- filetype 'yaml.docker-compose', which Neovim never sets on its own, so
            -- the server below was enabled but dead. The dotted name keeps yamlls
            -- attached too, since FileType matches each component.
            vim.filetype.add({
                filename = {
                    ["docker-compose.yml"] = "yaml.docker-compose",
                    ["docker-compose.yaml"] = "yaml.docker-compose",
                    ["compose.yml"] = "yaml.docker-compose",
                    ["compose.yaml"] = "yaml.docker-compose",
                },
            })

            -- Several upstream configs advertise VS Code language IDs that Neovim has
            -- no filetype for (mdx, njk, erb, buf-config, gotmpl, ...). They can never
            -- match a buffer, so they do nothing except fill :checkhealth vim.lsp with
            -- "Unknown filetype" warnings. Recomputed on every start, and after the
            -- vim.filetype.add above, so anything Neovim can actually detect is kept.
            local function known_filetypes(server)
                local base = vim.lsp.config[server]
                local filetypes = base and base.filetypes
                local ok, known = pcall(vim.filetype._get_known_filetypes)
                if not filetypes or not ok then
                    return filetypes
                end
                return vim.tbl_filter(function(ft)
                    return known[ft]
                end, filetypes)
            end

            -- lua
            vim.lsp.config["lua_ls"] = {
                cmd = { "lua-language-server" },
                capabilities = capabilities,
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = false,
                        },
                        telemetry = { enable = false },
                    },
                },
            }
            vim.lsp.enable("lua_ls")

            -- apple development
            local default_inlay_hint_handler = vim.lsp.handlers["textDocument/inlayHint"]

            vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, config)
                if err then
                    local msg = err.message or ""
                    if string.match(msg, "inlay hints failed") or err.code == -32802 or err.code == -32001 then
                        return
                    end
                end

                if default_inlay_hint_handler then
                    return default_inlay_hint_handler(err, result, ctx, config)
                end
            end

            local is_mac = vim.fn.has("mac") == 1
            if is_mac then
                vim.lsp.config["swift_mesonls"] = { -- sourcekit doesn't work, so it's a fake name
                    capabilities = capabilities,
                    root_dir = require("lspconfig.util").root_pattern(
                        "Package.swift",
                        "Project.swift",
                        ".git",
                        "*.xcodeproj",
                        "*.xcworkspace"
                    ),
                    cmd = { "xcrun", "--find", "sourcekit-lsp" },
                    on_attach = function(client, bufnr)
                        if vim.lsp.inlay_hint then
                            vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
                        end
                        client.server_capabilities.inlayHintProvider = false
                    end,
                }
            end
            -- apple development

            vim.lsp.config["rust_analyzer"] = {
                capabilities = capabilities,
            }

            vim.lsp.config["ts_ls"] = {
                capabilities = capabilities,
            }

            vim.lsp.config["eslint"] = {
                capabilities = capabilities,
            }

            vim.lsp.config["zls"] = {
                capabilities = capabilities,
            }

            vim.lsp.config["yamlls"] = {
                capabilities = capabilities,
                filetypes = known_filetypes("yamlls"),
            }

            vim.lsp.config["tailwindcss"] = {
                capabilities = capabilities,
                filetypes = known_filetypes("tailwindcss"),
            }

            vim.lsp.config["gopls"] = {
                capabilities = capabilities,
                filetypes = known_filetypes("gopls"),
            }

            -- nix
            vim.lsp.config["nil_ls"] = {
                capabilities = capabilities,
            }

            -- protocol buffer
            vim.lsp.config["buf_ls"] = {
                capabilities = capabilities,
                filetypes = known_filetypes("buf_ls"),
            }

            -- docker compose
            vim.lsp.config["docker_compose_language_service"] = {
                capabilities = capabilities,
            }

            -- cobol
            vim.lsp.config["cobol_ls"] = {
                capabilities = capabilities,
            }

            -- svelte
            vim.lsp.config["svelte"] = {
                capabilities = capabilities,
            }
            -- python
            vim.lsp.config["pyright"] = {
                capabilities = capabilities,
            }

            -- bash
            vim.lsp.config["bashls"] = {
                capabilities = capabilities,
            }

            vim.lsp.config["asm_lsp"] = {
                capabilities = capabilities,
            }

            -- Only enable servers whose binary is actually installed, otherwise
            -- :checkhealth reports "not executable. Configuration will not be used".
            -- The configs above are kept ready, so re-enabling one is a single line
            -- here plus adding it to mason's ensure_installed.
            vim.lsp.enable({
                "ts_ls",
                "eslint",
                "zls",
                "yamlls",
                "tailwindcss",
                "gopls",
                "buf_ls",
                "docker_compose_language_service",
                "svelte",
                "bashls",
                "sourcekit",
            })
            -- lsp kepmap setting
            vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {})
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, {})
            vim.keymap.set("n", "gr", vim.lsp.buf.references, {})
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
            vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
            -- list all methods in a file
            -- working with go confirmed, don't know about other, keep changing as necessary
            vim.keymap.set("n", "<leader>fm", function()
                local filetype = vim.bo.filetype
                local symbols_map = {
                    python = "function",
                    javascript = "function",
                    typescript = "function",
                    java = "class",
                    lua = "function",
                    go = { "method", "struct", "interface" },
                }
                local symbols = symbols_map[filetype] or "function"
                require("fzf-lua").lsp_document_symbols({ symbols = symbols })
            end, {})
        end,
    },
}
