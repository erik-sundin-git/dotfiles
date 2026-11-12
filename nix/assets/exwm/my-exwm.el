;;; my-exwm.el --- EXWM workspaces, keys, actions and menus -*- no-byte-compile: t; lexical-binding: t; -*-

;; The binds come from my-exwm-nix.el, translated from sway's bindings by
;; programs/exwm/keybindings.nix as (KEY ACTION . ARGS).  This file maps each
;; ACTION to a command (`my-exwm--actions') and builds the menus (sway's
;; modes).  Reloaded by the `reload' action, so everything here must be safe
;; to evaluate twice.

;;; Code:

(require 'exwm)
(require 'exwm-input)
(require 'exwm-layout)
(require 'exwm-floating)
(require 'exwm-manage)
(require 'exwm-workspace)
(require 'exwm-randr)
(require 'windmove)
(require 'xdg)
(require 'seq)
(require 'subr-x)

;; From my-exwm-nix.el
(defvar my-exwm-nix-workspace-names)
(defvar my-exwm-nix-window-rules)
(defvar my-exwm-nix-global-keys)
(defvar my-exwm-nix-modes)

(declare-function my-exwm-load-files "init")
(defvar vterm-shell)
(declare-function vterm "vterm")


;;;; Workspaces

(defun my-exwm-workspace-name (index)
  "Name of workspace INDEX: 1..10, then sway's named workspaces."
  (or (nth index my-exwm-nix-workspace-names)
      (number-to-string (1+ index))))

(setopt exwm-workspace-number (length my-exwm-nix-workspace-names)
        exwm-workspace-index-map #'my-exwm-workspace-name)

(defvar my-exwm--previous-workspace nil
  "Index of the workspace before the last `my-exwm-workspace' switch.")

(defun my-exwm-workspace (index)
  "Switch to workspace INDEX; on the current one, go back to the previous.
Like sway's workspace_auto_back_and_forth."
  (let ((current (exwm-workspace--position exwm-workspace--current)))
    (when (and (= index current) my-exwm--previous-workspace)
      (setq index my-exwm--previous-workspace))
    (unless (= index current)
      (setq my-exwm--previous-workspace current)
      (exwm-workspace-switch-create index))))

(defun my-exwm-move-to-workspace (index)
  "Move the selected window's buffer to workspace INDEX.
X windows move with EXWM; an Emacs buffer is shown in that workspace's
selected window and replaced here."
  (if (derived-mode-p 'exwm-mode)
      (exwm-workspace-move-window index)
    (let ((buffer (current-buffer))
          (frame (or (nth index exwm-workspace--list)
                     (progn (exwm-workspace-switch-create index)
                            (nth index exwm-workspace--list)))))
      (switch-to-prev-buffer nil t)
      (set-window-buffer (frame-selected-window frame) buffer))))

(defun my-exwm--rename-buffer ()
  "Name X window buffers after their class and title."
  (exwm-workspace-rename-buffer
   (if (and exwm-title (not (string-empty-p exwm-title))
            (not (equal exwm-title exwm-class-name)))
       (format "%s: %s" exwm-class-name exwm-title)
     (or exwm-class-name "X window"))))

(add-hook 'exwm-update-class-hook #'my-exwm--rename-buffer)
(add-hook 'exwm-update-title-hook #'my-exwm--rename-buffer)


;;;; Window rules

(defun my-exwm--rule-match (class title)
  "Non-nil if the X window matches CLASS and TITLE (regexps, TITLE optional).
CLASS is tried against both the class and the instance name, since some
apps (e.g. ones started with --class) only set the instance."
  (let ((case-fold-search t))
    (and (or (and exwm-class-name (string-match-p class exwm-class-name))
             (and exwm-instance-name (string-match-p class exwm-instance-name)))
         (or (null title)
             (and exwm-title (string-match-p title exwm-title))))))

(setopt exwm-manage-configurations
        (mapcar (lambda (rule)
                  (cons `(my-exwm--rule-match ,(nth 0 rule) ,(nth 1 rule))
                        (nthcdr 2 rule)))
                my-exwm-nix-window-rules))


;;;; Actions (the ACTION symbols in my-exwm-nix.el)

(defun my-exwm-exec (command)
  "Run shell COMMAND detached, so it isn't an Emacs subprocess at logout."
  (let ((default-directory "~/"))
    (call-process-shell-command command nil 0)))

(defun my-exwm--spawn (program &rest args)
  "Run PROGRAM with ARGS detached, without a shell."
  (let ((default-directory "~/"))
    (apply #'call-process program nil 0 nil args)))

(defun my-exwm--vterm (&optional name command directory)
  "Open a new vterm buffer in the selected window.
NAME is the buffer name, COMMAND a shell command to run instead of the
shell, DIRECTORY where it starts.  Over an X window it starts in ~."
  (unless (require 'vterm nil t)
    (user-error "vterm isn't installed"))
  (let ((default-directory (or directory
                               (if (derived-mode-p 'exwm-mode) "~/" default-directory)))
        (vterm-shell (or command vterm-shell)))
    (vterm (or name t))))

(defun my-exwm-vterm ()
  "Open a new terminal (sway's terminal bind)."
  (my-exwm--vterm))

(defun my-exwm-kill ()
  "Close the selected window, like sway's kill.
An X window is closed (and its Emacs window deleted unless it's the only
one); for an Emacs buffer the window goes, or the buffer when it's alone."
  (if (derived-mode-p 'exwm-mode)
      (let ((window (selected-window)))
        (kill-buffer)
        (when (and (window-live-p window) (not (one-window-p)))
          (delete-window window)))
    (if (one-window-p)
        (kill-current-buffer)
      (delete-window))))

(defun my-exwm-focus (direction)
  "Select the window in DIRECTION."
  (windmove-do-window-select direction))

(defun my-exwm-swap (direction)
  "Swap the selected window's buffer with the one in DIRECTION."
  (windmove-swap-states-in-direction direction))

(defun my-exwm-split (side)
  "Split the selected window, the new one on SIDE (right or below)."
  (split-window nil nil side))

(defun my-exwm-focus-toggle ()
  "Move focus between floating and tiled windows, like sway's mode_toggle."
  (if (and (derived-mode-p 'exwm-mode) exwm--floating-frame)
      (select-frame-set-input-focus exwm-workspace--current)
    (if-let* ((floating (seq-find
                         (lambda (buffer)
                           (with-current-buffer buffer
                             (and exwm--floating-frame
                                  (eq exwm--frame exwm-workspace--current))))
                         (mapcar #'cdr exwm--id-buffer-alist))))
        (exwm-workspace-switch-to-buffer floating)
      (message "No floating window on this workspace"))))

(defun my-exwm-fullscreen ()
  "Toggle fullscreen: X windows go fullscreen, Emacs windows take the frame.
The Emacs variant saves the window layout and restores it on the next press."
  (if (derived-mode-p 'exwm-mode)
      (exwm-layout-toggle-fullscreen)
    (if-let* ((saved (frame-parameter nil 'my-exwm-monocle)))
        (progn
          (set-frame-parameter nil 'my-exwm-monocle nil)
          (set-window-configuration saved))
      (unless (one-window-p)
        (set-frame-parameter nil 'my-exwm-monocle (current-window-configuration))
        (delete-other-windows)))))

(defun my-exwm-floating ()
  "Toggle floating for the selected X window."
  (unless (derived-mode-p 'exwm-mode)
    (user-error "Only X windows can float"))
  (exwm-floating-toggle-floating))

(defvar my-exwm--scratchpad nil
  "X window buffers sent to the scratchpad, next to show first.")

(defun my-exwm-scratchpad-hide ()
  "Send the selected X window to the scratchpad (floating, hidden)."
  (unless (derived-mode-p 'exwm-mode)
    (user-error "Only X windows go to the scratchpad"))
  (let ((buffer (current-buffer)))
    (setq my-exwm--scratchpad (cons buffer (delq buffer my-exwm--scratchpad)))
    (if exwm--floating-frame
        (exwm-floating-hide)
      ;; A newly floated window is shown by the layout refresh that follows
      ;; this command, so hide it after that
      (exwm-floating-toggle-floating)
      (run-at-time 0.1 nil
                   (lambda ()
                     (when (buffer-live-p buffer)
                       (with-current-buffer buffer
                         (when exwm--floating-frame
                           (exwm-floating-hide)))))))))

(defun my-exwm-scratchpad-show ()
  "Show the next scratchpad window on this workspace, or hide the shown one."
  (setq my-exwm--scratchpad (seq-filter #'buffer-live-p my-exwm--scratchpad))
  (cond
   ((and (memq (current-buffer) my-exwm--scratchpad) exwm--floating-frame)
    (exwm-floating-hide))
   (my-exwm--scratchpad
    (let ((buffer (car my-exwm--scratchpad)))
      ;; Cycle, so repeated presses walk through the scratchpad
      (setq my-exwm--scratchpad (append (cdr my-exwm--scratchpad) (list buffer)))
      (unless (eq (buffer-local-value 'exwm--frame buffer) exwm-workspace--current)
        (exwm-workspace-move-window exwm-workspace--current
                                    (buffer-local-value 'exwm--id buffer)))
      (exwm-workspace-switch-to-buffer buffer)))
   (t (message "Scratchpad is empty"))))

(defun my-exwm-resize (direction)
  "Resize the selected window: DIRECTION is wider, narrower, taller or shorter."
  (if (derived-mode-p 'exwm-mode)
      (pcase direction
        ('wider (exwm-layout-enlarge-window-horizontally 20))
        ('narrower (exwm-layout-shrink-window-horizontally 20))
        ('taller (exwm-layout-enlarge-window 20))
        ('shorter (exwm-layout-shrink-window 20)))
    (pcase direction
      ('wider (enlarge-window-horizontally 2))
      ('narrower (shrink-window-horizontally 2))
      ('taller (enlarge-window 1))
      ('shorter (shrink-window 1)))))

(defun my-exwm--osd (label percent)
  "Show LABEL with PERCENT as a bar in the echo area (sway's swayosd)."
  (let ((filled (/ (+ (max 0 (min 100 percent)) 5) 10)))
    (message "%s %s%s %d%%" label
             (make-string filled ?█) (make-string (- 10 filled) ?░) percent)))

(defun my-exwm--output (program &rest args)
  "Output of PROGRAM with ARGS, or nil if it fails."
  (let ((default-directory "~/"))
    (with-temp-buffer
      (when (eq 0 (apply #'call-process program nil '(t nil) nil args))
        (buffer-string)))))

(defun my-exwm--volume-percent ()
  "Volume of the default sink in percent."
  (let ((out (my-exwm--output "pactl" "get-sink-volume" "@DEFAULT_SINK@")))
    (if (and out (string-match "\\([0-9]+\\)%" out))
        (string-to-number (match-string 1 out))
      0)))

(defun my-exwm-volume (direction)
  "Change the volume: DIRECTION is up, down or mute (toggle). Capped at 100%."
  (if (eq direction 'mute)
      (my-exwm--output "pactl" "set-sink-mute" "@DEFAULT_SINK@" "toggle")
    (let ((target (+ (my-exwm--volume-percent) (if (eq direction 'up) 5 -5))))
      (my-exwm--output "pactl" "set-sink-volume" "@DEFAULT_SINK@"
                       (format "%d%%" (max 0 (min 100 target))))))
  (let ((muted (string-match-p
                "yes" (or (my-exwm--output "pactl" "get-sink-mute" "@DEFAULT_SINK@") ""))))
    (my-exwm--osd (if muted "Volume (muted)" "Volume") (my-exwm--volume-percent))))

(defun my-exwm-brightness (direction)
  "Change the screen brightness: DIRECTION is up or down."
  (let ((out (my-exwm--output "brightnessctl" "-m" "set"
                              (if (eq direction 'up) "+5%" "5%-"))))
    ;; device,class,current,percent%,max
    (when (and out (string-match ",\\([0-9]+\\)%," out))
      (my-exwm--osd "Brightness" (string-to-number (match-string 1 out))))))

(defun my-exwm-power (action)
  "Run systemctl ACTION, saving buffers first unless hibernating.
\\[keyboard-quit] at a save prompt aborts."
  (unless (equal action "hibernate")
    (save-some-buffers))
  (my-exwm--spawn "systemctl" action))

(defun my-exwm-logout ()
  "End the EXWM session (this Emacs is the session)."
  (save-buffers-kill-emacs))

(defun my-exwm-reload ()
  "Reload the EXWM config from ~/.emacs.d/exwm.
Keys removed from the binds stay grabbed until the next login."
  (my-exwm-load-files)
  (message "EXWM config reloaded"))


;;;; App launcher (sway's fuzzel)

(defvar my-exwm--apps-cache nil
  "(STAMP . APPS) for `my-exwm-launch-app', STAMP being the dirs and mtimes.")

(defun my-exwm--application-dirs ()
  "The XDG applications directories, highest priority first."
  (seq-filter #'file-directory-p
              (mapcar (lambda (dir) (expand-file-name "applications" dir))
                      (cons (xdg-data-home) (xdg-data-dirs)))))

(defun my-exwm--desktop-shown-p (entry)
  "Non-nil if desktop ENTRY (a hash table) belongs in the launcher."
  (let ((get (lambda (key) (gethash key entry))))
    (and (equal (funcall get "Type") "Application")
         (funcall get "Name")
         (funcall get "Exec")
         (not (equal (funcall get "NoDisplay") "true"))
         (not (equal (funcall get "Hidden") "true"))
         ;; EXWM isn't a desktop that apps list
         (not (funcall get "OnlyShowIn"))
         (let ((try (funcall get "TryExec")))
           (or (null try) (executable-find try))))))

(defun my-exwm--desktop-apps ()
  "Alist of (LABEL . ENTRY) for the launchable desktop entries.
Entries are keyed by desktop-file ID; the first one found wins, so a user
override (even one with Hidden=true) shadows the system copy."
  (let* ((dirs (my-exwm--application-dirs))
         (stamp (mapcar (lambda (dir)
                          (cons dir (file-attribute-modification-time
                                     (file-attributes dir))))
                        dirs)))
    (unless (equal (car my-exwm--apps-cache) stamp)
      (let ((seen (make-hash-table :test #'equal))
            apps)
        (dolist (dir dirs)
          (dolist (file (directory-files-recursively dir "\\.desktop\\'"))
            (let ((id (string-replace "/" "-" (file-relative-name file dir))))
              (unless (gethash id seen)
                (puthash id t seen)
                (when-let* ((entry (condition-case nil
                                       (xdg-desktop-read-file file)
                                     (error nil)))
                            ((my-exwm--desktop-shown-p entry)))
                  (let ((label (gethash "Name" entry)))
                    (when (assoc label apps)
                      (setq label (format "%s (%s)" label id)))
                    (push (cons label entry) apps)))))))
        (setq my-exwm--apps-cache
              (cons stamp (sort apps (lambda (a b) (string< (car a) (car b))))))))
    (cdr my-exwm--apps-cache)))

(defun my-exwm--desktop-command (entry)
  "Shell command for desktop ENTRY: Exec without field codes."
  (replace-regexp-in-string
   "%%" "%"
   (replace-regexp-in-string "%[fFuUdDnNickvm]" "" (gethash "Exec" entry))))

(defun my-exwm-launch-app ()
  "Pick a desktop application and start it."
  (my-exwm--leave-fullscreen)
  (let* ((apps (my-exwm--desktop-apps))
         (completion-extra-properties
          `(:annotation-function
            ,(lambda (label)
               (when-let* ((comment (gethash "Comment" (cdr (assoc label apps)))))
                 (concat "  " (propertize comment 'face 'completions-annotations))))))
         (label (completing-read "Run: " apps nil t)))
    (when-let* ((entry (cdr (assoc label apps))))
      (if (equal (gethash "Terminal" entry) "true")
          (my-exwm--vterm (format "*%s*" label) (my-exwm--desktop-command entry))
        (my-exwm-exec (my-exwm--desktop-command entry))))))


;;;; Claude helpers (sway's nix-add-package / claude-prompt, in vterm)

(defun my-exwm--claude (prompt)
  "Start an interactive claude session on PROMPT in a vterm in ~/dotfiles."
  (my-exwm--vterm (generate-new-buffer-name "*claude*")
                  (concat "claude " (shell-quote-argument prompt))
                  "~/dotfiles/"))

(defun my-exwm-nix-add-package ()
  "Ask for a nixpkgs package and a target file, then hand off to claude.
The targets and the prompt come from the nix-add-package script
(homeManager.claudeLaunchers), which sway's bind runs with fuzzel."
  (my-exwm--leave-fullscreen)
  (let ((pkg (string-trim (read-string "nixpkgs package (e.g. htop): "))))
    (unless (string-empty-p pkg)
      (let ((label (completing-read (format "Add \"%s\" to: " pkg)
                                    (process-lines "nix-add-package" "--list-targets")
                                    nil t)))
        (unless (string-empty-p label)
          (my-exwm--claude
           (car (process-lines "nix-add-package" "--print-prompt" pkg label))))))))

(defun my-exwm-claude-prompt ()
  "Ask claude a question (sway's claude-prompt)."
  (my-exwm--leave-fullscreen)
  (let ((prompt (string-trim (read-string "Ask claude: "))))
    (unless (string-empty-p prompt)
      (my-exwm--claude prompt))))


;;;; Menus (sway's modes)

(defun my-exwm--leave-fullscreen ()
  "Leave fullscreen, which would hide the menu or minibuffer."
  (when (and (derived-mode-p 'exwm-mode) (exwm-layout--fullscreen-p))
    (exwm-layout-unset-fullscreen)))

(defun my-exwm-menu-exit ()
  "Leave the open menu."
  (interactive))

(defun my-exwm-menu-stray ()
  "Ignore a key the open menu doesn't bind, staying in the menu (like sway)."
  (interactive))

(defun my-exwm--menu-hint (title binds)
  "Echo-area text for menu TITLE listing BINDS, like sway's mode notification."
  (concat (propertize title 'face 'bold) "  "
          (mapconcat (lambda (bind)
                       (concat (propertize (nth 0 bind) 'face 'help-key-binding)
                               " " (nth 1 bind)))
                     binds "  ")
          "  " (propertize "Esc/Spc" 'face 'help-key-binding) " exit"))

(defun my-exwm-menu (name)
  "Open menu NAME from `my-exwm-nix-modes' until a bind runs or it's left.
A menu with :stay (resize) stays open after each bind, until Esc/Spc/C-g.
While open, keys reach Emacs even over X windows: line-mode passthrough is
on, and a char-mode window has its keyboard grabbed until the menu closes."
  (my-exwm--leave-fullscreen)
  (let* ((mode (alist-get name my-exwm-nix-modes))
         (stay (plist-get mode :stay))
         (binds (plist-get mode :binds))
         (hint (my-exwm--menu-hint (plist-get mode :title) binds))
         (id (and (derived-mode-p 'exwm-mode) exwm--id))
         (grabbed (and id (eq exwm--input-mode 'char-mode)))
         (map (make-sparse-keymap)))
    (define-key map [t] #'my-exwm-menu-stray)
    (dolist (key '("<escape>" "SPC" "C-g"))
      (define-key map (kbd key) #'my-exwm-menu-exit))
    (pcase-dolist (`(,key ,_desc ,action . ,args) binds)
      (define-key map (kbd key)
                  (lambda ()
                    (interactive)
                    (apply #'my-exwm-run action args)
                    (when stay (message "%s" hint)))))
    (setq exwm-input-line-mode-passthrough t)
    (when grabbed
      (exwm-input--grab-keyboard id))
    (message "%s" hint)
    (set-transient-map
     map
     (lambda ()
       (if stay
           (not (eq this-command #'my-exwm-menu-exit))
         (eq this-command #'my-exwm-menu-stray)))
     (lambda ()
       (setq exwm-input-line-mode-passthrough nil)
       ;; The bind may have closed the window or switched it to line-mode
       (when-let* ((grabbed)
                   (buffer (exwm--id->buffer id))
                   ((eq (buffer-local-value 'exwm--input-mode buffer) 'char-mode)))
         (exwm-input--release-keyboard id))
       (message nil)))))


;;;; Keys

(defvar my-exwm--actions
  '((exec . my-exwm-exec)
    (launch-app . my-exwm-launch-app)
    (vterm . my-exwm-vterm)
    (nix-add-package . my-exwm-nix-add-package)
    (claude-prompt . my-exwm-claude-prompt)
    (volume . my-exwm-volume)
    (brightness . my-exwm-brightness)
    (power . my-exwm-power)
    (logout . my-exwm-logout)
    (kill . my-exwm-kill)
    (focus . my-exwm-focus)
    (swap . my-exwm-swap)
    (focus-toggle . my-exwm-focus-toggle)
    (split . my-exwm-split)
    (fullscreen . my-exwm-fullscreen)
    (floating . my-exwm-floating)
    (scratchpad-show . my-exwm-scratchpad-show)
    (scratchpad-hide . my-exwm-scratchpad-hide)
    (workspace . my-exwm-workspace)
    (move-to-workspace . my-exwm-move-to-workspace)
    (resize . my-exwm-resize)
    (reload . my-exwm-reload)
    (menu . my-exwm-menu))
  "ACTION symbols from my-exwm-nix.el and the functions that run them.")

(defun my-exwm-run (action &rest args)
  "Run ACTION with ARGS."
  (if-let* ((function (alist-get action my-exwm--actions)))
      (apply function args)
    (error "my-exwm: unknown action %s" action)))

(defun my-exwm--command (action args)
  "Interactive command running ACTION with ARGS."
  (lambda ()
    (interactive)
    (apply #'my-exwm-run action args)))

(defun my-exwm--keysyms-or-unavailable (keysyms)
  "Return KEYSYMS, or ((0 . 0)) when xelb found none.
xelb returns nil for a key the keymap can't produce with its modifiers
(e.g. s-¤ without a Swedish layout); EXWM then fails to start instead of
warning \"Key unavailable\", which it does for ((0 . 0))."
  (or keysyms '((0 . 0))))

(advice-add 'xcb:keysyms:event->keysyms :filter-return
            #'my-exwm--keysyms-or-unavailable)

;; Global keys are super keys only, so no X window loses a key of its own
(setopt exwm-input-global-keys
        (append
         (mapcar (pcase-lambda (`(,key ,action . ,args))
                   (cons (kbd key) (my-exwm--command action args)))
                 my-exwm-nix-global-keys)
         ;; Back to line-mode from char-mode (C-c C-k goes to char-mode)
         `((,(kbd "s-<escape>") . exwm-input-toggle-keyboard))))

;; Over line-mode X windows these reach Emacs instead of the app: EXWM's
;; defaults plus the regular config's M-o (other-window) and C-ö leader.
;; A window in char-mode gets every key except the global ones.
(setopt exwm-input-prefix-keys
        (mapcar #'kbd '("C-x" "C-u" "C-h" "M-x" "M-`" "M-&" "M-:" "M-o" "C-ö")))

;; Send the next key to the X window as is
(define-key exwm-mode-map (kbd "C-q") #'exwm-input-send-next-key)

;; The kernel's rfkill acts on these; sway ignores them, Emacs would say
;; "<XF86Bluetooth> is undefined"
(dolist (key '("<XF86Bluetooth>" "<XF86WLAN>" "<XF86RFKill>"))
  (keymap-global-set key #'ignore))

;; Emacs keys translated for line-mode X windows
(setopt exwm-input-simulation-keys
        '(([?\C-b] . [left])
          ([?\C-f] . [right])
          ([?\C-p] . [up])
          ([?\C-n] . [down])
          ([?\C-a] . [home])
          ([?\C-e] . [end])
          ([?\M-v] . [prior])
          ([?\C-v] . [next])
          ([?\C-d] . [delete])
          ([?\C-k] . [S-end delete])
          ([?\M-w] . [?\C-c])
          ([?\C-y] . [?\C-v])
          ([?\C-w] . [?\C-x])
          ([?\C-s] . [?\C-f])))

;; Fullscreen X windows would otherwise switch to char-mode
(setopt exwm-layout-fullscreen-release-keyboard nil)


;;;; Mouse and monitors

;; Like sway: focus follows the mouse; s-drag moves/resizes floating windows
;; (EXWM's default exwm-input-move-event / exwm-input-resize-event).
(setopt focus-follows-mouse t
        mouse-autoselect-window t)

(defun my-exwm--screen-changed ()
  "Turn on newly connected outputs."
  (my-exwm--spawn "xrandr" "--auto"))

(add-hook 'exwm-randr-screen-change-hook #'my-exwm--screen-changed)

;;; my-exwm.el ends here
