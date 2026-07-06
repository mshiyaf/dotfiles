---
description: Create git commits from staged changes in this repo or child repos.
agent: pr-writer
---
Use the git-commit skill.

Context:
!`python - <<'PY'
from pathlib import Path
import os
import subprocess

ROOT = Path.cwd()
SKIP_DIRS = {'.git', '.hg', '.svn', 'node_modules', 'vendor', '.cache', '.next', 'dist', 'build'}


def git(cwd, *args):
    try:
        return subprocess.run(
            ['git', '-C', str(cwd), *args],
            capture_output=True,
            text=True,
            timeout=20,
        )
    except Exception as error:
        return subprocess.CompletedProcess(args, 1, '', str(error))


def repo_root(path):
    result = git(path, 'rev-parse', '--show-toplevel')
    if result.returncode != 0:
        return None
    return Path(result.stdout.strip()).resolve()


repos = {}
root_repo = repo_root(ROOT)
if root_repo:
    repos[str(root_repo)] = root_repo

for dirpath, dirnames, filenames in os.walk(ROOT):
    has_git_dir = '.git' in dirnames
    dirnames[:] = [name for name in dirnames if name not in SKIP_DIRS]
    path = Path(dirpath)
    if has_git_dir or '.git' in filenames:
        found = repo_root(path)
        if found:
            repos[str(found)] = found

if not repos:
    print('No git repositories found under the current directory.')
    raise SystemExit(0)

for repo in sorted(repos.values(), key=lambda path: (len(path.relative_to(ROOT).parts) if path.is_relative_to(ROOT) else 999, str(path))):
    label = '.' if repo == ROOT else str(repo.relative_to(ROOT)) if repo.is_relative_to(ROOT) else str(repo)
    print(f'## Repository: {label}')

    for title, args in [
        ('Status', ('status', '--short')),
        ('Unstaged stat', ('diff', '--stat')),
        ('Staged stat', ('diff', '--cached', '--stat')),
        ('Staged diff', ('diff', '--cached')),
        ('Recent commits', ('log', '--oneline', '-10')),
    ]:
        result = git(repo, *args)
        if title == 'Recent commits' and result.returncode != 0:
            output = '(none)'
        else:
            output = result.stdout.strip() or result.stderr.strip() or '(none)'
        print(f'### {title}')
        print(output)
        print()
PY`

Create git commits from currently staged changes.

Rules:
- If the current directory is a git repository, include it.
- If child git repositories or submodules are present, include each one listed in the context.
- Commit each repository with staged changes separately, using `git -C <repo> commit ...` when needed.
- If a listed repository has nothing staged, skip it; do not stage files automatically. Say what needs staging.
- If no repositories are found, report that instead of running plain git commands that error.
- Do not commit secrets, credentials, `.env` files, or unrelated generated artifacts.
- Use a concise Conventional Commit subject plus a short descriptive body by default.
- The body should explain what changed and why in 1-3 bullets or sentences. Include verification when useful.
- Omit the body only for truly trivial changes.
- Run `git commit` with separate subject/body arguments, for example `git commit -m "type(scope): subject" -m "body"`, then run `git status --short` or `git -C <repo> status --short` to verify.
- If commit hooks fail, report the failure and what needs fixing. Do not amend.
