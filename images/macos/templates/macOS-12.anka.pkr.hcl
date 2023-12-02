packer {
  required_plugins {
    tart = {
      version = ">= 0.6.0"
      source  = "github.com/cirruslabs/tart"
    }
  }
}

variable "source_vm_name" {
  type = string
}

variable "source_vm_tag" {
  type = string
}

variable "build_id" {
  type = string
}

variable "vm_username" {
  type = string
  sensitive = true
}

variable "vm_password" {
  type = string
  sensitive = true
}

variable "github_api_pat" {
  type = string
  default = ""
}

variable "xcode_install_storage_url" {
  type = string
  sensitive = true
}

variable "xcode_install_sas" {
  type = string
  sensitive = true
}

variable "vcpu_count" {
  type = string
  default = "6"
}

variable "ram_size" {
  type = string
  default = "24G"
}

variable "image_os" {
  type = string
  default = "macos12"
}

variable github_url {
  description = "The URL of the GitHub repository"
  type        = string
  default     = "https://github.com/"
}

variable github_org {
  description = "The GitHub organization"
  type        = string
  default     = "gesundheitscloud"
}

variable runner_name {
  description = "The name of the GitHub runner"
  type        = string
  default     = "macos12-runner"
}

variable runner_token {
  description = "The GitHub token to use for registering the runner"
  type        = string
}

variable runner_labels {
  description = "Additional labels for the GitHub runner (comma separated)"
  type        = string
  default     = "macOS12"
}

#source "veertu-anka-vm-clone" "template" {
#  vm_name = "${var.build_id}"
#  source_vm_name = "${var.source_vm_name}"
#  source_vm_tag = "${var.source_vm_tag}"
#  vcpu_count = "${var.vcpu_count}"
#  ram_size = "${var.ram_size}"
#  stop_vm = "true"
#}

source "tart-cli" "tart" {
  vm_base_name = "${var.source_vm_name}"
  vm_name      = "${var.build_id}"
  cpu_count    = 4
  memory_gb    = 8
  disk_size_gb = 160
  ssh_username = "admin"
  ssh_password = "admin"
  ssh_timeout  = "120s"
}


build {
#  sources = [
#    "source.veertu-anka-vm-clone.template"
#  ]
  sources = ["source.tart-cli.tart"]
  provisioner "shell" {
    inline = [
      "mkdir ~/image-generation"
    ]
  }
  provisioner "file" {
    destination = "image-generation/"
    sources = [
      "./provision/assets",
      "./tests",
      "./software-report",
      "./helpers"
    ]
  }
  provisioner "file" {
    destination = "image-generation/software-report/"
    source = "../../helpers/software-report-base"
  }
  provisioner "file" {
    destination = "image-generation/add-certificate.swift"
    source = "./provision/configuration/add-certificate.swift"
  }
  provisioner "file" {
    destination = ".bashrc"
    source = "./provision/configuration/environment/bashrc"
  }
  provisioner "file" {
    destination = ".bash_profile"
    source = "./provision/configuration/environment/bashprofile"
  }
  provisioner "file" {
    destination = "./"
    source = "./provision/utils"
  }
  provisioner "shell" {
    inline = [
      "mkdir ~/bootstrap"
    ]
  }
  provisioner "file" {
    destination = "bootstrap"
    source = "./provision/bootstrap-provisioner/"
  }
  provisioner "file" {
    destination = "image-generation/toolset.json"
    source = "./toolsets/toolset-12.json"
  }
  provisioner "shell" {
    scripts = [
      "./provision/core/xcode-clt.sh",
      "./provision/core/rosetta.sh",
      "./provision/core/homebrew.sh"
    ]
    execute_command = "chmod +x {{ .Path }}; source $HOME/.bash_profile; {{ .Vars }} {{ .Path }}"
  }
  provisioner "shell" {
    scripts = [
      "./provision/configuration/configure-tccdb-macos.sh",
#      "./provision/configuration/add-network-interface-detection.sh",
#      "./provision/configuration/autologin.sh",
#      "./provision/configuration/disable-auto-updates.sh",
#      "./provision/configuration/screensaver-off.sh",
#      "./provision/configuration/ntpconf.sh",
#      "./provision/configuration/max-files.sh",
      "./provision/configuration/shell-change.sh"
    ]
    environment_vars = [
      "PASSWORD=${var.vm_password}",
      "USERNAME=${var.vm_username}"
    ]
    execute_command = "chmod +x {{ .Path }}; source $HOME/.bash_profile; sudo {{ .Vars }} {{ .Path }}"
  }
  provisioner "shell" {
    scripts = [
      "./provision/configuration/preimagedata.sh",
      "./provision/configuration/configure-ssh.sh",
      "./provision/configuration/configure-machine.sh"
    ]
    environment_vars = [
      "IMAGE_VERSION=${var.build_id}",
      "IMAGE_OS=${var.image_os}",
      "PASSWORD=${var.vm_password}"
    ]
    execute_command = "chmod +x {{ .Path }}; source $HOME/.bash_profile; {{ .Vars }} {{ .Path }}"
  }
  provisioner "shell" {
    script  = "./provision/core/reboot.sh"
    execute_command = "chmod +x {{ .Path }}; source $HOME/.bash_profile; sudo {{ .Vars }} {{ .Path }}"
    expect_disconnect = true
  }
  provisioner "shell" {
    pause_before = "30s"
    scripts = [
      "./provision/core/open_windows_check.sh",
      "./provision/core/powershell.sh",
      "./provision/core/python.sh",
      "./provision/core/azcopy.sh",
      "./provision/core/openssl.sh",
      "./provision/core/ruby.sh",
      "./provision/core/rubygem.sh",
      "./provision/core/git.sh",
      "./provision/core/mongodb.sh",
      "./provision/core/node.sh",
      "./provision/core/commonutils.sh"
    ]
    environment_vars = [
      "API_PAT=${var.github_api_pat}",
      "USER_PASSWORD=${var.vm_password}"
    ]
    execute_command = "chmod +x {{ .Path }}; source $HOME/.bash_profile; echo EXEC {{ .Path }}; {{ .Vars }} {{ .Path }}"
  }
  // Install GitHub agent, run as super user to create runner user and add systemd service
  provisioner "shell" {
    environment_vars = ["GITHUB_URL=${var.github_url}", "GITHUB_ORG=${var.github_org}",
                        "RUNNER_NAME=${var.runner_name}", "RUNNER_TOKEN=${var.runner_token}", "RUNNER_LABELS=${var.runner_labels}"
                        ]
    execute_command  = "sh -c '{{ .Vars }} {{ .Path }}'"
    scripts          = ["./provision/core/github-runner.sh"]
  }
  provisioner "shell" {
    script = "./provision/core/xcode.ps1"
    environment_vars = [
      "XCODE_INSTALL_STORAGE_URL=${var.xcode_install_storage_url}",
      "XCODE_INSTALL_SAS=${var.xcode_install_sas}"
    ]
    execute_command = "chmod +x {{ .Path }}; source $HOME/.bash_profile; {{ .Vars }} pwsh -f {{ .Path }}"
  }
  provisioner "shell" {
    script = "./provision/core/reboot.sh"
    execute_command = "chmod +x {{ .Path }}; source $HOME/.bash_profile; sudo {{ .Vars }} {{ .Path }}"
    expect_disconnect = true
  }
  provisioner "shell" {
    scripts = [
      "./provision/core/action-archive-cache.sh",
      "./provision/core/llvm.sh",
      "./provision/core/golang.sh",
      "./provision/core/swiftlint.sh",
      "./provision/core/openjdk.sh",
      "./provision/core/php.sh",
      "./provision/core/aws.sh",
      "./provision/core/rust.sh",
      "./provision/core/gcc.sh",
      "./provision/core/haskell.sh",
      "./provision/core/cocoapods.sh",
      "./provision/core/android-toolsets.sh",
#      "./provision/core/xamarin.sh",
      "./provision/core/vsmac.sh",
      "./provision/core/nvm.sh",
      "./provision/core/apache.sh",
      "./provision/core/nginx.sh",
      "./provision/core/postgresql.sh",
#      "./provision/core/audiodevice.sh",
#      "./provision/core/vcpkg.sh",
      "./provision/core/miniconda.sh",
      "./provision/core/safari.sh",
      "./provision/core/chrome.sh",
#      "./provision/core/edge.sh",
      "./provision/core/firefox.sh",
      "./provision/core/pypy.sh",
      "./provision/core/pipx-packages.sh",
      "./provision/core/bicep.sh",
      "./provision/core/codeql-bundle.sh"
    ]
    environment_vars = [
      "API_PAT=${var.github_api_pat}"
    ]
    execute_command = "chmod +x {{ .Path }}; source $HOME/.bash_profile; {{ .Vars }} {{ .Path }}"
  }
  provisioner "shell" {
    scripts = [
      "./provision/core/toolset.ps1",
      "./provision/core/configure-toolset.ps1"
    ]
    execute_command = "chmod +x {{ .Path }}; source $HOME/.bash_profile; {{ .Vars }} pwsh -f {{ .Path }}"
  }
  provisioner "shell" {
    script = "./provision/core/delete-duplicate-sims.rb"
    execute_command = "source $HOME/.bash_profile; ruby {{ .Path }}"
  }
  provisioner "shell" {
      script = "./provision/core/fix-xcode-simulators.ps1"
      execute_command = "chmod +x {{ .Path }}; {{ .Vars }} pwsh -f {{ .Path }}"
  }
#  provisioner "shell" {
#    inline = [
#      "pwsh -File \"$HOME/image-generation/software-report/SoftwareReport.Generator.ps1\" -OutputDirectory \"$HOME/image-generation/output/software-report\" -ImageName ${var.build_id}",
#      "pwsh -File \"$HOME/image-generation/tests/RunAll-Tests.ps1\""
#    ]
#    execute_command = "source $HOME/.bash_profile; {{ .Vars }} {{ .Path }}"
#  }
#  provisioner "file" {
#    destination = "../image-output/"
#    direction = "download"
#    source = "./image-generation/output/"
#  }
  provisioner "shell" {
    scripts = [
      "./provision/configuration/configure-hostname.sh",
      "./provision/configuration/finalize-vm.sh"
    ]
    execute_command = "chmod +x {{ .Path }}; source $HOME/.bash_profile; {{ .Vars }} {{ .Path }}"
  }
}
