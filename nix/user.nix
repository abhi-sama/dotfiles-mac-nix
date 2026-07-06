{ config, pkgs, inputs, ... }:

let
  dotfilesDir = "${config.home.homeDirectory}/github/dotfiles-mac-nix";
in
{
  home.username = "abhi-sama";
  home.homeDirectory = "/Users/abhi-sama";
  home.stateVersion = "23.11";
  home.language.base = "en_US.UTF-8";

  home.packages = with pkgs; [
    git
    gh
    inputs.treehouse.packages.${pkgs.system}.default  # treehouse: reusable git worktree pool for agents
    neovim
    tree-sitter
    curl
    wget
    jq
    fd
    fastfetch
    ripgrep
    killall
    lazygit
    tree
    tmux
    bun
    rustup
    zip
    unzip
    nerd-fonts.hack
    roboto
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    font-awesome
  ];

  fonts.fontconfig.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Put user-local binaries (e.g. Claude Code's native installer at
  # ~/.local/bin/claude) on PATH for login shells.
  home.sessionPath = [
    "$HOME/.local/bin"
  ];

  programs.git = {
    enable = true;
    lfs.enable = true;
    signing.format = null;
    settings = {
      user = {
        name = "abhi-sama";
        email = "abhi121197@gmail.com";
      };
      core.editor = "nvim";
      color.ui = true;
      push.autoSetupRemote = true;
      pull.rebase = true;
      rebase.updateRefs = true;
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      command_timeout = 1000;
      add_newline = false;
      format = "$username$hostname$directory$git_branch$git_state$git_status$cmd_duration$line_break$character";

      directory.style = "blue";

      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](green)";
      };

      git_branch = {
        format = "[$branch]($style)";
        style = "bright-black";
      };

      git_status = {
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style)";
        style = "cyan";
        stashed = "≡";
      };

      git_state = {
        format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
        style = "bright-black";
      };

      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };

      python = {
        format = "[$virtualenv]($style) ";
        style = "bright-black";
      };
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ".." = "cd ..";
      cc = "claude --dangerously-skip-permissions";
      m = "git switch main";
      mst = "git switch master";
      pull = "git pull";
      push = "git push";
      pushf = "git push --force";
      add = "git add .";
      amend = "git commit --amend";
      reset = "git reset --soft HEAD^";
      rebasem = "git rebase -i main";
      rebasemst = "git rebase -i master";
      rebuild = "sudo /run/current-system/sw/bin/darwin-rebuild switch --flake ~/github/dotfiles-mac-nix#mac";
    };
    initContent = ''
      # Put Homebrew (Apple Silicon) on PATH so `brew` works in the shell.
      eval "$(/opt/homebrew/bin/brew shellenv)"

      bindkey '^f' autosuggest-accept

      # ── Shift+Arrow text selection on the command line ─────────────
      # Highlight text like a GUI editor; typing or Backspace over a
      # highlighted range replaces/deletes it, and Alt/Esc-w copies it.
      # NOTE: the terminal must actually emit the modified-arrow key
      # codes below. Terminal.app needs custom key mappings for this
      # (see README); WezTerm/iTerm2 send them out of the box.
      _sel() { ((REGION_ACTIVE)) || zle set-mark-command; zle "$1" }
      _ss_left()   { _sel backward-char }
      _ss_right()  { _sel forward-char }
      _ss_wleft()  { _sel backward-word }
      _ss_wright() { _sel forward-word }
      _ss_home()   { _sel beginning-of-line }
      _ss_end()    { _sel end-of-line }
      _ss_self_insert() { ((REGION_ACTIVE)) && zle kill-region; zle .self-insert }
      _ss_backspace()   { if ((REGION_ACTIVE)); then zle kill-region; else zle .backward-delete-char; fi }
      _ss_copy() {
        (( REGION_ACTIVE )) || return
        local a=$MARK b=$CURSOR
        (( a > b )) && { a=$CURSOR; b=$MARK; }
        print -rn -- "''${BUFFER[a+1,b]}" | pbcopy
      }
      for w in _ss_left _ss_right _ss_wleft _ss_wright _ss_home _ss_end _ss_copy; do zle -N $w; done
      zle -N self-insert _ss_self_insert
      zle -N backward-delete-char _ss_backspace
      bindkey '^[[1;2D' _ss_left     # Shift+Left
      bindkey '^[[1;2C' _ss_right    # Shift+Right
      bindkey '^[[1;6D' _ss_wleft    # Shift+Ctrl+Left  (by word)
      bindkey '^[[1;6C' _ss_wright   # Shift+Ctrl+Right (by word)
      bindkey '^[[1;2H' _ss_home     # Shift+Home
      bindkey '^[[1;2F' _ss_end      # Shift+End
      bindkey '^[w'     _ss_copy     # Alt/Esc-w: copy selection to clipboard

      # Load nvm (installed by setup/mac.sh) so node/npm/npx are available.
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    '';
  };

  home.file = {
    ".config/wezterm".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/files/.config/wezterm";
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/files/.config/nvim";

    # Global agent instructions: ~/AGENTS.md is the source of truth, and
    # ~/.claude/CLAUDE.md points at it so Claude Code loads it as user memory.
    "AGENTS.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/files/AGENTS.md";
    ".claude/CLAUDE.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/files/AGENTS.md";
    "OPINIONS.md".source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/files/OPINIONS.md";
  };
}
