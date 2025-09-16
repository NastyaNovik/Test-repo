import json
import sys
from google.cloud import aiplatform

input_json = sys.argv[1]
PROJECT_ID = "iw-team-05-ab76"

aiplatform.init(project=PROJECT_ID)

with open(input_json, "r", encoding="utf-8") as f:
    pr_diff = json.load(f)

prompt_lines = ["Generate a concise PR diff summary from the following changes:"]
for file in pr_diff.get("files_changed", []):
    prompt_lines.append(f"\nFile: {file['file']} ({file['status']})")
    for change in file['changes']:
        if change.strip():
            prompt_lines.append(change)

prompt_text = "\n".join(prompt_lines)

model = aiplatform.TextGenerationModel.from_pretrained("text-bison@001")

response = model.predict(
    prompt_text,
    max_output_tokens=500,
    temperature=0.2
)

print("\n=== PR Summary ===\n")
print(response.text)
