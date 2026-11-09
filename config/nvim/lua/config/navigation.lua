local M = {}

---Use native Ghostty/cmux splits only for a local session outside a multiplexer.
function M.uses_native_splits()
  return vim.env.TERM_PROGRAM == "ghostty"
    and vim.fn.has("macunix") == 1
    and not vim.env.TMUX
    and not vim.env.ZELLIJ
    and vim.env.HERDR_ENV ~= "1"
    -- herdr-core terminals may inherit TERM_PROGRAM=ghostty from their launcher.
    and not vim.env.HC_TERMINAL_ID
    and not vim.env.SSH_CONNECTION
end

return M
