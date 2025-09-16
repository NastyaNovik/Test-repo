import json
import sys

diff_file = sys.argv[1]
output_file = sys.argv[2]

entries = []
current_file = None
changes = []
is_new_file = False

with open(diff_file, "r") as f:
    for line in f:
        line = line.rstrip("\n")
        if line.startswith("diff --git"):
            if current_file:
                status = "added" if is_new_file else ("modified" if changes else "modified")
                entries.append({
                    "file": current_file,
                    "status": status,
                    "changes": changes
                })
            current_file = line.split(" b/")[-1].strip()
            changes = []
            is_new_file = False
        elif line.startswith("new file mode"):
            is_new_file = True
        elif line.startswith("+") or line.startswith("-"):
            changes.append(line)

if current_file:
    status = "added" if is_new_file else ("modified" if changes else "modified")
    entries.append({
        "file": current_file,
        "status": status,
        "changes": changes
    })

output_json = {"files": entries}

with open(output_file, "w") as out:
    json.dump(output_json, out, indent=2)

with open(output_file, "r") as out:
    print(out.read())
