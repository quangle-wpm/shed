#!/usr/bin/env python3
"""Sync shed config files into marked sections of knowledge files.

Creates a PR in the knowledge repo with auto-merge enabled.
Requires markdownlint to pass before the PR is merged.
"""

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
SYNC_BRANCH = "shed/sync-configs"

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


def github_api(token, method, endpoint, body=None):
    """Make an authenticated GitHub API request and return parsed JSON."""
    url = (
        f"{GITHUB_API}/graphql"
        if endpoint == "/graphql"
        else f"{GITHUB_API}/repos/{KNOWLEDGE_REPO}/{endpoint}"
    )
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2026-03-10",
    }
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    with urllib.request.urlopen(req) as resp:
        raw = resp.read()
        return json.loads(raw) if raw else None


def get_file(token, path):
    """Fetch a file from the knowledge repo default branch."""
    data = github_api(token, "GET", f"contents/{path}")
    content = base64.b64decode(data["content"].replace("\n", "")).decode("utf-8")
    return content, data["sha"]


def put_file(token, path, content, sha, message, branch):
    """Write a file to a specific branch in the knowledge repo."""
    github_api(
        token,
        "PUT",
        f"contents/{path}",
        {
            "message": message,
            "content": base64.b64encode(content.encode("utf-8")).decode("ascii"),
            "sha": sha,
            "branch": branch,
        },
    )


def ensure_branch(token, branch_name, sha):
    """Delete existing branch (if any) and create it fresh from the given SHA."""
    try:
        github_api(token, "DELETE", f"git/refs/heads/{branch_name}")
    except urllib.error.HTTPError as exc:
        if exc.code != 404:
            raise
    github_api(
        token,
        "POST",
        "git/refs",
        {"ref": f"refs/heads/{branch_name}", "sha": sha},
    )


def create_pull_request(token, branch, title, body):
    """Create a PR and return (number, node_id)."""
    data = github_api(
        token,
        "POST",
        "pulls",
        {"title": title, "head": branch, "base": "main", "body": body},
    )
    return data["number"], data["node_id"]


def enable_auto_merge(token, pr_node_id):
    """Enable auto-merge (squash) via GitHub GraphQL API."""
    github_api(
        token,
        "POST",
        "/graphql",
        {
            "query": (
                "mutation($id: ID!) {"
                "  enablePullRequestAutoMerge(input: {"
                "    pullRequestId: $id, mergeMethod: SQUASH"
                "  }) { pullRequest { autoMergeRequest { enabledAt } } }"
                "}"
            ),
            "variables": {"id": pr_node_id},
        },
    )


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
        print(
            "ERROR: knowledge-sync.yml parsed 0 mappings — check formatting",
            file=sys.stderr,
        )
        sys.exit(1)

    # Group mappings by target knowledge file so multiple markers in the same
    # file are applied together in a single commit.
    file_groups: dict[str, list[dict]] = {}
    for mapping in mappings:
        file_groups.setdefault(mapping["file"], []).append(mapping)

    # Collect changes — compare local configs against the current default branch.
    # Each entry: (file_path, updated_content, blob_sha, list_of_markers)
    changes: list[tuple[str, str, str, list[str]]] = []

    for file_path, group in file_groups.items():
        content, sha = get_file(token, file_path)
        updated = content
        markers_changed: list[str] = []

        for mapping in group:
            config_path = REPO_ROOT / mapping["config"]
            marker = mapping["marker"]

            if not config_path.exists():
                print(
                    f"ERROR: config file not found: {config_path}", file=sys.stderr
                )
                sys.exit(1)
            config_content = config_path.read_text().rstrip("\r\n")

            escaped = re.escape(marker)
            pattern = (
                rf"<!-- shed:{escaped}:start -->"
                rf"([\s\S]*?)"
                rf"<!-- shed:{escaped}:end -->"
            )
            match = re.search(pattern, updated)
            if not match:
                print(
                    f"WARNING: marker '{marker}' not found in {file_path} — skipping",
                    file=sys.stderr,
                )
                continue

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

            updated = updated[: match.start()] + replacement + updated[match.end() :]
            markers_changed.append(marker)

        if markers_changed:
            changes.append((file_path, updated, sha, markers_changed))

    if not changes:
        print("nothing to sync")
        return

    # Create a fresh branch from the current default-branch HEAD.
    main_sha = github_api(token, "GET", "git/ref/heads/main")["object"]["sha"]
    ensure_branch(token, SYNC_BRANCH, main_sha)

    all_markers: list[str] = []
    for file_path, updated_content, sha, markers_changed in changes:
        commit_msg = f"chore: sync {', '.join(markers_changed)} from shed"
        put_file(token, file_path, updated_content, sha, commit_msg, SYNC_BRANCH)
        all_markers.extend(markers_changed)
        print(f"synced: {', '.join(markers_changed)} -> {file_path}")

    # Create PR and enable auto-merge.
    if len(all_markers) <= 3:
        title = f"chore: sync {', '.join(all_markers)} from shed"
    else:
        title = "chore: sync configs from shed"
    body = "Automated sync of config files from shed."
    pr_number, pr_node_id = create_pull_request(token, SYNC_BRANCH, title, body)
    print(f"created PR #{pr_number}")

    enable_auto_merge(token, pr_node_id)
    print(f"auto-merge enabled for PR #{pr_number}")


if __name__ == "__main__":
    main()
