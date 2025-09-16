import json
import sys

diff_file = sys.argv[1]
output_file = sys.argv[2]

entries = []
current_file = None
changes = []

with open(diff_file, "r") as f:
    for line in f:
        line = line.rstrip("\n")
        if line.startswith("diff --git"):
            if current_file:
                entries.append({
                    "file": current_file,
                    "status": "modified" if changes else "added",
                    "changes": changes
                })
            current_file = line.split(" b/")[-1].strip()
            changes = []
        elif line.startswith("+") or line.startswith("-"):
            changes.append(line)

if current_file:
    entries.append({
        "file": current_file,
        "status": "modified" if changes else "added",
        "changes": changes
    })

output_json = {"files": entries}

with open(output_file, "w") as out:
    json.dump(output_json, out, indent=2)

with open(output_file, "r") as out:
    print(out.read())
