local M = {}

M.options = {
	hl_bg = "green",
	hl_fg = "white",
}

function M.setup(opts)
	M.options = vim.tbl_extend("force", M.options, opts or {})
end

local function create_highlight_group()
	vim.cmd("highlight CustomSearchHL guibg=" .. M.options.hl_bg .. " guifg=" .. M.options.hl_fg)
end

local function add_highlights(bufnr, ns_id, pattern)
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	local matches = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for i, line in ipairs(lines) do
		local start = 1
		while true do
			local s, e = line:find(pattern, start)
			if not s then
				break
			end
			table.insert(matches, { line = i - 1, col_start = s - 1, col_end = e })
			start = e + 1
		end
	end

	for _, match in ipairs(matches) do
		vim.api.nvim_buf_add_highlight(bufnr, ns_id, "CustomSearchHL", match.line, match.col_start, match.col_end)
	end
	return #matches
end

local function interactive_search(bufnr, ns_id)
	local search_term = ""
	while true do
		vim.api.nvim_echo({ { "find> " .. search_term, "Normal" } }, false, {})
		local char = vim.fn.getchar()
		if char == 13 then -- Enter key
			break
		elseif char == 27 then -- Escape key
			vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
			print("\nSearch cancelled.")
			return nil
		elseif char == 8 or char == 127 then -- Backspace
			if #search_term > 0 then
				search_term = search_term:sub(1, -2)
			end
		else
			search_term = search_term .. vim.fn.nr2char(char)
		end
		add_highlights(bufnr, ns_id, search_term)
		vim.cmd("redraw")
	end

	if search_term == "" then
		vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
		print("\nSearch term is empty. Aborting.")
		return nil
	end

	return search_term
end

local function replace_in_buffer(bufnr, search_term, replace_term)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local replacement_count = 0

	for i, line in ipairs(lines) do
		local new_line, count = line:gsub(search_term, replace_term)
		if count > 0 then
			vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { new_line })
			replacement_count = replacement_count + count
		end
	end

	return replacement_count
end

function M.find_and_replace_in_buffer()
	create_highlight_group()
	local bufnr = vim.api.nvim_get_current_buf()
	local ns_id = vim.api.nvim_create_namespace("custom_search_highlight")

	local search_term = interactive_search(bufnr, ns_id)
	if not search_term then
		return
	end

	local replace_term = vim.fn.input("replace> ")
	local replacement_count = replace_in_buffer(bufnr, search_term, replace_term)

	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	print(string.format("Replaced %d occurrence(s) of '%s' with '%s'", replacement_count, search_term, replace_term))
end

return M
