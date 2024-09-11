;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;(setq doom-font (font-spec :family "Fira Code" :size 24))

;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-tokyo-night)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "/mnt/storagebox/org")
(setq org-roam-directory "/mnt/storagebox/org-roam")




(defun vulpea-project-p ()
  "Return non-nil if current buffer has any todo entry.

TODO entries marked as done are ignored, meaning the this
function returns nil if current buffer contains only completed
tasks."
  (seq-find                                 ; (3)
   (lambda (type)
     (eq type 'todo))
   (org-element-map                         ; (2)
       (org-element-parse-buffer 'headline) ; (1)
       'headline
     (lambda (h)
       (org-element-property :todo-type h)))))

(defun vulpea-project-update-tag ()
    "Update PROJECT tag in the current buffer."
    (when (and (not (active-minibuffer-window))
               (vulpea-buffer-p))
      (save-excursion
        (goto-char (point-min))
        (let* ((tags (vulpea-buffer-tags-get))
               (original-tags tags))
          (if (vulpea-project-p)
              (setq tags (cons "project" tags))
            (setq tags (remove "project" tags)))

          ;; cleanup duplicates
          (setq tags (seq-uniq tags))

          ;; update tags if changed
          (when (or (seq-difference tags original-tags)
                    (seq-difference original-tags tags))
            (apply #'vulpea-buffer-tags-set tags))))))

(defun vulpea-buffer-p ()
  "Return non-nil if the currently visited buffer is a note."
  (and buffer-file-name
       (string-prefix-p
        (expand-file-name (file-name-as-directory org-roam-directory))
        (file-name-directory buffer-file-name))))

(defun vulpea-project-files ()
    "Return a list of note files containing 'project' tag." ;
    (seq-uniq
     (seq-map
      #'car
      (org-roam-db-query
       [:select [nodes:file]
        :from tags
        :left-join nodes
        :on (= tags:node-id nodes:id)
        :where (like tag (quote "%\"project\"%"))]))))


(add-hook 'find-file-hook #'vulpea-project-update-tag)
(add-hook 'before-save-hook #'vulpea-project-update-tag)

(advice-add 'org-agenda :before #'vulpea-agenda-files-update)
(advice-add 'org-todo-list :before #'vulpea-agenda-files-update)

;; Function to get current time in hh:mm

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


  (setq org-capture-templates
        ;; Add entry to inbox
        '(("a" "Agenda / Calendar")
           ("aa" "Add an item to the agenda" entry
            (file+olp+datetree "/mnt/storagebox/org/agenda.org")
            "* %?\nSCHEDULED: %^{Time}t\n")

          ("t" "Todo" entry (file+headline "/mnt/storagebox/org/Inbox.org" "Tasks")
           "* TODO %?\n")))
(setq org-agenda-prefix-format
      '((agenda . " %i %(vulpea-agenda-category 12)%?-12t% s")
        (todo . " %i %(vulpea-agenda-category 12) ")
        (tags . " %i %(vulpea-agenda-category 12) ")
        (search . " %i %(vulpea-agenda-category 12) ")))

(defun vulpea-agenda-category (&optional len)
  "Get category of item at point for agenda.

Category is defined by one of the following items:

- CATEGORY property
- TITLE keyword
- TITLE property
- filename without directory and extension

When LEN is a number, resulting string is padded right with
spaces and then truncated with ... on the right if result is
longer than LEN.

Usage example:

  (setq org-agenda-prefix-format
        '((agenda . \" %(vulpea-agenda-category) %?-12t %12s\")))

Refer to `org-agenda-prefix-format' for more information."
  (let* ((file-name (when buffer-file-name
                      (file-name-sans-extension
                       (file-name-nondirectory buffer-file-name))))
         (title (vulpea-buffer-prop-get "title"))
         (category (org-get-category))
         (result
          (or (if (and
                   title
                   (string-equal category file-name))
                  title
                category)
              "")))
    (if (numberp len)
        (s-truncate len (s-pad-right len " " result))
      result))))

 '(org-agenda-custom-commands
   '(("s" "School agenda" agenda ""
      ((org-agenda-span 'day)
       (org-agenda-overriding-header "School")
       (org-agenda-tag-filter-preset
        '("+skola"))))
     ("i" "Inbox" alltodo " -{.*}"
      ((org-agenda-files
        '("/mnt/storagebox/org/Inbox.org"))))
     ("d" "Today’s Schedule"
      ((agenda ""
               ((org-agenda-span 'day)
                (org-agenda-start-on-weekday 0)
                (org-agenda-todo-ignore-scheduled 'n)
                (org-agenda-overriding-header "Today's Schedule:")
                (org-agenda-prefix-format
                 '((agenda . "  %i %-30:c%?-20t% s")))))

       (alltodo ""
                ((org-agenda-todo-ignore-scheduled t)
                 (org-agenda-overriding-header "Unscheduled")
                 (org-agenda-overriding-header ""))))
      nil)
     ("u" "Untagged Tasks"
      ((tags-todo "-{.*}"
                  ((org-agenda-overriding-header "Untagged Tasks:")
                   (org-agenda-prefix-format
                    '((tags . "  %i %-30:c %s"))))))
      nil)
     ("n" "Tasks Without @scheduled Tag"
      ((tags-todo "-scheduled"
                  ((org-agenda-overriding-header "Tasks Without @scheduled Tag:")
                   (org-agenda-prefix-format
                    '((tags . "  %i %-30:c %s"))))))
      nil)))


;; lilypond
(use-package lilypond-mode
  :ensure t
  :mode ("\\.ly\\'" . LilyPond-mode))

;; Evil
(map! :i "C-c C-c" 'evil-normal-state)
