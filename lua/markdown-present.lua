local M = {}

--- @class Float
--- @field win integer
--- @field bufno integer

--- @class Page
--- @field title string
--- @field contents string[]

local state = {
	filename = "",
	current_page = 1,

	--- @type Page[]
	pages = {},

	--- @type table<string, Float>
	floats = {},
}

local auto_group = vim.api.nvim_create_augroup("markdown-present", {})

--- @return Page[]
local parse_markdown = function(opts)
	opts = opts or {}
	opts.bufno = opts.bufno or vim.api.nvim_get_current_buf()

	local lines = vim.api.nvim_buf_get_lines(opts.bufno, 0, -1, false)

	--- @type Page[]
	local pages = {}

	--- @type Page
	local current_page = {
		title = state.filename, -- using filename as fallback title
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
		elseif #current_page.contents == 0 and #(vim.trim(line)) == 0 then
			-- do not store first empty lines
		else
			table.insert(current_page.contents, line)
		end
	end
	table.insert(pages, current_page)

	return pages
end

--- @return table<string, vim.api.keyset.win_config>
local create_window_config = function()
	local border_size = 2
	local indent = 8
	local float_width = vim.o.columns - indent * 2

	local title_height = 3
	local footer_height = 2
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
			zindex = 10,
		},
		body = {
			relative = "editor",
			width = float_width,
			height = body_height,
			border = "none",
			style = "minimal",
			row = title_height + border_size,
			col = indent,
			zindex = 8,
		},
		footer = {
			relative = "editor",
			width = float_width,
			height = footer_height,
			border = "none",
			style = "minimal",
			row = body_height + border_size + title_height,
			col = indent,
			zindex = 7,
		},
		background = {
			relative = "editor",
			width = vim.o.columns,
			height = vim.o.lines,
			border = "none",
			style = "minimal",
			row = 0,
			col = 0,
			zindex = 5,
		},
	}
end

--- @return Float
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
	--- TODO: center the title

	local width = vim.api.nvim_win_get_width(state.floats.title.win)
	local raw_title = state.pages[state.current_page].title
	local padding = string.rep(" ", (width - #raw_title) / 2)
	local title = padding .. raw_title
	vim.api.nvim_buf_set_lines(state.floats.body.bufno, 1, -1, false, state.pages[state.current_page].contents)
	vim.api.nvim_buf_set_lines(state.floats.title.bufno, 1, -1, false, { title })
	vim.api.nvim_buf_set_lines(state.floats.footer.bufno, 1, -1, false, footer_content())
end

M.start_present = function(opts)
	opts = opts or {}
	state.filename = vim.fn.expand("%:t")
	state.pages = parse_markdown(opts)

	local window_config = create_window_config()
	state.floats.title = create_window(window_config.title, false)
	state.floats.body = create_window(window_config.body, true)
	state.floats.footer = create_window(window_config.footer, false)
	state.floats.background = create_window(window_config.background, false)
	set_page_content()

	vim.keymap.set("n", "<c-n>", function()
		if state.current_page == #state.pages then
			return
		end

		state.current_page = state.current_page + 1
		set_page_content()
	end, { buffer = state.floats.body.bufno })

	vim.keymap.set("n", "<c-p>", function()
		if state.current_page == 1 then
			return
		end

		state.current_page = state.current_page - 1
		set_page_content()
	end, { buffer = state.floats.body.bufno })

	vim.keymap.set("n", "q", function()
		vim.api.nvim_win_close(state.floats.body.win, true)
	end, { buffer = state.floats.body.bufno })

	vim.api.nvim_create_autocmd("BufLeave", {
		group = auto_group,
		buffer = state.floats.body.bufno,
		callback = function()
			for _, float in pairs(state.floats) do
				if vim.api.nvim_win_is_valid(float.win) then
					vim.api.nvim_win_close(float.win, true)
				end
			end

			state.current_page = 1
			state.pages = {}
			state.floats = {}
		end,
	})

	vim.api.nvim_create_autocmd("VimResized", {
		group = auto_group,
		buffer = state.floats.body.bufno,
		callback = function()
			local updated_config = create_window_config()
			for name, float in pairs(state.floats) do
				vim.api.nvim_win_set_config(float.win, updated_config[name])
			end
			set_page_content()
		end,
	})
end

return M
