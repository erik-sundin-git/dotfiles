(setq doom-theme 'doom-tokyo-night)
(setq display-line-numbers-type t)

(setq org-directory "/mnt/storagebox/org")
(setq org-roam-directory "/mnt/storagebox/org-roam")

(load! "agenda.el")
(load! "exwm.el")

(defun my-current-time ()
  "Return the current time in hh:mm format."
  (format-time-string "%H:%M"))

(setq org-roam-dailies-capture-templates
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
         (file "/mnt/storagebox/org-roam/capture-templates/sovrutin.org")
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
            (file+olp+datetree "/mnt/storagebox/org-roam/20240912165402-agenda.org")
            "* %?\nSCHEDULED: %^{Time}t\n")

          ("t" "Todo" entry (file+headline "/mnt/storagebox/org-roam/20240912165541-task_inbox.org" "Tasks")
           "* TODO %?\n")))

  ;; Corrected org-agenda-custom-commands
  (setq org-agenda-custom-commands
        '(("s" "School agenda" agenda ""
           ((org-agenda-span 'day)
            (org-agenda-overriding-header "School")
            (org-agenda-tag-filter-preset
             '("+skola"))))
          ("i" "Inbox" alltodo " -{.*}"
           ((org-agenda-files
             '("/mnt/storagebox/org/Inbox.org"))))
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
