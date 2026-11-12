#!/usr/bin/env python3
"""Session-token measurement and budget guard for Helix skills (docs/sdd/token-budget-guard).

Python 3 standard library only. Token estimate = bytes/4. The link-graph walk is a port of
ols-qa-evidence `graph_v2.py`, and `measure` follows `compare_tokens.py` (direct = the skill's mandatory
reads; routed = helix router mandatory + skill mandatory, each file once; always-on = frontmatter
`description:` bytes of every skills/*/SKILL.md). Every error exits 2: a measurement that cannot run
is a fail, never a pass.

Usage:
  token-measure.py graph ROOT                 graph_v2-compatible JSON (the 8 token-diet skills)
  token-measure.py graph-digest ROOT          sha256 of the canonical graph JSON
  token-measure.py measure ROOT               session cost of every skills/*/SKILL.md, JSON
  token-measure.py self-test [--repo GIT]     R2 known answers on helix 18200e2
  token-measure.py check --root ROOT --budget FILE [--selftest-repo GIT] [--summary MD]
                         [--report OUT --tag TAG --commit SHA --rule-lines pass|fail]
                                              exit 0 = no increase, 1 = increase, 2 = error
  token-measure.py budget --root ROOT --tag TAG --commit SHA --out FILE [--selftest-repo GIT]
  token-measure.py ratchet --root ROOT --budget FILE --tag TAG --commit SHA [--selftest-repo GIT]
                                              lowers FILE to the measured numbers; never raises it
  token-measure.py compare-budgets BASE HEAD  exit 0 = HEAD raises nothing, 3 = HEAD raises, 2 = error
"""
import argparse, hashlib, io, json, os, re, subprocess, sys, tarfile, tempfile
from collections import defaultdict

# --- graph_v2.py port (regexes and classification unchanged) ---------------------------------------
GRAPH_SKILLS = ["catch-ai-workflow", "create-bug-workflow", "helix", "retest-bug-workflow",
                "tc-api-prep-workflow", "tc-fe-prep-workflow", "tc-review-workflow", "testing-ticket-workflow"]
LINK = re.compile(r'\]\(([^)#\s]+\.md)(?:#[^)]*)?\)')
BARE = re.compile(r'`((?:\.\./)*(?:references|skills)/[\w./-]+\.md)`')
UNCOND = re.compile(r'(read and follow|^\s*\d*\.?\s*\**follow\b|\bfollow \[|must read|required reading|shared rules|'
                    r'read \[[^\]]+\]\([^)]+\)\s*(once at session start|at session start|at the start|first|before any|before every|at session end|before (you|the) (skip|start)|before invoking)|'
                    r'\bload and follow\b|end-to-end)', re.I)
COND = re.compile(r'(only when|on-demand|optional|\bif (the|a|you|any)\b|when (the user|exporting|tempted|choosing|proposing|a test|a round|needed|the workflow)|at step \d|at phase)', re.I)

# R2 known answers: graph_v2.py + compare_tokens.measure on helix 18200e2 (release v1.5.181).
KA_COMMIT = "18200e2d6249f22bff6b4f874e9344058bf71987"
KA_GRAPH_DIGEST = "acce664f2828a04c0f4977d57f31145e0f313055edda6687adea0f3b7fea1217"
KA_SKILLS = {
    "catch-ai-workflow": (9337, 14491), "create-bug-workflow": (6876, 14571), "helix": (8195, None),
    "retest-bug-workflow": (18495, 25907), "tc-api-prep-workflow": (6287, 13982),
    "tc-fe-prep-workflow": (17173, 24585), "tc-review-workflow": (8069, 15221),
    "testing-ticket-workflow": (17179, 24874),
}
KA_ALWAYS_ON = (5090, 1272)
METHOD = ("graph_v2.py port; tokens = bytes/4; direct = skill mandatory reads; routed = helix router "
          "mandatory + skill mandatory, each file once; always_on = skills/*/SKILL.md description bytes")


class MeasureError(Exception):
    pass


def tok(p):
    return os.path.getsize(p) // 4


class Graph:
    def __init__(self, root):
        self.root = os.path.abspath(root)
        if not os.path.isdir(os.path.join(self.root, "skills")):
            raise MeasureError(f"no skills/ directory under {root}")
        self._cache = {}

    def resolve(self, src, target):
        if target.startswith("http"):
            return None
        cands = [os.path.normpath(os.path.join(os.path.dirname(src), target)),
                 os.path.normpath(os.path.join(self.root, target.lstrip("./")))]
        for c in cands:
            if c.startswith(self.root) and os.path.isfile(c):
                rel = os.path.relpath(c, self.root)
                if rel.startswith(("references/", "skills/")):
                    return c
        return None

    def links(self, p):
        if p in self._cache:
            return self._cache[p]
        out = []
        proc_dir = os.path.dirname(p) if "/procedures/" in p else None
        with open(p, encoding="utf-8") as fh:
            for i, line in enumerate(fh, 1):
                for m in list(LINK.finditer(line)) + list(BARE.finditer(line)):
                    t = self.resolve(p, m.group(1))
                    if not t or t == p:
                        continue
                    same_proc = proc_dir and os.path.dirname(t) == proc_dir and os.path.basename(t) != "WORKFLOW.md"
                    kind = (("cond" if COND.search(line) else "proc") if same_proc
                            else ("uncond" if UNCOND.search(line) and not COND.search(line) else "cond"))
                    out.append((t, kind, i, line.strip()[:200]))
        self._cache[p] = out
        return out

    def closure(self, starts, kinds):
        seen, stack, via = set(starts), list(starts), {}
        while stack:
            f = stack.pop()
            for t, k, i, _l in self.links(f):
                if k in kinds and t not in seen:
                    seen.add(t); stack.append(t); via[t] = (os.path.relpath(f, self.root), i, k)
        return seen, via

    def run(self, skills):
        rel = lambda f: os.path.relpath(f, self.root)
        res = {"skills": {}, "mandatory_by_file": defaultdict(list), "full_by_file": defaultdict(list)}
        for s in skills:
            sk = os.path.join(self.root, "skills", s, "SKILL.md")
            wf = os.path.join(self.root, "skills", "procedures", s, "WORKFLOW.md")
            if not os.path.isfile(sk):
                raise MeasureError(f"missing skills/{s}/SKILL.md")
            base = [sk] + ([wf] if os.path.isfile(wf) else [])
            mand, via = self.closure(base, {"proc", "uncond"})
            full, _ = self.closure(base, {"proc", "uncond", "cond"})
            res["skills"][s] = {
                "skill_md": tok(sk), "workflow_md": tok(wf) if os.path.isfile(wf) else 0,
                "mandatory_total": sum(tok(f) for f in mand), "mandatory_files": len(mand),
                "full_total": sum(tok(f) for f in full), "full_files": len(full),
                "mandatory": sorted([(rel(f), tok(f), via.get(f)) for f in mand if f not in base], key=lambda x: -x[1]),
            }
            for f in mand: res["mandatory_by_file"][rel(f)].append(s)
            for f in full: res["full_by_file"][rel(f)].append(s)
        res["sizes"] = {os.path.relpath(os.path.join(d, f), self.root): os.path.getsize(os.path.join(d, f)) // 4
                        for d, _, fs in os.walk(self.root) for f in fs
                        if f.endswith(".md") and ("/references" in d or "/skills" in d)}
        return res


def graph_json(root):
    return json.dumps(Graph(root).run(GRAPH_SKILLS), indent=1, default=list)


def graph_digest(root):
    d = json.loads(graph_json(root))
    for s in d["skills"].values():
        s["mandatory"] = sorted(s["mandatory"], key=lambda x: (-x[1], x[0]))
    for k in ("mandatory_by_file", "full_by_file"):
        d[k] = {f: sorted(v) for f, v in d[k].items()}
    return hashlib.sha256(json.dumps(d, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


# --- compare_tokens.measure port ---------------------------------------------------------------------
def description_bytes(skill_md):
    with open(skill_md, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    if not lines or lines[0].strip() != "---":
        return 0
    out, on = [], False
    for ln in lines[1:]:
        if ln.strip() == "---":
            break
        if ln.startswith("description:"):
            on = True
            v = ln[len("description:"):].strip()
            if v not in (">", ">-", "|", "|-"):
                out.append(v)
        elif on and (ln.startswith(" ") or ln.startswith("\t")):
            out.append(ln.strip())
        elif on:
            break
    return len(" ".join(out).strip().strip('"').strip("'").encode("utf-8"))


def skill_names(root):
    sd = os.path.join(root, "skills")
    return sorted(n for n in os.listdir(sd) if os.path.isfile(os.path.join(sd, n, "SKILL.md")))


def measure(root):
    """Session cost of every skill with a skills/<name>/SKILL.md (a superset of the 8 graph_v2 skills;
    each skill's closure is independent, so the 8 numbers are unchanged)."""
    root = os.path.abspath(root)
    g = Graph(root)
    names = skill_names(root)
    if "helix" not in names:
        raise MeasureError("skills/helix/SKILL.md (the router) is missing")
    r = g.run(names)
    sizes = r["sizes"]
    files_of = {}
    for f, sks in r["mandatory_by_file"].items():
        for s in sks:
            files_of.setdefault(s, set()).add(f)
    toks = lambda fs: sum(sizes.get(f, os.path.getsize(os.path.join(root, f)) // 4) for f in fs)
    router = files_of.get("helix", set())
    skills = {s: {"direct": v["mandatory_total"], "direct_files": v["mandatory_files"],
                  "routed": None if s == "helix" else toks(router | files_of.get(s, set()))}
              for s, v in r["skills"].items()}
    desc = {n: description_bytes(os.path.join(root, "skills", n, "SKILL.md")) for n in names}
    total = sum(desc.values())
    return {"skills": skills,
            "always_on": {"description_bytes": total, "tokens": total // 4, "skills": len(desc),
                          "max_bytes": max(desc.values()) if desc else 0}}


# --- R2 self-test ------------------------------------------------------------------------------------
def extract(repo, ref, dest):
    p = subprocess.run(["git", "-C", repo, "archive", "--format=tar", ref], capture_output=True)
    if p.returncode != 0:
        raise MeasureError(f"cannot read {ref} from {repo}: {p.stderr.decode(errors='replace').strip()}")
    with tarfile.open(fileobj=io.BytesIO(p.stdout)) as t:
        try:
            t.extractall(dest, filter="data")
        except TypeError:  # Python without the extraction-filter backport
            t.extractall(dest)


def default_selftest_repo(*candidates):
    for c in candidates:
        if not c:
            continue
        p = subprocess.run(["git", "-C", c, "rev-parse", "--show-toplevel"], capture_output=True, text=True)
        if p.returncode == 0:
            return p.stdout.strip()
    raise MeasureError("no git repository for the self-test (pass --selftest-repo)")


def self_test(repo):
    with tempfile.TemporaryDirectory() as d:
        extract(repo, KA_COMMIT, d)
        dig = graph_digest(d)
        m = measure(d)
    bad = []
    if dig != KA_GRAPH_DIGEST:
        bad.append(f"graph digest {dig}")
    for s, (direct, routed) in KA_SKILLS.items():
        got = m["skills"].get(s, {})
        if (got.get("direct"), got.get("routed")) != (direct, routed):
            bad.append(f"{s} direct/routed {got.get('direct')}/{got.get('routed')} want {direct}/{routed}")
    a = m["always_on"]
    if (a["description_bytes"], a["tokens"]) != KA_ALWAYS_ON:
        bad.append(f"always_on {a['description_bytes']}/{a['tokens']} want {KA_ALWAYS_ON[0]}/{KA_ALWAYS_ON[1]}")
    if bad:
        raise MeasureError("self-test FAIL on 18200e2: " + "; ".join(bad))
    return "token-measure self-test pass (18200e2: 8 skills, always-on 5090 B / 1272 tok, graph digest ok)"


# --- budget comparison -------------------------------------------------------------------------------
def load_json(path, what):
    try:
        with open(path, encoding="utf-8") as fh:
            return json.load(fh)
    except (OSError, ValueError) as e:
        raise MeasureError(f"cannot read {what} {path}: {e}")


def budget_entries(b):
    """Flatten a budget (or a measurement) into {key: number}; None values are skipped."""
    try:
        out = {}
        for s, v in b["skills"].items():
            for k in ("direct", "routed"):
                if v.get(k) is not None:
                    out[f"{s}.{k}"] = int(v[k])
        out["always_on.description_bytes"] = int(b["always_on"]["description_bytes"])
        out["always_on.tokens"] = int(b["always_on"]["tokens"])
        return out
    except (KeyError, TypeError, ValueError, AttributeError) as e:
        raise MeasureError(f"malformed budget/measurement: {e!r}")


def compare(measured, budget):
    """Return (increases, rows). An increase is any measured number above its budget, or a skill with
    no budget entry (a new skill needs a [token-budget-raise] PR, R9)."""
    bud, cur = budget_entries(budget), budget_entries(measured)
    increases, rows = [], []
    for s in sorted(measured["skills"]):
        if s not in budget["skills"]:
            increases.append(f"{s}: new skill with no budget entry")
    for k in sorted(cur):
        b = bud.get(k)
        if b is None:
            if k.split(".")[0] in budget["skills"]:
                increases.append(f"{k}: no budget entry")
            rows.append((k, None, cur[k], "NEW"))
            continue
        st = "UP" if cur[k] > b else ("down" if cur[k] < b else "same")
        if cur[k] > b:
            increases.append(f"{k}: {b} -> {cur[k]} (+{cur[k] - b})")
        rows.append((k, b, cur[k], st))
    return increases, rows


def summary_md(rows, increases):
    lines = ["## Token budget (docs/sdd/token-budget-guard)", "",
             "| entry | budget | now | change |", "|---|---:|---:|---|"]
    for k, b, c, st in rows:
        lines.append(f"| {k} | {'-' if b is None else b} | {c} | {st if b is None else f'{c - b:+d} {st}'} |")
    lines += ["", "**FAIL**: " + "; ".join(increases) if increases else "**PASS**: no increase"]
    return "\n".join(lines) + "\n"


def budget_doc(m, tag, commit):
    return {"schema": 1, "method": METHOD, "tag": tag, "commit": commit,
            "skills": {s: {"direct": v["direct"], "routed": v["routed"]} for s, v in sorted(m["skills"].items())},
            "always_on": {"description_bytes": m["always_on"]["description_bytes"],
                          "tokens": m["always_on"]["tokens"]}}


def write_json(path, doc):
    with open(path, "w", encoding="utf-8") as fh:
        json.dump(doc, fh, indent=1, sort_keys=False)
        fh.write("\n")


def cmd_check(a):
    repo = a.selftest_repo or default_selftest_repo(a.root, os.path.dirname(os.path.abspath(__file__)))
    st = self_test(repo)
    budget = load_json(a.budget, "budget")
    m = measure(a.root)
    increases, rows = compare(m, budget)
    md = summary_md(rows, increases)
    if a.summary:
        with open(a.summary, "a", encoding="utf-8") as fh:
            fh.write(md)
    verdict = "pass" if not increases and a.rule_lines != "fail" else "fail"
    if a.report:
        if not (a.tag and a.commit):
            raise MeasureError("--report needs --tag and --commit")
        write_json(a.report, {"schema": 1, "tag": a.tag, "release_tag": a.tag, "release_commit": a.commit, "method": METHOD,
                              "self_test": "pass", "rule_lines": a.rule_lines or "not-run",
                              "measured": budget_doc(m, a.tag, a.commit), "budget": budget,
                              "increases": increases, "verdict": verdict})
    print(st)
    for k, b, c, s in rows:
        if s in ("UP", "NEW"):
            print(f"  {k}: {'-' if b is None else b} -> {c}")
    if increases:
        print("token-budget: FAIL — session tokens would rise: " + "; ".join(increases))
        print("  Lower the cost, or raise the budget in a [token-budget-raise] PR quoting the owner's approval.")
        return 1
    if a.rule_lines == "fail":
        print("token-budget: FAIL — rule-line check failed")
        return 1
    print("token-budget: pass (no increase over " + str(budget.get("tag", "?")) + ")")
    return 0


def cmd_budget(a):
    repo = a.selftest_repo or default_selftest_repo(a.root, os.path.dirname(os.path.abspath(__file__)))
    self_test(repo)
    write_json(a.out, budget_doc(measure(a.root), a.tag, a.commit))
    print(f"wrote {a.out} ({a.tag} {a.commit[:7]})")
    return 0


def cmd_ratchet(a):
    repo = a.selftest_repo or default_selftest_repo(a.root, os.path.dirname(os.path.abspath(__file__)))
    self_test(repo)
    budget = load_json(a.budget, "budget")
    m = measure(a.root)
    increases, rows = compare(m, budget)
    if increases:
        print("ratchet refused — measured cost is above the budget: " + "; ".join(increases))
        return 1
    lower = any(st == "down" for _k, _b, _c, st in rows) or set(budget["skills"]) - set(m["skills"])
    if not lower:
        print("ratchet: unchanged")
        return 0
    write_json(a.budget, budget_doc(m, a.tag, a.commit))
    print(f"ratchet: lowered {a.budget} to {a.tag} {a.commit[:7]}")
    return 0


def cmd_compare_budgets(a):
    base, head = load_json(a.base, "base budget"), load_json(a.head, "head budget")
    b, h = budget_entries(base), budget_entries(head)
    raised = [f"{k}: {b.get(k, '-')} -> {v}" for k, v in sorted(h.items()) if k not in b or v > b[k]]
    if raised:
        print("budget raised: " + "; ".join(raised))
        return 3
    print("budget not raised")
    return 0


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    for n in ("graph", "graph-digest", "measure"):
        sub.add_parser(n).add_argument("root")
    p = sub.add_parser("self-test"); p.add_argument("--repo")
    p = sub.add_parser("check")
    p.add_argument("--root", required=True); p.add_argument("--budget", required=True)
    p.add_argument("--selftest-repo"); p.add_argument("--summary"); p.add_argument("--report")
    p.add_argument("--tag"); p.add_argument("--commit"); p.add_argument("--rule-lines", choices=["pass", "fail"])
    for n in ("budget", "ratchet"):
        p = sub.add_parser(n)
        p.add_argument("--root", required=True); p.add_argument("--tag", required=True)
        p.add_argument("--commit", required=True); p.add_argument("--selftest-repo")
        p.add_argument("--out" if n == "budget" else "--budget", required=True)
    p = sub.add_parser("compare-budgets"); p.add_argument("base"); p.add_argument("head")
    a = ap.parse_args(argv)
    try:
        if a.cmd == "graph":
            print(graph_json(a.root)); return 0
        if a.cmd == "graph-digest":
            print(graph_digest(a.root)); return 0
        if a.cmd == "measure":
            print(json.dumps(measure(a.root), indent=1)); return 0
        if a.cmd == "self-test":
            print(self_test(a.repo or default_selftest_repo(os.getcwd(), os.path.dirname(os.path.abspath(__file__)))))
            return 0
        return {"check": cmd_check, "budget": cmd_budget, "ratchet": cmd_ratchet,
                "compare-budgets": cmd_compare_budgets}[a.cmd](a)
    except (MeasureError, OSError, ValueError, UnicodeDecodeError) as e:
        print(f"token-budget: FAIL — measurement error (fail closed): {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
