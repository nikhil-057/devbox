{ config, pkgs, ... }: {

  # Home Manager needs a bit of information about you and the paths it should manage.
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  #
  # It is sometimes useful to fine-tune packages, for example, by applying
  # overrides. You can do that directly here, just don't forget the
  # parentheses. Maybe you want to install Nerd Fonts with a limited number of fonts?
  #   (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
  #
  # You can also create simple shell scripts directly inside your
  # configuration. For example, this adds a command 'my-hello' to your environment:
  #   (pkgs.writeShellScriptBin "my-hello" ''
  #     echo "Hello, ${config.home.username}!"
  #   '')
  home.packages = [
    pkgs.glibc
    pkgs.gnused
    pkgs.npins
    pkgs.tmux
    pkgs.neovim
    pkgs.zsh
    pkgs.oh-my-zsh
    pkgs.gcc
    pkgs.gnumake
    pkgs.cmake
    pkgs.unzip
    pkgs.zip
    pkgs.xauth
    pkgs.ripgrep
    pkgs.fd
    pkgs.jq
    pkgs.procps
    pkgs.docker-client
    pkgs.curlFull.dev
    pkgs.openssl.dev
    pkgs.openssh
    pkgs.pkg-config
    pkgs.neo4j
    pkgs.awscli2
    pkgs.groff
    pkgs.wget
    pkgs.mysql84
    pkgs.coreutils
    pkgs.tree-sitter
    pkgs.nodejs_22
    pkgs.jdk17
    pkgs.python311
    pkgs.poetry
    pkgs.uv
    pkgs.sonarlint-ls
    pkgs.vimPlugins.sonarlint-nvim
    pkgs.basedpyright
    pkgs.ruff
    pkgs.black
    pkgs.isort
    pkgs.taplo
    pkgs.typescript
    pkgs.typescript-language-server
    pkgs.opencode
    pkgs.gh
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  # Building this configuration will create a copy of 'dotfiles/<filename>' in
  # the Nix store. Activating the configuration will then make '~/<filename>' a
  # symlink to the Nix store copy.
  #
  # You can also set the file content immediately.
  #   ".gradle/gradle.properties".text = ''
  #     org.gradle.console=verbose
  #     org.gradle.daemon.idletimeout=3600000
  #   '';
  home.file = {
    ".config/nvim/init.lua".source = dotfiles/init.lua;
    ".tmux.conf".source = dotfiles/tmux.conf;
    ".profile".source = dotfiles/profile;
    ".zshrc".source = dotfiles/zshrc;
    # https://man.archlinux.org/man/containers-policy.json.5.en
    ".config/containers/policy.json".source = dotfiles/containers-policy.json;
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/nikhil/etc/profile.d/hm-session-vars.sh
  #

  home.sessionVariables = {
    # OpenSSL build flags
    PKG_CONFIG_PATH = "${pkgs.openssl.dev}/lib/pkgconfig";
    CFLAGS = "-I${pkgs.openssl.dev}/include";
    LDFLAGS = "-L${pkgs.openssl.out}/lib";
    LD_LIBRARY_PATH = "${pkgs.gcc.cc.lib}/lib";
    # SonarLint plugins path
    SONARLINT_PLUGINS = "${pkgs.sonarlint-ls}/share/plugins";
  };

  # aws config
  home.file.".profile.d/aws-config.sh".text = ''
    if [ -f "$HOME/.aws/credentials.json" ]; then
      CREDS=$(cat "$HOME/.aws/credentials.json")
      export AWS_ACCESS_KEY_ID=$(echo "$CREDS" | jq -r ".AccessKeyId")
      export AWS_SECRET_ACCESS_KEY=$(echo "$CREDS" | jq -r ".SecretAccessKey")
      export AWS_SESSION_TOKEN=$(echo "$CREDS" | jq -r ".SessionToken")
      export AWS_DEFAULT_REGION="us-west-2";
    fi
  '';

  # git config
  programs.git = {
    enable = true;
    includes = [{
      contents = {
        user.name="nikhil";
        user.email="<>";
        core.editor = "nvim";
        merge.tool = "nvim";
        mergetool.nvim.cmd = "nvim -d $LOCAL $BASE $REMOTE $MERGED";
        safe.directory = [
          "*"
        ];
      };
    }];
  };

  # ssh config
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "*" = {
        HashKnownHosts = true;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        ControlMaster = "auto";
        ControlPersist = "10m";
      };
      "git.blackhawknetwork.com" = {
        UserKnownHostsFile = "/dev/null";
        StrictHostKeyChecking = "no";
      };
    };
  };

  # poetry config
  xdg.configFile."pypoetry/config.toml".text = ''
    [virtualenvs]
    in-project = true
  '';

  # opencode config
  xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    model = "bedrock/anthropic.claude-sonnet-4-5-20250929-v1:0";
  };

  xdg.configFile."opencode/tui.json".text = builtins.toJSON {
    "$schema" = "https://opencode.ai/tui.json";
    split = false;
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
