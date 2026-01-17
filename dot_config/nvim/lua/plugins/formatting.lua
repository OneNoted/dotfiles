return {
  "stevearc/conform.nvim",
  enabled = true,
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      desc = "Format",
    },
  },
  opts = function()
    local formatters = {
      rust = { "rustfmt" },
      go = { "goimports", "gofmt" },
      nix = { "nixfmt" },
      yaml = { "prettier" },
      toml = { "taplo" },
      zig = { "zigfmt" },
      markdown = { "prettier" },
      json = { "prettier" },
      jsonc = { "prettier" },
    }

    for _, formatter_opts in pairs(formatters) do
      formatter_opts.lsp_format = "fallback"
    end

    -- Lua: use stylua if available, otherwise LSP
    formatters.lua = { "stylua", lsp_format = "fallback" }

    return {
      formatters_by_ft = formatters,
      format_on_save = {
        timeout_ms = 1000,
      },
      formatters = {
        -- Custom formatter configurations if needed
        stylua = {
          prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
        },
      },
    }
  end,
  init = function()
    -- Add format keymap to code group in which-key
    vim.g.autoformat = true
  end,
}
