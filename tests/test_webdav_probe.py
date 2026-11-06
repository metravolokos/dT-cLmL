"""Offline tests; no real credentials or external requests."""
import unittest
from tools.webdav_probe import remote_path, parse_entries, safe_range_header, Client, ProbeError

XML = b"""<d:multistatus xmlns:d="DAV:"><d:response>
<d:href>/AllMusic/</d:href><d:propstat>
<d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop>
<d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response></d:multistatus>"""


class M0Tests(unittest.TestCase):
    def test_collection(self):
        self.assertEqual(parse_entries(XML), [("/AllMusic/", True)])

    def test_invalid_xml(self):
        with self.assertRaises(ProbeError):
            parse_entries(b"<not-valid")

    def test_cross_origin_forbidden(self):
        with self.assertRaises(ProbeError):
            remote_path("https://evil.invalid/AllMusic/track.mp3")

    def test_parent_path_forbidden(self):
        with self.assertRaises(ProbeError):
            remote_path("/AllMusic/%2e%2e/secret")

    def test_range_format(self):
        self.assertEqual(safe_range_header("bytes=0-4095/50000"), "bytes=0-4095/50000")
        self.assertEqual(safe_range_header("bytes 0-4095/50000"), "bytes 0-4095/50000")
        self.assertEqual(safe_range_header("sensitive text"), "unexpected-format")

    def test_missing_credentials(self):
        with self.assertRaises(ProbeError):
            Client("", "")


if __name__ == "__main__":
    unittest.main()
