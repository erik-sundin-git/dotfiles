;;; my-exwm-bar.el --- Workspaces and status in the tab bar -*- no-byte-compile: t; lexical-binding: t; -*-

;; waybar's job under EXWM: the tab bar of every workspace frame shows the
;; workspaces on the left and status items on the right, with the system
;; tray at the top right.  Only standard Emacs faces, no theme colors.
;; Changes here apply to this (EXWM) Emacs only.

;;; Code:

(require 'exwm)
(require 'exwm-workspace)
(require 'exwm-systemtray)
(require 'tab-bar)
(require 'battery)
(require 'json)
(require 'seq)
(require 'subr-x)

;; From my-exwm-nix.el
(defvar my-exwm-nix-laptop)
(defvar my-exwm-nix-thermal-path)
(defvar my-exwm-nix-claude-usage)

(declare-function my-exwm-workspace-name "my-exwm")


;;;; Workspaces

;; Own faces: tab-bar-auto-width stretches items in the tab-bar-tab faces
;; (tab-bar-auto-width-faces) as if they were tabs
(defface my-exwm-bar-workspace-current '((t :inherit tab-bar-tab))
  "Workspace shown on this monitor.")

(defface my-exwm-bar-workspace '((t :inherit tab-bar-tab-inactive))
  "Other occupied workspace.")

(defun my-exwm-bar-redraw (&rest _)
  "Redraw the tab bars."
  (force-mode-line-update t))

(defun my-exwm-bar--windows-by-frame ()
  "Alist (WORKSPACE-FRAME . URGENT) for the occupied workspaces.
Occupied means holding an X window or showing a buffer other than
*scratch*, which empty workspaces show (terminals are vterm buffers)."
  (let (result)
    (pcase-dolist (`(,_id . ,buffer) exwm--id-buffer-alist)
      (when (buffer-live-p buffer)
        (let* ((frame (buffer-local-value 'exwm--frame buffer))
               (urgent (buffer-local-value 'exwm--hints-urgency buffer))
               (cell (assq frame result)))
          (if cell
              (setcdr cell (or (cdr cell) urgent))
            (push (cons frame urgent) result)))))
    (dolist (frame exwm-workspace--list)
      (unless (or (assq frame result)
                  (seq-every-p (lambda (window)
                                 (equal (buffer-name (window-buffer window))
                                        "*scratch*"))
                               (window-list frame 'nomini)))
        (push (cons frame nil) result)))
    result))

(defun my-exwm-bar-workspaces ()
  "Tab-bar items for the occupied workspaces and the shown one.
Computed at every redraw, so it can't go stale.  \"Shown\" is the frame
whose tab bar is drawn, so each monitor highlights its own workspace."
  (let ((occupied (my-exwm-bar--windows-by-frame))
        (shown (selected-frame))
        items)
    (seq-do-indexed
     (lambda (frame index)
       (let ((cell (assq frame occupied)))
         (when (or cell (eq frame shown))
           (push `(,(intern (format "my-exwm-workspace-%d" index))
                   menu-item
                   ,(propertize (format " %s " (my-exwm-workspace-name index))
                                'face (cond ((eq frame shown) 'my-exwm-bar-workspace-current)
                                            ((cdr cell) 'error)
                                            (t 'my-exwm-bar-workspace)))
                   ,(lambda ()
                      (interactive)
                      (exwm-workspace-switch index))
                   :help ,(format "Workspace %s" (my-exwm-workspace-name index)))
                 items))))
     exwm-workspace--list)
    (nreverse items)))

(defun my-exwm-bar-mode ()
  "[C] while the selected X window is in char-mode (sway's mode indicator)."
  (let ((buffer (window-buffer (frame-selected-window))))
    (when (and (eq (buffer-local-value 'major-mode buffer) 'exwm-mode)
               (eq (buffer-local-value 'exwm--input-mode buffer) 'char-mode))
      `((my-exwm-input-mode menu-item ,(propertize " [C] " 'face 'warning)
                            exwm-input-toggle-keyboard
                            :help "char-mode: keys go to the X window (s-<escape> toggles)")))))

(defun my-exwm-bar-tabs ()
  "The regular Emacs tabs, only when there is more than one.
Keeps the regular config's tab-bar-show 1 behaviour."
  (when (> (length (funcall tab-bar-tabs-function)) 1)
    (tab-bar-format-tabs)))


;;;; Status items

(defvar my-exwm-bar--status nil
  "Alist (ITEM TEXT FACE HELP) of the current status texts.")

(defvar my-exwm-bar--next nil
  "Alist (ITEM . TIME) of when each item is due again.")

(defvar my-exwm-bar--procs (make-hash-table)
  "Running process per item, so a slow one isn't started twice.")

(defun my-exwm-bar--set (item text &optional face help)
  "Show TEXT (nil hides ITEM) with FACE and tooltip HELP."
  (setf (alist-get item my-exwm-bar--status) (and text (list text face help))))

(defun my-exwm-bar--run (item program args callback)
  "Run PROGRAM with ARGS for ITEM and call CALLBACK with its output.
Skipped while the previous run is alive.  Starts in ~ (never a remote
`default-directory'); stderr is discarded."
  (unless (process-live-p (gethash item my-exwm-bar--procs))
    (let ((default-directory "~/")
          (buffer (generate-new-buffer (format " *my-exwm-bar-%s*" item) t)))
      (puthash
       item
       (make-process
        :name (format "my-exwm-bar-%s" item)
        :buffer buffer
        :command (append (list "sh" "-c" "exec \"$0\" \"$@\" 2>/dev/null" program) args)
        :connection-type 'pipe
        :noquery t
        :sentinel
        (lambda (process _event)
          (unless (process-live-p process)
            (let ((output (with-current-buffer buffer (buffer-string))))
              (kill-buffer buffer)
              (with-demoted-errors "my-exwm-bar: %S"
                (funcall callback output (process-exit-status process)))
              (my-exwm-bar-redraw)))))
       my-exwm-bar--procs))))

(defun my-exwm-bar--nmcli-fields (line)
  "Split nmcli terse LINE on unescaped colons."
  (let ((fields nil) (field "") (i 0) (n (length line)))
    (while (< i n)
      (let ((c (aref line i)))
        (cond
         ((and (eq c ?\\) (< (1+ i) n))
          (setq field (concat field (string (aref line (1+ i)))) i (+ i 2)))
         ((eq c ?:)
          (push field fields)
          (setq field "" i (1+ i)))
         (t (setq field (concat field (string c)) i (1+ i))))))
    (nreverse (cons field fields))))

(defun my-exwm-bar--ethernet-ip ()
  "IPv4 address of a wired interface (en*/eth*), or nil."
  (when-let* ((pair (seq-find (lambda (pair) (string-match-p "\\`e" (car pair)))
                              (network-interface-list t 'ipv4))))
    (format-network-address (cdr pair) t)))

(defun my-exwm-bar-update-network ()
  "W: <ssid>, E: <ip> or down, like waybar's network module."
  (my-exwm-bar--run
   'network "nmcli" '("-t" "-f" "ACTIVE,SSID" "dev" "wifi" "list" "--rescan" "no")
   (lambda (output _status)
     (let ((ssid (seq-some (lambda (line)
                             (pcase (my-exwm-bar--nmcli-fields line)
                               (`("yes" ,ssid) ssid)))
                           (split-string output "\n" t)))
           (ip (my-exwm-bar--ethernet-ip)))
       (cond
        (ssid (my-exwm-bar--set 'network (concat "W: " ssid)))
        (ip (my-exwm-bar--set 'network (concat "E: " ip)))
        (t (my-exwm-bar--set 'network "down" 'shadow)))))))

(defconst my-exwm-bar--battery-icons
  (mapcar #'string '(#xf008e #xf007a #xf007b #xf007c #xf007d #xf007e
                     #xf007f #xf0080 #xf0081 #xf0082 #xf0079))
  "Battery level icons from empty to full (waybar's).")

(defun my-exwm-bar-update-battery ()
  "Battery icon and percentage, like waybar's battery module."
  (let* ((status (funcall battery-status-function))
         (percent (round (string-to-number (or (alist-get ?p status) "0"))))
         (state (downcase (or (alist-get ?B status) "")))
         (charging (equal state "charging"))
         (icon (nth (min 10 (round percent 10)) my-exwm-bar--battery-icons)))
    (my-exwm-bar--set
     'battery
     (cond (charging (format "%s %d%%" (string #xf140b) percent))
           ((>= percent 98) (format "%s full" icon))
           (t (format "%s %d%%" icon percent)))
     (cond (charging 'warning)
           ((<= percent 30) 'error))
     (format "Battery %d%% (%s)" percent state))))

(defun my-exwm-bar-update-disk ()
  "Space available on / to a normal user."
  (when-let* ((info (file-system-info "/")))
    (my-exwm-bar--set 'disk (concat " " (file-size-human-readable (nth 2 info) 'iec))
                      nil "Free on /")))

(defun my-exwm-bar-update-memory ()
  "Memory in use (MemTotal - MemAvailable)."
  (with-temp-buffer
    (insert-file-contents "/proc/meminfo")
    (let ((field (lambda (name)
                   (goto-char (point-min))
                   (when (re-search-forward (concat "^" name ": *\\([0-9]+\\)") nil t)
                     (string-to-number (match-string 1))))))
      (when-let* ((total (funcall field "MemTotal"))
                  (available (funcall field "MemAvailable")))
        (my-exwm-bar--set 'memory (format " %.1fG" (/ (- total available) 1048576.0))
                          nil "Memory used")))))

(defun my-exwm-bar-update-claude ()
  "Claude subscription usage from waybar-claude-usage's JSON."
  (when my-exwm-nix-claude-usage
    (my-exwm-bar--run
     'claude my-exwm-nix-claude-usage nil
     (lambda (output _status)
       (if (string-empty-p (string-trim output))
           (my-exwm-bar--set 'claude nil)  ; not logged in
         (let ((json (json-parse-string output :object-type 'alist)))
           (my-exwm-bar--set
            'claude (alist-get 'text json)
            (pcase (alist-get 'class json)
              ("critical" 'error)
              ("warning" 'warning)
              ("unknown" 'shadow))
            (alist-get 'tooltip json))))))))

(defun my-exwm-bar-update-clock ()
  "Date and time."
  (my-exwm-bar--set 'clock (format-time-string "%Y-%m-%d %H:%M")))

(defun my-exwm-bar-update-temperature ()
  "CPU temperature from the host's thermal zone."
  (when my-exwm-nix-thermal-path
    (with-temp-buffer
      (insert-file-contents my-exwm-nix-thermal-path)
      (my-exwm-bar--set 'temperature
                        (format "%.0f °C" (/ (string-to-number (buffer-string)) 1000.0))))))

(defconst my-exwm-bar--items
  '((network 15 my-exwm-bar-update-network)
    (battery 30 my-exwm-bar-update-battery)
    (disk 60 my-exwm-bar-update-disk)
    (memory 15 my-exwm-bar-update-memory)
    (claude 300 my-exwm-bar-update-claude)
    (clock 15 my-exwm-bar-update-clock)
    (temperature 15 my-exwm-bar-update-temperature))
  "Status items in display order: (ITEM INTERVAL UPDATE-FUNCTION).")

(defun my-exwm-bar--item-enabled-p (item)
  "Non-nil if ITEM applies to this host."
  (pcase item
    ('battery my-exwm-nix-laptop)
    ('claude my-exwm-nix-claude-usage)
    ('temperature my-exwm-nix-thermal-path)
    (_ t)))

(defun my-exwm-bar--tick ()
  "Update the items that are due, then redraw once."
  (let ((now (float-time)))
    (pcase-dolist (`(,item ,interval ,update) my-exwm-bar--items)
      (when (and (my-exwm-bar--item-enabled-p item)
                 (>= now (alist-get item my-exwm-bar--next 0)))
        ;; A second of slack, so a 15 s item runs on every 15 s tick
        (setf (alist-get item my-exwm-bar--next) (+ now interval -1))
        (with-demoted-errors "my-exwm-bar: %S"
          (funcall update)))))
  (my-exwm-bar-redraw))

(defun my-exwm-bar-status ()
  "Tab-bar items for the status texts, plus room for the system tray."
  (append
   (delq nil
         (mapcar
          (pcase-lambda (`(,item . ,_))
            (when-let* ((entry (alist-get item my-exwm-bar--status)))
              (pcase-let ((`(,text ,face ,help) entry))
                `(,(intern (format "my-exwm-status-%s" item))
                  menu-item ,(propertize (concat " " text " ") 'face face)
                  ignore
                  ,@(when help (list :help help))))))
          my-exwm-bar--items))
   (when (> exwm-systemtray-width 0)
     `((my-exwm-tray menu-item
                     ,(propertize " " 'display `(space :width (,exwm-systemtray-width)))
                     ignore)))))


;;;; Setup

;; The icons are Nerd Font glyphs in the private use areas, which Emacs's
;; default fontset maps to no usable font (they'd show as boxes). uiHelpers
;; installs this font.
(dolist (range '((#xe000 . #xf8ff) (#xf0000 . #xfffff)))
  (set-fontset-font t range "JetBrainsMono Nerd Font"))

(setopt tab-bar-show t
        tab-bar-format '(my-exwm-bar-workspaces
                         my-exwm-bar-mode
                         my-exwm-bar-tabs
                         tab-bar-format-align-right
                         my-exwm-bar-status)
        ;; The tray sits on the tab bar's right end, not over the echo area
        exwm-systemtray-position 'top
        exwm-systemtray-background-color 'tab-bar)

(add-hook 'exwm-workspace-switch-hook #'my-exwm-bar-redraw)
(add-hook 'exwm-manage-finish-hook #'my-exwm-bar-redraw)
(add-hook 'exwm-workspace-list-change-hook #'my-exwm-bar-redraw)
;; A workspace gains or loses its Emacs buffers
(add-hook 'window-buffer-change-functions #'my-exwm-bar-redraw)
;; No hooks for these: windows closing or moving, urgency, input mode
(dolist (function '(exwm-manage--unmanage-window
                    exwm-workspace-move-window
                    exwm--update-hints
                    exwm--on-net-wm-state
                    exwm-input-grab-keyboard
                    exwm-input-release-keyboard))
  (advice-add function :after #'my-exwm-bar-redraw))

(defvar my-exwm-bar--timer nil "The status timer.")

(when (timerp my-exwm-bar--timer)
  (cancel-timer my-exwm-bar--timer))
(setq my-exwm-bar--next nil)
;; Ticks on :00/:15/:30/:45, so the clock turns over on the minute
(setq my-exwm-bar--timer
      (run-at-time (- 15 (mod (float-time) 15)) 15 #'my-exwm-bar--tick))
(my-exwm-bar--tick)

;;; my-exwm-bar.el ends here
