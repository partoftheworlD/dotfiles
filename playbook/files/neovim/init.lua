-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
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
vim.keymap.set({ "n", "v" }, "<leader>f", function()
    require("conform").format()
end, { desc = "Format buffer" })
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>", { desc = "Clear search highlights" })
vim.keymap.set("v", "<leader>/", "gc", { desc = "Toggle line comment" })
vim.keymap.set("v", "<leader><leader>/", "gb", { desc = "Toggle block comment" })
vim.keymap.set("n", "<leader>fc", "zc", { desc = "Fold close" })
vim.keymap.set("n", "<leader>fo", "zo", { desc = "Fold open" })
vim.keymap.set("n", "<leader>fM", "zM", { desc = "Fold all" })
vim.keymap.set("n", "<leader>fR", "zR", { desc = "Fold all open" })

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
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldcolumn = "1"
vim.opt.foldlevelstart = 99
vim.opt.foldlevel = 99
vim.opt.colorcolumn = "80"
vim.api.nvim_create_autocmd("Filetype", { pattern = "rust", command = "set colorcolumn=100" })

-- Setup lazy.nvim
require("lazy").setup({
    spec = {
        {
            "mofiqul/vscode.nvim",
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
        {
            "lukas-reineke/indent-blankline.nvim",
            main = "ibl",
            ---@module "ibl"
            ---@type ibl.config
            opts = {},
            config = function()
                local highlight = {
                    "RainbowRed",
                    "RainbowYellow",
                    "RainbowBlue",
                    "RainbowOrange",
                    "RainbowGreen",
                    "RainbowViolet",
                    "RainbowCyan",
                }

                local hooks = require("ibl.hooks")
                -- create the highlight groups in the highlight setup hook, so they are reset
                -- every time the colorscheme changes
                hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
                    vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
                    vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
                    vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
                    vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
                    vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
                    vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
                    vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
                end)

                require("ibl").setup({ indent = { highlight = highlight } })
            end,
        },

        { "mfussenegger/nvim-dap" },
        { "rcarriga/nvim-dap-ui" },
        { "thehamsta/nvim-dap-virtual-text" },
        { "jay-babu/mason-nvim-dap.nvim" },
        {
            "folke/todo-comments.nvim",
            dependencies = "nvim-lua/plenary.nvim",
            event = "bufread",
            config = function()
                require("todo-comments").setup()
            end,
            keys = {
                { "<leader>st", "<cmd>todotelescope<cr>", desc = "find todos" },
            },
        },

        -- lsp и mason
        {
            "williamboman/mason.nvim",
            config = function()
                require("mason").setup()
            end,
        },

        -- интеграция mason и lspconfig
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
                        "basedpyright",
                        "cpplint",
                        "cpptools",
                        "codelldb",
                        "stylua",
                    },
                    automatic_installation = true,
                })
            end,
        },

        -- автодополнение (intellisense)
        { "hrsh7th/nvim-cmp" },
        { "hrsh7th/cmp-nvim-lsp" },
        { "hrsh7th/cmp-buffer" },
        { "hrsh7th/cmp-path" },
        { "l3mon4d3/luasnip" },
        { "saadparwaiz1/cmp_luasnip" },
        { "rafamadriz/friendly-snippets" },

        -- treesitter (подсветка и структура)
        {
            "nvim-treesitter/nvim-treesitter",
            build = ":tsupdate",
            config = function()
                require("nvim-treesitter").setup({
                    ensure_installed = {
                        "python",
                        "lua",
                        "vim",
                        "vimdoc",
                        "rust",
                        "cpp",
                        "bash",
                        "c",
                        "yaml",
                        "ansible",
                    },
                    highlight = {
                        enable = true,
                        additional_vim_regex_highlighting = false,
                    },
                    fold = { enable = true },
                })
            end,
        },

        -- форматирование и линтинг
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
                                "$filename",
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
        { "nvim-telescope/telescope.nvim",            dependencies = { "nvim-lua/plenary.nvim" } },
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },

        -- Статусная строка
        {
            "nvim-lualine/lualine.nvim",
            config = function()
                require("lualine").setup({
                    options = {
                        theme = "auto",
                        section_separators = { left = "", right = "" },
                        component_separators = { left = "", right = "" },
                    },
                    sections = {
                        lualine_a = { "mode" },
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
            "neovim/nvim-lspconfig",
            config = function()
                -- Setup language servers.

                -- Rust
                vim.lsp.config("rust_analyzer", {
                    -- Server-specific settings. See `:help lspconfig-setup`
                    settings = {
                        ["rust-analyzer"] = {
                            cargo = {
                                features = "all",
                            },
                            checkOnSave = {
                                enable = true,
                            },
                            check = {
                                command = "clippy",
                            },
                            imports = {
                                group = {
                                    enable = false,
                                },
                            },
                            completion = {
                                postfix = {
                                    enable = false,
                                },
                            },
                        },
                    },
                })
                vim.lsp.enable("rust_analyzer")

                -- Bash LSP
                if vim.fn.executable("bash-language-server") == 1 then
                    vim.lsp.enable("bashls")
                end

                -- Ruff for Python
                if vim.fn.executable("ruff") == 1 then
                    vim.lsp.enable("ruff")
                end

                -- Global mappings.
                -- See `:help vim.diagnostic.*` for documentation on any of the below functions
                vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float)
                vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
                vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
                vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist)

                -- Use LspAttach autocommand to only map the following keys
                -- after the language server attaches to the current buffer
                vim.api.nvim_create_autocmd("LspAttach", {
                    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
                    callback = function(ev)
                        -- Enable completion triggered by <c-x><c-o>
                        vim.bo[ev.buf].omnifunc = "v:lua.vim.lsp.omnifunc"

                        -- Buffer local mappings.
                        -- See `:help vim.lsp.*` for documentation on any of the below functions
                        local opts = { buffer = ev.buf }
                        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
                        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
                        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
                        vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
                        vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
                        vim.keymap.set("n", "<leader>wl", function()
                            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                        end, opts)
                        --vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
                        vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
                        vim.keymap.set({ "n", "v" }, "<leader>a", vim.lsp.buf.code_action, opts)
                        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
                        vim.keymap.set("n", "<leader>f", function()
                            vim.lsp.buf.format({ async = true })
                        end, opts)

                        local client = vim.lsp.get_client_by_id(ev.data.client_id)

                        -- TODO: find some way to make this only apply to the current line.
                        if client.server_capabilities.inlayHintProvider then
                            vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
                        end

                        -- None of this semantics tokens business.
                        -- https://www.reddit.com/r/neovim/comments/143efmd/is_it_possible_to_disable_treesitter_completely/
                        client.server_capabilities.semanticTokensProvider = nil

                        -- format on save for Rust
                        if client.server_capabilities.documentFormattingProvider then
                            vim.api.nvim_create_autocmd("BufWritePre", {
                                group = vim.api.nvim_create_augroup("RustFormat", { clear = true }),
                                buffer = bufnr,
                                callback = function()
                                    vim.lsp.buf.format({ bufnr = bufnr })
                                end,
                            })
                        end
                    end,
                })
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
        {
            "numToStr/Comment.nvim",
            config = function()
                require("Comment").setup()
            end,
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
                cmp.abort()
            else
                fallback()
            end
        end, { "i", "s" }),
    }),
    sources = {
        { name = "nvim_lsp" },
        { name = "buffer" },
        { name = "path" },
    },
})

vim.api.nvim_set_hl(0, "@markup.raw", { fg = "#FFA500" })

