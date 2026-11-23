#!/usr/bin/env python3
"""Resolve a stable Inferzero release and choose safe image tags."""
import json
import re
import sys

TAG_RE = re.compile(r"^[A-Za-z0-9._-]+$")


def resolve(releases, requested=""):
    stable = next((item for item in releases if not item.get("draft") and not item.get("prerelease")), None)
    if stable is None:
        raise ValueError("No published stable Inferzero release found")
    release = stable if not requested else next((item for item in releases if item.get("tag_name") == requested), None)
    if release is None or release.get("draft") or release.get("prerelease"):
        raise ValueError("Requested release is not a published stable release")
    tag = release.get("tag_name", "")
    if not TAG_RE.fullmatch(tag):
        raise ValueError("Invalid release tag")
    tags = [tag]
    if tag == stable["tag_name"]:
        tags.insert(0, "latest")
    return tag, tags


def main():
    try:
        releases = json.load(sys.stdin)
        tag, tags = resolve(releases, sys.argv[1] if len(sys.argv) > 1 else "")
    except (ValueError, KeyError, TypeError, json.JSONDecodeError) as exc:
        print(str(exc), file=sys.stderr)
        return 1
    print(f"release={tag}")
    print("tags=" + ",".join(tags))
    print("latest=" + ("true" if "latest" in tags else "false"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
