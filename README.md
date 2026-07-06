# dotfiles-mac-nix

This repo is the public, reusable core of my Mac setup.

It is built with [Nix](https://nixos.org/), [`nix-darwin`](https://github.com/nix-darwin/nix-darwin), [Home Manager](https://github.com/nix-community/home-manager), and declarative [Homebrew](https://brew.sh/). The goal is to give macOS developers a reproducible base they can fork and adapt without inheriting someone else's entire private dotfiles repo.

If you want the longer explanation, see the [blog post](https://open.substack.com/pub/kunchenguid/p/how-i-built-a-reproducible-mac-setup?utm_campaign=post-expanded-share&utm_medium=web).

## What this repo does

It gives you a structured starting point for managing a Mac setup in code:

- bootstrap a fresh Mac with `setup/mac.sh`
- configure macOS defaults with `nix-darwin`
- manage user packages and shell behavior with Home Manager
- install GUI apps and macOS-native tools declaratively with Homebrew
- keep selected app config in the repo and link it into place

I include [WezTerm](https://wezfurlong.org/wezterm/) as the one concrete app-config example because it is real enough to demonstrate the pattern without dragging in the more personal parts of my workflow.

## What is intentionally not included

This repo does **not** try to mirror my entire machine.

I left out things that are too personal or too workflow-specific to make a good public starter repo, including:

- editor config
- custom shell systems
- personal scripts
- AI tooling
- secrets and tokens
- private automation

The goal is to provide a reusable foundation that you can make your own.

## Repo structure

- `setup/mac.sh` - bootstrap a fresh Mac
- `setup/README.md` - bootstrap usage and testing notes
- `flake.nix` - top-level Nix wiring
- `nix/host.nix` - machine-level macOS config (nix-darwin)
- `nix/user.nix` - user environment: packages, shell, git, fonts, dotfiles (Home Manager)
- `files/.config/wezterm/wezterm.lua` - example app config linked into place
- `tests/` - regression tests for the bootstrap script
- `blog.md` - local copy of the [blog post](https://open.substack.com/pub/kunchenguid/p/how-i-built-a-reproducible-mac-setup?utm_campaign=post-expanded-share&utm_medium=web)

## How to use it

### 1. Clone the repo

```bash
git clone git@github.com:kunchenguid/dotfiles-mac-nix.git ~/github/dotfiles-mac-nix
cd ~/github/dotfiles-mac-nix
```

### 2. Replace the placeholders

Update values like:

- `yourname`
- `/Users/yourname`
- `Your Name`
- `you@example.com`

If you are on an Intel Mac, change the system target in `flake.nix` from:

```nix
system = "aarch64-darwin";
```

to:

```nix
system = "x86_64-darwin";
```

### 3. Run the bootstrap script on a fresh Mac

This repo is primarily set up for Apple Silicon Macs. If you are on Intel, make the architecture change above before you run the bootstrap script.

```bash
bash setup/mac.sh
```

The script will:

- install [Determinate Nix Installer](https://determinate.systems/nix-installer/) if needed
- install [Homebrew](https://brew.sh/) if needed
- apply the `nix-darwin` + Home Manager config
- install [`nvm`](https://github.com/nvm-sh/nvm) and a default Node.js version if needed

On a fresh machine, the bootstrap is designed to complete in one run.
After the Determinate installer runs, the script sources the Nix daemon profile into the current shell and uses an absolute `nix` path for the first `nix-darwin` activation, so you should not need a second shell or a second setup run.

The `NIX_DAEMON_PROFILE` and `DARWIN_REBUILD_BIN` environment variables are only there so the regression test can point the script at sandboxed paths.
Normal use should leave them unset.

## How I manage changes later

After the initial bootstrap, the usual workflow is:

1. edit the Nix config
2. run:

```bash
rebuild
```

This alias is included in the shell config and expands to the repo path used in this guide:

```bash
/run/current-system/sw/bin/darwin-rebuild switch --flake ~/github/dotfiles-mac-nix#mac
```

## Testing

Do not run `setup/mac.sh` against a development or CI machine just to test it.
Run the sandboxed regression test instead:

```bash
bash tests/mac_setup_test.sh
```

It runs the real script logic with stub executables for `curl`, `sh`, `nix`, `darwin-rebuild`, `sudo`, and `bash`, covering both a fresh-machine single-pass bootstrap and the already-bootstrapped fast path.
The harness also guards every harness/stub write against sandbox escapes, re-homes `NVM_DIR` under the sandboxed `HOME`, and unsets inherited `BASH_ENV`/`ENV` hooks before invoking the script under test.

## Where to add new tools

My rough rule of thumb:

- use **Home Manager / Nix** for reproducible baseline CLI tools, fonts, shell utilities, and user environment packages
- use **Homebrew** for GUI apps and macOS-native tools that fit naturally there
- use **ecosystem-specific package managers** like `npm` when that is the right abstraction for the tool

A good setup does not force every tool through one package manager. It just makes the ownership of each layer clear.

## Agent skills (AXI)

These [AXI](https://axi.md/) agent skills are installed imperatively with the `skills` CLI, so they live in `~/.agents/skills/` (symlinked into Claude Code) and are **not** managed by Nix.
They do not restore automatically on a fresh machine, so reinstall them after bootstrap:

```bash
npx --yes skills add kunchenguid/gh-axi --skill gh-axi -g
npx --yes skills add kunchenguid/chrome-devtools-axi --skill chrome-devtools-axi -g
npx --yes skills add kunchenguid/lavish-axi --skill lavish -g
```

Prerequisites (all handled by the Nix config except Chrome): `gh-axi` needs the `gh` CLI authenticated via `gh auth login`, and `chrome-devtools-axi` needs Google Chrome installed.
The `-g` flag installs globally; each package also ships an optional secondary skill that only installs per-project (drop `-g` inside a project to get it).

## no-mistakes gate

[no-mistakes](https://github.com/kunchenguid/no-mistakes) is a local git proxy that validates code (review, test, docs, lint) in an isolated worktree before it reaches the remote, then opens a PR.
It is a standalone binary plus a user-level `/no-mistakes` agent skill, installed outside Nix, so it does not restore on a fresh machine.

Reinstall the binary after bootstrap:

```bash
curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh
```

It installs to `~/.no-mistakes/bin` and symlinks into `~/.local/bin` (already on PATH via `home.sessionPath`), so no `sudo` is needed.
Then, from inside a repo that has an `origin` remote, register the gate and the user-level `/no-mistakes` skill:

```bash
no-mistakes init
```

Push through the gate with `git push no-mistakes <branch>`; remove it from a repo with `no-mistakes eject`.
Prerequisites `git` and the `gh` CLI are both in the Nix config; gate artifacts live under `~/.no-mistakes/` and the repo already git-ignores `.no-mistakes/`.

## gnhf (Good Night, Have Fun)

[gnhf](https://github.com/kunchenguid/gnhf) is an autonomous agent orchestrator: it repeatedly calls a coding agent until a natural-language stop condition is met, committing one small, documented change per iteration.
It is a global npm CLI plus a user-level `gnhf` agent skill, installed outside Nix, so it does not restore on a fresh machine.

Reinstall after bootstrap:

```bash
npm install -g gnhf
ln -sfn "$(npm root -g)/gnhf/skills/gnhf" ~/.claude/skills/gnhf
```

The first line installs the CLI; the second registers the `gnhf` skill for Claude Code at user level.
Start a run with `gnhf "<objective>"`, and always bound it with `--max-iterations`, `--max-tokens`, or `--stop-when` since it drives the agent unattended.
Run metadata lives in `.gnhf/runs/` (git-ignored) and config in `~/.gnhf/config.yml`.

## firstmate (multi-agent orchestrator)

[firstmate](https://github.com/kunchenguid/firstmate) is a multi-agent orchestrator: one "first mate" agent supervises a crew of autonomous agents, each in its own [treehouse](https://github.com/kunchenguid/treehouse) worktree, and hands back PRs, approved local merges, or investigation reports.
It is a standalone repo you operate *from* (not an installed package), so it is not managed by Nix.

Clone it once, then launch your agent harness inside it:

```bash
git clone https://github.com/kunchenguid/firstmate ~/github/firstmate
cd ~/github/firstmate && cc
```

Then talk to it in natural language; it clones each target project under `projects/` and spawns crewmates in tmux.
Prerequisites `gh` (authenticated), `git`, and `tmux` are all in the Nix config; it ships work through per-project modes including the `no-mistakes` gate set up above.

## Why this setup looks like this

I wanted a setup that was:

- reproducible on a new Mac
- structured enough to maintain
- pragmatic about macOS
- publishable without oversharing the rest of my workflow

That is why this repo focuses on the reusable core.

## Related

- Long-form write-up: [blog post](https://open.substack.com/pub/kunchenguid/p/how-i-built-a-reproducible-mac-setup?utm_campaign=post-expanded-share&utm_medium=web)
- GitHub repo: <https://github.com/kunchenguid/dotfiles-mac-nix>
