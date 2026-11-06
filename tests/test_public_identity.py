"""Offline identity contract for the Windows/Linux desktop app."""
from pathlib import Path
import json
import unittest

ROOT = Path(__file__).resolve().parents[1]
BRAND = "teStPlaYclouDE"

class PublicIdentityTests(unittest.TestCase):
    def test_arb_display_name(self):
        data = json.loads((ROOT / "lib/l10n/app_ru.arb").read_text(encoding="utf-8"))
        self.assertEqual(data["appTitle"], BRAND)

    def test_desktop_display_names(self):
        expected = {
            "linux/runner/my_application.cc": f'gtk_header_bar_set_title(header_bar, "{BRAND}")',
            "windows/runner/main.cpp": f'window.Create(L"{BRAND}"',
            "packaging/flatpak/com.cloudmailplayer.cloudmail_player.desktop": f"Name={BRAND}",
        }
        for path, value in expected.items():
            with self.subTest(path=path):
                self.assertIn(value, (ROOT / path).read_text(encoding="utf-8"))

    def test_stable_internal_ids(self):
        self.assertIn("name: cloudmail_player", (ROOT / "pubspec.yaml").read_text())
        self.assertIn(
            "app-id: com.cloudmailplayer.cloudmail_player",
            (ROOT / "packaging/flatpak/com.cloudmailplayer.cloudmail_player.yml").read_text(),
        )

if __name__ == "__main__":
    unittest.main()
