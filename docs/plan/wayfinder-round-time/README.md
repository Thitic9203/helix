# Local-markdown wayfinder tracker

This folder is one wayfinder map, stored as plain markdown because the repo has no wayfinder issue-tracker setup.

| Concept | How it lives here |
|---------|-------------------|
| Map | `MAP.md` (frontmatter `labels: [wayfinder:map]`) |
| Ticket | `tickets/NN-<slug>.md`. The id is `NN`, and the title is the first `# ` heading |
| Type label | frontmatter `type: research \| prototype \| grilling \| task` |
| Open / closed | frontmatter `status: open \| closed` |
| Claim | frontmatter `assignee:`. If it is empty, the ticket is unclaimed |
| Blocking | frontmatter `blocked_by: [NN, ...]` |
| Resolution | a `## Resolution` section appended to the ticket, then `status: closed` |
| Assets | linked from the ticket. Raw data that may hold customer identifiers stays **outside** this public repo; only redacted summaries are committed |

**Frontier** = open + unassigned + every `blocked_by` ticket closed. Run this from the repo root:

```bash
node -e 'const fs=require("fs"),d="docs/plan/wayfinder-round-time/tickets",t={};for(const f of fs.readdirSync(d)){const s=fs.readFileSync(d+"/"+f,"utf8"),m=s.match(/^---\n([\s\S]*?)\n---/)[1],g=k=>(m.match(new RegExp("^"+k+":[ \\t]*(.*)$","m"))||[])[1]||"";t[f.slice(0,2)]={f,status:g("status"),assignee:g("assignee").trim(),blocked:(g("blocked_by").match(/\d+/g)||[]),title:(s.match(/^# (.*)$/m)||[])[1]}}for(const[k,v]of Object.entries(t))if(v.status==="open"&&!v.assignee&&v.blocked.every(b=>t[b]&&t[b].status==="closed"))console.log(k,v.title)'
```

When the map is finished, rename the folder with the `done_` prefix, matching the other plans in `docs/plan/`.
