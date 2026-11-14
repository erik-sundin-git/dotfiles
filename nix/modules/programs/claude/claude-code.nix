{ ... }:
{
  # Claude Code from HM's programs.claude-code, for the MCP server and the LSP
  # only: HM puts both in a --plugin-dir wrapper around `claude`, so they work
  # in every directory. `settings` stays unset on purpose: HM would turn
  # ~/.claude/settings.json into a read-only store link, and claude writes to
  # it (/config, model, auto mode). This repo's permissions, hooks and
  # commands live in its own .claude/. Added to every profile (profiles.nix).
  flake.modules.homeManager.claudeCode =
    {
      lib,
      pkgs,
      pkgsUnstable,
      ...
    }:
    {
      programs.claude-code = {
        enable = true;
        package = pkgsUnstable.claude-code;
        # nixpkgs packages, NixOS/HM options and their versions, live
        mcpServers.nixos = {
          type = "stdio";
          command = lib.getExe pkgs.mcp-nixos;
        };
        # Diagnostics and go-to-definition for .nix files
        lspServers.nix = {
          command = lib.getExe pkgs.nixd;
          extensionToLanguage.".nix" = "nix";
        };
      };
    };
}
