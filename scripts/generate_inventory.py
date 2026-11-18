#!/usr/bin/env python3
"""Build an Ansible inventory from Terraform's vm_public_ips output."""
import argparse
import json
from pathlib import Path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--terraform-output", required=True)
    parser.add_argument("--inventory", required=True)
    parser.add_argument("--ssh-user", default="ubuntu")
    args = parser.parse_args()

    payload = json.loads(Path(args.terraform_output).read_text())
    if "vm_public_ips" not in payload:
        raise SystemExit("Terraform output 'vm_public_ips' was not found")
    instances = payload["vm_public_ips"].get("value") or []
    if not instances:
        raise SystemExit("Terraform returned no VM instances; refusing to create empty inventory")

    lines = ["[web]"]
    for item in instances:
        ip = item.get("public_ip")
        if not ip:
            raise SystemExit(f"Instance {item.get('name', '<unknown>')} has no public IP")
        lines.append(f"{ip} ansible_user={args.ssh_user}")
    lines.extend(["", "[web:vars]", "ansible_python_interpreter=/usr/bin/python3", ""])

    destination = Path(args.inventory)
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text("\n".join(lines))
    print(f"Created inventory with {len(instances)} host(s): {destination}")


if __name__ == "__main__":
    main()
