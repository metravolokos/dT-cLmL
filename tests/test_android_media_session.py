"""Android foreground MediaSession manifest contract without GMS dependencies."""

from pathlib import Path
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
ANDROID = "{http://schemas.android.com/apk/res/android}"


class AndroidMediaSessionManifestTests(unittest.TestCase):
    def test_foreground_playback_service_and_button_receiver(self):
        manifest = ROOT / "android/app/src/main/AndroidManifest.xml"
        tree = ET.parse(manifest)
        root = tree.getroot()
        permissions = {
            item.attrib.get(ANDROID + "name")
            for item in root.findall("uses-permission")
        }
        self.assertIn("android.permission.INTERNET", permissions)
        self.assertIn("android.permission.FOREGROUND_SERVICE", permissions)
        self.assertIn("android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK", permissions)
        self.assertIn("android.permission.WAKE_LOCK", permissions)

        application = root.find("application")
        self.assertIsNotNone(application)
        service = next(
            (
                entry for entry in application.findall("service")
                if entry.attrib.get(ANDROID + "name")
                == "com.ryanheise.audioservice.AudioService"
            ),
            None,
        )
        self.assertIsNotNone(service)
        self.assertEqual(service.attrib[ANDROID + "foregroundServiceType"], "mediaPlayback")
        receiver = next(
            (
                entry for entry in application.findall("receiver")
                if entry.attrib.get(ANDROID + "name")
                == "com.ryanheise.audioservice.MediaButtonReceiver"
            ),
            None,
        )
        self.assertIsNotNone(receiver)
        receiver_actions = {
            action.attrib.get(ANDROID + "name")
            for intent in receiver.findall("intent-filter")
            for action in intent.findall("action")
        }
        self.assertIn("android.intent.action.MEDIA_BUTTON", receiver_actions)

    def test_android_activity_uses_media_session_host(self):
        code = (
            ROOT
            / "android/app/src/main/kotlin/com/cloudmailplayer/cloudmail_player/MainActivity.kt"
        ).read_text(encoding="utf-8")
        self.assertIn("class MainActivity : AudioServiceActivity()", code)


if __name__ == "__main__":
    unittest.main()
