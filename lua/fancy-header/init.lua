local M = {}

local default_config = {
	colors = {
		box = { fg = "#FF006E" },
		filename = { fg = "#FFBE0B", bold = true },
		logo_42 = { fg = "#06FFA5" },
		author = { fg = "#3A86FF" },
		date = { fg = "#8338EC" },
	},
}

local ns_id = vim.api.nvim_create_namespace("42_header")

local function setup_highlights(colors)
	vim.api.nvim_set_hl(0, "H42Box", { fg = colors.box.fg })
	vim.api.nvim_set_hl(0, "H42Filename", { fg = colors.filename.fg, bold = colors.filename.bold })
	vim.api.nvim_set_hl(0, "H42Logo", { fg = colors.logo_42.fg })
	vim.api.nvim_set_hl(0, "H42Author", { fg = colors.author.fg })
	vim.api.nvim_set_hl(0, "H42Date", { fg = colors.date.fg })
end

local function apply_highlights(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	-- The 42 header is always exactly 11 lines long
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 11, false)

	-- Strict validation: Only run if line 1 is a 42 header border
	if #lines < 11 or not lines[1]:match("^/%*%s*%*+%s*%*/$") then
		return
	end

	for i, line in ipairs(lines) do
		local row = i - 1
		local line_len = #line

		-- Verify it looks like a standard padded header line
		if line_len >= 5 and line:match("^/%*") and line:match("%*/$") then
			-- Highlight the '/*' (cols 0 to 2) and '*/' (end of line)
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, 0, { end_col = 2, hl_group = "H42Box" })
			vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, line_len - 2, { end_col = line_len, hl_group = "H42Box" })

			-- Top and Bottom full borders
			if row == 0 or row == 10 then
				vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, 2, { end_col = line_len - 2, hl_group = "H42Box" })

			-- Middle text lines (skip empty border lines 1 and 9)
			elseif row ~= 1 and row ~= 9 then
				-- Determine text color based on standard 42 header rows
				local text_hl = nil
				if row == 3 then
					text_hl = "H42Filename"
				elseif row == 5 then
					text_hl = "H42Author"
				elseif row == 7 or row == 8 then
					text_hl = "H42Date"
				end

				-- Parse gap: Find the first instance of 4+ spaces followed by a logo char (:, +, or #)
				local logo_start_col = nil
				local _, gap_end = string.find(line, "%s%s%s%s+[%:%+#]")

				if gap_end then
					logo_start_col = gap_end - 1 -- 0-based index of where the logo starts
				end

				-- Apply the split highlights
				if logo_start_col then
					if text_hl then
						-- Color the left text (Filename, Author, etc.)
						vim.api.nvim_buf_set_extmark(
							bufnr,
							ns_id,
							row,
							2,
							{ end_col = logo_start_col, hl_group = text_hl }
						)
					end
					-- Color the right logo
					vim.api.nvim_buf_set_extmark(
						bufnr,
						ns_id,
						row,
						logo_start_col,
						{ end_col = line_len - 2, hl_group = "H42Logo" }
					)
				elseif text_hl then
					-- Fallback if no logo was found
					vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, 2, { end_col = line_len - 2, hl_group = text_hl })
				end
			end
		end
	end
end

function M.refresh()
	local bufnr = vim.api.nvim_get_current_buf()
	apply_highlights(bufnr)
end

function M.setup(opts)
	local config = vim.tbl_deep_extend("force", default_config, opts or {})
	setup_highlights(config.colors)

	local group = vim.api.nvim_create_augroup("Header42Visuals", { clear = true })

	-- Refresh highlights when text changes or buffers load
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged", "InsertLeave" }, {
		group = group,
		callback = M.refresh,
	})

	-- Toggle Logic
	vim.api.nvim_create_user_command("HeaderToggle", function()
		local bufnr = vim.api.nvim_get_current_buf()
		local extmarks = vim.api.nvim_buf_get_extmarks(bufnr, ns_id, 0, -1, {})
		if #extmarks > 0 then
			vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
		else
			M.refresh()
		end
	end, {})
end

return M
