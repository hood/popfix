local M = {}
M.__index = M

local api = vim.api
local mappings = require'popfix.mappings'

local identifier = api.nvim_create_namespace('popfix.identifier')
local listNamespace = api.nvim_create_namespace('popfix.prompt_popup')


-- @class ListManager manages list UI and selection on various
-- events
function M:new(opts)
	local obj = {
		list = opts.list,
		prompt = opts.prompt,
		action = opts.action,
		renderLimit = opts.renderLimit,
		linesRendered = 0,
		currentPromptText = '',
		keymaps = opts.keymaps,
		additionalKeymaps = opts.additionalKeymaps,
		highlightingFunction = opts.highlightingFunction,
	}
	setmetatable(obj, self)
	return obj
end

function M:setupKeymaps()
	local default_keymaps = {
		n = {
			['q'] = self.close_cancelled,
			['<Esc>'] = self.close_cancelled,
			['j'] = self.select_next,
			['k'] = self.select_prev,
			['<CR>'] = self.close_selected
		},
		i = {
			['<C-c>'] = self.close_cancelled,
			['<C-n>'] = self.select_next,
			['<C-p>'] = self.select_prev,
			['<CR>'] = self.close_selected,
		}
	}
	self.keymaps = self.keymaps or default_keymaps
	if self.additional_keymaps then
		local i_maps = self.additional_keymaps.i
		if i_maps then
			if not self.keymaps.i then
				self.keymaps.i = {}
			end
			for k, v in pairs(i_maps) do
				self.keymaps.i[k] = v
			end
		end
		local n_maps = self.additional_keymaps.n
		if n_maps then
			if not self.keymaps.n then
				self.keymaps.n = {}
			end
			for k, v in pairs(n_maps) do
				self.keymaps.n[k] = v
			end
		end
	end
	mappings.add_keymap(self.prompt.buffer, self.keymaps, self)
end

function M:select(lineNumber)
	api.nvim_buf_clear_namespace(self.list.buffer, listNamespace,
	0, -1)
	api.nvim_buf_add_highlight(self.list.buffer, listNamespace,
	"Visual", lineNumber - 1, 0, -1)
	self.action:select(self.sortedList[lineNumber].index,
	self.list:get(lineNumber - 1))
end

function M:select_next()
	if self.currentLineNumber == #self.sortedList then
		return
	end
	if self.currentLineNumber == self.renderLimit then
		self.currentLineNumber = self.currentLineNumber + 1
		self.renderLimit = self.renderLimit + 1
		local string =
		self.originalList[self.sortedList[self.currentLineNumber].index]
		-- print(vim.inspect(self.sortedList))
		-- print(vim.inspect(self.sortedList[self.currentLineNumber]))
		vim.schedule(function()
			self.list:appendLine(string)
			self:select(self.currentLineNumber)
		end)
	else
		self.currentLineNumber = self.currentLineNumber + 1
		vim.schedule(function()
			self:select(self.currentLineNumber)
		end)
	end
end

function M:select_prev()
	if self.currentLineNumber == 1 then return end
	self.currentLineNumber = self.currentLineNumber - 1
	self:select(self.currentLineNumber)
end

function M:add(line, starting, ending, highlightLine)
	local add = false
	local highlight = true
	if self.currentPromptText == '' then
		highlight = true
	end
	if self.linesRendered < self.renderLimit then
		add = true
	end
	if ((not starting) or (not ending)) then
		if not add then return end
		self.linesRendered = self.linesRendered + 1
		local highlightTable
		if highlight then
			highlightTable = self.highlightingFunction(self.currentPromptText,
			line)
		end
		self.currentLineNumber = 1
		vim.schedule(function()
			self.list:appendLine(line)
			self:select(1)
			if highlight then
				for _, col in pairs(highlightTable) do
					api.nvim_buf_add_highlight(self.list.buffer, identifier,
					"Identifier", highlightLine, col - 1, col)
				end
			end
		end)
		return
	end
	if starting >= self.renderLimit then
		return
	end
	if add then
		self.linesRendered = self.linesRendered + 1
	end
	local highlightTable =
	self.highlightingFunction(self.currentPromptText, line)
	self.currentLineNumber = 1
	vim.schedule(function()
		if not add then
			self.list:clearLast()
		end
		self.list:addLine(line, starting, ending)
		self:select(1)
		for _, col in pairs(highlightTable) do
			api.nvim_buf_add_highlight(self.list.buffer, identifier,
			"Identifier", highlightLine, col - 1, col)
		end
	end)
end

function M:clear()
	self.linesRendered = 0
	vim.schedule(function()
		self.list:clear()
	end)
end

function M:close()
	mappings.free(self.prompt.buffer)
end

return M
