-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- The login shell ($SHELL) is nushell. Neovim's shell options (shellcmdflag,
-- shellredir, shellpipe, …) assume a POSIX shell, so :!, :make, :grep and
-- string-form system() calls would break under nu. Use zsh instead;
-- `:terminal nu` still opens a nu terminal.
vim.o.shell = "zsh"
