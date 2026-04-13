-- Java ftplugin: starts nvim-jdtls per buffer
-- This is the canonical entry point for nvim-jdtls

local ok, jdtls = pcall(require, "jdtls")
if not ok then
	return
end

-- Mason paths
local mason_registry = require("mason-registry")

local function get_mason_package_path(name)
	local pkg = mason_registry.get_package(name)
	return pkg:get_install_path()
end

-- Find jdtls installation
local jdtls_path = get_mason_package_path("jdtls")
local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")

-- Platform config
local os_config = "linux"
if vim.fn.has("mac") == 1 then
	os_config = "mac"
elseif vim.fn.has("win32") == 1 then
	os_config = "win"
end
local config_path = jdtls_path .. "/config_" .. os_config

-- Project name for data directory
local root_markers = { "gradlew", "mvnw", ".git", "pom.xml", "build.gradle", "build.gradle.kts" }
local root_dir = require("jdtls.setup").find_root(root_markers)
local project_name = root_dir and vim.fn.fnamemodify(root_dir, ":p:h:t") or "default"
local data_dir = vim.fn.expand("~/.cache/jdtls/") .. project_name

-- Debug and test bundles (if installed via Mason)
local bundles = {}

local function add_bundles(package_name, pattern)
	local has_pkg, pkg_path = pcall(get_mason_package_path, package_name)
	if has_pkg then
		local jars = vim.fn.glob(pkg_path .. pattern, true, true)
		for _, jar in ipairs(jars) do
			table.insert(bundles, jar)
		end
	end
end

add_bundles("java-debug-adapter", "/extension/server/com.microsoft.java.debug.plugin-*.jar")
add_bundles("java-test", "/extension/server/*.jar")

-- cmp-nvim-lsp capabilities
local capabilities = vim.tbl_deep_extend(
	"force",
	vim.lsp.protocol.make_client_capabilities(),
	require("cmp_nvim_lsp").default_capabilities()
)

local config = {
	cmd = {
		"java",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xmx1g",
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",
		"-jar",
		launcher_jar,
		"-configuration",
		config_path,
		"-data",
		data_dir,
	},

	root_dir = root_dir,
	capabilities = capabilities,

	settings = {
		java = {
			signatureHelp = { enabled = true },
			contentProvider = { preferred = "fernflower" },
			completion = {
				favoriteStaticMembers = {
					"org.hamcrest.MatcherAssert.assertThat",
					"org.hamcrest.Matchers.*",
					"org.hamcrest.CoreMatchers.*",
					"org.junit.jupiter.api.Assertions.*",
					"java.util.Objects.requireNonNull",
					"java.util.Objects.requireNonNullElse",
					"org.mockito.Mockito.*",
				},
				importOrder = {
					"java",
					"javax",
					"com",
					"org",
				},
			},
			sources = {
				organizeImports = {
					starThreshold = 9999,
					staticStarThreshold = 9999,
				},
			},
		},
	},

	init_options = {
		bundles = bundles,
	},

	on_attach = function(_, bufnr)
		-- Setup DAP if debug bundles are available
		if #bundles > 0 then
			jdtls.setup_dap({ hotcodereplace = "auto" })
		end

		-- Java-specific keymaps
		local map = function(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
		end

		map("n", "<leader>co", jdtls.organize_imports, "Organize Imports")
		map("n", "<leader>cv", jdtls.extract_variable, "Extract Variable")
		map("n", "<leader>cc", jdtls.extract_constant, "Extract Constant")
		map("v", "<leader>cm", function()
			jdtls.extract_method(true)
		end, "Extract Method")
		map("n", "<leader>cT", jdtls.pick_test, "Pick Test")
		map("n", "<leader>ct", jdtls.test_nearest_method, "Run Nearest Test")
	end,
}

jdtls.start_or_attach(config)
