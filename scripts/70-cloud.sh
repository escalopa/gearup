#!/usr/bin/env bash
# 70-cloud.sh — Terraform + the heavier IaC/Kubernetes/cloud CLIs.
# Tools that ship cleanly via `go install` (terraform-docs, k9s, dive, ...) live
# in 40-tools.sh; this file is for the ones that need a per-OS binary/installer.
# Every installer is idempotent (has_cmd guard) and soft (warns, never aborts).

_arch_gnu() { case "$(uname -m)" in x86_64|amd64) echo amd64 ;; aarch64|arm64) echo arm64 ;; *) uname -m ;; esac; }

# ---- terraform (the headline) ----------------------------------------------
install_terraform() {
  if [[ "$GEARUP_OS" == "macos" ]]; then
    run brew tap hashicorp/tap
    run brew install hashicorp/tap/terraform
  else
    local ver arch url
    ver="$(curl -fsSL https://checkpoint-api.hashicorp.com/v1/check/terraform | jq -r .current_version)"
    [[ -n "$ver" && "$ver" != "null" ]] || { warn "terraform: could not resolve latest version"; return 1; }
    arch="$(_arch_gnu)"
    url="https://releases.hashicorp.com/terraform/${ver}/terraform_${ver}_linux_${arch}.zip"
    run mkdir -p "$HOME/.local/bin"
    log "downloading terraform $ver"
    run curl -fsSL -o /tmp/terraform.zip "$url" || return 1
    run unzip -o /tmp/terraform.zip -d "$HOME/.local/bin" || return 1
    run rm -f /tmp/terraform.zip
  fi
}

# ---- kubectl ----------------------------------------------------------------
install_kubectl() {
  if [[ "$GEARUP_OS" == "macos" ]]; then
    run brew install kubectl
  else
    local ver arch
    ver="$(curl -fsSL https://dl.k8s.io/release/stable.txt)" || return 1
    arch="$(_arch_gnu)"
    run mkdir -p "$HOME/.local/bin"
    run curl -fsSL -o "$HOME/.local/bin/kubectl" "https://dl.k8s.io/release/${ver}/bin/linux/${arch}/kubectl" || return 1
    run chmod +x "$HOME/.local/bin/kubectl"
  fi
}

# ---- helm -------------------------------------------------------------------
install_helm() {
  if [[ "$GEARUP_OS" == "macos" ]]; then
    run brew install helm
  else
    run mkdir -p "$HOME/.local/bin"
    # Official installer, redirected to a no-sudo, user-local prefix.
    run sh -c 'curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | HELM_INSTALL_DIR="$HOME/.local/bin" USE_SUDO=false bash' || return 1
  fi
}

# ---- tflint -----------------------------------------------------------------
# ---- aws cli v2 -------------------------------------------------------------
install_awscli() {
  if [[ "$GEARUP_OS" == "macos" ]]; then
    run brew install awscli
  else
    run curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o /tmp/awscliv2.zip || return 1
    run unzip -q -o /tmp/awscliv2.zip -d /tmp || return 1
    run /tmp/aws/install --update -i "$HOME/.local/aws-cli" -b "$HOME/.local/bin" || return 1
    run rm -rf /tmp/aws /tmp/awscliv2.zip
  fi
}

# ---- yandex cloud cli -------------------------------------------------------
install_yc() {
  # Official cross-platform installer. -n keeps it from editing rc files (gearup
  # already puts ~/.local/bin on PATH); we symlink the binary there.
  run curl -fsSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh -o /tmp/yc-install.sh || return 1
  run bash /tmp/yc-install.sh -i "$HOME/.yandex-cloud" -n || return 1
  run rm -f /tmp/yc-install.sh
  run mkdir -p "$HOME/.local/bin"
  run ln -sf "$HOME/.yandex-cloud/bin/yc" "$HOME/.local/bin/yc"
}

# ---- google cloud cli -------------------------------------------------------
install_gcloud() {
  if [[ "$GEARUP_OS" == "macos" ]]; then
    run brew install --cask google-cloud-sdk
  else
    # Official installer, non-interactive; symlink gcloud/gsutil onto PATH.
    run curl -fsSL https://sdk.cloud.google.com -o /tmp/gcloud-install.sh || return 1
    run bash /tmp/gcloud-install.sh --disable-prompts --install-dir="$HOME" || return 1
    run rm -f /tmp/gcloud-install.sh
    run mkdir -p "$HOME/.local/bin"
    run ln -sf "$HOME/google-cloud-sdk/bin/gcloud" "$HOME/.local/bin/gcloud"
    run ln -sf "$HOME/google-cloud-sdk/bin/gsutil" "$HOME/.local/bin/gsutil"
  fi
}

# name=install-function ; command name is the GEARUP_ONLY / has_cmd key.
CLOUD_TOOLS=(
  "terraform=install_terraform"
  "kubectl=install_kubectl"
  "helm=install_helm"
  "aws=install_awscli"
  "yc=install_yc"
  "gcloud=install_gcloud"
)

for entry in "${CLOUD_TOOLS[@]}"; do
  cmd="${entry%%=*}" fn="${entry#*=}"
  _need "$cmd" || continue
  log "installing $cmd"
  if "$fn"; then
    ok "installed $cmd"; record_result installed "$cmd"
  else
    warn "$cmd: install failed or unsupported on this platform — install it manually"; record_result failed "$cmd"
  fi
done
