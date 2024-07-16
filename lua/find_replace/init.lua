local M = {}

M.options = {
	hl_bg = "green",
	hl_fg = "white",
}

function M.setup(opts)
	M.options = vim.tbl_extend("force", M.options, opts or {})
end

function M.find_and_replace_in_buffer()
	-- Create a new highlight group

	if M.options.hl_bg then
		print("highlight bg is set to " .. M.options.hl_bg)
	else
		print("highlight bg is not set")
	end

	-- vim.cmd("highlight CustomSearchHL guibg=yellow guifg=black")
	vim.cmd("highlight CustomSearchHL guibg=" .. M.options.hl_bg .. " guifg=" .. M.options.hl_fg)
	local bufnr = vim.api.nvim_get_current_buf()
	local ns_id = vim.api.nvim_create_namespace("custom_search_highlight")

	-- Function to add highlights
	local function add_highlights(pattern)
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

	-- Interactive search prompt
	local search_term = ""
	-- local match_count = 0
	while true do
		vim.api.nvim_echo({ { "find> " .. search_term, "Normal" } }, false, {})
		local char = vim.fn.getchar()
		if char == 13 then -- Enter key
			break
		elseif char == 27 then -- Escape key
			vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
			print("\nSearch cancelled.")
			return
		elseif char == 8 or char == 127 then -- Backspace
			search_term = search_term:sub(1, -2)
		else
			search_term = search_term .. vim.fn.nr2char(char)
		end
		add_highlights(search_term)
		vim.cmd("redraw")
	end

	if search_term == "" then
		vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
		print("\nSearch term is empty. Aborting.")
		return
	end

	-- Prompt for the replacement term
	local replace_term = vim.fn.input("replace> ")

	-- Get all lines in the current buffer
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local replacement_count = 0

	-- Iterate through each line
	for i, line in ipairs(lines) do
		local new_line, count = line:gsub(search_term, replace_term)
		if count > 0 then
			-- Replace the line in the buffer
			vim.api.nvim_buf_set_lines(bufnr, i - 1, i, false, { new_line })
			replacement_count = replacement_count + count
		end
	end

	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	print(string.format("Replaced %d occurrence(s) of '%s' with '%s'", replacement_count, search_term, replace_term))
end

-- Set up a keymap to call the function
-- vim.keymap.set("n", "<leader>fr", M.find_and_replace_in_buffer, { desc = "Find and replace in current buffer" })

return M
