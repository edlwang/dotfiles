-- No installed plugin uses the remote-plugin host providers (python3/node/ruby/
-- perl). Setting these to 0 short-circuits the provider autoload guard, which
-- silences the 6 :checkhealth vim.provider warnings and prevents the on-demand
-- interpreter probing detection would otherwise do (e.g. spawning python to test
-- `import pynvim`). Use the integer 0, not false: these are numeric Vimscript
-- flags the runtime compares against (0 = disabled, 2 = loaded). Disabling does
-- NOT affect markdown-preview's npx shell-out, nor the pyenv/py313 venv (:!python).
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
