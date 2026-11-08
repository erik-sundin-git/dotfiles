{
  lib,
  python3Packages,
  coreutils,
  cryptsetup,
  disko,
  git,
  git-crypt,
  iproute2,
  lvm2,
  mdadm,
  nixfmt,
  openssh,
  ssh-to-age,
  util-linux,
}:

# The live ISO's installer TUI (see CLAUDE.md, "Installing a host"). The ISO
# overrides `disko` with the flake input's, matching the nixos.diskLayout
# module; `nix run .#install-host -- --dry-run` works anywhere.
python3Packages.buildPythonApplication {
  pname = "install-host";
  version = "2.0";
  pyproject = true;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./pyproject.toml
      ./install_host
      ./tests
    ];
  };

  build-system = [ python3Packages.setuptools ];
  dependencies = [ python3Packages.urwid ];

  nativeCheckInputs = [
    python3Packages.pytestCheckHook
    nixfmt
    git # tests/test_repo.py runs Changes against a scratch repo
  ];
  pythonImportsCheck = [ "install_host" ];

  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [
      coreutils
      cryptsetup
      disko
      git
      git-crypt
      iproute2
      lvm2
      mdadm
      openssh
      ssh-to-age
      util-linux
    ])
    # nix, nixos-install, nixos-enter, nixos-generate-config and nmtui must be
    # the running system's own
    "--suffix"
    "PATH"
    ":"
    "/run/current-system/sw/bin"
    # The sudo re-exec needs a path; the wrapper leaves a bare name in argv[0]
    "--set"
    "INSTALL_HOST_BIN"
    "${placeholder "out"}/bin/install-host"
  ];

  meta.mainProgram = "install-host";
}
