---
alwaysApply: true
---

# General config style rules

These rules are instructions for Cursor about formatting and style.

## Indentation and formatting

Cursor should:

- Preserve existing indentation style in each file  
- Format new code or config to match the surrounding style  
- Avoid reformatting the entire file unless explicitly requested  

JSON and JSONC:

- Use double quotes  
- Keep key order stable where possible  
- Only change what is necessary  

Lua (Neovim):

- Use the indentation already used in the file  
- Keep requires and plugin specs grouped logically  

Shell scripts:

- Use the shebang: #!/usr/bin/env bash  
- Use set -e when failure should abort the script  
- Use clear echo statements for user facing scripts  

Example:

```bash
#!/usr/bin/env bash
set -e

echo "[script-name] Starting"

# logic here

echo "[script-name] Done"
```

## Comments and structure

Cursor should:

- Keep comments that explain intent  
- Add short comments when adding non obvious behavior  
- Use a tone that matches the existing file  

## Avoid over engineering

Cursor should avoid:

- Large refactors inside config files unless asked  
- Introducing unnecessary abstractions  
- Turning simple configs into complex frameworks  

The goal is clarity and stability.

## Safety first

If a change could affect multiple machines via sync, Cursor should lean toward:

- Keeping the change minimal  
- Respecting per device overrides  
- Not touching any Omarchy system paths  
