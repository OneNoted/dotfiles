return {
  {
    "alker0/chezmoi.vim",
    lazy = false,
    init = function()
      vim.g["chezmoi#use_tmp_buffer"] = 1

      -- fix chezmoi.vim being evil and defaulting to "~/.local/share/chezmoi"
      vim.g["chezmoi#use_external"] = 1
    end,
  },

  {
    "xvzc/chezmoi.nvim",

    init = function()
      -- auto chezmoi apply and enter when editing source files
      vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
        pattern = { vim.env.HOME .. "/Chezmoi/Source/*" },
        callback = function()
          vim.schedule(require("chezmoi.commands.__edit").watch)
        end,
      })

      -- Cache for managed files (to avoid calling chezmoi on every save)
      local managed_files_cache = {}
      local cache_checked = false

      -- Function to check if a file is managed by chezmoi
      local function is_chezmoi_managed(filepath)
        -- Build cache on first check
        if not cache_checked then
          local result = vim.fn.systemlist("chezmoi managed --include=files 2>/dev/null")
          if vim.v.shell_error == 0 then
            for _, file in ipairs(result) do
              -- chezmoi managed returns paths relative to home
              local full_path = vim.env.HOME .. "/" .. file
              managed_files_cache[full_path] = true
            end
          end
          cache_checked = true
        end
        return managed_files_cache[filepath] == true
      end

      -- Auto re-add managed files on save
      vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("chezmoi_auto_add", { clear = true }),
        callback = function(event)
          local filepath = vim.fn.expand("%:p")
          if is_chezmoi_managed(filepath) then
            vim.fn.jobstart({ "chezmoi", "re-add", filepath }, {
              on_exit = function(_, code)
                if code == 0 then
                  vim.notify("Chezmoi: re-added " .. vim.fn.fnamemodify(filepath, ":~"), vim.log.levels.INFO)
                else
                  vim.notify("Chezmoi: failed to re-add " .. filepath, vim.log.levels.ERROR)
                end
              end,
            })
          end
        end,
      })

      -- Command to refresh the managed files cache
      vim.api.nvim_create_user_command("ChezmoiRefreshCache", function()
        managed_files_cache = {}
        cache_checked = false
        vim.notify("Chezmoi managed files cache cleared", vim.log.levels.INFO)
      end, { desc = "Refresh chezmoi managed files cache" })
    end,
  },
}
