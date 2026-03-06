#!/usr/bin/env python3

from __future__ import annotations

import pathlib
import sys
import tomllib


def main() -> int:
    root = pathlib.Path("dot_config/yazi")
    package_path = root / "package.toml"

    with package_path.open("rb") as fh:
        data = tomllib.load(fh)

    missing: list[str] = []
    deps = data.get("plugin", {}).get("deps", [])

    for dep in deps:
        use = dep["use"]
        name = use.rsplit(":", 1)[-1].split("/", 1)[-1]
        plugin_dir = root / "plugins" / f"{name}.yazi"
        has_entry = (plugin_dir / "readonly_main.lua").exists() or (plugin_dir / "main.lua").exists()
        if not has_entry:
            missing.append(f"{use} -> {plugin_dir}")

    if missing:
        sys.stderr.write("Missing vendored Yazi plugins:\n")
        sys.stderr.write("\n".join(missing))
        sys.stderr.write("\n")
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
