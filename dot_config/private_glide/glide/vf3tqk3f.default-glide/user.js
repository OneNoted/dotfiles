// Keep large restored Glide sessions from exhausting RAM/swap and degrading
// browser chrome popups such as context menus and extension panels.
user_pref("browser.tabs.unloadOnLowMemory", true);
user_pref("browser.tabs.min_inactive_duration_before_unload", 300000);
user_pref("browser.low_commit_space_threshold_mb", 2048);
user_pref("browser.low_commit_space_threshold_percent", 20);

// Limit content-process fan-out. This trades some isolation parallelism for
// lower resident memory in 50+ tab sessions.
user_pref("dom.ipc.processCount", 4);
user_pref("dom.ipc.processCount.webIsolated", 2);
user_pref("dom.ipc.processPrelaunch.enabled", false);

// Keep fewer live back-forward page viewers in memory.
user_pref("browser.sessionhistory.max_total_viewers", 2);
