;;; pre-init.el --- minimal-emacs.d hook, loaded before init -*- no-byte-compile: t; lexical-binding: t; -*-

;; Empty on purpose. straight.el used to be bootstrapped here, only for two
;; GitHub packages; they now come from use-package's built-in :vc (Emacs 30),
;; so straight no longer builds its own magit/compat/use-package copies that
;; shadowed the ELPA ones.
