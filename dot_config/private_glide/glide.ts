// Config docs:
//
//   https://glide-browser.app/config
//
// API reference:
//
//   https://glide-browser.app/api
//
// Default config files can be found here:
//
//   https://github.com/glide-browser/glide/tree/main/src/glide/browser/base/content/plugins
//
// Most default keymappings are defined here:
//
//   https://github.com/glide-browser/glide/blob/main/src/glide/browser/base/content/plugins/keymaps.mts
//
// Try typing `glide.` and see what you can do!
glide.o.hint_size = "11px";

const catppuccinMocha = {
	rosewater: "#f5e0dc",
	flamingo: "#f2cdcd",
	pink: "#f5c2e7",
	mauve: "#cba6f7",
	red: "#f38ba8",
	maroon: "#eba0ac",
	peach: "#fab387",
	yellow: "#f9e2af",
	green: "#a6e3a1",
	teal: "#94e2d5",
	sky: "#89dceb",
	sapphire: "#74c7ec",
	blue: "#89b4fa",
	lavender: "#b4befe",
	text: "#cdd6f4",
	subtext1: "#bac2de",
	subtext0: "#a6adc8",
	overlay2: "#9399b2",
	overlay1: "#7f849c",
	overlay0: "#6c7086",
	surface2: "#585b70",
	surface1: "#45475a",
	surface0: "#313244",
	base: "#1e1e2e",
	mantle: "#181825",
	crust: "#11111b",
} as const;

const catppuccinMochaTheme: Browser.Manifest.ThemeType = {
	colors: {
		frame: catppuccinMocha.crust,
		frame_inactive: catppuccinMocha.mantle,
		tab_background_text: catppuccinMocha.subtext0,
		tab_selected: catppuccinMocha.surface0,
		tab_text: catppuccinMocha.text,
		tab_line: catppuccinMocha.mauve,
		tab_background_separator: catppuccinMocha.surface1,
		tab_loading: catppuccinMocha.blue,
		toolbar: catppuccinMocha.base,
		toolbar_text: catppuccinMocha.text,
		bookmark_text: catppuccinMocha.text,
		toolbar_field: catppuccinMocha.mantle,
		toolbar_field_text: catppuccinMocha.text,
		toolbar_field_border: catppuccinMocha.surface1,
		toolbar_field_focus: catppuccinMocha.surface0,
		toolbar_field_text_focus: catppuccinMocha.text,
		toolbar_field_border_focus: catppuccinMocha.lavender,
		toolbar_field_highlight: catppuccinMocha.mauve,
		toolbar_field_highlight_text: catppuccinMocha.crust,
		toolbar_top_separator: catppuccinMocha.surface0,
		toolbar_bottom_separator: catppuccinMocha.surface0,
		toolbar_vertical_separator: catppuccinMocha.surface0,
		icons: catppuccinMocha.text,
		icons_attention: catppuccinMocha.peach,
		button_background_hover: catppuccinMocha.surface0,
		button_background_active: catppuccinMocha.surface1,
		popup: catppuccinMocha.mantle,
		popup_text: catppuccinMocha.text,
		popup_border: catppuccinMocha.surface1,
		popup_highlight: catppuccinMocha.surface0,
		popup_highlight_text: catppuccinMocha.lavender,
		ntp_background: catppuccinMocha.base,
		ntp_card_background: catppuccinMocha.surface0,
		ntp_text: catppuccinMocha.text,
		sidebar: catppuccinMocha.base,
		sidebar_border: catppuccinMocha.surface0,
		sidebar_text: catppuccinMocha.text,
		sidebar_highlight: catppuccinMocha.surface0,
		sidebar_highlight_text: catppuccinMocha.lavender,
	},
	properties: {
		color_scheme: "dark",
		content_color_scheme: "dark",
	},
};

void browser.theme.update(catppuccinMochaTheme);

type ClearPageStorageResult = {
	cacheNamesDeleted: number;
	errors: string[];
	indexedDbDeleted: number;
	localStorageCleared: boolean;
	serviceWorkersUnregistered: number;
	sessionStorageCleared: boolean;
};

type ClearCookiesResult = {
	errors: string[];
	removed: number;
};

type MeasureTabMemoryResult =
	| {
			bytes: number;
			label: string;
			status: "available";
	  }
	| {
			reason: string;
			status: "unsupported";
	  };

async function notify(title: string, message: string): Promise<void> {
	try {
		await browser.notifications.create({
			type: "basic",
			title,
			message,
		});
	} catch (error) {
		console.log(`[${title}] ${message}`, error);
	}
}

function getCookieRemovalUrl(cookie: Browser.Cookies.Cookie, fallbackProtocol: "http:" | "https:"): string {
	const scheme = cookie.secure ? "https:" : fallbackProtocol;
	const host = cookie.domain.replace(/^\./, "");

	return `${scheme}//${host}${cookie.path}`;
}

async function clearCookiesForUrl(url: URL, cookieStoreId: string | undefined): Promise<ClearCookiesResult> {
	const errors: string[] = [];
	const cookies = await browser.cookies.getAll({
		url: url.toString(),
		storeId: cookieStoreId,
		partitionKey: {},
	});
	let removed = 0;
	const fallbackProtocol = url.protocol as "http:" | "https:";

	await Promise.all(
		cookies.map(async (cookie) => {
			try {
				const result = await browser.cookies.remove({
					url: getCookieRemovalUrl(cookie, fallbackProtocol),
					name: cookie.name,
					storeId: cookie.storeId,
					firstPartyDomain: cookie.firstPartyDomain,
					partitionKey: cookie.partitionKey,
				});

				if (result) {
					removed += 1;
				}
			} catch (error) {
				errors.push(
					`cookie ${cookie.name}: ${error instanceof Error ? error.message : String(error)}`,
				);
			}
		}),
	);

	return { errors, removed };
}

function formatBytes(bytes: number): string {
	if (!Number.isFinite(bytes) || bytes < 0) {
		return `${bytes} B`;
	}

	const units = ["B", "KiB", "MiB", "GiB", "TiB"];
	let value = bytes;
	let unitIndex = 0;

	while (value >= 1024 && unitIndex < units.length - 1) {
		value /= 1024;
		unitIndex += 1;
	}

	const digits = value >= 100 || unitIndex === 0 ? 0 : value >= 10 ? 1 : 2;

	return `${value.toFixed(digits)} ${units[unitIndex]}`;
}

function getTabDisplayName(tab: { pendingUrl?: string | null; title?: string | null; url?: string | null }): string {
	if (tab.title && tab.title.trim().length > 0) {
		return tab.title.trim();
	}

	const rawUrl = tab.url ?? tab.pendingUrl;

	if (!rawUrl) {
		return "this tab";
	}

	try {
		return new URL(rawUrl).hostname || rawUrl;
	} catch {
		return rawUrl;
	}
}

async function measureTabMemoryInPage(): Promise<MeasureTabMemoryResult> {
	type PerformanceWithMemory = Performance & {
		memory?: {
			usedJSHeapSize?: number;
		};
		measureUserAgentSpecificMemory?: () => Promise<{ bytes: number }>;
	};

	const performanceWithMemory = performance as PerformanceWithMemory;

	if (typeof performanceWithMemory.measureUserAgentSpecificMemory === "function") {
		if (!crossOriginIsolated) {
			return {
				reason: "Detailed page memory requires a cross-origin-isolated page",
				status: "unsupported",
			};
		}

		try {
			const result = await performanceWithMemory.measureUserAgentSpecificMemory();

			return {
				bytes: result.bytes,
				label: "page memory",
				status: "available",
			};
		} catch (error) {
			return {
				reason: error instanceof Error ? error.message : String(error),
				status: "unsupported",
			};
		}
	}

	if (typeof performanceWithMemory.memory?.usedJSHeapSize === "number") {
		return {
			bytes: performanceWithMemory.memory.usedJSHeapSize,
			label: "JS heap",
			status: "available",
		};
	}

	return {
		reason: "This page does not expose per-tab memory metrics to extensions",
		status: "unsupported",
	};
}

async function clearOriginStorageInPage(): Promise<ClearPageStorageResult> {
	const errors: string[] = [];
	let cacheNamesDeleted = 0;
	let indexedDbDeleted = 0;
	let localStorageCleared = false;
	let serviceWorkersUnregistered = 0;
	let sessionStorageCleared = false;

	function formatError(scope: string, error: unknown): string {
		return `${scope}: ${error instanceof Error ? error.message : String(error)}`;
	}

	try {
		window.localStorage.clear();
		localStorageCleared = true;
	} catch (error) {
		errors.push(formatError("localStorage", error));
	}

	try {
		window.sessionStorage.clear();
		sessionStorageCleared = true;
	} catch (error) {
		errors.push(formatError("sessionStorage", error));
	}

	if (typeof caches !== "undefined") {
		try {
			const cacheNames = await caches.keys();

			await Promise.all(
				cacheNames.map(async (cacheName) => {
					try {
						if (await caches.delete(cacheName)) {
							cacheNamesDeleted += 1;
						}
					} catch (error) {
						errors.push(formatError(`cache ${cacheName}`, error));
					}
				}),
			);
		} catch (error) {
			errors.push(formatError("cacheStorage", error));
		}
	}

	try {
		const indexedDbFactory = indexedDB as IDBFactory & {
			databases?: () => Promise<Array<{ name?: string | null }>>;
		};

		if (typeof indexedDbFactory.databases === "function") {
			const databases = await indexedDbFactory.databases();
			const databaseNames = databases
				.map((database) => database.name)
				.filter((databaseName): databaseName is string => typeof databaseName === "string" && databaseName.length > 0);

			await Promise.all(
				databaseNames.map(
					(databaseName) =>
						new Promise<void>((resolve) => {
							const request = indexedDB.deleteDatabase(databaseName);

							request.onsuccess = () => {
								indexedDbDeleted += 1;
								resolve();
							};
							request.onerror = () => {
								errors.push(formatError(`indexedDB ${databaseName}`, request.error));
								resolve();
							};
							request.onblocked = () => {
								errors.push(`indexedDB ${databaseName}: delete blocked by an open connection`);
								resolve();
							};
						}),
				),
			);
		} else {
			errors.push("indexedDB: database enumeration is unavailable in this browser");
		}
	} catch (error) {
		errors.push(formatError("indexedDB", error));
	}

	if ("serviceWorker" in navigator) {
		try {
			const registrations = await navigator.serviceWorker.getRegistrations();

			await Promise.all(
				registrations.map(async (registration) => {
					try {
						if (await registration.unregister()) {
							serviceWorkersUnregistered += 1;
						}
					} catch (error) {
						errors.push(formatError("serviceWorker", error));
					}
				}),
			);
		} catch (error) {
			errors.push(formatError("serviceWorker", error));
		}
	}

	return {
		cacheNamesDeleted,
		errors,
		indexedDbDeleted,
		localStorageCleared,
		serviceWorkersUnregistered,
		sessionStorageCleared,
	};
}

async function clearActivePageStorage(tabId: number): Promise<void> {
	try {
		const tab = await browser.tabs.get(tabId);
		const rawUrl = tab.url ?? tab.pendingUrl;

		if (!rawUrl) {
			await notify("Glide", "The active tab does not have a URL yet.");
			return;
		}

		const url = new URL(rawUrl);

		if (url.protocol !== "http:" && url.protocol !== "https:") {
			await notify("Glide", `Storage clearing only supports http(s) tabs. Current protocol: ${url.protocol}`);
			return;
		}

		const injectionResults = await browser.scripting.executeScript({
			target: { tabId },
			world: "MAIN",
			func: clearOriginStorageInPage,
		});
		const injectionResult = injectionResults[0];

		if (!injectionResult) {
			throw new Error("Storage clear script did not return any frame results");
		}

		if (injectionResult.error) {
			throw injectionResult.error;
		}

		const pageStorage = injectionResult.result as ClearPageStorageResult | undefined;

		if (!pageStorage) {
			throw new Error("Storage clear script did not return a result");
		}

		const cookies = await clearCookiesForUrl(url, tab.cookieStoreId);
		const warnings = [...pageStorage.errors, ...cookies.errors];
		const summary = [
			`${cookies.removed} cookies`,
			pageStorage.localStorageCleared ? "localStorage" : "localStorage skipped",
			pageStorage.sessionStorageCleared ? "sessionStorage" : "sessionStorage skipped",
			`${pageStorage.indexedDbDeleted} IndexedDB DBs`,
			`${pageStorage.cacheNamesDeleted} caches`,
			`${pageStorage.serviceWorkersUnregistered} service workers`,
		].join(", ");

		if (warnings.length > 0) {
			console.error("Storage clear warnings:", warnings);
		}

		await notify(
			"Glide",
			warnings.length > 0
				? `Cleared ${summary} for ${url.origin}. See console for ${warnings.length} warning(s).`
				: `Cleared ${summary} for ${url.origin}.`,
		);
	} catch (error) {
		console.error("Failed to clear active page storage:", error);
		await notify(
			"Glide",
			`Failed to clear active page storage: ${error instanceof Error ? error.message : String(error)}`,
		);
	}
}

async function openTabMemoryDiagnostics(tabId: number): Promise<void> {
	const sourceTab = await browser.tabs.get(tabId).catch(() => undefined);

	await browser.tabs.create({
		...(typeof sourceTab?.index === "number" ? { index: sourceTab.index + 1 } : {}),
		...(typeof sourceTab?.windowId === "number" ? { windowId: sourceTab.windowId } : {}),
		url: "about:processes",
	});
}

async function inspectTabMemory(tabId: number): Promise<void> {
	try {
		const tab = await browser.tabs.get(tabId);
		const rawUrl = tab.url ?? tab.pendingUrl;
		const displayName = getTabDisplayName(tab);

		if (!rawUrl) {
			await openTabMemoryDiagnostics(tabId);
			await notify("Glide", `Opened about:processes to inspect memory for ${displayName}.`);
			return;
		}

		let url: URL | undefined;

		try {
			url = new URL(rawUrl);
		} catch {
			url = undefined;
		}

		if (!url || (url.protocol !== "http:" && url.protocol !== "https:")) {
			await openTabMemoryDiagnostics(tabId);
			await notify(
				"Glide",
				`Opened about:processes for ${displayName}. Direct tab memory only works on http(s) pages.`,
			);
			return;
		}

		const injectionResults = await browser.scripting.executeScript({
			target: { tabId },
			world: "MAIN",
			func: measureTabMemoryInPage,
		});
		const injectionResult = injectionResults[0];

		if (!injectionResult) {
			throw new Error("Memory inspection script did not return any frame results");
		}

		if (injectionResult.error) {
			throw injectionResult.error;
		}

		const memoryResult = injectionResult.result as MeasureTabMemoryResult | undefined;

		if (memoryResult?.status === "available") {
			await notify("Glide", `${displayName}: ${formatBytes(memoryResult.bytes)} of ${memoryResult.label}.`);
			return;
		}

		await openTabMemoryDiagnostics(tabId);
		await notify(
			"Glide",
			`${displayName}: ${memoryResult?.reason ?? "Direct page memory is unavailable"}. Opened about:processes.`,
		);
	} catch (error) {
		console.error("Failed to inspect tab memory:", error);

		try {
			await openTabMemoryDiagnostics(tabId);
		} catch (openError) {
			console.error("Failed to open about:processes after memory inspection error:", openError);
		}

		await notify(
			"Glide",
			`Failed to inspect tab memory: ${error instanceof Error ? error.message : String(error)}`,
		);
	}
}

function installGmailMarkdownPasteContentScript(): void {
	type TableAlignment = "center" | "left" | "right";

	type HtmlToken = {
		html: string;
		token: string;
	};

	const globalState = window as Window & {
		__glideGmailMarkdownPasteInstalled?: boolean;
	};

	if (globalState.__glideGmailMarkdownPasteInstalled) {
		return;
	}

	globalState.__glideGmailMarkdownPasteInstalled = true;

	const emailTextStyle =
		"font-family: Arial, Helvetica, sans-serif; font-size: 14px; line-height: 1.5; color: #202124;";
	const paragraphStyle = "margin: 0 0 12px;";
	const listStyle = "margin: 0 0 12px 24px; padding: 0;";
	const listItemStyle = "margin: 0 0 6px;";
	const blockquoteStyle =
		"margin: 0 0 12px; padding: 8px 0 8px 14px; border-left: 4px solid #dadce0; color: #3c4043;";
	const inlineCodeStyle =
		"font-family: Consolas, Monaco, 'Liberation Mono', monospace; font-size: 0.95em; background: #f1f3f4; border-radius: 3px; padding: 1px 4px;";
	const codeBlockStyle =
		"font-family: Consolas, Monaco, 'Liberation Mono', monospace; font-size: 13px; line-height: 1.45; background: #f8f9fa; border: 1px solid #dadce0; border-radius: 6px; margin: 0 0 12px; padding: 10px 12px; white-space: pre-wrap;";
	const tableStyle = "border-collapse: collapse; margin: 0 0 14px; width: 100%;";
	const tableHeaderStyle =
		"border: 1px solid #dadce0; background: #f8f9fa; font-weight: 700; padding: 6px 8px; vertical-align: top;";
	const tableCellStyle = "border: 1px solid #dadce0; padding: 6px 8px; vertical-align: top;";

	function escapeHtml(value: string): string {
		return value.replace(/[&<>]/g, (character) => {
			if (character === "&") {
				return "&amp;";
			}

			if (character === "<") {
				return "&lt;";
			}

			return "&gt;";
		});
	}

	function escapeAttribute(value: string): string {
		return escapeHtml(value).replace(/"/g, "&quot;");
	}

	function sanitizeUrl(rawUrl: string): string | undefined {
		const trimmedUrl = rawUrl.trim().replace(/^<|>$/g, "");

		if (!/^(https?:|mailto:|tel:)/i.test(trimmedUrl)) {
			return undefined;
		}

		try {
			const parsedUrl = new URL(trimmedUrl);
			const allowedProtocols = new Set(["http:", "https:", "mailto:", "tel:"]);

			return allowedProtocols.has(parsedUrl.protocol) ? parsedUrl.href : undefined;
		} catch {
			return undefined;
		}
	}

	function renderInline(text: string): string {
		const tokens: HtmlToken[] = [];
		const createToken = (html: string): string => {
			const token = `\uE000${tokens.length}\uE001`;

			tokens.push({ html, token });
			return token;
		};

		let workingText = text.replace(/`([^`\n]+)`/g, (_match: string, code: string) =>
			createToken(`<code style="${inlineCodeStyle}">${escapeHtml(code)}</code>`),
		);

		workingText = workingText.replace(
			/!\[([^\]]*)\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g,
			(match: string, altText: string, url: string) => {
				const safeUrl = sanitizeUrl(url);

				if (!safeUrl) {
					return match;
				}

				const label = altText.trim().length > 0 ? `[image: ${altText.trim()}]` : "[image]";

				return createToken(
					`<a href="${escapeAttribute(safeUrl)}" style="color: #1155cc; text-decoration: underline;">${escapeHtml(label)}</a>`,
				);
			},
		);

		workingText = workingText.replace(
			/\[([^\]]+)\]\(([^)\s]+)(?:\s+"[^"]*")?\)/g,
			(match: string, label: string, url: string) => {
				const safeUrl = sanitizeUrl(url);

				if (!safeUrl) {
					return label;
				}

				return createToken(
					`<a href="${escapeAttribute(safeUrl)}" style="color: #1155cc; text-decoration: underline;">${renderInline(label)}</a>`,
				);
			},
		);

		workingText = escapeHtml(workingText)
			.replace(/\*\*([^*\n]+)\*\*/g, "<strong>$1</strong>")
			.replace(/__([^_\n]+)__/g, "<strong>$1</strong>")
			.replace(/~~([^~\n]+)~~/g, "<s>$1</s>")
			.replace(/(^|[\s([{"'>])\*([^*\n]+)\*(?=$|[\s.,;:!?)}\]"'<])/g, "$1<em>$2</em>")
			.replace(/(^|[\s([{"'>])_([^_\n]+)_(?=$|[\s.,;:!?)}\]"'<])/g, "$1<em>$2</em>");

		for (const { html, token } of tokens) {
			workingText = workingText.split(token).join(html);
		}

		return workingText;
	}

	function splitTableRow(line: string): string[] {
		let trimmedLine = line.trim();

		if (trimmedLine.startsWith("|")) {
			trimmedLine = trimmedLine.slice(1);
		}

		if (trimmedLine.endsWith("|")) {
			trimmedLine = trimmedLine.slice(0, -1);
		}

		const cells: string[] = [];
		let cell = "";
		let escaped = false;

		for (const character of trimmedLine) {
			if (escaped) {
				cell += character;
				escaped = false;
				continue;
			}

			if (character === "\\") {
				escaped = true;
				continue;
			}

			if (character === "|") {
				cells.push(cell.trim());
				cell = "";
				continue;
			}

			cell += character;
		}

		if (escaped) {
			cell += "\\";
		}

		cells.push(cell.trim());
		return cells;
	}

	function parseAlignment(separatorCell: string): TableAlignment | undefined {
		const trimmedCell = separatorCell.trim();

		if (!/^:?-{3,}:?$/.test(trimmedCell)) {
			return undefined;
		}

		if (trimmedCell.startsWith(":") && trimmedCell.endsWith(":")) {
			return "center";
		}

		if (trimmedCell.endsWith(":")) {
			return "right";
		}

		return "left";
	}

	function isTableSeparator(line: string): boolean {
		const cells = splitTableRow(line);

		return cells.length > 1 && cells.every((cell) => /^:?-{3,}:?$/.test(cell.trim()));
	}

	function isTableStart(lines: string[], index: number): boolean {
		const currentLine = lines[index];
		const nextLine = lines[index + 1];

		return (
			currentLine !== undefined &&
			nextLine !== undefined &&
			currentLine.includes("|") &&
			isTableSeparator(nextLine)
		);
	}

	function renderTable(headers: string[], separator: string, rows: string[][]): string {
		const alignments = splitTableRow(separator).map(parseAlignment);
		const headerHtml = headers
			.map((header, index) => {
				const alignment = alignments[index];
				const alignmentStyle = alignment ? ` text-align: ${alignment};` : "";

				return `<th style="${tableHeaderStyle}${alignmentStyle}">${renderInline(header)}</th>`;
			})
			.join("");
		const bodyHtml = rows
			.map((row) => {
				const cellsHtml = row
					.map((cell, index) => {
						const alignment = alignments[index];
						const alignmentStyle = alignment ? ` text-align: ${alignment};` : "";

						return `<td style="${tableCellStyle}${alignmentStyle}">${renderInline(cell)}</td>`;
					})
					.join("");

				return `<tr>${cellsHtml}</tr>`;
			})
			.join("");

		return `<table style="${tableStyle}"><thead><tr>${headerHtml}</tr></thead><tbody>${bodyHtml}</tbody></table>`;
	}

	function isBlockBoundary(lines: string[], index: number): boolean {
		const line = lines[index];

		if (line === undefined) {
			return false;
		}

		return (
			/^#{1,6}\s+/.test(line) ||
			/^```/.test(line) ||
			/^>\s?/.test(line) ||
			/^\s*[-*+]\s+/.test(line) ||
			/^\s*\d+[.)]\s+/.test(line) ||
			isTableStart(lines, index)
		);
	}

	function renderHeading(line: string): string | undefined {
		const match = line.match(/^(#{1,6})\s+(.+?)\s*#*\s*$/);

		if (!match) {
			return undefined;
		}

		const marker = match[1];
		const headingText = match[2];

		if (marker === undefined || headingText === undefined) {
			return undefined;
		}

		const level = Math.min(marker.length, 6);
		const sizeByLevel = new Map<number, string>([
			[1, "24px"],
			[2, "20px"],
			[3, "17px"],
			[4, "15px"],
			[5, "14px"],
			[6, "13px"],
		]);
		const fontSize = sizeByLevel.get(level) ?? "14px";
		const marginTop = level <= 2 ? "18px" : "14px";

		return `<h${level} style="font-family: Arial, Helvetica, sans-serif; font-size: ${fontSize}; line-height: 1.25; margin: ${marginTop} 0 8px; color: #202124;">${renderInline(headingText)}</h${level}>`;
	}

	function renderBlocks(markdown: string): string {
		const lines = markdown.replace(/\r\n?/g, "\n").trim().split("\n");
		const blocks: string[] = [];
		let index = 0;

		while (index < lines.length) {
			const line = lines[index];

			if (line === undefined) {
				break;
			}

			if (line.trim().length === 0) {
				index += 1;
				continue;
			}

			if (/^```/.test(line)) {
				index += 1;

				const codeLines: string[] = [];

				while (index < lines.length) {
					const codeLine = lines[index];

					if (codeLine === undefined || /^```/.test(codeLine)) {
						break;
					}

					codeLines.push(codeLine);
					index += 1;
				}

				if (index < lines.length) {
					index += 1;
				}

				blocks.push(`<pre style="${codeBlockStyle}"><code>${escapeHtml(codeLines.join("\n"))}</code></pre>`);
				continue;
			}

			if (isTableStart(lines, index)) {
				const headerLine = lines[index];
				const separatorLine = lines[index + 1];

				if (headerLine === undefined || separatorLine === undefined) {
					break;
				}

				const headers = splitTableRow(headerLine);
				const rows: string[][] = [];

				index += 2;

				while (index < lines.length) {
					const rowLine = lines[index];

					if (rowLine === undefined || rowLine.trim().length === 0 || !rowLine.includes("|")) {
						break;
					}

					rows.push(splitTableRow(rowLine));
					index += 1;
				}

				blocks.push(renderTable(headers, separatorLine, rows));
				continue;
			}

			const heading = renderHeading(line);

			if (heading) {
				blocks.push(heading);
				index += 1;
				continue;
			}

			if (/^>\s?/.test(line)) {
				const quotedLines: string[] = [];

				while (index < lines.length) {
					const quoteLine = lines[index];

					if (quoteLine === undefined || !/^>\s?/.test(quoteLine)) {
						break;
					}

					quotedLines.push(quoteLine.replace(/^>\s?/, ""));
					index += 1;
				}

				blocks.push(`<blockquote style="${blockquoteStyle}">${renderBlocks(quotedLines.join("\n"))}</blockquote>`);
				continue;
			}

			const unorderedMatch = line.match(/^\s*[-*+]\s+(.+)$/);
			const orderedMatch = line.match(/^\s*\d+[.)]\s+(.+)$/);

			if (unorderedMatch || orderedMatch) {
				const ordered = Boolean(orderedMatch);
				const tagName = ordered ? "ol" : "ul";
				const listItems: string[] = [];

				while (index < lines.length) {
					const itemLine = lines[index];

					if (itemLine === undefined) {
						break;
					}

					const itemMatch = ordered ? itemLine.match(/^\s*\d+[.)]\s+(.+)$/) : itemLine.match(/^\s*[-*+]\s+(.+)$/);
					const itemText = itemMatch?.[1];

					if (itemText === undefined) {
						break;
					}

					listItems.push(`<li style="${listItemStyle}">${renderInline(itemText)}</li>`);
					index += 1;
				}

				blocks.push(`<${tagName} style="${listStyle}">${listItems.join("")}</${tagName}>`);
				continue;
			}

			const paragraphLines: string[] = [];

			while (index < lines.length) {
				const paragraphLine = lines[index];

				if (
					paragraphLine === undefined ||
					paragraphLine.trim().length === 0 ||
					(paragraphLines.length > 0 && isBlockBoundary(lines, index))
				) {
					break;
				}

				paragraphLines.push(paragraphLine.trim());
				index += 1;
			}

			if (paragraphLines.length > 0) {
				blocks.push(`<p style="${paragraphStyle}">${renderInline(paragraphLines.join(" "))}</p>`);
				continue;
			}

			index += 1;
		}

		return blocks.join("");
	}

	function stripMarkdownPasteMarker(markdown: string): string {
		return markdown.replace(/^\s*<!--\s*gmail-md\s*-->\s*/i, "");
	}

	function looksLikeMarkdown(text: string, clipboardTypes: readonly string[]): boolean {
		const trimmedText = text.trim();

		if (trimmedText.length < 3) {
			return false;
		}

		if (/^\s*<!--\s*gmail-md\s*-->/i.test(trimmedText)) {
			return true;
		}

		if (clipboardTypes.includes("text/markdown") || clipboardTypes.includes("text/x-markdown")) {
			return true;
		}

		if (/^\s*</.test(trimmedText) && /<\/?[a-z][\s>]/i.test(trimmedText.slice(0, 200))) {
			return false;
		}

		const lines = trimmedText.split(/\n/);
		let markdownSignals = 0;
		const listLineCount = lines.filter((candidateLine) =>
			/^\s*[-*+]\s+/.test(candidateLine) || /^\s*\d+[.)]\s+/.test(candidateLine)
		).length;

		if (lines.some((candidateLine, lineIndex) => candidateLine.includes("|") && isTableStart(lines, lineIndex))) {
			markdownSignals += 3;
		}

		if (lines.some((candidateLine) => /^#{1,6}\s+/.test(candidateLine))) {
			markdownSignals += 2;
		}

		if (listLineCount > 0) {
			markdownSignals += listLineCount >= 2 ? 2 : 1;
		}

		if (lines.some((candidateLine) => /^>\s?/.test(candidateLine))) {
			markdownSignals += 1;
		}

		if (/```|`[^`\n]+`/.test(trimmedText)) {
			markdownSignals += 1;
		}

		if (/\[[^\]]+\]\((?:https?:|mailto:|tel:)[^)]+\)/i.test(trimmedText)) {
			markdownSignals += 1;
		}

		if (/(^|[\s([{"'>])(?:\*\*[^*\n]+\*\*|__[^_\n]+__|\*[^*\n]+\*|_[^_\n]+_)(?=$|[\s.,;:!?)}\]"'<])/m.test(trimmedText)) {
			markdownSignals += 1;
		}

		return markdownSignals >= 2 || (markdownSignals >= 1 && lines.length >= 3 && trimmedText.includes("\n\n"));
	}

	function findGmailComposeBody(target: EventTarget | null): HTMLElement | undefined {
		if (!(target instanceof Element)) {
			return undefined;
		}

		const editable = target.closest<HTMLElement>('[contenteditable="true"]');

		if (!editable) {
			return undefined;
		}

		const ariaLabel = (editable.getAttribute("aria-label") ?? "").toLowerCase();

		if (ariaLabel.includes("subject")) {
			return undefined;
		}

		return editable;
	}

	function insertHtml(editable: HTMLElement, html: string): void {
		editable.focus();

		if (document.execCommand("insertHTML", false, html)) {
			return;
		}

		const selection = window.getSelection();

		if (!selection || selection.rangeCount === 0) {
			editable.insertAdjacentHTML("beforeend", html);
			return;
		}

		const range = selection.getRangeAt(0);

		if (!editable.contains(range.commonAncestorContainer)) {
			editable.insertAdjacentHTML("beforeend", html);
			return;
		}

		range.deleteContents();

		const template = document.createElement("template");

		template.innerHTML = html;

		const fragment = template.content;
		const lastChild = fragment.lastChild;

		range.insertNode(fragment);

		if (lastChild) {
			range.setStartAfter(lastChild);
			range.collapse(true);
			selection.removeAllRanges();
			selection.addRange(range);
		}
	}

	document.addEventListener(
		"paste",
		(event) => {
			const editable = findGmailComposeBody(event.target);
			const clipboardData = event.clipboardData;

			if (!editable || !clipboardData) {
				return;
			}

			const markdown = clipboardData.getData("text/plain");
			const clipboardTypes = Array.from(clipboardData.types);

			if (!looksLikeMarkdown(markdown, clipboardTypes)) {
				return;
			}

			const html = `<div style="${emailTextStyle}">${renderBlocks(stripMarkdownPasteMarker(markdown))}</div>`;

			event.preventDefault();
			event.stopPropagation();
			insertHtml(editable, html);
		},
		true,
	);
}

let gmailMarkdownPasteRegistration: Browser.ContentScripts.RegisteredContentScript | undefined;

async function registerGmailMarkdownPasteContentScript(): Promise<void> {
	if (gmailMarkdownPasteRegistration) {
		return;
	}

	try {
		gmailMarkdownPasteRegistration = await browser.contentScripts.register({
			allFrames: true,
			js: [{ code: `(${installGmailMarkdownPasteContentScript.toString()})();` }],
			matches: ["https://mail.google.com/*"],
			runAt: "document_idle",
		});
	} catch (error) {
		console.error("Failed to register Gmail Markdown paste content script:", error);
	}
}

async function installGmailMarkdownPasteForTab(tabId: number): Promise<void> {
	try {
		const tab = await browser.tabs.get(tabId);
		const rawUrl = tab.url ?? tab.pendingUrl;

		if (!rawUrl) {
			await notify("Glide", "The active tab does not have a URL yet.");
			return;
		}

		const url = new URL(rawUrl);

		if (url.hostname !== "mail.google.com") {
			await notify("Glide", "Open a Gmail tab before enabling Markdown paste for this tab.");
			return;
		}

		await browser.scripting.executeScript({
			func: installGmailMarkdownPasteContentScript,
			target: { allFrames: true, tabId },
		});

		await notify("Glide", "Markdown paste is enabled for this Gmail tab.");
	} catch (error) {
		console.error("Failed to install Gmail Markdown paste helper:", error);
		await notify(
			"Glide",
			`Failed to enable Markdown paste: ${error instanceof Error ? error.message : String(error)}`,
		);
	}
}

void registerGmailMarkdownPasteContentScript();

async function openGithubProfile(tabId: number): Promise<void> {
	try {
		await browser.tabs.update(tabId, {
			url: "https://github.com/OneNoted",
		});
	} catch (error) {
		console.error("Failed to open GitHub profile:", error);
		await notify(
			"Glide",
			`Failed to open GitHub profile: ${error instanceof Error ? error.message : String(error)}`,
		);
	}
}

glide.keymaps.set(
	"normal",
	"<leader>gh",
	({ tab_id }) => {
		void openGithubProfile(tab_id);
	},
	{ description: "Open GitHub profile" },
);

// Development helper for resetting site state without leaving the keyboard.
glide.keymaps.set(
	"normal",
	"<leader>cs",
	({ tab_id }) => {
		void clearActivePageStorage(tab_id);
	},
	{ description: "Clear storage for the active page" },
);

glide.keymaps.set(
	"normal",
	"<leader>tm",
	({ tab_id }) => {
		void inspectTabMemory(tab_id);
	},
	{ description: "Inspect memory for the active tab" },
);

glide.keymaps.set(
	"normal",
	"<leader>gm",
	({ tab_id }) => {
		void installGmailMarkdownPasteForTab(tab_id);
	},
	{ description: "Enable Gmail Markdown paste helper" },
);
