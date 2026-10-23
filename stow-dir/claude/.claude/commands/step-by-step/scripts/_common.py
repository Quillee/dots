"""Shared helpers for the step-by-step scripts.

Standard library only. Written for Python 3.12 and avoids syntax newer than 3.9
at runtime, so it also runs on older interpreters. All file I/O is UTF-8 with
LF line endings, and all wikilinks use forward slashes, so behavior is the same
on Windows, macOS, and Linux.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
import unicodedata
from dataclasses import dataclass, field
from pathlib import Path

# --------------------------------------------------------------------------
# Constants
# --------------------------------------------------------------------------

OWNERS = {"you", "claude"}
TASK_STATUS = {"not-started", "in-progress", "blocked", "done", "dropped"}
PRD_STATUS = {"planning", "in-progress", "done", "dropped"}
FINISHED = {"done", "dropped"}
SETTINGS_ALLOWED = {
    "grill": {"full", "quick", "skip"},
    "own": {"core", "more", "most"},
    "hints": {"none", "graduated", "full"},
    "stop": {"prd", "plan", "scaffold"},
    "level": {"new", "familiar", "expert"},
}
SETTINGS_DEFAULTS = {
    "grill": "full",
    "own": "core",
    "hints": "graduated",
    "stop": "scaffold",
    "level": "familiar",
}
PLACEHOLDER = "_(to be written)_"

# [[target#section|alias]] with an optional backslash before the pipe (table cells).
WIKILINK_RE = re.compile(
    r"\[\[([^\]\|#^\\]+?)(?:[#^][^\]\|\\]*)?(?:\\?\|([^\]]*?))?\]\]"
)
# Same, but captures every part so a link can be rebuilt exactly.
WIKILINK_PARTS_RE = re.compile(
    r"\[\[([^\]\|#^\\]+?)([#^][^\]\|\\]*)?(\\?\|[^\]]*?)?\]\]"
)
WALKTHROUGH_RE = re.compile(r"^(\d{2,})((?:\.\d{2,})*)-([a-z0-9]+(?:-[a-z0-9]+)*)\.md$")
PRD_FILE_RE = re.compile(r"^prd-([a-z0-9]+(?:-[a-z0-9]+)*)\.md$")
CHECKBOX_RE = re.compile(r"^\s*-\s\[( |x|X)\]\s?(.*)$")
DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
SLUG_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

EXIT_OK = 0
EXIT_FINDINGS = 1
EXIT_USAGE = 2


# --------------------------------------------------------------------------
# Output, files, errors
# --------------------------------------------------------------------------

def setup_output() -> None:
    """Force UTF-8 output so Windows consoles do not choke on non-ASCII."""
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except Exception:  # pragma: no cover - older or odd streams
            pass


def die(message: str, code: int = EXIT_USAGE) -> None:
    print(f"error: {message}", file=sys.stderr)
    sys.exit(code)


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig").replace("\r\n", "\n")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(text)


def emit_json(data) -> None:
    print(json.dumps(data, indent=2, ensure_ascii=False, default=str))


def slugify(text: str, max_len: int = 40) -> str:
    text = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    text = re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")
    if len(text) > max_len:
        text = text[:max_len].rstrip("-")
    return text


def pad(n: int) -> str:
    return f"{n:02d}"


def walk_stem(task_id: int, deps: list, slug: str) -> str:
    """NN[.MM...]-slug, without the .md extension."""
    return pad(task_id) + "".join("." + pad(d) for d in deps) + "-" + slug


# --------------------------------------------------------------------------
# Findings (shared by check_drift and validate_task)
# --------------------------------------------------------------------------

class Findings:
    def __init__(self) -> None:
        self.items: list[dict] = []

    def _add(self, severity: str, kind: str, message: str, task=None) -> None:
        entry = {"severity": severity, "kind": kind, "task": task, "message": message}
        if entry not in self.items:
            self.items.append(entry)

    def error(self, kind: str, message: str, task=None) -> None:
        self._add("error", kind, message, task)

    def warn(self, kind: str, message: str, task=None) -> None:
        self._add("warning", kind, message, task)

    @property
    def errors(self) -> list[dict]:
        return [i for i in self.items if i["severity"] == "error"]

    @property
    def warnings(self) -> list[dict]:
        return [i for i in self.items if i["severity"] == "warning"]

    @staticmethod
    def _line(item: dict) -> str:
        who = f" task {pad(item['task'])}:" if isinstance(item["task"], int) else ""
        return f"  [{item['kind']}]{who} {item['message']}"

    def render(self, title: str, error_label: str, clean_message: str) -> str:
        out = [title]
        if self.errors:
            out.append(f"{error_label} ({len(self.errors)})")
            out.extend(self._line(i) for i in self.errors)
        if self.warnings:
            out.append(f"WARNINGS ({len(self.warnings)})")
            out.extend(self._line(i) for i in self.warnings)
        if not self.items:
            out.append(clean_message)
        return "\n".join(out)

    def to_dict(self) -> dict:
        return {
            "ok": not self.errors,
            "errors": self.errors,
            "warnings": self.warnings,
        }


# --------------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------------

@dataclass
class Paths:
    repo_root: Path
    repo: str
    prd_root: Path


def find_repo_root(start: Path | None = None) -> Path:
    start = (start or Path.cwd()).resolve()
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            cwd=start, capture_output=True, text=True, timeout=10,
        )
        if result.returncode == 0 and result.stdout.strip():
            return Path(result.stdout.strip()).resolve()
    except (OSError, subprocess.SubprocessError):
        pass
    for candidate in [start, *start.parents]:
        if (candidate / ".git").exists():
            return candidate
    return start


def add_path_args(parser) -> None:
    parser.add_argument("--repo-root", help="repository root (default: git toplevel of the current directory)")
    parser.add_argument("--prd-root", help="override the prd directory (default: 'prd' one level above the repo root)")
    parser.add_argument("--repo", help="override the repo folder name under prd/ (default: repo root basename)")


def resolve_paths(args) -> Paths:
    repo_root = Path(args.repo_root).resolve() if getattr(args, "repo_root", None) else find_repo_root()
    prd_root = Path(args.prd_root).resolve() if getattr(args, "prd_root", None) else repo_root.parent / "prd"
    repo = getattr(args, "repo", None) or repo_root.name
    return Paths(repo_root=repo_root, repo=repo, prd_root=prd_root)


def locate_task(args) -> tuple[Path, Path]:
    """Return (prd_root, task_dir) from a path or a bare task name."""
    given = getattr(args, "task", None)
    if not given:
        die("a task directory (or task name) is required")
    candidate = Path(given)
    if candidate.is_dir():
        task_dir = candidate.resolve()
        prd_root = Path(args.prd_root).resolve() if getattr(args, "prd_root", None) else task_dir.parent.parent
    else:
        paths = resolve_paths(args)
        task_dir = paths.prd_root / paths.repo / given
        prd_root = paths.prd_root
    if not task_dir.is_dir():
        die(f"task directory not found: {task_dir}")
    return prd_root, task_dir


def vault_prefix(task_dir: Path, prd_root: Path) -> str:
    try:
        return task_dir.resolve().relative_to(prd_root.resolve()).as_posix()
    except ValueError:
        return f"{task_dir.parent.name}/{task_dir.name}"


# --------------------------------------------------------------------------
# Front matter (a small YAML subset: scalars, lists, one-level maps)
# --------------------------------------------------------------------------

def split_front_matter(text: str):
    """Return (front_matter_lines | None, body)."""
    lines = text.split("\n")
    if not lines or lines[0].strip() != "---":
        return None, text
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return lines[1:i], "\n".join(lines[i + 1:])
    return None, text


def _strip_comment(s: str) -> str:
    out = []
    quote = None
    for i, ch in enumerate(s):
        if quote:
            if ch == quote:
                quote = None
        elif ch in "\"'":
            quote = ch
        elif ch == "#" and (i == 0 or s[i - 1].isspace()):
            break
        out.append(ch)
    return "".join(out).rstrip()


def _unquote(s: str) -> str:
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in "\"'":
        inner = s[1:-1]
        if s[0] == '"':
            inner = inner.replace('\\"', '"')
        return inner
    return s


def _split_inline_list(inner: str) -> list[str]:
    parts, buf, quote = [], [], None
    for ch in inner:
        if quote:
            buf.append(ch)
            if ch == quote:
                quote = None
        elif ch in "\"'":
            quote = ch
            buf.append(ch)
        elif ch == ",":
            parts.append("".join(buf))
            buf = []
        else:
            buf.append(ch)
    if "".join(buf).strip():
        parts.append("".join(buf))
    return parts


def _scalar(raw: str):
    raw = _strip_comment(raw).strip()
    if raw == "":
        return ""
    if raw[0] in "\"'":
        return _unquote(raw)
    if re.fullmatch(r"-?\d+", raw):
        return int(raw)
    if raw == "[]":
        return []
    if raw.startswith("[") and not raw.startswith("[[") and raw.endswith("]"):
        return [_scalar(p) for p in _split_inline_list(raw[1:-1])]
    return raw


KEY_RE = re.compile(r"^([A-Za-z_][\w.-]*):\s*(.*)$")


def parse_front_matter(lines: list[str]):
    """Parse the supported YAML subset. Returns (data, issues)."""
    data: dict = {}
    issues: list[str] = []
    i, n = 0, len(lines)
    while i < n:
        line = lines[i]
        if not line.strip() or line.lstrip().startswith("#"):
            i += 1
            continue
        match = KEY_RE.match(line)
        if not match:
            issues.append(f"front matter line {i + 2}: cannot parse '{line.strip()[:40]}'")
            i += 1
            continue
        key, rest = match.group(1), _strip_comment(match.group(2)).strip()
        i += 1
        if rest == "":
            j, kind = i, None
            items: list = []
            mapping: dict = {}
            while j < n:
                current = lines[j]
                if not current.strip() or current.lstrip().startswith("#"):
                    j += 1
                    continue
                if not current.startswith((" ", "\t")):
                    break
                stripped = current.strip()
                if stripped == "-" or stripped.startswith("- "):
                    kind = kind or "list"
                    item = _strip_comment(stripped[1:]).strip()
                    if item.startswith("[["):
                        issues.append(
                            f"front matter line {j + 2}: wikilink must be quoted ({item[:50]})"
                        )
                        items.append(item)
                    else:
                        items.append(_scalar(item))
                else:
                    sub = KEY_RE.match(stripped)
                    if sub:
                        kind = kind or "map"
                        mapping[sub.group(1)] = _scalar(sub.group(2))
                j += 1
            i = j
            data[key] = items if kind == "list" else mapping if kind == "map" else ""
        elif rest.startswith("[["):
            issues.append(f"front matter line {i + 1}: wikilink must be quoted ({rest[:50]})")
            data[key] = rest
        else:
            data[key] = _scalar(rest)
    return data, issues


# --------------------------------------------------------------------------
# Markdown helpers
# --------------------------------------------------------------------------

def get_section(body: str, heading: str) -> str | None:
    """Text under '## heading' up to the next level-2 heading (level 3+ stay inside)."""
    collected = None
    for line in body.split("\n"):
        if collected is None:
            if re.match(rf"^##\s+{re.escape(heading)}\s*$", line):
                collected = []
        else:
            if re.match(r"^##\s", line):
                break
            collected.append(line)
    return None if collected is None else "\n".join(collected)


def get_callout(body: str, title_pattern: str) -> str | None:
    lines = body.split("\n")
    for i, line in enumerate(lines):
        m = re.match(r"^\s*>\s*\[!(\w+)\][+-]?\s*(.*)$", line)
        if m and re.fullmatch(title_pattern, m.group(2).strip(), re.I):
            text = []
            for follow in lines[i + 1:]:
                if re.match(r"^\s*>", follow):
                    text.append(re.sub(r"^\s*>\s?", "", follow))
                else:
                    break
            return "\n".join(text).strip()
    return None


def wikilinks(text: str) -> list[tuple[str, str | None]]:
    return [(m.group(1).strip(), m.group(2)) for m in WIKILINK_RE.finditer(text)]


def link_id(target: str, alias: str | None) -> int | None:
    """Task number a link refers to: the alias's leading number, else the file stem's."""
    if alias:
        m = re.match(r"\s*(\d+)\b", alias)
        if m:
            return int(m.group(1))
    m = re.match(r"(\d+)", target.rsplit("/", 1)[-1])
    return int(m.group(1)) if m else None


def link_ids(value) -> list[int | None]:
    values = value if isinstance(value, list) else [value]
    ids = []
    for v in values:
        if isinstance(v, str):
            for target, alias in wikilinks(v):
                ids.append(link_id(target, alias))
    return ids


def resolve_link(target: str, prd_root: Path) -> bool:
    target = target.strip()
    rel = target if target.endswith(".md") else target + ".md"
    return (prd_root / rel).is_file()


def split_row(line: str) -> list[str]:
    s = line.strip()
    if s.startswith("|"):
        s = s[1:]
    if s.endswith("|") and not s.endswith("\\|"):
        s = s[:-1]
    return [c.strip() for c in re.split(r"(?<!\\)\|", s)]


# --------------------------------------------------------------------------
# Model: PRD, walkthroughs, task directory
# --------------------------------------------------------------------------

@dataclass
class Task:
    id: int
    name: str
    owner: str
    depends: list
    status: str
    walkthrough_target: str | None
    walkthrough_alias: str | None
    notes: str = ""


@dataclass
class Step:
    num: int | None
    checked: bool
    text: str


@dataclass
class Prd:
    path: Path
    text: str
    fm: dict
    body: str
    fm_issues: list
    tasks: list
    table_found: bool
    table_issues: list
    mermaid: dict | None
    next_up_link: tuple | None

    @property
    def settings(self) -> dict:
        s = self.fm.get("settings")
        return s if isinstance(s, dict) else {}

    @property
    def stem(self) -> str:
        return self.path.name[:-3]


@dataclass
class Walkthrough:
    path: Path
    stem: str
    file_id: int
    file_deps: list
    slug: str
    text: str
    fm: dict
    body: str
    fm_issues: list
    steps: list = field(default_factory=list)
    steps_section: bool = False
    resume: str | None = None


@dataclass
class TaskDir:
    dir: Path
    prd_root: Path
    prefix: str
    prd: Prd | None = None
    prd_problem: str | None = None
    walkthroughs: list = field(default_factory=list)
    stray: list = field(default_factory=list)

    def walkthroughs_for(self, task_id: int) -> list:
        return [w for w in self.walkthroughs if w.file_id == task_id]


REQUIRED_COLUMNS = ["#", "task", "owner", "depends on", "status", "walkthrough"]


def parse_task_table(body: str):
    """Return (tasks, found, issues) from the first table under '## Tasks'."""
    section = get_section(body, "Tasks")
    lines = (section if section is not None else body).split("\n")
    tasks: list[Task] = []
    issues: list[str] = []
    start = None
    for i in range(len(lines) - 1):
        if lines[i].strip().startswith("|") and re.match(r"^\s*\|[\s:\-|]+\|\s*$", lines[i + 1]):
            start = i
            break
    if start is None:
        return tasks, False, ["no task table found under '## Tasks'"]
    header = [h.lower().strip() for h in split_row(lines[start])]
    for col in REQUIRED_COLUMNS:
        if col not in header:
            issues.append(f"task table is missing the '{col}' column")
    if issues:
        return tasks, True, issues
    idx = {name: header.index(name) for name in header}
    row_no = 0
    for line in lines[start + 2:]:
        if not line.strip().startswith("|"):
            break
        row_no += 1
        cells = split_row(line)
        if len(cells) != len(header):
            issues.append(
                f"table row {row_no}: {len(cells)} cells, expected {len(header)} "
                "(unescaped '|' inside a wikilink?)"
            )
            continue
        raw_id = cells[idx["#"]]
        if not re.fullmatch(r"\d+", raw_id):
            issues.append(f"table row {row_no}: '#' must be a number, got '{raw_id}'")
            continue
        raw_dep = cells[idx["depends on"]]
        deps = [] if raw_dep.lower() in {"", "none", "-", "\u2014", "n/a"} else [int(x) for x in re.findall(r"\d+", raw_dep)]
        cell = cells[idx["walkthrough"]]
        links = wikilinks(cell)
        target = alias = None
        if links:
            target, alias = links[0]
        elif cell.lower() not in {"", "n/a", "-", "\u2014", "none"}:
            issues.append(f"table row {row_no}: walkthrough cell must be a wikilink or n/a, got '{cell[:30]}'")
        tasks.append(Task(
            id=int(raw_id),
            name=cells[idx["task"]],
            owner=cells[idx["owner"]].lower(),
            depends=deps,
            status=cells[idx["status"]].lower(),
            walkthrough_target=target,
            walkthrough_alias=alias,
            notes=cells[idx["notes"]] if "notes" in idx else "",
        ))
    return tasks, True, issues


def parse_mermaid(body: str) -> dict | None:
    m = re.search(r"```mermaid\s*\n(.*?)```", body, re.S)
    if not m:
        return None
    nodes: dict = {}
    edges: set = set()
    for line in m.group(1).splitlines():
        line = line.strip()
        if not line or line.startswith(("graph", "flowchart", "%%")):
            continue
        ids = []
        for part in [p.strip() for p in line.split("-->")]:
            nm = re.match(r"^T(\d+)\s*(?:\[\"?([^\]\"]*)\"?\])?", part)
            if not nm:
                ids.append(None)
                continue
            tid = int(nm.group(1))
            ids.append(tid)
            if nm.group(2) is not None:
                nodes[tid] = nm.group(2)
            else:
                nodes.setdefault(tid, None)
        for a, b in zip(ids, ids[1:]):
            if a is not None and b is not None:
                edges.add((a, b))
    return {"nodes": nodes, "edges": edges}


def parse_prd(path: Path) -> Prd:
    text = read_text(path)
    fm_lines, body = split_front_matter(text)
    fm, issues = ({}, ["no front matter found"]) if fm_lines is None else parse_front_matter(fm_lines)
    tasks, found, table_issues = parse_task_table(body)
    nu = get_callout(body, r"Next up")
    nu_link = None
    if nu:
        links = wikilinks(nu)
        if links:
            nu_link = links[0]
    return Prd(
        path=path, text=text, fm=fm, body=body, fm_issues=issues, tasks=tasks,
        table_found=found, table_issues=table_issues, mermaid=parse_mermaid(body),
        next_up_link=nu_link,
    )


def parse_steps(body: str):
    section = get_section(body, "Steps")
    if section is None:
        return [], False
    steps = []
    for line in section.split("\n"):
        m = CHECKBOX_RE.match(line)
        if m:
            text = m.group(2).strip()
            num = re.match(r"^(\d+)[.)]\s", text)
            steps.append(Step(int(num.group(1)) if num else None, m.group(1) != " ", text))
    return steps, True


def parse_walkthrough(path: Path) -> Walkthrough:
    m = WALKTHROUGH_RE.match(path.name)
    text = read_text(path)
    fm_lines, body = split_front_matter(text)
    fm, issues = ({}, ["no front matter found"]) if fm_lines is None else parse_front_matter(fm_lines)
    steps, has_section = parse_steps(body)
    return Walkthrough(
        path=path,
        stem=path.name[:-3],
        file_id=int(m.group(1)),
        file_deps=[int(x) for x in m.group(2).split(".") if x],
        slug=m.group(3),
        text=text, fm=fm, body=body, fm_issues=issues,
        steps=steps, steps_section=has_section,
        resume=get_callout(body, r"Resume here"),
    )


def load_task_dir(task_dir: Path, prd_root: Path) -> TaskDir:
    td = TaskDir(dir=task_dir, prd_root=prd_root, prefix=vault_prefix(task_dir, prd_root))
    prds = []
    for p in sorted(task_dir.iterdir()):
        if p.is_dir() or p.name.startswith(".") or p.suffix.lower() != ".md":
            continue
        if PRD_FILE_RE.match(p.name):
            prds.append(p)
        elif WALKTHROUGH_RE.match(p.name):
            td.walkthroughs.append(parse_walkthrough(p))
        else:
            td.stray.append(p)
    td.walkthroughs.sort(key=lambda w: (w.file_id, w.path.name))
    if not prds:
        td.prd_problem = "no prd-<name>.md found in the task directory"
    elif len(prds) > 1:
        td.prd_problem = "multiple PRD files: " + ", ".join(p.name for p in prds)
    else:
        td.prd = parse_prd(prds[0])
    return td


# --------------------------------------------------------------------------
# Task-graph logic
# --------------------------------------------------------------------------

def next_up(tasks: list) -> Task | None:
    """First user-owned, unfinished, unblocked task whose prerequisites are finished."""
    status = {t.id: t.status for t in tasks}
    for t in sorted(tasks, key=lambda t: t.id):
        if t.owner != "you" or t.status in FINISHED or t.status == "blocked":
            continue
        if all(status.get(d) in FINISHED for d in t.depends):
            return t
    return None


def next_focus(tasks: list):
    """(task, eligible). The task the 'Next up' callout should name.

    eligible is True when its prerequisites are finished (the user can start now);
    False when it is merely the first unfinished user-owned task, queued behind
    Claude's scaffolding.
    """
    eligible = next_up(tasks)
    if eligible is not None:
        return eligible, True
    for t in sorted(tasks, key=lambda t: t.id):
        if t.owner == "you" and t.status not in FINISHED and t.status != "blocked":
            return t, False
    return None, False


def find_cycle(tasks: list) -> list | None:
    graph = {t.id: [d for d in t.depends if d != t.id] for t in tasks}
    WHITE, GREY, BLACK = 0, 1, 2
    color = {k: WHITE for k in graph}
    stack: list = []

    def visit(node):
        color[node] = GREY
        stack.append(node)
        for dep in graph.get(node, []):
            if dep not in graph:
                continue
            if color[dep] == GREY:
                return stack[stack.index(dep):] + [dep]
            if color[dep] == WHITE:
                found = visit(dep)
                if found:
                    return found
        stack.pop()
        color[node] = BLACK
        return None

    for node in list(graph):
        if color[node] == WHITE:
            found = visit(node)
            if found:
                return found
    return None


def dependents(tasks: list, task_id: int) -> list[int]:
    return sorted(t.id for t in tasks if task_id in t.depends)
