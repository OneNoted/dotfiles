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
