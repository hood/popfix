local api = vim.api
local autocmd = require'popfix.autocmd'

local M = {}

local default_opts = {
	relative = "editor",
	width = 80,
	height = 40,
	row = 0,
	col = 0,
	title = "",
	options = {},
	border = false,
}

local function create_win(row, col, width, height, relative, focusable)
	local buf = api.nvim_create_buf(false, true)
	local options = {
		style = "minimal",
		relative = relative,
		width = width,
		height = height,
		row = row,
		col = col,
		focusable = focusable
	}
	local win = api.nvim_open_win(buf, false, options)
	api.nvim_win_set_option(win, 'winhl', 'Normal:PopFixNormal')
	return {
		buf = buf,
		win = win
	}
end

local function fill_border_data(buf, width, height, title)
	local border_lines = { '╔' .. title .. string.rep('═', width - #title) .. '╗' }
	local middle_line = '║' .. string.rep(' ', width) .. '║'
	for i=1, height do
		table.insert(border_lines, middle_line)
	end
	table.insert(border_lines, '╚' .. string.rep('═', width) .. '╝')

	api.nvim_buf_set_lines(buf, 0, -1, false, border_lines)
end

--TODO: get rid of this type hack.
function M.create_win(opts, type)
	if type == nil then type = 'editor' end
	opts.relative = opts.relative or default_opts.relative
	opts.width = opts.width or default_opts.width
	opts.height = opts.height or default_opts.height
	opts.title = opts.title or default_opts.title
	opts.row = opts.row or default_opts.row
	opts.col = opts.col or default_opts.col
	if opts.border == nil then
		opts.border = default_opts.border
	end

	local border_buf = nil

	local win_buf_pair
	if type == 'split' then
		win_buf_pair = create_win(opts.row, opts.col, opts.width, opts.height, opts.relative, true)
	end

	if opts.border then
		local border_win_buf_pair = create_win(opts.row - 1, opts.col - 1,
		opts.width + 2, opts.height + 2, opts.relative, false
		)
		border_buf = border_win_buf_pair.buf
		fill_border_data(border_buf, opts.width , opts.height, opts.title )
	end

	if type == 'editor' then
		win_buf_pair = create_win(opts.row, opts.col, opts.width, opts.height, opts.relative, true)
	end


	if border_buf then
		autocmd.addCommand(win_buf_pair.buf,{
			['BufWipeout'] = string.format('exe "silent bwipeout! %s"', border_buf, true)
		}, true)
	end
	return win_buf_pair
end

return M
