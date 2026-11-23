import importlib.util
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("select_inferzero_release.py")
spec = importlib.util.spec_from_file_location("select_inferzero_release", SCRIPT)
selector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(selector)


class ReleaseSelectionTests(unittest.TestCase):
    releases = [
        {"tag_name": "2026.11.23.12", "draft": False, "prerelease": False},
        {"tag_name": "2026.11.23.13-rc1", "draft": False, "prerelease": True},
        {"tag_name": "2026.11.23.14", "draft": True, "prerelease": False},
        {"tag_name": "2026.11.22.26", "draft": False, "prerelease": False},
    ]

    def test_blank_selects_latest_stable_and_both_tags(self):
        self.assertEqual(selector.resolve(self.releases), ("2026.11.23.12", ["latest", "2026.11.23.12"]))

    def test_requested_older_release_keeps_version_tag_without_latest(self):
        self.assertEqual(selector.resolve(self.releases, "2026.11.22.26"), ("2026.11.22.26", ["2026.11.22.26"]))

    def test_prerelease_and_draft_are_rejected(self):
        for tag in ("2026.11.23.13-rc1", "2026.11.23.14"):
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                selector.resolve(self.releases, tag)

    def test_missing_stable_release_is_rejected(self):
        with self.assertRaises(ValueError):
            selector.resolve([{"tag_name": "rc", "draft": False, "prerelease": True}])


if __name__ == "__main__":
    unittest.main()
