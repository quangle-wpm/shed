#!/usr/bin/env python3
"""Sync shed config files into marked sections of knowledge files."""

import base64
import json
import os
import pathlib
import re
import sys
import urllib.error
import urllib.request

KNOWLEDGE_REPO = "quangle-wpm/knowledge"
GITHUB_API = "https://api.github.com"

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent.parent


def parse_manifest(text):
    """Parse knowledge-sync.yml text into a list of mapping dicts."""
    mappings = []
    current = {}
    for line in text.splitlines():
        line = line.rstrip()
        if line.startswith("  - config:"):
            if current:
                mappings.append(current)
            current = {"config": line.split(":", 1)[1].strip()}
        elif line.startswith("    file:"):
            current["file"] = line.split(":", 1)[1].strip()
        elif line.startswith("    marker:"):
            current["marker"] = line.split(":", 1)[1].strip()
    if current:
        mappings.append(current)
    for i, m in enumerate(mappings):
        for key in ("config", "file", "marker"):
            if key not in m:
                raise ValueError(f"Mapping {i} missing required key '{key}'")
    return mappings


def get_lang_tag(filename):
    """Return the fenced code block language tag for a config filename."""
    suffix = pathlib.Path(filename).suffix
    return {
        ".conf": "ini",
        ".ini": "ini",
        ".toml": "toml",
        ".yaml": "yaml",
        ".yml": "yaml",
        ".json": "json",
    }.get(suffix, "ini")


def github_get(token, path):
    """Fetch a file from the knowledge repo. Returns (content_str, sha)."""
    url = f"{GITHUB_API}/repos/{KNOWLEDGE_REPO}/contents/{path}"
    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2026-03-10",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read())
        content = base64.b64decode(
            data["content"].replace("\n", "")
        ).decode("utf-8")
        return content, data["sha"]
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"ERROR: GET {path} failed: {e.code} {e.reason}: {body}", file=sys.stderr)
        sys.exit(1)


def github_put(token, path, content, sha, message):
    """Write an updated file back to the knowledge repo."""
    url = f"{GITHUB_API}/repos/{KNOWLEDGE_REPO}/contents/{path}"
    payload = json.dumps(
        {
            "message": message,
            "content": base64.b64encode(content.encode("utf-8")).decode("ascii"),
            "sha": sha,
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=payload,
        method="PUT",
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "Content-Type": "application/json",
            "X-GitHub-Api-Version": "2026-03-10",
        },
    )
    try:
        with urllib.request.urlopen(req) as resp:
            resp.read()
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        if e.code == 409:
            print(
                f"ERROR: PUT {path} — conflict (409), another commit landed during sync: {body}",
                file=sys.stderr,
            )
        else:
            print(f"ERROR: PUT {path} failed: {e.code} {e.reason}: {body}", file=sys.stderr)
        sys.exit(1)


def main():
    token = os.environ.get("KNOWLEDGE_TOKEN")
    if not token:
        print("ERROR: KNOWLEDGE_TOKEN environment variable not set", file=sys.stderr)
        sys.exit(1)

    manifest_path = REPO_ROOT / "knowledge-sync.yml"
    if not manifest_path.exists():
        print("ERROR: knowledge-sync.yml not found", file=sys.stderr)
        sys.exit(1)

    try:
        mappings = parse_manifest(manifest_path.read_text())
    except ValueError as e:
        print(f"ERROR: knowledge-sync.yml is malformed: {e}", file=sys.stderr)
        sys.exit(1)

    if not mappings:
        print("ERROR: knowledge-sync.yml parsed 0 mappings — check formatting", file=sys.stderr)
        sys.exit(1)

    for mapping in mappings:
        config_path = REPO_ROOT / mapping["config"]
        file_path = mapping["file"]
        marker = mapping["marker"]

        # Step 1: read local config
        if not config_path.exists():
            print(
                f"ERROR: config file not found: {config_path}", file=sys.stderr
            )
            sys.exit(1)
        config_content = config_path.read_text().rstrip("\r\n")

        # Step 2: GET knowledge file
        file_content, sha = github_get(token, file_path)

        # Step 3: find markers
        escaped = re.escape(marker)
        pattern = (
            rf"<!-- shed:{escaped}:start -->([\s\S]*?)<!-- shed:{escaped}:end -->"
        )
        match = re.search(pattern, file_content)
        if not match:
            print(
                f"WARNING: marker '{marker}' not found in {file_path} — skipping",
                file=sys.stderr,
            )
            continue

        # Step 4: build replacement and check for no-op
        lang = get_lang_tag(config_path.name)
        replacement = (
            f"<!-- shed:{marker}:start -->\n"
            f"```{lang}\n"
            f"{config_content}\n"
            f"```\n"
            f"<!-- shed:{marker}:end -->"
        )
        if match.group(0) == replacement:
            print(f"no change: {marker}")
            continue

        # Step 5: patch file and PUT back
        updated_file = file_content[: match.start()] + replacement + file_content[match.end() :]
        github_put(token, file_path, updated_file, sha, f"chore: sync {marker} from shed")
        print(f"synced: {marker} -> {file_path}")


if __name__ == "__main__":
    main()
