# vSphere: Create a GitHub Runner VM (Ubuntu 24.04)

Build a GitHub Actions self-hosted runner VM on vSphere by cloning your existing Ubuntu 24.04 template and running the **full runner-images provisioner chain** (same install scripts as [build.ubuntu-24_04.pkr.hcl](images/ubuntu/templates/build.ubuntu-24_04.pkr.hcl): Git, Docker, .NET, Node, Python, Java, and the rest of the toolset). The build takes a long time (hours) and must be run from the **runner-images** repo so script paths resolve.

## Prerequisites

- **vCenter** access and credentials
- **Existing template** `linux-ubuntu-24.04-lts-main` in folder **GitHub Runners** (built e.g. via [gh-cache-vm](../gh-cache-vm) Packer)
- **Packer** CLI (`packer version`)
- **Runner-images repo** checked out; build is run from `images/ubuntu/templates`

## Variables

Copy the example and set your values. **Do not commit real credentials**—keep `packer-variables.json` out of version control or use a secrets manager.

```bash
cd images/ubuntu/templates
cp packer-variables.json.example packer-variables.json
# Edit packer-variables.json: set vsphere_* and build_* (SSH user/password for the template)
```

Or re-use [gh-cache-vm/packer-variables.json](../gh-cache-vm/packer-variables.json) if you already have it (same variable names).

- **vsphere_cluster**: set to your cluster name, or leave empty and set **vsphere_host** to your ESXi host.
- **vsphere_template_name**: template to clone (default `linux-ubuntu-24.04-lts-main`).
- **vm_name**: name of the new VM (default `github-runner-ubuntu-24.04`).
- **vm_disk_size**: primary disk size in MiB (default `122880` = 120 GB). For an SSD, use a datastore backed by SSD (e.g. set **vsphere_datastore** to your SSD datastore).
- **build_username** / **build_password**: SSH user and password on the template (e.g. `ubuntu`).

## Build

Run from **images/ubuntu/templates** (paths in the config are relative to this directory):

```bash
cd images/ubuntu/templates
packer build -var-file=packer-variables.json build.ubuntu-24_04.vsphere.pkr.hcl
```

Or, using gh-cache-vm variables (same variable names):

```bash
cd images/ubuntu/templates
packer build -var-file=../../gh-cache-vm/packer-variables.json build.ubuntu-24_04.vsphere.pkr.hcl
```

When the build finishes, a new VM exists in vSphere (folder **GitHub Runners**). It is not converted to a template so you can power it on and use it as a runner. The VM has the same software set as the Azure Ubuntu 24.04 image (see [Ubuntu2404-Readme.md](images/ubuntu/Ubuntu2404-Readme.md) after a build that generated the report).

## After the build

1. **Power on** the VM in vSphere and note its IP (or use DHCP and find it).
2. **Register the GitHub Actions runner** (one-time per VM):
   - In GitHub: **Settings → Actions → Runners → New self-hosted runner**; pick Linux and copy the commands.
   - SSH into the VM as `build_username` and run the download/configure/install commands, then start the runner (or install the service so it starts on boot).

Example (replace with the URL and token from the GitHub UI):

```bash
ssh ubuntu@<VM_IP>
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf actions-runner-linux-x64-2.311.0.tar.gz
./config.sh --url https://github.com/YOUR_ORG/YOUR_REPO --token YOUR_TOKEN
./run.sh
# Or: sudo ./svc.sh install && sudo ./svc.sh start
```

3. Use the runner in workflows with `runs-on: self-hosted` (and Docker is available for container jobs).
