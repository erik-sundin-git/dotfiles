(setq doom-theme 'doom-tokyo-night)
(setq display-line-numbers-type t)
(setq doom-font "Fira Code-14")

(load! "agenda.el")
;;(load! "exwm.el")

(setq org-directory "~/notes/"
      org-roam-directory (file-truename (file-name-concat org-directory "roam/"))
      org-attach-id-dir (expand-file-name "assets" org-roam-directory)
     org-roam-dailies-directory "journals/"
      org-roam-file-exclude-regexp "\\.git/.*\\|logseq/.*$")

(add-hook 'logseq-org-roam-updated-hook #'org-roam-db-sync)

(after! org(org-bullets-mode))

(setq ispell-dictionary "svenska")

;; Regular
(setq org-roam-capture-templates
   '(("d" "default" plain
      "%?"
      ;; Accomodates for the fact that Logseq uses the "pages" directory
      :target (file+head "pages/${slug}.org" "#+title: ${title}\n")
      :unnarrowed t)

     ;; Cards
     ("c" "Create a card")

     ("cd" "Database management" plain
      (file "~/notes/roam/capture-templates/card.org")
      :target (file+head "database-management/cards/${slug}.org"
                         "#+title: ${title}\n")
      :unnarrowed t)

     ;; regular entries
     ("s" "Select other category")

     ("sd" "Database management" plain
      "%?"
      :target (file+head "database-management/${slug}.org" "#+title: ${title}\n")
      :unnarrowed t))

   ;; Dailies
   org-roam-dailies-capture-templates
   '(
     ("d" "daily" plain
      "\n* Entry %<%H:%M>\n%?"
      :target (file+head "daily/%<%Y-%m-%d>.org"
                         "#+title: Daily Journal %<%Y-%m-%d>\n"))
     ("s" "Sleep stuff")
     ("ss" "sleep" plain
      "%?\n* Sleep\n** score\n** notes\n"
      :target (file+head "sleep/%<%Y-%m-%d>.org"
                         "#+title: Sleep Log %<%Y-%m-%d>\n"))

     ("sr" "Kvällsrutin" plain
      (file "~/notes/roam/capture-templates/sovrutin.org")
      :target (file+head "Kvällsrutin/%<%Y-%m-%d>.org"
                       "#+title: Kvällsrutin %<%Y-%m-%d>\n"))

     ("t" "tetra" table-line
      "|%T|%^{typ:|vape}|%^{längd|}|%^{antal|1}|"
      :target (file+head "tetra/%<%Y-%m-%d>.org"
                         "#+title: Daily t Journal %<%Y-%m-%d>\n")
      :immediate-finish)))

(after! org
  (setq org-tag-alist '(
                        ("@skola" . ?s)
                        ("@hem" . ?h)
                        ("@ekonomi" . ?e)
                        ("@system" . ?S))))

(after! org
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

(after! org
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

(after! evil
;; Evil
(map! :i "C-ö" 'evil-normal-state)
(map! "C-ä" 'evil-end-of-line)
(map! "M-o" 'other-window)

(setq evil-vsplit-window-right 1))

(set-eshell-alias! "hms" "home-manager switch --flake $HOME/nixos/")

;; coding system
(prefer-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
