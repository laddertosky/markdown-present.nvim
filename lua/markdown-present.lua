local M = {}

local state = {
	current_page = 1,
	pages = {},
	floats = {
		body = {
			bufno = -1,
			win = -1,
		},
	},
}

--- @return string[][]
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

local window_config = {
	body = {
		relative = "editor",
		width = vim.o.columns,
		height = vim.o.lines,
		border = "rounded",
		style = "minimal",
		row = 0,
		col = 0,
	},
}

local create_window = function(opts, enter)
	enter = enter or false
	local bufno = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(bufno, enter, opts)
	vim.bo[bufno].filetype = "markdown"
	return { bufno = bufno, win = win }
end

local start_present = function(opts)
	opts = opts or {}
	state.pages = parse_markdown(opts)

	state.floats.body = create_window(window_config.body, true)
	vim.api.nvim_buf_set_lines(state.floats.body.bufno, 0, -1, false, state.pages[1])

	vim.keymap.set("n", "<c-n>", function()
		state.current_page = math.min(state.current_page + 1, #state.pages)
		vim.api.nvim_buf_set_lines(state.floats.body.bufno, 0, -1, false, state.pages[state.current_page])
	end, { buffer = state.floats.body.bufno })

	vim.keymap.set("n", "<c-p>", function()
		state.current_page = math.max(state.current_page - 1, 1)
		vim.api.nvim_buf_set_lines(state.floats.body.bufno, 0, -1, false, state.pages[state.current_page])
	end, { buffer = state.floats.body.bufno })
end

M.setup = function() end

vim.api.nvim_create_user_command("Present", start_present, {})

return M
