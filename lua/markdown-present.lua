local M = {}

local state = {
	current_page = 1,
	pages = {},
	floats = {
		title = {
			bufno = -1,
			win = -1,
		},
		body = {
			bufno = -1,
			win = -1,
		},
		footer = {
			bufno = -1,
			win = -1,
		},
		background = {
			bufno = -1,
			win = -1,
		},
	},
	filename = "",
}

--- @class Page
--- @field title string
--- @field contents string[]

--- @return Page[]
local parse_markdown = function(opts)
	opts = opts or {}
	opts.bufno = opts.bufno or vim.api.nvim_get_current_buf()

	local lines = vim.api.nvim_buf_get_lines(opts.bufno, 0, -1, false)

	--- @type Page[]
	local pages = {}

	--- @type Page
	local current_page = {
		title = "",
		contents = {},
	}

	for _, line in pairs(lines) do
		if vim.startswith(line, "#") then
			if #current_page.contents > 0 then
				table.insert(pages, current_page)
			end

			current_page = {
				title = line,
				contents = {},
			}
		elseif vim.startswith(line, "----") or vim.startswith(line, "====") then
			if #current_page.contents > 1 then
				local section_title = table.remove(current_page.contents, #current_page.contents)
				table.insert(pages, current_page)
				current_page = {
					title = section_title,
					contents = {},
				}
			end
		else
			table.insert(current_page.contents, line)
		end
	end
	table.insert(pages, current_page)

	return pages
end

local create_window_config = function()
	local border_size = 2
	local indent = 8
	local float_width = vim.o.columns - indent * 2

	local title_height = 2
	local footer_height = 1
	local body_height = vim.o.lines - footer_height - border_size - title_height

	return {
		title = {
			relative = "editor",
			width = vim.o.columns,
			height = title_height,
			border = "rounded",
			style = "minimal",
			row = 0,
			col = 0,
			zindex = 100,
		},
		body = {
			relative = "editor",
			width = float_width,
			height = body_height,
			border = "none",
			style = "minimal",
			row = title_height + border_size,
			col = indent,
			zindex = 80,
		},
		footer = {
			relative = "editor",
			width = float_width,
			height = footer_height,
			border = "none",
			style = "minimal",
			row = body_height + border_size + title_height,
			col = indent,
		},
		background = {
			relative = "editor",
			width = vim.o.columns,
			height = vim.o.lines,
			border = "none",
			style = "minimal",
			row = 0,
			col = 0,
		},
	}
end

local create_window = function(opts, enter)
	enter = enter or false
	local bufno = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(bufno, enter, opts)

	vim.wo[win].cursorline = false
	vim.bo[bufno].filetype = "markdown"
	return { bufno = bufno, win = win }
end

--- @return string[]
local footer_content = function()
	return {
		string.format("%d / %d, %s", state.current_page, #state.pages, state.filename),
	}
end

local set_page_content = function()
	vim.api.nvim_buf_set_lines(state.floats.title.bufno, 0, -1, false, { state.pages[state.current_page].title })
	vim.api.nvim_buf_set_lines(state.floats.body.bufno, 0, -1, false, state.pages[state.current_page].contents)
	vim.api.nvim_buf_set_lines(state.floats.footer.bufno, 0, -1, false, footer_content())
end

M.start_present = function(opts)
	opts = opts or {}
	state.pages = parse_markdown(opts)
	state.filename = vim.fn.expand("%:t")

	local window_config = create_window_config()
	state.floats.title = create_window(window_config.title, false)
	state.floats.body = create_window(window_config.body, true)
	state.floats.footer = create_window(window_config.footer, false)
	state.floats.background = create_window(window_config.background, false)
	set_page_content()

	vim.keymap.set("n", "<c-n>", function()
		state.current_page = math.min(state.current_page + 1, #state.pages)
		set_page_content()
	end, { buffer = state.floats.body.bufno })

	vim.keymap.set("n", "<c-p>", function()
		state.current_page = math.max(state.current_page - 1, 1)
		set_page_content()
	end, { buffer = state.floats.body.bufno })

	vim.keymap.set("n", "q", function()
		for _, float in pairs(state.floats) do
			vim.api.nvim_win_close(float.win, true)
		end

		state.current_page = 1
		state.pages = {}
		state.floats = {}
	end, { buffer = state.floats.body.bufno })
end

return M
