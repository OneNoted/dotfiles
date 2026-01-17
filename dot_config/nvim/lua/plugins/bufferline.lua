-- lua/plugins/bufferline.lua
return {
  "akinsho/bufferline.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "echasnovski/mini.bufremove",
  },
  opts = function()
    local diag_icons = {
      Error = " ",
      Warn = " ",
      Info = " ",
      Hint = "󰌵 ",
    }

    local function bufdelete(bufnr)
      require("mini.bufremove").delete(bufnr, false)
    end

    return {
      options = {
        close_command = bufdelete,
        right_mouse_command = bufdelete,

        diagnostics = "nvim_lsp",
        always_show_bufferline = false,

        diagnostics_indicator = function(_, _, diag)
          local ret = ""
          if diag.error and diag.error > 0 then
            ret = ret .. diag_icons.Error .. diag.error .. " "
          end
          if diag.warning and diag.warning > 0 then
            ret = ret .. diag_icons.Warn .. diag.warning
          end
          return vim.trim(ret)
        end,

        offsets = {
          {
            filetype = "neo-tree",
            text = "Neo-tree",
            highlight = "Directory",
            text_align = "left",
          },
          {
            filetype = "snacks_layout_box",
          },
        },

        ---@param opts bufferline.IconFetcherOpts
        get_element_icon = function(opts)
          local devicons = require("nvim-web-devicons")
          local icon, hl = devicons.get_icon_by_filetype(opts.filetype, { default = true })
          return icon, hl
        end,
      },
    }
  end,
  config = function(_, opts)
    require("bufferline").setup(opts)

    -- Small safety refresh: helps keep tabline correct after session restores / buffer churn
    vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
      callback = function()
        vim.schedule(function()
          pcall(function()
            vim.cmd("redrawtabline")
          end)
        end)
      end,
    })
  end,
}
