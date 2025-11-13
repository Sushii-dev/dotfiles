---
alwaysApply: true
---

# Scripts and automation rules

These rules are instructions for Cursor when working with helper scripts.

## Script location

All user helper scripts must live in:

- dotfiles/scripts/.local/bin/

These are exposed to the system via stow so that:

- ~/.local/bin/<name> -> dotfiles/scripts/.local/bin/<name>

Cursor must not place scripts directly into ~/.local/bin. Scripts must always be created or edited in the repo.

## Script style

Scripts should:

- Start with: #!/usr/bin/env bash  
- Use set -e when failure should abort the script  
- Print clear status messages with echo  
- Avoid destructive behavior unless explicitly requested  

Example template:

```bash
#!/usr/bin/env bash
set -e

echo "[script-name] Starting"

# script logic

echo "[script-name] Done"
```

## Existing key scripts

dotfiles-sync:

- Handles git status, add, commit, and push or pull for the dotfiles repo  
- Cursor should refer to it when describing the sync workflow  

omarchy-sync-hypr:

- Backs up ~/.config/hypr  
- Copies ~/dotfiles/hypr/.config/hypr to ~/.config/hypr  
- Tries to run hyprctl reload  

bootstrap-omarchy.sh:

- Lives in the repo root  
- Used once per new install  
- Backs up existing configs, stows safe packages, sets up scripts, and applies Hypr config  

Cursor must not duplicate the logic of these scripts in new scripts. Changes to bootstrap behavior belong in bootstrap-omarchy.sh.

## Safety rules for new scripts

When creating new scripts, Cursor should:

- Prefer backing up existing files or directories before overwriting  
- Avoid touching ~/.config/omarchy and ~/.local/share/omarchy  
- Avoid modifying system wide locations such as /etc, /usr, or /opt  
- Keep behavior idempotent when possible so that repeated runs are safe  

If a script could impact multiple devices through sync, Cursor should document that in comments at the top of the script.
