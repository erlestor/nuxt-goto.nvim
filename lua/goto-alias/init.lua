--TODO:
--tests
--does .nuxt directory detection using string.concat have better preformance?
--newly created components do not seem to work

local M = {}

M.is_nuxt_project = false
M.original_definition = vim.lsp.buf.definition
M.nuxt_directory_path = ""

local default_check_directories = { "/apps/web", "/apps/nuxt", "/apps/frontend", "/apps/website" }

M.setup = function(opts)
	opts = opts or {}

	local check_directories = vim.list_extend(default_check_directories, opts.check_directories or {})

	for _, directory in ipairs(check_directories) do
		if vim.fn.isdirectory(vim.loop.cwd() .. directory .. "/.nuxt") == 1 then
			M.is_nuxt_project = true
			if directory ~= "" then
				M.nuxt_directory_path = string.sub(directory, 2)
			end
			break
		end
	end

	if not M.is_nuxt_project then
		return
	end

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		pattern = { "*.vue" },
		callback = function()
			vim.lsp.buf.definition = M.watch
		end,
	})

	-- this is in the original repo. whyyy???
	-- - maybe for when you change repo without closing neovim?
	-- M.is_nuxt_project = false
	-- M.original_definition = vim.lsp.buf.definition
	-- M.nuxt_directory_path = ""
end

M.watch = function()
	M.original_definition()

	if not M.is_nuxt_project then
		return
	end

	vim.defer_fn(function()
		local line = vim.fn.getline(".")
		local path = string.match(line, '".-/(.-)"')
		local file = vim.fn.expand("%")

		local auto_import_files = { "components.d.ts", "imports.d.ts" }

		for _, auto_import_file in ipairs(auto_import_files) do
			if string.find(file, auto_import_file) then
				vim.api.nvim_buf_delete(0, { force = false })
				vim.cmd("edit " .. M.nuxt_directory_path .. "/" .. path)
				break
			elseif string.find(line, auto_import_file) then
				if string.find(line, "stores") then
					local storePath = string.match(line, "'.-/(.-)'")
					vim.cmd("cclose")
					vim.cmd("edit " .. M.nuxt_directory_path .. "/stores/" .. storePath .. ".ts")
				elseif string.find(line, "composables") then
					local composablePath = string.match(line, "'.-/(.-)'")
					vim.cmd("cclose")
					vim.cmd("edit " .. M.nuxt_directory_path .. "/composables/" .. composablePath .. ".ts")
				elseif string.find(line, "utils") then
					local utilsPath = string.match(line, "'.-/(.-)'")
					vim.cmd("cclose")
					vim.cmd("edit " .. M.nuxt_directory_path .. "/utils/" .. utilsPath .. ".ts")
				else
					vim.cmd("cclose")
					vim.cmd("edit " .. M.nuxt_directory_path .. "/" .. path)
				end
				break
			end
		end
	end, 100)
end

return M
