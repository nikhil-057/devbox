# agents.md — AI Agent Context for devbox

This file gives AI coding agents everything they need to work effectively in this repository without re-exploring the codebase from scratch.

---

## What this repo is

A **personal portable developer environment** managed with [Home Manager](https://github.com/nix-community/home-manager) and [npins](https://github.com/andir/npins). It is **not** a NixOS system configuration — it is purely user-space and runs on any Linux machine with `nix` installed. No flakes are used.

The entire environment (shell, editor, tools, dotfiles) is reproducibly defined in Nix and can be bootstrapped on a fresh machine (requires only `docker` and `git`) via `bootstrap.sh`.

---

## Repository layout

```
devbox/
├── bootstrap.sh                 # Full container teardown and rebuild
├── enter.sh                     # Day-to-day entry point: starts or enters the container
├── default.nix                  # Top-level build: exposes setupHomeManager script
├── home-manager/
│   ├── home.nix                 # THE main config: packages, dotfiles, programs
│   ├── setup-hook.sh            # Bootstrap script: symlinks config, runs home-manager switch
│   └── dotfiles/
│       ├── init.lua             # Full Neovim config (lazy.nvim)
│       ├── tmux.conf            # tmux config
│       ├── zshrc                # Zsh + Oh My Zsh
│       ├── profile              # POSIX env vars, aliases, AWS sourcing
│       └── containers-policy.json
├── npins/
│   ├── default.nix              # Auto-generated npins fetcher (DO NOT EDIT)
│   └── sources.json             # Pinned nixpkgs, home-manager, nixvim
└── setup/
    ├── hm.sh                    # Local install/update: runs nix-build + activates
    └── npins.sh                 # Re-initialize all npins pins
```

---

## Key files and their roles

### `home-manager/home.nix`
The single source of truth for the environment. Everything lives here:
- `home.packages` — all installed tools and languages
- `home.file` — dotfile symlinks (nvim, tmux, zsh, profile, containers policy)
- `home.sessionVariables` — env vars (OpenSSL flags, SonarLint plugins path)
- `home.file.".profile.d/aws-config.sh"` — inline AWS credential loader
- `programs.git` — git config (name, editor, mergetool)
- `programs.ssh` — SSH client config (ControlMaster, host-specific rules)
- `xdg.configFile."pypoetry/config.toml"` — Poetry: in-project venvs
- `xdg.configFile."opencode/opencode.json"` — OpenCode: AWS Bedrock model
- `xdg.configFile."opencode/tui.json"` — OpenCode: split disabled

### `home-manager/dotfiles/init.lua`
Full Neovim configuration. Uses `lazy.nvim` (auto-bootstrapped on first run). Defines all plugins, LSP servers, and key mappings.

### `home-manager/dotfiles/profile`
POSIX shell profile sourced by zsh. Sets locale, `XAUTHORITY`, `alias vim=nvim`, re-sources `hm-session-vars.sh`, and loads AWS credentials.

### `npins/sources.json`
Pinned dependency versions. Three pins:
- `nixpkgs` → `nixos/nixpkgs` on `nixos-unstable`
- `home-manager` → `nix-community/home-manager` on `master`
- `nixvim` → `nix-community/nixvim` on `main` (pinned but not yet wired in)

---

## Common tasks and how to do them

### Add a new package
Edit `home-manager/home.nix`, add to `home.packages`:
```nix
home.packages = [
  # ... existing packages ...
  pkgs.your-new-package
];
```
Then run `./setup/hm.sh` to activate.

### Add a new dotfile
1. Create the file at `home-manager/dotfiles/your-file`
2. Add a symlink in `home.nix`:
```nix
home.file = {
  # ... existing ...
  ".your-file".source = dotfiles/your-file;
};
```

### Add an inline config file
Use `home.file."path".text` for simple text or `xdg.configFile."path".text` for XDG config:
```nix
home.file.".myconfig".text = ''
  key = value
'';
```

### Add a session environment variable
```nix
home.sessionVariables = {
  MY_VAR = "value";
};
```

### Add a new Neovim plugin
Edit `home-manager/dotfiles/init.lua`. Add an entry to the `plugins` list following lazy.nvim spec:
```lua
{
  "author/plugin-name",
  config = function()
    require("plugin-name").setup({})
  end
}
```

### Add a new LSP server
1. Add the LSP binary to `home.packages` in `home.nix`
2. In `init.lua`, configure and enable:
```lua
vim.lsp.config("server-name", {
  cmd = { "server-binary", "--stdio" },
  capabilities = capabilities,
})
vim.lsp.enable("server-name")
```

### Update a pinned dependency
```bash
# Update a single pin
npins update nixpkgs

# Re-initialize all pins from scratch
./setup/npins.sh
```

### Bootstrap on a fresh machine
```bash
mkdir -p ~/repos
git clone git@github.com:nikhil-057/devbox.git ~/repos/devbox
~/repos/devbox/bootstrap.sh
```

---

## Design constraints and conventions

1. **No flakes** — the repo intentionally avoids flakes for compatibility with plain `nix-shell` / `nix-build` workflows. All pinning is done via npins.

2. **No NixOS** — this is user-space only via Home Manager. There are no `configuration.nix` or NixOS module files.

3. **Single host, single user** — `home.username` and `home.homeDirectory` are read from `$USER` and `$HOME` env vars at build time, making it machine-agnostic.

4. **Upstream home-manager** — the `home-manager` pin points to `nix-community/home-manager` on `master`. No fork is used.

5. **npins/default.nix is auto-generated** — never edit it manually. Use `npins` CLI to update `sources.json`.

6. **Dotfiles are symlinked from the Nix store** — after activation, files like `~/.config/nvim/init.lua` are read-only symlinks into `/nix/store/`. To edit them, edit the source in `home-manager/dotfiles/` and re-run `./setup/hm.sh`.

7. **One config file for everything** — resist splitting `home.nix` into modules unless the file becomes unmanageable. Simplicity is intentional.

---

## What NOT to do

- Do not edit `npins/default.nix` — it is auto-generated by npins.
- Do not edit files in `~/.config/nvim/`, `~/.tmux.conf`, etc. directly — they are Nix store symlinks. Edit the sources in `home-manager/dotfiles/`.
- Do not add system-level NixOS configuration — this repo is user-space only.
- Do not switch to flakes without understanding the full bootstrap chain.
- Do not commit `~/.aws/credentials.json` or any credentials to this repo.
