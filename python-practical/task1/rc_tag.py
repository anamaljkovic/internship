#!/usr/bin/env python3

import argparse
import re
import subprocess

RC_TAG_PATTERN = re.compile(r"^rc/(\d+)\.(\d+)\.(\d+)$")


def run_git(args, repo_path):
    result = subprocess.run(
        ["git"] + args,
        cwd=repo_path,
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def get_latest_commit_sha(repo_path):
    run_git(["fetch", "origin", "main"], repo_path)
    return run_git(["rev-parse", "origin/main"], repo_path)


def get_existing_rc_versions(repo_path):
    run_git(["fetch", "--tags", "origin"], repo_path)
    tags_output = run_git(["tag", "-l", "rc/*"], repo_path)

    versions = []
    for line in tags_output.splitlines():
        match = RC_TAG_PATTERN.match(line.strip())
        if match:
            x, y, z = (int(part) for part in match.groups())
            versions.append((x, y, z))

    return versions


def determine_next_version(repo_path):
    versions = get_existing_rc_versions(repo_path)

    if not versions:
        return (0, 1, 0)

    latest = max(versions)
    x, y, z = latest
    return (x, y + 1, z)


def create_tag(repo_path, tag_name, commit_sha):
    run_git(["tag", tag_name, commit_sha], repo_path)
    run_git(["push", "origin", tag_name], repo_path)


def main():
    parser = argparse.ArgumentParser(description="Create rc/release tags for a GitHub repo")
    parser.add_argument("repo", type=str, help="Path to the local git repository")
    parser.add_argument("--create-release", action="store_true", help="Also create a release tag")
    args = parser.parse_args()

    commit_sha = get_latest_commit_sha(args.repo)
    x, y, z = determine_next_version(args.repo)

    rc_tag = f"rc/{x}.{y}.{z}"
    create_tag(args.repo, rc_tag, commit_sha)
    print(f"Created rc tag: {rc_tag} -> {commit_sha}")

    if args.create_release:
        release_tag = f"{x}.{y}.{z}"
        create_tag(args.repo, release_tag, commit_sha)
        print(f"Created release tag: {release_tag} -> {commit_sha}")


main()