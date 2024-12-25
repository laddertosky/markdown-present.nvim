vim.api.nvim_create_user_command("Present", function()
	require("markdown-present").start_present()
end, {})
