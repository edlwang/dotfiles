-- On Windows, Neovim picks up $SHELL (Git Bash exports it as bash.exe) for
-- 'shell' but keeps the cmd.exe defaults for the rest of the shell* options.
-- The mismatch means every shell-out (toggleterm, :terminal, :!, :make) runs
--   bash.exe /s /c <cmd>
-- and bash reads "/s" as a script to execute -> "/s: No such file or directory",
-- so the terminal errors out and closes instantly. When the resolved shell is a
-- POSIX shell, switch the shell* options to their POSIX forms.
local function is_posix_shell(path)
	-- Neovim quotes the path when it contains a space (e.g. "Program Files"),
	-- so strip quotes before pulling out the basename.
	local base = path:lower():gsub('"', ""):gsub("\\", "/"):match("([^/]+)$") or path
	base = base:gsub("%.exe$", "")
	return base == "bash" or base == "sh" or base == "zsh" or base == "dash" or base == "fish"
end

if vim.fn.has("win32") == 1 and is_posix_shell(vim.o.shell) then
	vim.o.shellcmdflag = "-c"
	vim.o.shellxquote = ""
	vim.o.shellquote = ""
	vim.o.shellredir = ">%s 2>&1"
	vim.o.shellpipe = "2>&1 | tee"
end
