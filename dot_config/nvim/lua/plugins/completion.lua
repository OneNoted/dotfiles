-- Completions with nvim-cmp and mini.snippets
-- Source order: nvim_lsp first, then snippets, then buffer (after 3 chars), then path

return {
  -- Snippet engine with friendly-snippets
  {
    "echasnovski/mini.snippets",
    event = "InsertEnter",
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = function()
      local snippets = require("mini.snippets")
      return {
        snippets = {
          snippets.gen_loader.from_lang(),
        },
      }
    end,
  },

  -- Completion nvim-cmp
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "abeldekat/cmp-mini-snippets",
    },
    config = function()
      local cmp = require("cmp")

      cmp.setup({
        snippet = {
          expand = function(args)
            local insert = MiniSnippets.config.expand.insert or MiniSnippets.default_insert
            insert({ body = args.body })
            cmp.resubscribe({ "TextChangedI", "TextChangedP" })
            require("cmp.config").set_onetime({ sources = {} })
          end,
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "mini_snippets" },
        }, {
          { name = "buffer", keyword_length = 3 },
          { name = "path" },
        }),
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            local copilot_ok, copilot = pcall(require, "copilot.suggestion")
            if copilot_ok and copilot.is_visible() then
              copilot.accept()
            elseif cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        formatting = {
          format = function(entry, vim_item)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              mini_snippets = "[Snip]",
              buffer = "[Buf]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })
    end,
  },
}
