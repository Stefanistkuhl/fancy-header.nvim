local M = {}

local default_config = {
	colors = {
		box = { fg = "#6e6a86" }, -- Muted
		filename = { fg = "#f6c177", bold = true }, -- Gold
		author = { fg = "#9ccfd8" }, -- Foam
		date = { fg = "#c4a7e7" }, -- Iris
		logo_42 = { start = "#eb6f92", end_ = "#31748f" }, -- Love to Pine gradient
	},
}

local ns_id = vim.api.nvim_create_namespace("42_header")

-- --- Color Math for Gradient ---
local function hex_to_rgb(hex)
	hex = hex:gsub("#", "")
	return tonumber("0x" .. hex:sub(1, 2)), tonumber("0x" .. hex:sub(3, 4)), tonumber("0x" .. hex:sub(5, 6))
end

local function rgb_to_hex(r, g, b)
	return string.format("#%02x%02x%02x", r, g, b)
end

local function interpolate_color(c1, c2, factor)
	local r1, g1, b1 = hex_to_rgb(c1)
	local r2, g2, b2 = hex_to_rgb(c2)
	local r = r1 + (r2 - r1) * factor
	local g = g1 + (g2 - g1) * factor
	local b = b1 + (b2 - b1) * factor
	return rgb_to_hex(math.floor(r + 0.5), math.floor(g + 0.5), math.floor(b + 0.5))
end

local function setup_highlights(colors)
	vim.api.nvim_set_hl(0, "H42Box", { fg = colors.box.fg })
	vim.api.nvim_set_hl(0, "H42Filename", { fg = colors.filename.fg, bold = colors.filename.bold })
	vim.api.nvim_set_hl(0, "H42Author", { fg = colors.author.fg })
	vim.api.nvim_set_hl(0, "H42Date", { fg = colors.date.fg })

	-- Generate 7 highlight groups for the 7 lines of the logo gradient
	if colors.logo_42.start and colors.logo_42.end_ then
		for i = 0, 6 do
			local factor = i / 6 -- Math to step from 0.0 to 1.0
			local hex = interpolate_color(colors.logo_42.start, colors.logo_42.end_, factor)
			vim.api.nvim_set_hl(0, "H42Logo" .. i, { fg = hex })
		end
	else
		-- Fallback if no gradient is provided
		for i = 0, 6 do
			vim.api.nvim_set_hl(0, "H42Logo" .. i, { fg = colors.logo_42.fg or "#06FFA5" })
		end
	end
end

local function apply_highlights(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 11, false)
	local ft = vim.bo[bufnr].filetype

	-- Check for valid header based on filetype
	local is_valid_header = false
	if ft == "makefile" then
		is_valid_header = #lines >= 11 and lines[1]:match("^#%s*%*.*%*%s*#$")
	else
		is_valid_header = #lines >= 11 and lines[1]:match("^/%*%s*%*+%s*%*/$")
	end

	if not is_valid_header then
		return
	end

	for i, line in ipairs(lines) do
		local row = i - 1
		local line_len = #line

		-- Check if line is part of header (starts and ends with # or /*)
		local is_header_line = false
		if ft == "makefile" then
			is_header_line = line_len >= 5 and line:match("^#") and line:match("#$")
		else
			is_header_line = line_len >= 5 and line:match("^/%*") and line:match("%*/$")
		end

		if is_header_line then
			-- Borders with filetype-specific offsets
			if ft == "makefile" then
				-- Makefile: single # border
				vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, 0, { end_col = 1, hl_group = "H42Box" })
				vim.api.nvim_buf_set_extmark(
					bufnr,
					ns_id,
					row,
					line_len - 1,
					{ end_col = line_len, hl_group = "H42Box" }
				)
				local content_start = 1
				local content_end = line_len - 1

				if row == 0 or row == 10 then
					-- Top and bottom lines all box color
					vim.api.nvim_buf_set_extmark(
						bufnr,
						ns_id,
						row,
						content_start,
						{ end_col = content_end, hl_group = "H42Box" }
					)
				elseif row ~= 1 and row ~= 9 then
					-- Content rows (2-8)
					local text_hl = nil
					if row == 3 then
						text_hl = "H42Filename"
					elseif row == 5 then
						text_hl = "H42Author"
					elseif row == 7 or row == 8 then
						text_hl = "H42Date"
					end

					local logo_start_col = nil
					local _, gap_end = string.find(line, "%s%s%s%s+[%:%+#]")
					if gap_end then
						logo_start_col = gap_end - 1
					end

					if logo_start_col then
						if text_hl then
							vim.api.nvim_buf_set_extmark(
								bufnr,
								ns_id,
								row,
								content_start,
								{ end_col = logo_start_col, hl_group = text_hl }
							)
						end

						local logo_idx = math.max(0, math.min(6, row - 2))
						vim.api.nvim_buf_set_extmark(
							bufnr,
							ns_id,
							row,
							logo_start_col,
							{ end_col = content_end, hl_group = "H42Logo" .. logo_idx }
						)
					elseif text_hl then
						vim.api.nvim_buf_set_extmark(
							bufnr,
							ns_id,
							row,
							content_start,
							{ end_col = content_end, hl_group = text_hl }
						)
					end
				end
			else
				-- C file: /* */ border
				vim.api.nvim_buf_set_extmark(bufnr, ns_id, row, 0, { end_col = 2, hl_group = "H42Box" })
				vim.api.nvim_buf_set_extmark(
					bufnr,
					ns_id,
					row,
					line_len - 2,
					{ end_col = line_len, hl_group = "H42Box" }
				)
				local content_start = 2
				local content_end = line_len - 2

				if row == 0 or row == 10 then
					-- Top and bottom lines all box color
					vim.api.nvim_buf_set_extmark(
						bufnr,
						ns_id,
						row,
						content_start,
						{ end_col = content_end, hl_group = "H42Box" }
					)
				elseif row ~= 1 and row ~= 9 then
					-- Content rows (2-8)
					local text_hl = nil
					if row == 3 then
						text_hl = "H42Filename"
					elseif row == 5 then
						text_hl = "H42Author"
					elseif row == 7 or row == 8 then
						text_hl = "H42Date"
					end

					local logo_start_col = nil
					local _, gap_end = string.find(line, "%s%s%s%s+[%:%+#]")
					if gap_end then
						logo_start_col = gap_end - 1
					end

					if logo_start_col then
						if text_hl then
							vim.api.nvim_buf_set_extmark(
								bufnr,
								ns_id,
								row,
								content_start,
								{ end_col = logo_start_col, hl_group = text_hl }
							)
						end

						local logo_idx = math.max(0, math.min(6, row - 2))
						vim.api.nvim_buf_set_extmark(
							bufnr,
							ns_id,
							row,
							logo_start_col,
							{ end_col = content_end, hl_group = "H42Logo" .. logo_idx }
						)
					elseif text_hl then
						vim.api.nvim_buf_set_extmark(
							bufnr,
							ns_id,
							row,
							content_start,
							{ end_col = content_end, hl_group = text_hl }
						)
					end
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
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged", "InsertLeave" }, {
		group = group,
		callback = M.refresh,
	})

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
