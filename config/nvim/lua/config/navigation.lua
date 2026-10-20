local M = {}

---Use native Ghostty/cmux splits only for a local session outside a multiplexer.
function M.uses_native_splits()
  return vim.env.TERM_PROGRAM == "ghostty"
    and vim.fn.has("macunix") == 1
    and not vim.env.TMUX
    and not vim.env.ZELLIJ
    and not vim.env.SSH_CONNECTION
end

return M
