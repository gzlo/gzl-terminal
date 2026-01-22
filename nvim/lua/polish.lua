-- if true then return end -- WARN: REMOVE THIS LINE TO ACTIVATE THIS FILE

-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here
--
-- mappings for vim panel better
return function()
  -- Solo si NO está corriendo dentro de tmux
  if not os.getenv "TMUX" then
    vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Mover ventana a la izquierda" })
    vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Mover ventana abajo" })
    vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Mover ventana arriba" })
    vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Mover ventana a la derecha" })
  end
end
