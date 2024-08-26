(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-agenda-custom-commands
   '(("i" "Inbox" alltodo " -{.*}"
      ((org-agenda-files
        '("~/storagebox/org/Inbox.org"))))
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
 '(org-agenda-files
   '("~/storagebox/org/Inbox.org" "/home/erik/storagebox/org/todo.org" "/home/erik/storagebox/org-roam/20240808132719-todo_skola.org" "/home/erik/storagebox/org/agenda.org" "/home/erik/storagebox/org-roam/20240808132624-todo.org")))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
