local api = vim.api
local floating_win = require'popfix.floating_win'

local list = {}

local function popup_split(self, height, title)
	local oldWindow = api.nvim_get_current_win()
	vim.cmd('bot new')
	local win = api.nvim_get_current_win()
	local buf = api.nvim_get_current_buf()
	title = title or ''
	api.nvim_buf_set_name(buf, 'PopList #'..buf..title)
	api.nvim_win_set_height(win, height)
	self.buffer = buf
	self.window = win
	api.nvim_set_current_win(oldWindow)
end

local function popup(self, opts)
	local local_opts = {
		relative = opts.relative,
		width = opts.width,
		height = opts.height,
		row = opts.row,
		col = opts.col,
		title = opts.title,
		border = opts.border,
		border_chars = opts.border_chars
	}
	local buf_win = floating_win.create_win(local_opts)
	local win = buf_win.win
	local buf = buf_win.buf
	api.nvim_win_set_height(win, opts.height)
	self.buffer = buf
	self.window = win
end

function list:new(opts)
	opts.title = opts.title or ''
	if opts.border == nil then opts.border = false end
	self.__index = self
	local initial = {}
	popup(initial, opts)
	if opts.numbering == nil then
		opts.numbering = false
	end
	api.nvim_win_set_option(initial.window, 'number', opts.numbering)
	api.nvim_win_set_option(initial.window, 'relativenumber', false)
	if opts.coloring == nil or opts.coloring == false then
		api.nvim_win_set_option(initial.window, 'winhl', 'Normal:ListNormal')
	end
	api.nvim_win_set_option(initial.window, 'wrap', false)
	api.nvim_win_set_option(initial.window, 'cursorline', false)
	api.nvim_buf_set_option(initial.buffer, 'modifiable', false)
	api.nvim_buf_set_option(initial.buffer, 'bufhidden', 'hide')
	local obj = setmetatable(initial, self)
	obj.numData = 0
	return obj
end

function list:newSplit(opts)
	self.__index = self
	opts.title = opts.title or ''
	local initial = {}
	popup_split(initial, opts.height, opts.title)
	if opts.numbering == nil then
		opts.numbering = false
	end
	api.nvim_win_set_option(initial.window, 'number', opts.numbering)
	api.nvim_win_set_option(initial.window, 'relativenumber', false)
	if opts.coloring == nil or opts.coloring == false then
		api.nvim_win_set_option(initial.window, 'winhl', 'Normal:ListNormal')
	end
	api.nvim_win_set_option(initial.window, 'wrap', false)
	api.nvim_win_set_option(initial.window, 'cursorline', false)
	api.nvim_buf_set_option(initial.buffer, 'modifiable', false)
	api.nvim_buf_set_option(initial.buffer, 'bufhidden', 'hide')
	local obj = setmetatable(initial, self)
	obj.numData = 0
	return obj
end

function list:addLine(data, starting, ending)
	self.numData = self.numData + 1
	local buf = self.buffer
	if not buf then return end
	if buf == 0 then return end
	if vim.fn.bufexists(buf) then
		api.nvim_buf_set_option(buf, 'modifiable', true)
		api.nvim_buf_set_lines(buf, starting, ending, false, {data})
		api.nvim_buf_set_option(buf, 'modifiable', false)
	end
end

function list:appendLine(data)
	local numData = self.numData
	local buf = self.buffer
	if not buf then return end
	if buf == 0 then return end
	if vim.fn.bufexists(buf) then
		api.nvim_buf_set_option(buf, 'modifiable', true)
		api.nvim_buf_set_lines(buf, numData, -1, false, {data})
		api.nvim_buf_set_option(buf, 'modifiable', false)
	end
	self.numData = self.numData + 1
end


function list:setData(data, starting, ending)
	if not starting then starting = 0 end
	if not ending then ending = -1 end
	self.numData = #data
	local buf = self.buffer
	if not buf then return end
	if buf == 0 then return end
	if vim.fn.bufexists(buf) then
		api.nvim_buf_set_option(buf, 'modifiable', true)
		api.nvim_buf_set_lines(buf, starting, ending, false, data)
		api.nvim_buf_set_option(buf, 'modifiable', false)
	end
end

function list:addData(data)
	local numData = self.numData
	local buf = self.buffer
	if not buf then return end
	if buf == 0 then return end
	if vim.fn.bufexists(buf) then
		api.nvim_buf_set_option(buf, 'modifiable', true)
		api.nvim_buf_set_lines(buf, numData, -1, false, data)
		api.nvim_buf_set_option(buf, 'modifiable', false)
	end
	self.numData = self.numData + #data
end

function list:clear()
	self.numData = 0
	local buf = self.buffer
	if not buf then return end
	if buf == 0 then return end
	if vim.fn.bufexists(buf) then
		api.nvim_buf_set_option(buf, 'modifiable', true)
		api.nvim_buf_set_lines(buf, 0, -1, false, {})
		api.nvim_buf_set_option(buf, 'modifiable', false)
	end
end

function list:close()
	local buf = self.buffer
	vim.cmd('bwipeout! '..buf)
	self.buffer = nil
	self.window = nil
end

function list:clearLast()
	if self.buffer == nil or self.buffer == 0 then return end
	local numData = api.nvim_buf_line_count(self.buffer)
	if vim.fn.bufexists(self.buffer) then
		api.nvim_buf_set_option(self.buffer, 'modifiable', true)
		api.nvim_buf_set_lines(self.buffer, numData - 1, numData, false, {})
		api.nvim_buf_set_option(self.buffer, 'modifiable', false)
	end
end

function list:getCurrentLineNumber()
	return api.nvim_win_get_cursor(self.window)[1]
end

function list:getCurrentLine()
	local lineNumber = self:getCurrentLineNumber()
	return api.nvim_buf_get_lines(self.buffer, lineNumber - 1, lineNumber, false)[1]
end

function list:select_next()
	local lineNumber = self:getCurrentLineNumber()
	pcall(api.nvim_win_set_cursor, self.window, {lineNumber +1, 0})
	vim.cmd('redraw')
end

function list:select_prev()
	local lineNumber = self:getCurrentLineNumber()
	if lineNumber - 1 > 0 then
		api.nvim_win_set_cursor(self.window, {lineNumber - 1, 0})
	end
	vim.cmd('redraw')
end

function list:getSize()
	return api.nvim_buf_line_count(self.buffer)
end

function list:get(index)
	return api.nvim_buf_get_lines(self.buffer, index, index + 1, false)[1]
end

return list
