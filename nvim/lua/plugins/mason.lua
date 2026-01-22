-- if true then return {} end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- Customize Mason

---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = {
        -- LSPs
        "lua-language-server",
        "typescript-language-server",
        "html-lsp",
        "css-lsp",
        "tailwindcss-language-server",
        "vue-language-server", -- Vue
        "svelte-language-server", -- Svelte
        "intelephense", -- PHP
        "emmet-ls", -- Snippets HTML/CSS
        "marksman",
        "shopify-cli",

        -- Formatters
        "prettier",
        "stylua",
        "eslint_d",

        -- Debuggers
        "debugpy",

        -- Otros
        "tree-sitter-cli",
      },
    },
  },
}
