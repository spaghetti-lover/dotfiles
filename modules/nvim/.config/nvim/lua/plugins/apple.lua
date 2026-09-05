local is_mac = vim.fn.has("mac") == 1

-- Loading this outside an Xcode/SPM project only costs startup time and fills
-- :checkhealth with "no buildServer.json / did you run this from the project root?".
-- Everything it does (keymaps, the dap swift config, the project_manager hooks that
-- watch file creation) is wanted eagerly inside such a project, so gate on the tree
-- instead of lazy-loading on a swift buffer.
local function in_xcode_project()
    local markers = vim.fs.find(function(name)
        return name:match("%.xcodeproj$") or name:match("%.xcworkspace$") or name == "Package.swift"
    end, { upward = true, path = vim.fn.getcwd(), limit = 1 })
    return #markers > 0
end

return {
    "wojciech-kulik/xcodebuild.nvim",
    enabled = is_mac,
    cond = in_xcode_project,
    dependencies = {
        "ibhagwan/fzf-lua",
        "MunifTanjim/nui.nvim",
        -- "nvim-tree/nvim-tree.lua",
        "stevearc/oil.nvim",
        -- must load before the dap integration below registers the swift config
        "mfussenegger/nvim-dap",
    },
    config = function()
        require("xcodebuild").setup({
            show_build_progress_bar = true,
            logs = {
                auto_open_on_success_tests = false,
                auto_open_on_failed_tests = false,
                auto_open_on_success_build = false,
                auto_open_on_failed_build = true,
                auto_focus = false,
                auto_close_on_app_launch = true,
            },
            code_coverage = {
                enabled = true,
            },
            project_manager = {
                should_update_project = function(path)
                    -- Only manage files that live next to an .xcodeproj.
                    -- Walk up from the file; if we find a sibling *.xcodeproj
                    -- before leaving the repo, accept. Otherwise skip.
                    local dir = path:match("(.*/)")
                    while dir and #dir > 1 do
                        if vim.fn.glob(dir .. "*.xcodeproj") ~= "" then
                            -- still skip SPM/build noise inside the iOS tree
                            if path:match("/%.build/") then return false end
                            if path:match("/DerivedData/") then return false end
                            if path:match("/%.swiftpm/") then return false end
                            return true
                        end
                        dir = dir:match("(.*/)[^/]+/$")
                    end
                    return false
                end,
            },
        })

        -- registers the lldb-dap adapter and the swift configuration on nvim-dap.
        -- Xcode 16+ ships lldb-dap, so codelldb is not needed.
        require("xcodebuild.integrations.dap").setup()

        vim.keymap.set("n", "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", { desc = "Toggle Xcodebuild Logs" })
        vim.keymap.set("n", "<leader>xb", "<cmd>XcodebuildBuild<cr>", { desc = "Build Project" })
        vim.keymap.set("n", "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", { desc = "Build & Run Project" })
        vim.keymap.set("n", "<leader>xt", "<cmd>XcodebuildTest<cr>", { desc = "Run Tests" })
        vim.keymap.set("n", "<leader>xT", "<cmd>XcodebuildTestClass<cr>", { desc = "Run This Test Class" })
        vim.keymap.set("n", "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", { desc = "Select Device/Simulator" })
        vim.keymap.set("n", "<leader>xp", "<cmd>XcodebuildSelectProject<cr>", { desc = "Select Project/Workspace" })
        vim.keymap.set("n", "<leader>xD", "<cmd>XcodebuildBuildDebug<cr>", { desc = "Build & Debug" })
        vim.keymap.set("n", "<leader>xa", "<cmd>XcodebuildAttachDebugger<cr>", { desc = "Attach Debugger" })
    end,
}
