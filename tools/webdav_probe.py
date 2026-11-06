#!/usr/bin/env python3
"""Read-only, bounded WebDAV Cloud Mail.ru experiment. Python stdlib only."""
from __future__ import annotations

import argparse
import base64
import datetime
import json
import os
from pathlib import PurePosixPath
import re
import time
from urllib.error import HTTPError, URLError
from urllib.parse import quote, unquote, urlsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener
import xml.etree.ElementTree as ET

HOST = "webdav.cloud.mail.ru"
ROOT = "/AllMusic"
EXTENSIONS = {".flac", ".mp3", ".m4a", ".aac", ".ogg", ".opus", ".wav", ".wma"}
MAX_XML = 8 * 1024 * 1024
MAX_AUDIO_READ = 131073
PROPFIND = b"""<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype/><d:getetag/>
<d:getcontentlength/><d:getlastmodified/></d:prop></d:propfind>"""


class ProbeError(Exception):
    """Message deliberately contains no URL, credentials or private filename."""


class DenyRedirects(HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, msg, headers, newurl):
        return None


def remote_path(href: str) -> str:
    try:
        parsed = urlsplit(href)
        if (parsed.hostname and parsed.hostname.lower() != HOST) or parsed.username or parsed.password:
            raise ProbeError("Unexpected PROPFIND origin")
        path = unquote(parsed.path)
        if not path.startswith("/") or any(p in (".", "..") for p in path.split("/")):
            raise ProbeError("Unsafe PROPFIND resource")
        return path
    except ValueError:
        raise ProbeError("Invalid PROPFIND resource") from None


def parse_entries(xml: bytes) -> list[tuple[str, bool]]:
    try:
        tree = ET.fromstring(xml)
    except ET.ParseError:
        raise ProbeError("Malformed PROPFIND XML") from None
    ns = "{DAV:}"
    result = []
    for response in tree.findall(ns + "response"):
        href = response.findtext(ns + "href")
        if not href:
            continue
        for block in response.findall(ns + "propstat"):
            if " 200 " not in block.findtext(ns + "status", ""):
                continue
            props = block.find(ns + "prop")
            if props is None:
                continue
            kind = props.find(ns + "resourcetype")
            is_dir = kind is not None and kind.find(ns + "collection") is not None
            result.append((remote_path(href), is_dir))
            break
    return result


def safe_range_header(value: str | None) -> str | None:
    if value is None:
        return None
    return value if re.fullmatch(r"bytes[ =]\d+-\d+/(?:\d+|\*)", value) else "unexpected-format"


class Client:
    def __init__(self, username: str, password: str):
        if not username or not password:
            raise ProbeError("Missing Codex personal environment variables")
        token = base64.b64encode((username + ":" + password).encode()).decode("ascii")
        self.auth = "Basic " + token
        self.opener = build_opener(DenyRedirects())

    def fetch(self, method: str, path: str, headers=None, body=None, cap=MAX_AUDIO_READ):
        if method not in {"PROPFIND", "HEAD", "GET"}:
            raise ProbeError("Only read methods permitted")
        if not (path == ROOT or path.startswith(ROOT + "/")):
            raise ProbeError("Refusing resource outside AllMusic")
        request_headers = {"Authorization": self.auth, "Accept-Encoding": "identity",
                           "User-Agent": "CloudMailPlayer-M0/0.1"}
        request_headers.update(headers or {})
        req = Request("https://" + HOST + quote(path, safe="/"), data=body,
                      headers=request_headers, method=method)
        start = time.monotonic()
        try:
            with self.opener.open(req, timeout=20) as response:
                status = response.status
                response_headers = dict(response.headers.items())
                data = response.read(cap + 1) if method != "HEAD" else b""
        except HTTPError as error:
            status = error.code
            response_headers = dict(error.headers.items())
            data = b""
        except (URLError, TimeoutError, OSError):
            raise ProbeError("DNS/TLS/network/timeout failure") from None
        if len(data) > cap:
            raise ProbeError("Response exceeded safe byte cap")
        return {"status": status,
                "headers": {k.lower(): v for k, v in response_headers.items()},
                "data": data, "ms": round(1000 * (time.monotonic() - start))}

    def propfind(self, path: str, depth: int):
        response = self.fetch("PROPFIND", path, headers={
            "Depth": str(depth), "Content-Type": "application/xml; charset=utf-8"},
            body=PROPFIND, cap=MAX_XML)
        entries = parse_entries(response["data"]) if response["status"] == 207 else []
        return response, entries


def live(client: Client):
    summary = {"date_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
               "mode": "read_only_bounded", "root": ROOT}
    root, entries = client.propfind(ROOT, 0)
    summary["collection"] = {
        "status": root["status"], "ms": root["ms"],
        "is_collection": any(path.rstrip("/") == ROOT and is_dir for path, is_dir in entries)}
    if not summary["collection"]["is_collection"]:
        summary["result"] = "AllMusic collection not confirmed"
        return summary
    folders = [ROOT]
    sample = None
    read_count = 0
    while folders and read_count < 10 and sample is None:
        path = folders.pop(0)
        response, found = client.propfind(path, 1)
        read_count += 1
        for candidate, is_dir in found:
            if candidate.rstrip("/") == path.rstrip("/"):
                continue
            if not candidate.startswith(ROOT + "/"):
                continue
            if is_dir and len(folders) < 10:
                folders.append(candidate.rstrip("/"))
            elif PurePosixPath(candidate).suffix.lower() in EXTENSIONS:
                sample = candidate
                break
    summary["sampling"] = {"directories": read_count, "audio_found": sample is not None,
                           "coverage": "bounded_not_full_index"}
    if sample is None:
        return summary
    head = client.fetch("HEAD", sample, cap=0)
    summary["head"] = {
        "status": head["status"], "ms": head["ms"],
        "etag": "etag" in head["headers"],
        "last_modified": "last-modified" in head["headers"],
        "accept_ranges": head["headers"].get("accept-ranges", "")[:40]}
    summary["ranges"] = []
    for rg in ("bytes=0-4095", "bytes=0-65535", "bytes=65536-131071",
               "bytes=0-131071", "bytes=-4096"):
        resp = client.fetch("GET", sample, headers={"Range": rg}, cap=MAX_AUDIO_READ)
        summary["ranges"].append({
            "request": rg, "status": resp["status"],
            "bytes_read": len(resp["data"]),
            "content_range": safe_range_header(resp["headers"].get("content-range")),
            "ms": resp["ms"]})
    summary["untested"] = ["rate_limits", "full_index", "audio_decoding",
                            "seek_playback_latency", "tag_parsing", "concurrent_access"]
    return summary


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--live", action="store_true")
    parser.add_argument("--output", default="")
    opts = parser.parse_args()
    if not opts.live:
        print("DRY RUN: No network request performed. Pass --live to enable read-only M0.")
        return 0
    try:
        result = live(Client(os.environ.get("WEBDAV_USERNAME", ""),
                             os.environ.get("WEBDAV_PASSWORD", "")))
        payload = json.dumps(result, ensure_ascii=False, indent=2)
        if opts.output:
            if os.path.basename(opts.output) not in {
                    "m0-results.private.json", "m0-results.local.json"}:
                raise ProbeError("Output must use an ignored private filename")
            with open(opts.output, "w", encoding="utf-8") as fp:
                fp.write(payload + "\n")
        print(payload)
        return 0
    except ProbeError as exc:
        print("M0 BLOCKED: " + str(exc))
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
