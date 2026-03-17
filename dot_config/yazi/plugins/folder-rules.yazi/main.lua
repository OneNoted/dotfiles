local function setup()
	ps.sub("cd", function()
		local cwd = cx.active.current.cwd
		local use_mtime_sort = cwd:ends_with("Downloads")
			or cwd:ends_with("Pictures/Screenshots/Snippets")
			or cwd:ends_with("Pictures/Screencaptures/Snippets")

		if use_mtime_sort then
			ya.emit("sort", { "mtime", reverse = true, dir_first = false })
		else
			ya.emit("sort", { "alphabetical", reverse = false, dir_first = true })
		end
	end)
end

return { setup = setup }
