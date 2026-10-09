local function find_all_files()
  Snacks.picker.files({
    hidden = true,
    ignored = true,
  })
end

vim.keymap.set("n", "<leader><space>", find_all_files, { desc = "Find Files (including hidden/ignored)" })
vim.keymap.set("n", "<leader>ff", find_all_files, { desc = "Find Files (including hidden/ignored)" })
