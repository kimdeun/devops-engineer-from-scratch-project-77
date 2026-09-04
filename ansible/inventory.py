#!/usr/bin/env python3
"""Ansible dynamic inventory backed by Terraform outputs."""

import json
import subprocess
from pathlib import Path


terraform_dir = Path(__file__).resolve().parent.parent / "terraform"
result = subprocess.run(
    ["terraform", f"-chdir={terraform_dir}", "output", "-json", "web_server_ips"],
    check=True,
    capture_output=True,
    text=True,
)
hosts = json.loads(result.stdout)
print(json.dumps({
    "web": {"hosts": hosts},
    "_meta": {"hostvars": {host: {"ansible_user": "ubuntu"} for host in hosts}},
}))

