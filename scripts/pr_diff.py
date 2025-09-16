import json
import sys
import codecs

diff_file = sys.argv[1]
output_file = sys.argv[2]

entries = []
current_file = None
changes = []
status = "modified"

with open(diff_file, "r", encoding="utf-8") as f:
    for line in f:
        line = line.rstrip("\n")

        if line.startswith("diff --git"):
            if current_file:
                entries.append({
                    "file": current_file,
                    "status": status,
                    "changes": changes
                })
            raw_file = line.split(" b/")[-1].strip().strip('"')
            current_file = codecs.decode(raw_file, "unicode_escape")
            changes = []
            status = "modified"

        elif line.startswith("new file mode"):
            status = "added"

        elif line.startswith("deleted file mode"):
            status = "deleted"

        elif line.startswith("+") or line.startswith("-"):
            changes.append(line)

if current_file:
    entries.append({
        "file": current_file,
        "status": status,
        "changes": changes
    })

output_json = {"files_changed": entries}

with open(output_file, "w", encoding="utf-8") as out:
    json.dump(output_json, out, indent=2, ensure_ascii=False)

with open(output_file, "r", encoding="utf-8") as out:
    print(out.read())
