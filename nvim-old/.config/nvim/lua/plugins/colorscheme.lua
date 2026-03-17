return {
  -- {
  -- 	"loctvl842/monokai-pro.nvim",
  -- 	config = function()
  -- 		require("monokai-pro").setup({
  -- 			transparent_background = false,
  -- 			styles = {
  -- 				comment = { italic = true },
  -- 				keyword = { italic = true }, -- any other keyword
  -- 				type = { italic = true }, -- (preferred) int, long, char, etc
  -- 				storageclass = { italic = true }, -- static, register, volatile, etc
  -- 				structure = { italic = true }, -- struct, union, enum, etc
  -- 				parameter = { italic = true }, -- parameter pass in function
  -- 				annotation = { italic = true },
  -- 				tag_attribute = { italic = true }, -- attribute of tag in reactjs
  -- 			},
  -- 			filter = "pro",
  -- 			inc_search = "background", -- "background" | "underline"
  -- 			background_clear = {
  -- 				-- "float_win",
  -- 				"toggleterm",
  -- 				"telescope",
  -- 				-- "which-key",
  -- 				"renamer",
  -- 				"notify",
  -- 				-- "nvim-tree",
  -- 				-- "neo-tree",
  -- 				-- "bufferline", -- better used if background of `neo-tree` or `nvim-tree` is cleared
  -- 			}, -- "float_win", "togg
  -- 			plugins = {
  -- 				bufferline = {
  -- 					underline_selected = false,
  -- 					underline_visible = false,
  -- 				},
  -- 				indent_blankline = {
  -- 					context_highlight = "default", -- default | pro
  -- 					context_start_underline = false,
  -- 				},
  -- 			},
  -- 		})
  -- 		vim.cmd([[colorscheme monokai-pro]])
  -- 	end,
  -- },
  -- {
  --   "navarasu/onedark.nvim",
  --   config = function()
  --     require("onedark").setup({
  --       style = "warmer",
  --       transparent = false,
  --       code_style = {
  --         comments = "italic",
  --         keywords = "italic",
  --         parameter = "italic",
  --         strings = "none",
  --         variables = "none",
  --         structure = "italic",
  --       },
  --     })
  --     vim.cmd([[colorscheme onedark]])
  --   end,
  -- }
  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      require("rose-pine").setup({
        variant = "main",      -- auto, main, moon, or dawn
        dark_variant = "main", -- main, moon, or dawn
        dim_inactive_windows = true,
        extend_background_behind_borders = true,

        enable = {
          terminal = true,
          legacy_highlights = true, -- Improve compatibility for previous versions of Neovim
          migrations = true,        -- Handle deprecated options automatically
        },

        styles = {
          bold = true,
          -- italic = true,
          transparency = false,
        },

        groups = {
          border = "muted",
          link = "iris",
          panel = "surface",

          error = "love",
          hint = "iris",
          info = "foam",
          note = "pine",
          todo = "rose",
          warn = "gold",

          git_add = "foam",
          git_change = "rose",
          git_delete = "love",
          git_dirty = "rose",
          git_ignore = "muted",
          git_merge = "iris",
          git_rename = "pine",
          git_stage = "iris",
          git_text = "rose",
          git_untracked = "subtle",

          h1 = "iris",
          h2 = "foam",
          h3 = "rose",
          h4 = "gold",
          h5 = "pine",
          h6 = "foam",
        },
        disable_italics = true,
        highlight_groups = {
          Comment = { italic = true },
          Keyword = { italic = true },
          Parameter = { italic = true },
          Constant = { italic = true },
          Structure = { italic = true },
        },

        before_highlight = function(group, highlight, palette)
          -- Disable all undercurls
          -- if highlight.undercurl then
          --     highlight.undercurl = false
          -- end
          --
          -- Change palette colour
          -- if highlight.fg == palette.pine then
          --     highlight.fg = palette.foam
          -- end
        end,
      })
      vim.cmd([[colorscheme rose-pine]])
    end,
    -- vim.cmd("colorscheme rose-pine-main")
    -- vim.cmd("colorscheme rose-pine-moon")
    -- vim.cmd("colorscheme rose-pine-dawn")
  },
}
