import json
import subprocess
from pathlib import Path

resource_group = "rg-algebra-cloud-project"

az_path = r"C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd"

if not Path(az_path).exists():
    raise FileNotFoundError(
        "Azure CLI was not found at the expected path. "
        "Check Azure CLI installation or add az.cmd to PATH."
    )

command = [
    az_path,
    "resource",
    "list",
    "--resource-group",
    resource_group,
    "--output",
    "json"
]

result = subprocess.run(
    command,
    capture_output=True,
    text=True,
    check=True
)

resources = json.loads(result.stdout)

print(f"Resources in resource group: {resource_group}")
print("-" * 120)

for resource in resources:
    name = resource.get("name", "")
    resource_type = resource.get("type", "")
    location = resource.get("location", "")
    tags = resource.get("tags", {})

    print(f"Name: {name}")
    print(f"Type: {resource_type}")
    print(f"Location: {location}")
    print(f"Tags: {tags}")
    print("-" * 120)