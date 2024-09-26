(setq doom-theme 'doom-tokyo-night)
(setq display-line-numbers-type t)
(setq doom-font "Fira Code-14")


(setq org-directory "~/notes/"
      org-roam-directory (file-truename (file-name-concat org-directory "roam/"))
      org-attach-id-dir (expand-file-name "assets" org-roam-directory)
      org-roam-dailies-directory "journals/"
      org-roam-file-exclude-regexp "\\.git/.*\\|logseq/.*$")


(load! "agenda.el")
;;(load! "exwm.el")

(defun my-current-time ()
  "Return the current time in hh:mm format."
  (format-time-string "%H:%M"))



(setq org-roam-capture-templates
   '(("d" "default" plain
      "%?"
      ;; Accomodates for the fact that Logseq uses the "pages" directory
      :target (file+head "pages/${slug}.org" "#+title: ${title}\n")
      :unnarrowed t))
   org-roam-dailies-capture-templates
      '(("d" "daily" plain
        "\n* Entry %<%H:%M>\n%?"
        :target (file+head "daily/%<%Y-%m-%d>.org"
                            "#+title: Daily Journal %<%Y-%m-%d>\n")
         :unnarrowed t)
        ("s" "Sleep stuff")
        ("ss" "sleep" plain
         "%?\n* Sleep\n** score\n** notes\n"
         :target (file+head "sleep/%<%Y-%m-%d>.org"
                            "#+title: Sleep Log %<%Y-%m-%d>\n")
         :unnarrowed t)

         ("sr" "Kvällsrutin" plain
         (file "~/notes/roam/capture-templates/sovrutin.org")
         :target (file+head "Kvällsrutin/%<%Y-%m-%d>.org"
                            "#+title: Kvällsrutin %<%Y-%m-%d>\n")
         :unnarrowed t)

        ("t" "tetra" plain
         "%?\n* Tetra\n
| typ   | antal |   tid | längd (s) |
|-------+-------+-------+-----------|
|       |       |       |           |
|       |       |       |           |
|       |       |       |           |
|       |       |       |           |
|       |       |       |           |
|       |       |       |           |
|       |       |       |           |
|       |       |       |           |
|       |       |       |           |
|       |       |       |           |
|       |       |       |           |
|-------+-------+-------+-----------|
| Total |       |       |           |
#+TBLFM: @13$2=vsum(@2$2..@12$2)
"
         :target (file+head "tetra/%<%Y-%m-%d>.org"
                            "#+title: T %<%Y-%m-%d>\n")
         :unnarrowed t)))


(add-hook 'logseq-org-roam-updated-hook #'org-roam-db-sync)

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

(after! org
  (setq org-tag-alist '(
                        ("@skola" . ?s)
                        ("@hem" . ?h)
                        ("@ekonomi" . ?e)
                        ("@system" . ?S)))
  (setq org-capture-templates
        ;; Add entry to inbox
        '(("a" "Agenda / Calendar")
          ("aa" "Add an item to the agenda" entry
           (file+olp+datetree "~/notes/roam/20240912165402-agenda.org")
           "* %?\nSCHEDULED: %^{Time}t\n")

          ("t" "Todo")
          ("tt" "Todo" entry (file+headline "~/notes/roam/20240912165541-task_inbox.org" "Tasks")
           "* TODO %?\n")

          ("ts" "System Configuration" entry
           (file+headline "~/notes/roam/20240822143307-todo_system.org" "Inbox")
           "* TODO %?\n")

          ("l" "Transaktion - ledger")
          ("lm" "Transaction" plain (file "~/ledger/default.ledger")
           "%(org-read-date) Matvaror\n    Tillgångar:Swedbank:Privatkonto\n    Utgifter:Mat:Matvaror  SEK %^{Amount}"
           :empty-lines 1))))




  ;; Corrected org-agenda-custom-commands
  (setq org-agenda-start-day "")
  (setq org-agenda-custom-commands
        '(("s" "School agenda" agenda ""
           ((org-agenda-span 'day)
            (org-agenda-overriding-header "School")
            (org-agenda-tag-filter-preset
             '("+skola"))))
          ("c" "Today's Schedule and Upcoming Deadlines"
 ((agenda ""
          ((org-agenda-span 'day)                  ;; Today's scheduled tasks
           (org-deadline-warning-days 0)           ;; Only show today's deadlines
           (org-agenda-overriding-header "Today's Schedule:")))
  (agenda ""
          ((org-agenda-span 14)                    ;; Next 14 days view
           (org-deadline-warning-days 0)          ;; Show deadlines within 14 days
           (org-agenda-time-grid nil)              ;; Don't show time grid for this section
           (org-agenda-entry-types '(:deadline))   ;; Only show deadlines
           (org-agenda-overriding-header "Upcoming Deadlines (14 Days):"))))))))

;; lilypond
(use-package lilypond-mode
  :ensure t
  :mode ("\\.ly\\'" . LilyPond-mode))


;; Evil
(map! :i "C-ö" 'evil-normal-state)
(map! "C-ä" 'evil-end-of-line)
(map! "M-o" 'other-window)

(setq evil-vsplit-window-right 1)

(set-eshell-alias! "hms" "home-manager switch --flake $HOME/nixos/")


;; coding system
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
