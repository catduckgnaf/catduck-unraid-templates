#!/usr/bin/env python3
# Copyright (c) 2019 Selfhosters
# SPDX-License-Identifier: MIT
"""Minimal template checks adapted from the Selfhosters checker."""
import argparse
import os
import re
import sys
import xml.etree.ElementTree as ET


def check_xml(filename):
    root = ET.parse(filename).getroot()
    errors = []
    if not any((root.findtext(tag) or "").strip() for tag in ("Support", "Project")):
        errors.append("Missing Support or Project link")
    for tag in ("Support", "Project"):
        value = root.findtext(tag)
        if value and not value.startswith(("https://", "http://")):
            errors.append(f"{tag} must be an HTTP(S) URL")
    if root.find("WebUI") is not None:
        match = re.search(r"\[PORT:(\d+)\]", root.findtext("WebUI") or "", re.I)
        if match and match.group(1) not in [c.get("Target") for c in root.findall("Config") if c.get("Type") == "Port"]:
            errors.append(f"WebUI port {match.group(1)} is not a configured target")
    for tag in ("Support", "Project", "Registry", "Icon", "TemplateURL"):
        value = root.findtext(tag)
        if value and not value.startswith(("https://", "http://")):
            errors.append(f"{tag} must be an HTTP(S) URL")
    for config in root.findall("Config"):
        if config.get("Name") == "SMTP_PASSWORD":
            if config.get("Mask") != "true" or (config.text or "").strip():
                errors.append("SMTP_PASSWORD must be masked and have no prefilled value")
    for error in errors:
        print(f"::error file={filename}::{error}")
    return errors


def main():
    parser = argparse.ArgumentParser(description="Unraid template checker")
    parser.add_argument("--files", nargs="+", default=None)
    args = parser.parse_args()
    files = args.files or [os.path.join("templates", f) for f in os.listdir("templates") if f.endswith(".xml")]
    errors = 0
    for filename in files:
        errors += len(check_xml(filename))
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
