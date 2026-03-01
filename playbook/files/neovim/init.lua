-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.keymap.set("n", "<F2>", "<cmd>Telescope commands<cr>", { desc = "Show all commands" })
vim.keymap.set("n", "<F3>", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "<F4>", vim.lsp.buf.references, { desc = "Go to references" })
vim.keymap.set("n", "<F5>", vim.lsp.buf.implementation, { desc = "Go to implementation" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
vim.keymap.set({ "n", "v" }, "<leader>f", function()
	require("conform").format()
end, { desc = "Format buffer" })
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>", { desc = "Clear search highlights" })

vim.api.nvim_create_autocmd("FileType", {
	pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "o" })
	end,
})
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.completeopt = { "menu", "menuone", "noselect", "preview" }

vim.diagnostic.config({
	virtual_text = true,
	signs = true,
	underline = true,
	update_in_insert = true,
})

-- Setup lazy.nvim
require("lazy").setup({
	spec = {
		{
			"Mofiqul/vscode.nvim",
			config = function()
				require("vscode").setup({
					style = "dark",
				})
				vim.cmd.colorscheme("vscode")
			end,
		},

		{
			"nvim-tree/nvim-web-devicons",
			config = function()
				require("nvim-web-devicons").setup({})
			end,
		},

		{
			"rachartier/tiny-inline-diagnostic.nvim",
			event = "VeryLazy",
			config = function()
				require("tiny-inline-diagnostic").setup({})
			end,
		},

		{
			"saecki/crates.nvim",
			ft = { "rust", "toml" },
			dependencies = { "nvim-lua/plenary.nvim" },
			config = function()
				require("crates").setup()
			end,
		},

		{ "mfussenegger/nvim-dap" },
		{ "rcarriga/nvim-dap-ui" },
		{ "theHamsta/nvim-dap-virtual-text" },
		{ "jay-babu/mason-nvim-dap.nvim" },
		{
			"HiPhish/rainbow-delimiters.nvim",
			event = "BufReadPre",
			config = function()
				require("rainbow-delimiters.setup").setup({
					strategy = {},
				})
			end,
		},

		{
			"folke/todo-comments.nvim",
			dependencies = "nvim-lua/plenary.nvim",
			event = "BufRead",
			config = function()
				require("todo-comments").setup()
			end,
			keys = {
				{ "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
			},
		},

		-- LSP и Mason
		{
			"williamboman/mason.nvim",
			config = function()
				require("mason").setup()
			end,
		},

		-- Интеграция Mason и LSPconfig
		{
			"williamboman/mason-lspconfig.nvim",
			dependencies = { "neovim/nvim-lspconfig", "williamboman/mason.nvim" },
			config = function()
				require("mason-lspconfig").setup({
					ensure_installed = {
						"bash-language-server",
						"asnsible-language-server",
						"asm-lsp",
						"ansible-lint",
						"asmfmt",
						"lua-language-server",
						"pyright",
						"cpplint",
						"cpptools",
						"codelldb",
						"stylua",
					},
					automatic_installation = true,
				})
			end,
		},

		-- Автодополнение (IntelliSense)
		{ "hrsh7th/nvim-cmp" },
		{ "hrsh7th/cmp-nvim-lsp" },
		{ "hrsh7th/cmp-buffer" },
		{ "hrsh7th/cmp-path" },
		{ "L3MON4D3/LuaSnip" },
		{ "saadparwaiz1/cmp_luasnip" },
		{ "rafamadriz/friendly-snippets" },

		-- Treesitter (подсветка и структура)
		{ "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" },

		-- Форматирование и линтинг
		{
			"stevearc/conform.nvim",
			config = function()
				require("conform").setup({
					formatters_by_ft = {
						lua = { "stylua" },
						python = { "black" },
						rust = { "rustfmt" },
					},
					formatters = {
						stylua = {
							args = {
								"--search-parent-directories",
								"--stdin-filepath",
								"$FILENAME",
								"-",
							},
						},
					},
					format_on_save = {
						timeout_ms = 500,
						lsp_format = "fallback",
					},
				})
			end,
		},

		{ "mfussenegger/nvim-lint" },

		-- Файловый менеджер
		{
			"nvim-tree/nvim-tree.lua",
			dependencies = { "nvim-tree/nvim-web-devicons" },
			config = function()
				require("nvim-tree").setup()
			end,
		},

		-- Поиск (Telescope)
		{ "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },

		-- Статусная строка
		{
			"nvim-lualine/lualine.nvim",
			config = function()
				require("lualine").setup({
					options = {
						theme = "auto", -- автоматически подстраивается под тему
						section_separators = { left = "", right = "" }, -- убрать разделители
						component_separators = { left = "", right = "" },
					},
					sections = {
						lualine_a = { "mode" }, -- режим (Normal, Insert и т.д.)
						lualine_b = { "branch", "diff", "diagnostics" },
						lualine_c = { "filename" },
						lualine_x = { "encoding", "fileformat", "filetype" },
						lualine_y = { "progress" },
						lualine_z = { "location" },
					},
				})
			end,
		},

		-- Вкладки (буферы)
		{ "akinsho/bufferline.nvim" },

		-- Терминал
		{ "akinsho/toggleterm.nvim" },

		-- Git
		{ "lewis6991/gitsigns.nvim" },

		-- Комментарии
		{ "numToStr/Comment.nvim" },

		-- Автопары
		{
			"windwp/nvim-autopairs",
			event = "InsertEnter",
			config = function()
				require("nvim-autopairs").setup({
					enable_check_bracket_line = false,
					map_cr = true,
					map_char = {
						all = "(",
					},
				})
			end,
		},

		-- Отступы
		{ "lukas-reineke/indent-blankline.nvim" },

		-- Подсказки клавиш
		{ "folke/which-key.nvim" },

		{
			"mrcjkb/rustaceanvim",
			ft = { "rust" },
			config = function()
				vim.g.rustaceanvim = {
					server = {
						on_attach = function(client, bufnr)
							-- ваши маппинги клавиш
						end,
						default_settings = {
							["rust-analyzer"] = {
								diagnostics = {
									enable = true,
									enableExperimental = true,
									disabled = {},
								},
								checkOnSave = true,
								check = {
									command = "clippy",
								},
							},
							completion = {
								autoimport = { enable = true },
								autoself = { enable = true },
								fullfilling = { enable = true },
							},
						},
					},
				}
			end,
		},
		{ "someone-stole-my-name/yaml-companion.nvim", ft = { "yaml", "yml" } },
		{
			"sontungexpt/url-open",
			config = true,
			keys = {
				{ "gx", "<cmd>URLOpenUnderCursor<CR>", desc = "Open URL under cursor" },
			},
		},
	},
})

require("mason-lspconfig").setup({
	ensure_installed = {
		"pyright",
		"lua_ls",
		"bashls",
		"ansiblels",
		"yamlls",
		"taplo",
	},
})

local dap = require("dap")
dap.adapters.codelldb = {
	type = "server",
	port = "${port}",
	executable = {
		command = "codelldb",
		args = { "--port", "${port}" },
	},
}

local cmp = require("cmp")
cmp.setup({
	completion = {
		autocomplete = {
			require("cmp.types").cmp.TriggerEvent.InsertEnter,
			require("cmp.types").cmp.TriggerEvent.TextChanged,
		},
	},
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
		["<Tab>"] = cmp.mapping.select_next_item(),
		["<S-Tab>"] = cmp.mapping.select_prev_item(),
		["<Esc>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.abort() -- закрыть меню, оставаясь в режиме вставки
			else
				fallback() -- стандартное поведение Esc (выход в нормальный режим)
			end
		end, { "i", "s" }),
	}),
	sources = {
		{ name = "nvim_lsp" },
		{ name = "buffer" },
		{ name = "path" },
	},
})
