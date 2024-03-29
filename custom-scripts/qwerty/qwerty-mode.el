;; qwerty-mode --- QWERTY Key Navigation
;;; Code:
(define-minor-mode qwerty-mode
  "Navigation in QWERTY"
  :lighter " qwerty"
  :keymap (let ((map (make-sparse-keymap)))
            ;; Movement
            (define-key map (kbd "C-j") 'next-line)
            (define-key map (kbd "C-k") 'previous-line)
            (define-key map (kbd "M-k") 'backward-paragraph)
            (define-key map (kbd "M-j") 'forward-paragraph)
            (define-key map (kbd "M-p") 'backward-paragraph)
            (define-key map (kbd "M-n") 'forward-paragraph)
            ;; Window Navigation
            (define-key map (kbd "C-c C-n") 'windmove-down)
            (define-key map (kbd "C-c C-p") 'windmove-up)
            (define-key map (kbd "C-c C-f") 'windmove-right)
            (define-key map (kbd "C-c C-b") 'windmove-left)
            (define-key map (kbd "C-c <down>") 'windmove-down)
            (define-key map (kbd "C-c <up>") 'windmove-up)
            (define-key map (kbd "C-c <right>") 'windmove-right)
            (define-key map (kbd "C-c <left>") 'windmove-left)
            map))

(define-globalized-minor-mode global-qwerty-mode qwerty-mode
  (lambda () (qwerty-mode 1)))

(provide 'qwerty-mode)
;;; qwerty-mode.el ends here
