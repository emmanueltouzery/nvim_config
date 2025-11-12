require 'key-menu'.set('n', '<localleader>t', {desc='Toggle overseer features...', buffer=true})
vim.keymap.set("n", "<localleader>ta", function()
  if vim.g.overseer_disable_autodispose then
    notif({"Enabling overseer autodispose"})
    vim.g.overseer_disable_autodispose = false
  else
    notif({"Disabling overseer autodispose"})
    vim.g.overseer_disable_autodispose = true
  end
end, {desc="Toggle overseer job autodispose", buffer=true})
