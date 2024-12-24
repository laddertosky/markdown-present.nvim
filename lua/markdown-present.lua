local M = {}

--- @return string[]
local parse_markdown = function(opts)
	opts = opts or {}
	opts.bufno = opts.bufno or vim.api.nvim_get_current_buf()

	local lines = vim.api.nvim_buf_get_lines(opts.bufno, 0, -1, false)
	local pages = {}
	local current_page = {}

	for _, line in pairs(lines) do
		if vim.startswith(line, "#") then
			if #current_page > 0 then
				table.insert(pages, current_page)
				current_page = {}
			end
		elseif vim.startswith(line, "----") or vim.startswith(line, "====") then
			if #current_page > 1 then
				local section_header = table.remove(current_page, #current_page)
				table.insert(pages, current_page)
				current_page = { section_header }
			end
		end

		table.insert(current_page, line)
	end
	table.insert(pages, current_page)

	return pages
end

local start_present = function(opts)
	opts = opts or {}
	local parsed = parse_markdown(opts)
	print(vim.inspect(parsed))
end

M.setup = function() end

vim.api.nvim_create_user_command("Present", start_present, {})

return M
