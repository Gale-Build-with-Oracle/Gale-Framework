#!/usr/bin/env python3
"""Upsert the FLEET-DOCTRINE block into ~/.codex/AGENTS.md from WF/codex/instructions.md.
Idempotent. Placed in the omx-preserved zone (after END AUTONOMY DIRECTIVE, before
omx:generated marker). Codex reads ~/.codex/AGENTS.md as user-scope user_instructions;
it does NOT read ~/.codex/instructions.md (verified codex 0.139)."""
import sys, os

START = "<!-- FLEET-DOCTRINE:START — managed by fleet-sync from Gale-Framework/codex/instructions.md; edit the fragment, never here -->"
END   = "<!-- FLEET-DOCTRINE:END -->"
AUTONOMY_END = "<!-- END AUTONOMY DIRECTIVE -->"
OMX_GEN = "<!-- omx:generated:agents-md -->"

agents_path = os.path.expanduser(sys.argv[1])   # ~/.codex/AGENTS.md
doctrine_path = sys.argv[2]                      # WF/codex/instructions.md

doctrine = open(doctrine_path).read().strip()
block = f"{START}\n{doctrine}\n{END}"

if not os.path.exists(agents_path):
    # No OMX AGENTS.md yet — create a minimal file holding just the fleet block.
    open(agents_path, "w").write(block + "\n")
    print("created (no prior AGENTS.md)")
    sys.exit(0)

content = open(agents_path).read()
s, e = content.find(START), content.find(END)
if s >= 0 and e > s:
    new = content[:s] + block + content[e + len(END):]
    if new == content:
        print("in sync")
    else:
        open(agents_path, "w").write(new)
        print("updated existing block")
    sys.exit(0)

# No fleet block yet — insert in the preserved zone.
anchor = content.find(AUTONOMY_END)
if anchor >= 0:
    ins = anchor + len(AUTONOMY_END)
    if content[ins:ins+1] == "\n": ins += 1
    new = content[:ins] + block + "\n" + content[ins:]
elif content.find(OMX_GEN) >= 0:
    g = content.find(OMX_GEN)
    new = content[:g] + block + "\n" + content[g:]
else:
    new = block + "\n\n" + content
open(agents_path, "w").write(new)
print("inserted new block (preserved zone)")
