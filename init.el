;; Package configs
(require 'package)
(setq package-enable-at-startup nil)
(setq package-archives '(("org"   . "http://orgmode.org/elpa/")
                         ("gnu"   . "http://elpa.gnu.org/packages/")
                         ("melpa-stable" . "http://stable.melpa.org/packages/")
                         ("melpa" . "http://melpa.org/packages/")))
(package-initialize)
;; Bootstrap `use-package`
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

;; Load path
(add-to-list 'load-path "~/.emacs.d/lisp/")
(setq exec-path (append exec-path '("~/elixir-lsp")))

;; Server
(if (and (fboundp 'server-running-p)
         (not (server-running-p)))
   (server-start))

;; Other configs
(setq confirm-kill-emacs 'yes-or-no-p)
(global-auto-revert-mode 1)
(setq ring-bell-function 'ignore)
(defalias 'yes-or-no-p 'y-or-n-p)

;; Smooth scroll
(pixel-scroll-mode -1)

;; Custom commands
(defun edit-init ()
  (interactive)
  (find-file "~/.emacs.d/init.el"))

;; Make mouse wheel / trackpad scrolling less jerky
(setq mouse-wheel-scroll-amount '(1
                                  ((control))))
(dolist (multiple '("" "double-" "triple-"))
  (dolist (direction '("right" "left"))
    (global-set-key (read-kbd-macro (concat "<" multiple "wheel-" direction ">")) 'ignore)))

;; PACKAGES INSTALL

;; Ranger
(use-package ranger
  :ensure t
  :config
  (setq ranger-hide-cursor nil)
  (setq ranger-show-literal t)
  (setq ranger-dont-show-binary t)
  :init
  (ranger-override-dired-mode 1))

;; Highlight Indent (like Sublime)
(use-package highlight-indent-guides
  :ensure t
  :config
  (setq highlight-indent-guides-method 'character)
  (setq highlight-indent-guides-character ?\│)
  :hook ((prog-mode . highlight-indent-guides-mode)))

;; Smart Parens
(use-package smartparens
  :ensure t
  :init (smartparens-global-mode 1)
  :diminish smartparens-mode)

(setq make-backup-files nil)
(setq auto-save-default nil)
(setq lazy-highlight-cleanup nil)
(setq-default tab-width 2)
(setq-default default-tab-width 2)
(setq-default indent-tabs-mode nil)
(setq-default truncate-lines -1)
(setq-default typescript-indent-level 2)
(setq-default rust-indent-offset 2)

;; Linum enhancement
(setq linum-format "  %3d ")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun enhance-ui-for-orgmode ()
  "Enhance UI for orgmode."
  (org-bullets-mode 1)
  (org-autolist-mode 1)
  (toggle-truncate-lines)
  (linum-mode -1)
  (dolist (face '(org-level-1 org-level-2 org-level-3 org-level-4 org-level-5))
    (set-face-attribute face nil :height 1.0 :background nil))
  )

(defun kill-other-buffers ()
  "Kill all other buffers."
  (interactive)
  (mapc 'kill-buffer (delq (current-buffer) (buffer-list))))

;; Deleting
(delete-selection-mode 1)

;; Some term enhancement
(defadvice term-sentinel (around my-advice-term-sentinel (proc msg))
  (if (memq (process-status proc) '(signal exit))
      (let ((buffer (process-buffer proc)))
        ad-do-it
        (kill-buffer buffer))
    ad-do-it))
(ad-activate 'term-sentinel)

(defadvice term (before force-bash)
  (interactive (list "/usr/local/bin/fish")))
(ad-activate 'term)
(add-hook 'term-mode-hook (lambda ()
                            (linum-mode -1)
                            (setq left-fringe-width 0)
                            (setq right-fringe-width 0)
                            (setq buffer-face-mode-face `(:background "#202235"))
                            (buffer-face-mode 1)
                            (local-unset-key (kbd "C-r"))))

(use-package multi-term
  :ensure t
  :config
  (setq multi-term-program "/usr/local/bin/fish"))

;; Expand Region (for vim-like textobject)
(use-package expand-region :ensure t)

;; Multiple Cursors
(use-package multiple-cursors :ensure t)

;; Splash Screen
(setq inhibit-startup-screen t)
(setq initial-scratch-message ";; Happy Hacking")

;; Show and jump between matching parens
(setq show-paren-delay 0)
(show-paren-mode  1)
(global-set-key "%" 'match-paren)
(defun match-paren (arg)
  "Go to the matching paren if on a paren; otherwise insert %."
  (interactive "p")
  (cond ((looking-at "\\s(") (forward-list 1) (backward-char 1))
        ((looking-at "\\s)") (forward-char 1) (backward-list 1))
        (t (self-insert-command (or arg 1)))))

;; Custom copy line function
(defun copy-line (arg)
  "Copy lines (as many as prefix argument) in the kill ring.
      Ease of use features:
      - Move to start of next line.
      - Appends the copy on sequential calls.
      - Use newline as last char even on the last line of the buffer.
      - If region is active, copy its lines."
  (interactive "p")
  (let ((beg (line-beginning-position))
        (end (line-end-position arg)))
    (when mark-active
      (if (> (point) (mark))
          (setq beg (save-excursion (goto-char (mark)) (line-beginning-position)))
        (setq end (save-excursion (goto-char (mark)) (line-end-position)))))
    (if (eq last-command 'copy-line)
        (kill-append (buffer-substring beg end) (< end beg))
      (kill-ring-save beg end)))
  (kill-append "\n" nil)
  (beginning-of-line (or (and arg (1+ arg)) 2))
  (if (and arg (not (= 1 arg))) (message "%d lines copied" arg)))

;; Ace Jump
(use-package ace-jump-mode :ensure t)

;; Custom keybinding
;; Movement and editing
(global-set-key (kbd "C-o") (lambda ()
                              "insert new line"
                              (interactive)
                              (end-of-line)
                              (newline-and-indent)))
(global-set-key (kbd "C-c C-l") 'copy-line)
(windmove-default-keybindings 'meta)
(global-set-key (kbd "C-c b") 'mark-whole-buffer)
(global-set-key (kbd "C-c q") (lambda () (interactive)
                                (if (equal mode-line-format nil)
                                    (setq mode-line-format t)
                                  (setq mode-line-format nil))))
(global-set-key (kbd "C-x SPC") 'cua-rectangle-mark-mode)
(global-set-key (kbd "C-c l") 'join-line)
(global-set-key (kbd "C-c n") (lambda () (interactive) (join-line -1)))
(global-set-key (kbd "M-s") 'ace-jump-mode)
(global-set-key (kbd "M-l") 'ace-jump-line-mode)
;; Searching
(global-set-key (kbd "C-c s") 'helm-projectile-ag)
(global-set-key (kbd "C-c ;") 'helm-projectile-ag)
(global-set-key (kbd "C-x .") 'helm-resume)
(global-unset-key (kbd "C-s"))
(global-set-key (kbd "C-s") 'helm-occur)
(global-set-key (kbd "C-;") 'helm-occur)
;; Macro
(defun toggle-kbd-macro-recording-on ()
  "One-key keyboard macros: turn recording on."
  (interactive)
  (define-key global-map (this-command-keys)
    'toggle-kbd-macro-recording-off)
  (start-kbd-macro nil))

(defun toggle-kbd-macro-recording-off ()
  "One-key keyboard macros: turn recording off."
  (interactive)
  (define-key global-map (this-command-keys)
    'toggle-kbd-macro-recording-on)
  (end-kbd-macro))

;; Functions
(global-set-key (kbd "C-c f f") 'json-pretty-print-buffer)
(global-set-key (kbd "C-v") 'er/expand-region)
(global-set-key (kbd "C-c m m") 'mc/mark-all-dwim)
(global-set-key (kbd "C-c j") 'lsp-find-definition)
(global-set-key (kbd "C-0") 'quickrun)
(global-set-key (kbd "C-c SPC") 'lsp-ui-imenu)
(global-unset-key (kbd "C-\\"))
(global-set-key (kbd "C-\\") 'helm-M-x)
(global-set-key (kbd "C-c p p") 'helm-projectile-switch-project)
(global-set-key (kbd "C-c p f") 'helm-projectile-find-file)
(global-set-key (kbd "C-c f e d") (lambda ()
                                    "open emacs config"
                                    (interactive)
                                    (find-file "~/.emacs.d/init.el")))
(global-set-key (kbd "C-c f e R") (lambda ()
                                    "reload emacs config"
                                    (interactive)
                                    (load-file "~/.emacs.d/init.el")))
(global-set-key (kbd "C-c a t") 'multi-term)
(global-set-key (kbd "C-c f t") 'neotree-project-dir)
(global-set-key (kbd "C-c f r") 'neotree-refresh)
(global-set-key (kbd "C-c C-c") 'lazy-highlight-cleanup)
(global-set-key (kbd "C-c TAB") 'previous-buffer)
(global-set-key (kbd "C-x p r") 'helm-show-kill-ring)
(global-set-key (kbd "C-z") 'undo)
(global-set-key (kbd "M-d") (lambda ()
                              "delete word sexp"
                              (interactive)
                              (backward-sexp)
                              (kill-sexp)))
(global-unset-key (kbd "C-x d"))
(global-set-key (kbd "C-x d") 'ranger)
;; Window management
(global-set-key (kbd "C-c =") 'balance-windows)
(global-set-key (kbd "C-c /") 'split-window-right)
(global-set-key (kbd "C-c \\") 'split-window-below)
(global-set-key (kbd "C-x w n") 'make-frame)
(global-set-key (kbd "C-x w k") 'delete-frame)
(global-set-key (kbd "C-c k") 'delete-window)
(global-set-key (kbd "C-x w .") 'kill-buffer-and-window)
(global-set-key (kbd "C-c <down>") (lambda () (interactive) (shrink-window 5)))
(global-set-key (kbd "C-c <up>") (lambda () (interactive) (enlarge-window 5)))
(global-set-key (kbd "C-c <left>") (lambda () (interactive) (shrink-window-horizontally 5)))
(global-set-key (kbd "C-c <right>") (lambda () (interactive) (enlarge-window-horizontally 5)))

(use-package htmlize :ensure t)

(use-package org-autolist :ensure t)

(use-package org-bullets :ensure t)

;; Kill the frame if one was created for the capture
(defun delete-frame-if-neccessary (&rest r)
    (delete-frame))

;; UI configurations
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode   -1))
(when (fboundp 'tooltip-mode)
  (tooltip-mode    -1))
(when (fboundp 'menu-bar-mode)
  (menu-bar-mode   -1))
(when (fboundp 'global-linum-mode)
  (global-linum-mode 1))
(add-to-list 'default-frame-alist '(height . 60))
(add-to-list 'default-frame-alist '(width . 190))
(setq left-fringe-width 20)

(set-face-attribute 'default nil :font "Inconsolata" :height 180)
(setq-default line-spacing 0.15)

;; Anzu for search matching
(use-package anzu
  :ensure t
  :config
  (global-anzu-mode 1)
  (global-set-key [remap query-replace-regexp] 'anzu-query-replace-regexp)
  (global-set-key [remap query-replace] 'anzu-query-replace))

(setq show-trailing-whitespace t)

;; Helm
(use-package helm
  :ensure t
  :init
  (setq helm-M-x-fuzzy-match t
        helm-mode-fuzzy-match t
        helm-buffers-fuzzy-matching t
        helm-recentf-fuzzy-match t
        helm-locate-fuzzy-match t
        helm-semantic-fuzzy-match t
        helm-imenu-fuzzy-match t
        helm-completion-in-region-fuzzy-match t
        helm-candidate-number-list 80
        helm-split-window-in-side-p t
        helm-move-to-line-cycle-in-source t
        helm-echo-input-in-header-line t
        helm-autoresize-max-height 0
        helm-autoresize-min-height 20)
  :config
  (helm-mode 1)
  (define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action)
  (define-key helm-map (kbd "C-z") 'helm-select-action))

;; RipGrep
(use-package helm-rg :ensure t)
;; AG
(use-package helm-ag
  :ensure t
  :init
  (setq helm-ag-insert-at-point 'symbol)
  :config
  (define-key helm-ag-mode-map (kbd "<RET>") 'helm-ag-mode-jump-other-window)
  (define-key helm-ag-mode-map (kbd "C-o") 'helm-ag-mode-jump))

;; Prettier
(require 'prettier-js)

;; Projectile
(use-package projectile
  :ensure t
  :init
  (setq projectile-require-project-root nil)
  :config
  (projectile-mode 1))

;; Helm Projectile
(use-package helm-projectile
  :ensure t
  :init
  (setq helm-projectile-fuzzy-match t)
  (setq projectile-switch-project-action 'projectile-find-file-dwim)
  :config
  (helm-projectile-on))

;; All The Icons
(use-package all-the-icons :ensure t)
(use-package all-the-icons-dired :ensure t
  :hook (dired-mode . all-the-icons-dired-mode))

;; NeoTree
(use-package neotree
  :ensure t
  :init
  (setq neo-theme (if (display-graphic-p) 'icons 'arrow))
  (setq neo-vc-integration nil)
  (defun neotree-project-dir ()
    "Open NeoTree using the git root."
    (interactive)
    (let ((project-dir (projectile-project-root))
          (file-name (buffer-file-name)))
      (neotree-toggle)
      (if project-dir
          (if (neo-global--window-exists-p)
              (progn
                (neotree-dir project-dir)
                (neotree-find file-name)))
        (message "Could not find git project root."))))
  :config
  (define-key neotree-mode-map (kbd "C-c C-m") 'neotree-create-node)
  (add-hook 'neotree-mode-hook #'hide-mode-line-mode)
  (add-hook 'neotree-mode-hook (lambda ()
                                 (linum-mode -1)
                                 (setq-local linum-mode nil)
                                 (setq left-fringe-width 0)
                                 (setq right-fringe-width 0)
                                 (setq buffer-face-mode-face '(:family "Inconsolata"))
                                 (buffer-face-mode 1))))
(global-set-key (kbd "C-,") 'neotree-toggle)
(defun text-scale-twice ()(interactive)(progn(text-scale-adjust 0)(text-scale-decrease 2)))
(add-hook 'neo-after-create-hook (lambda (_)(call-interactively 'text-scale-twice)(neo-global--set-window-width 20)))

;; Which Key
(use-package which-key
  :ensure t
  :init
  (setq which-key-separator " ")
  (setq which-key-prefix-prefix "+")
  :config
  (which-key-mode))

;; Editorconfig
(use-package editorconfig
  :ensure t
  :config
  (editorconfig-mode 1))

;; Git Diff
(use-package diff-hl
  :ensure t
  :config
  (global-diff-hl-mode 1))

;; Highlight line
(global-hl-line-mode 1)
(set-face-attribute 'hl-line nil :inherit nil :background "#2b3547")

;; Remove decoration
(set-frame-parameter nil 'undecorated t)

;; Fancy titlebar for MacOS
(add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
(add-to-list 'default-frame-alist '(ns-appearance . dark))
(setq ns-use-proxy-icon  nil)
(setq frame-title-format '("%b"))
(setq mac-allow-anti-aliasing t)
(setq mac-option-key-is-meta nil)
(setq mac-command-key-is-meta t)
(setq mac-command-modifier 'meta)
(setq mac-option-modifier nil)
(global-set-key (kbd "M-`") 'other-frame)

;; Groovy
(use-package groovy-mode :ensure t)
(use-package grails-mode :ensure t)

;; Arduino
(use-package arduino-mode
  :ensure t
  :config
  (setq arduino-executable "/Applications/Arduino.app/Contents/MacOS/Arduino"))
(use-package company-arduino
  :after (arduino-mode company)
  :ensure t)

;; JS TS and Web
(use-package tide
  :ensure t
  :after (typescript-mode company flycheck)
  :hook ((typescript-mode . tide-setup)
         (typescript-mode . tide-hl-identifier-mode)
         (typescript-mode . flycheck-mode)
         (typescript-mode . prettier-js-mode)
         (before-save . tide-formater-before-save))
  :config
  (define-key typescript-mode-map (kbd "C-c r") 'tide-refactor))

(add-hook 'typescript-mode-hook
          (lambda()
            (when (and (stringp buffer-file-name)
                       (string-match "\\.tsx\\'" buffer-file-name))
              (setq emmet-expand-jsx-className? t)
              (emmet-mode))))

;; Vue
(defun setup-vue()
  (interactive)
  (require 'company)
  (require 'company-tern)
  (add-to-list 'company-backends 'company-tern)
  (tern-mode)
  (company-mode +1)
  (prettier-js-mode)
  (emmet-mode))

(defun setup-css()
  (interactive)
  (require 'company)
  (require 'company-css)
  (add-to-list 'company-backends 'company-css)
  (company-mode +1))

;; disable mmm-mode background
(add-hook 'mmm-mode-hook
          (lambda ()
            (set-face-background 'mmm-default-submode-face nil)))

(add-hook 'vue-mode-hook 'setup-vue)
(add-hook 'css-mode-hook 'setup-css)

(use-package web-mode
  :ensure t
  :init
  (add-to-list 'auto-mode-alist '("\\.html?\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.ejs\\'" . web-mode))
  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . typescript-mode))
  (add-to-list 'auto-mode-alist '("\\.jsx\\'" . typescript-mode))
  (add-to-list 'auto-mode-alist '("\\.js\\'" . typescript-mode))
  (setq web-mode-enable-current-element-highlight t)
  :hook ((web-mode . emmet-mode))
  :config
  (define-key web-mode-map (kbd "%") 'web-mode-tag-match))

;; Purescript
(use-package purescript-mode
  :ensure t
  :hook ((purescript-mode . turn-on-purescript-indentation)))

;; Python
(add-hook 'python-mode-hook 'lsp)
(add-hook 'python-mode-hook 'flymake-mode-off)

;; Flycheck
(use-package flycheck :ensure t)

;; Markdown
(add-hook 'markdown-mode-hook (lambda ()
                                (progn
                                  (set-frame-font "Inconsolata" t)
                                  (visual-line-mode t))))

;; LSP
(use-package lsp-mode :ensure t)

(use-package lsp-ui
  :ensure t
  :init
  (add-hook 'lsp-mode-hook 'lsp-ui-mode)
  (setq lsp-ui-doc-enable nil
        lsp-ui-peek-enable nil
        eldoc-echo-area-use-multiline-p nil))

;; Company mode
(use-package company
  :ensure t
  :init
  (setq company-tooltip-align-annotations t)
  (setq company-minimum-prefix-length 3)
  (setq company-auto-complete nil)
  (setq company-idle-delay 0.1)
  (setq company-require-match 'never)
  (setq company-frontends
        '(company-pseudo-tooltip-unless-just-one-frontend
          company-preview-frontend
          company-echo-metadata-frontend))
  (setq tab-always-indent 'complete)
  (defvar completion-at-point-functions-saved nil)
  :config
  (global-company-mode 1)
  (define-key company-active-map (kbd "TAB") 'company-complete-common-or-cycle)
  (define-key company-active-map (kbd "<tab>") 'company-complete-common-or-cycle)
  (define-key company-active-map (kbd "S-TAB") 'company-select-previous)
  (define-key company-active-map (kbd "<backtab>") 'company-select-previous)
  (define-key company-mode-map [remap indent-for-tab-command] 'company-indent-for-tab-command)
  (defun company-indent-for-tab-command (&optional arg)
    (interactive "P")
    (let ((completion-at-point-functions-saved completion-at-point-functions)
          (completion-at-point-functions '(company-complete-common-wrapper)))
      (indent-for-tab-command arg)))

  (defun company-complete-common-wrapper ()
    (let ((completion-at-point-functions completion-at-point-functions-saved))
      (company-complete-common))))

;; Rust
(use-package rust-mode
  :ensure t
  :init
  (add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-mode))
  :hook ((rust-mode . lsp)
         (rust-mode . flycheck-mode)))

(use-package cargo
  :ensure t
  :init
  (add-hook 'rust-mode-hook 'cargo-minor-mode))

(use-package flycheck-rust
  :ensure t
  :config
  (add-hook 'flycheck-mode-hook #'flycheck-rust-setup))

;; Elixir
;;(setq lsp-print-io t)
(setq lsp-clients-elixir-server-executable "language_server.sh")
(add-hook 'elixir-mode 'lsp)

;; Shrink Path
(use-package shrink-path
  :ensure t
  :demand t)

;; Modeline
(use-package hide-mode-line :ensure t)

(setq auto-revert-check-vc-info t)

(defun pretty-buffername ()
  (if buffer-file-truename
      (let* ((cur-dir (file-name-directory buffer-file-truename))
             (two-up-dir (-as-> cur-dir it (or (f-parent it) "") (or (f-parent it) "")))
             (shrunk (shrink-path-file-mixed two-up-dir cur-dir buffer-file-truename)))
        (concat (car shrunk)
                (mapconcat #'identity (butlast (cdr shrunk)) "/")
                (car (last shrunk))))
    (buffer-name)))

;; Well, this is stupid, but the icons I have on my modeline measured at approximate
;; 2 characters length each. So, in order for the simple-mode-line-render to render
;; properly, I need to add these length for each icon added.
(defun calculate-icons-width ()
  (let ((left-icon-length 2)
        (right-icon-length 2))
  (+ left-icon-length (pcase flycheck-last-status-change
         (`finished (if flycheck-current-errors
                        (let ((count (let-alist (flycheck-count-errors flycheck-current-errors)
                                       (+ (or .warning 0) (or .error 0)))))
                          right-icon-length)
                      right-icon-length))
         (`running  right-icon-length)
         (`no-checker  right-icon-length)
         (`not-checked 0)
         (`errored     right-icon-length)
         (`interrupted right-icon-length)
         (`suspicious  0)))))

(defun simple-mode-line-render (left right)
  "Return a string of `window-width' length containing LEFT, and RIGHT aligned respectively."
  (let* ((available-width (- (window-total-width) (length left) (calculate-icons-width))))
    (format (format "%%s %%%ds" available-width) left right)))

(defun insert-icon (type name &optional valign)
  "Insert an icon based on the TYPE and NAME and VALIGN optional."
  (or valign (setq valign -0.1))
  (funcall type name :height (/ all-the-icons-scale-factor 1.5) :v-adjust valign))

(defun custom-modeline-flycheck-status ()
  "Custom status for flycheck with icons."
  (let* ((text (pcase flycheck-last-status-change
                 (`finished (if flycheck-current-errors
                    (let ((count (let-alist (flycheck-count-errors flycheck-current-errors)
                                   (+ (or .warning 0) (or .error 0)))))
                       (format "%s %s" (insert-icon 'all-the-icons-faicon "bug") count))
                       (format "%s" (insert-icon 'all-the-icons-faicon "check"))))
                 (`running  (format "%s Running" (insert-icon 'all-the-icons-faicon "spinner" -0.15)))
                 (`no-checker  (format "%s No Checker" (insert-icon 'all-the-icons-material "warning" -0.15)))
                 (`not-checked "")
                 (`errored     (format "%s Error" (insert-icon 'all-the-icons-material "warning" -0.15)))
                 (`interrupted (format "%s Interrupted" (insert-icon 'all-the-icons-faicon "stop" -0.15)))
                 (`suspicious  ""))))
    (propertize text
                'help-echo "Show Flycheck Errors"
                'mouse-face '(:box 1)
                'local-map (make-mode-line-mouse-map
                            'mouse-1 (lambda () (interactive) (flycheck-list-errors))))))

(setq-default mode-line-format
  '((:eval (simple-mode-line-render
    ;; left
    (format-mode-line (list
     '((:eval
        (cond
         (buffer-read-only
          (format " %s"
                  (propertize (insert-icon 'all-the-icons-faicon "coffee")
                              'face '(:foreground "red"))))
         ((buffer-modified-p)
          (format " %s"
                  (propertize (insert-icon 'all-the-icons-faicon "chain-broken")
                              'face '(:foreground "orange")))))))
     " "
     '(:eval (propertize (insert-icon 'all-the-icons-icon-for-mode major-mode)))
     '(:eval (format " %s " (pretty-buffername)))
     "| %I L%l"))
    ;; right
    (format-mode-line (list
      '(:eval
        (format "%s %s %s"
                mode-name
                (if vc-mode
                    (let* ((noback (replace-regexp-in-string (format "^ %s" (vc-backend buffer-file-name)) " " vc-mode))
                           (face (cond ((string-match "^ -" noback) 'mode-line-vc)
                                       ((string-match "^ [:@]" noback) 'mode-line-vc-edit)
                                       ((string-match "^ [!\\?]" noback) 'mode-line-vc-modified)))
                           (icon (propertize (insert-icon 'all-the-icons-octicon "git-branch" -0.03))))
                      (format "%s %s" icon (substring noback 2)))
                  "")
                (custom-modeline-flycheck-status)))))))))

;; Quickrun
(use-package quickrun
  :ensure t
  :init
  (global-set-key (kbd "s-<return>") 'quickrun)
  :config
  (quickrun-add-command "typescript"
    '((:command . "ts-node")
      (:exec . ("%c %s")))
    :mode "typescript"
    :override t)
  )

;; Elm
(use-package elm-mode
  :ensure t
  :init
  (add-to-list 'company-backends 'company-elm))

;; Magit
(use-package magit :ensure t)

;; A hack for fixing projectile with ag/rg
;; Source: https://github.com/syohex/emacs-helm-ag/issues/283
(defun helm-projectile-ag (&optional options)
  "Helm version of projectile-ag."
  (interactive (if current-prefix-arg (list (read-string "option: " "" 'helm-ag--extra-options-history))))
  (if (require 'helm-ag nil  'noerror)
      (if (projectile-project-p)
          (let ((helm-ag-command-option options)
                (current-prefix-arg nil))
            (helm-do-ag (projectile-project-root) (car (projectile-parse-dirconfig-file))))
        (error "You're not in a project"))
    (error "helm-ag not available")))

;; Theme
(add-to-list 'custom-theme-load-path "~/.emacs.d/custom-themes/")

(defun set-dark-theme ()
  "Set the dark theme with some customization if needed."
  (interactive)
  (load-theme 'atom-one-dark t)
  (require 'color)
  (let ((bg (face-attribute 'default :background)))
    (custom-set-faces
     `(company-tooltip ((t (:inherit default :background ,(color-lighten-name bg 2)))))
     `(company-tooltip-annotation ((t (:foreground ,"#C678DD" :background ,(color-lighten-name bg 2)))))
     `(company-tooltip-annotation-selection ((t (:foreground ,"#C678DD"))))
     `(company-tooltip-align-annotations t)
     `(company-scrollbar-bg ((t (:background ,(color-lighten-name bg 10)))))
     `(company-scrollbar-fg ((t (:background ,(color-lighten-name bg 5)))))
     `(company-tooltip-selection ((t (:inherit font-lock-function-name-face))))
     `(company-tooltip-common-selection ((t (:inherit font-lock-function-name-face :foreground ,"#E5C07B"))))
     `(company-tooltip-common ((t (:inherit font-lock-constant-face :foreground ,"#E5C07B" :background ,(color-lighten-name bg 2)))))))
  (custom-set-faces
   '(default ((t (:inherit nil :stipple nil :foreground "#EAEDF3" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight thin :width normal))))
   '(helm-candidate-number ((t (:background "#f7cc62" :foreground "black"))))
   '(helm-ff-pipe ((t (:background "black" :foreground "#f7cc62"))))
   '(helm-ff-prefix ((t (:background "#f7cc62" :foreground "black"))))
   '(helm-header-line-left-margin ((t (:background "#f7cc62" :foreground "black"))))
   '(helm-match ((t (:foreground "white" :inverse-video nil))))
   '(helm-rg-preview-line-highlight ((t (:background "#46b866" :foreground "black"))))
   '(helm-selection ((t (:foreground "#f7cc62" :inverse-video t))))
   '(helm-source-header ((t (:foreground "white" :weight bold :height 1.0))))
   '(neo-dir-link-face ((t (:foreground "gray85"))))
   '(vertical-border ((t (:background "#161616" :foreground "#211C1C"))))
   '(window-divider ((t (:foreground "#211C1C"))))
   '(linum ((t (:inherit default :background nil :foreground "#5A5353" :strike-through nil :underline nil :slant normal :weight normal))))
   '(window-divider-first-pixel ((t (:foreground "#211C1C"))))))

(set-dark-theme)

;; Automatically generated
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(anzu-cons-mode-line-p nil)
 '(appt-disp-window-function (quote user-appt-display))
 '(company-idle-delay 0.1)
 '(company-require-match (quote never))
 '(flycheck-disabled-checkers (quote (javascript-jshint)))
 '(font-lock-maximum-decoration t)
 '(global-company-mode t)
 '(helm-M-x-fuzzy-match t t)
 '(helm-ag-base-command "rg --no-heading --ignore-case -M300")
 '(helm-ag-use-temp-buffer t)
 '(helm-autoresize-max-height 0)
 '(helm-autoresize-min-height 20)
 '(helm-buffers-fuzzy-matching t)
 '(helm-completion-in-region-fuzzy-match t)
 '(helm-echo-input-in-header-line t)
 '(helm-grep-ag-command "")
 '(helm-locate-fuzzy-match t)
 '(helm-mode t)
 '(helm-mode-fuzzy-match t)
 '(helm-move-to-line-cycle-in-source t)
 '(helm-split-window-inside-p t)
 '(magit-dispatch-arguments nil)
 '(magit-log-arguments (quote ("--graph" "--color" "--decorate" "-n32")))
 '(multi-term-program "/usr/local/bin/fish")
 '(neo-window-fixed-size nil)
 '(neo-window-width 20)
 '(package-selected-packages
   (quote
    (tuareg intero atom-one-dark-theme darkroom yasnippet-snippets json-mode gruvbox-theme hide-mode-line ranger shrink-path highlight-indent-guides dap-mode ace-jump indium multiple-cursors expand-region org-capture-pop-frame purescript-mode company-arduino all-the-icons-dired groovy-mode multi-term deft ace-jump-mode package-lint emacs-htmlize go-eldoc go-complete go-stacktracer go-mode helm-ag cargo org-autolist smartparens wrap-region lsp-javascript-typescript magit elm-mode lsp-symbol-outline outline-magic company-lsp web-mode tide quickrun org-bullets lsp-ui flycheck-rust flycheck-inline lsp-rust f lsp-mode rust-mode company diff-hl editorconfig general which-key helm use-package)))
 '(term-default-bg-color "#101723")
 '(vc-annotate-background "#282c34")
 '(vc-annotate-color-map
   (list
    (cons 20 "#98be65")
    (cons 40 "#b4be6c")
    (cons 60 "#d0be73")
    (cons 80 "#ECBE7B")
    (cons 100 "#e6ab6a")
    (cons 120 "#e09859")
    (cons 140 "#da8548")
    (cons 160 "#d38079")
    (cons 180 "#cc7cab")
    (cons 200 "#c678dd")
    (cons 220 "#d974b7")
    (cons 240 "#ec7091")
    (cons 260 "#ff6c6b")
    (cons 280 "#cf6162")
    (cons 300 "#9f585a")
    (cons 320 "#6f4e52")
    (cons 340 "#5B6268")
    (cons 360 "#5B6268")))
 '(vc-annotate-very-old-color nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(default ((t (:inherit nil :stipple nil :foreground "#EAEDF3" :inverse-video nil :box nil :strike-through nil :overline nil :underline nil :slant normal :weight thin :width normal))))
 '(bold ((t (:foreground "orange1" :weight extra-bold))))
 '(fixed-pitch ((t (:family "CodingFontTobi"))))
 '(fixed-pitch-serif ((t (:family "CodingFontTobi"))))
 '(font-lock-comment-delimiter-face ((t (:foreground "#71696A" :slant italic))))
 '(font-lock-comment-face ((t (:foreground "#71696A" :slant italic))))
 '(fringe ((t (:background nil))))
 '(helm-candidate-number ((t (:background "#f7cc62" :foreground "black"))))
 '(helm-ff-directory ((t (:foreground "OrangeRed1"))))
 '(helm-ff-executable ((t (:inherit font-lock-string-face))))
 '(helm-ff-pipe ((t (:background "black" :foreground "#f7cc62"))))
 '(helm-ff-prefix ((t (:background "#f7cc62" :foreground "black"))))
 '(helm-grep-finish ((t (:inherit font-lock-string-face))))
 '(helm-header-line-left-margin ((t (:background "#f7cc62" :foreground "black"))))
 '(helm-locate-finish ((t (:inherit font-lock-string-face))))
 '(helm-match ((t (:foreground "white" :inverse-video nil))))
 '(helm-moccur-buffer ((t (:inherit font-lock-string-face :underline t))))
 '(helm-prefarg ((t (:inherit font-lock-string-face))))
 '(helm-rg-active-arg-face ((t (:inherit font-lock-string-face))))
 '(helm-rg-file-match-face ((t (:inherit font-lock-string-face :underline t))))
 '(helm-rg-preview-line-highlight ((t (:background "#46b866" :foreground "black"))))
 '(helm-selection ((t (:foreground "#f7cc62" :inverse-video t))))
 '(helm-source-header ((t (:foreground "white" :weight bold :height 1.0))))
 '(helm-visible-mark ((t nil)))
 '(js2-function-param ((t (:foreground "#F18D73"))))
 '(linum ((t (:inherit default :background nil :foreground "#5A5353" :strike-through nil :underline nil :slant normal :weight normal))))
 '(neo-dir-link-face ((t (:foreground "gray85"))))
 '(neo-root-dir-face ((t (:background "#101723" :foreground "#8D8D84"))))
 '(term ((t (:inherit default :background "#101723"))))
 '(term-bold ((t (:background "#101723" :weight bold))))
 '(term-underline ((t (:background "#101723" :underline t))))
 '(tide-hl-identifier-face ((t (:inherit highlight :inverse-video t))))
 '(vertical-border ((t (:background "#161616" :foreground "#211C1C"))))
 '(window-divider ((t (:foreground "#211C1C"))))
 '(window-divider-first-pixel ((t (:foreground "#211C1C")))))
(put 'narrow-to-region 'disabled nil)
;; ## added by OPAM user-setup for emacs / base ## 56ab50dc8996d2bb95e7856a6eddb17b ## you can edit, but keep this line
(require 'opam-user-setup "~/.emacs.d/opam-user-setup.el")
;; ## end of OPAM user-setup addition for emacs / base ## keep this line
