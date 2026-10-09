local active = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
if vim.fn.filereadable(active) == 1 then
  return dofile(active)
end

return {
  { "ellisonleao/gruvbox.nvim" },
  { "LazyVim/LazyVim", opts = { colorscheme = "gruvbox" } },
}
