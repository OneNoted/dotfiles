return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPost", "BufNewFile", "BufWritePost" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      go = { "golangcilint" },
      -- Note: Rust linting via rust-analyzer/clippy (rustaceanvim)
      -- Note: Lua linting via lua_ls
      -- Note: Nix linting via nil_ls
    }

    -- Create autocmd to run linting
    vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
      group = vim.api.nvim_create_augroup("user_lint", { clear = true }),
      callback = function()
        -- Don't lint if buffer is not a normal file
        if vim.bo.buftype ~= "" then
          return
        end
        lint.try_lint()
      end,
    })
  end,
}
