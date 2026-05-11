{ ... }:
{
  flake.modules.homeManager.starship =
    { config, ... }:
    let
      c = config.theme;
    in
    {
      programs.starship = {
        enable = true;
        settings = {
          format = "$username$hostname$directory$git_branch$git_state$git_status$cmd_duration$line_break$python$character";

          directory.style = "fg:${c.blue}";

          character = {
            success_symbol = "[❯](fg:${c.magenta})";
            error_symbol = "[❯](fg:${c.red})";
            vimcmd_symbol = "[❮](fg:${c.green})";
          };

          git_branch = {
            format = "[$branch]($style)";
            style = "fg:${c.brightBlack}";
          };

          git_status = {
            format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](fg:${c.brightMagenta}) ($ahead_behind$stashed)]($style)";
            style = "fg:${c.cyan}";
            # zero-width space (U+200B) — suppresses the default status symbols
            conflicted = "​";
            untracked = "​";
            modified = "​";
            staged = "​";
            renamed = "​";
            deleted = "​";
            stashed = "≡";
          };

          git_state = {
            format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
            style = "fg:${c.brightBlack}";
          };

          cmd_duration = {
            format = "[$duration]($style) ";
            style = "fg:${c.yellow}";
          };

          python = {
            format = "[$virtualenv]($style) ";
            style = "fg:${c.brightBlack}";
          };
        };
      };
    };
}
