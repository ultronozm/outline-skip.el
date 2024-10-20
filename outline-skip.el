;;; outline-skip.el --- Skip certain outline headings  -*- lexical-binding: t; -*-

;; Copyright (C) 2024  Paul D. Nelson

;; Author: Paul D. Nelson <nelson.paul.david@gmail.com
;; Version: 0.1
;; URL: https://github.com/ultronozm/outline-skip.el
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience, tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a minor mode to make outline commands skip
;; over verbatim environments and comments, or whatever else.

;;; Code:

(defgroup outline-skip nil
  "Customization options for outline-skip mode."
  :group 'outline)

(defcustom outline-skip-commands
  '(outline-next-heading
    outline-previous-heading
    outline-up-heading
    outline-forward-same-level
    outline-backward-same-level)
  "List of outline commands to be advised."
  :type '(repeat function)
  :group 'outline-skip)

(defun outline-skip-check-default ()
  "Default function to determine whether to skip the heading."
  (let ((ppss (syntax-ppss)))
    (or (nth 3 ppss)  ; in string/verbatim
        (nth 4 ppss))))  ; in comment

(defcustom outline-skip-check-function #'outline-skip-check-default
  "Function to determine if point is in a region to be skipped.
Should return non-nil if current heading should be skipped."
  :type 'function
  :group 'outline-skip)

;;;###autoload
(define-minor-mode outline-skip-mode
  "Minor mode to make outline commands skip certain headings."
  :global nil
  (if outline-skip-mode
      (outline-skip-mode--enable)
    (outline-skip-mode--disable)))

(defun outline-skip-mode--enable ()
  "Enable advice for outline commands to skip specified regions."
  (dolist (cmd outline-skip-commands)
    (advice-add cmd :around #'outline-skip--advice)))

(defun outline-skip-mode--disable ()
  "Disable advice for outline commands."
  (dolist (cmd outline-skip-commands)
    (advice-remove cmd #'outline-skip--advice)))

(defcustom outline-skip-max-iterations 100
  "Maximum number of iterations for skipping regions in outline commands."
  :type 'integer
  :group 'outline-skip)

(defun outline-skip--advice (orig-fun &rest args)
  "Advice to make outline commands skip specified regions.
ORIG-FUN is the original function to be advised, ARGS are the arguments
passed to the function."
  (let ((n outline-skip-max-iterations))
    (apply orig-fun args)
    (while (and (funcall outline-skip-check-function) (> n 0))
      (setq n (1- n))
      (apply orig-fun args))
    (when (zerop n)
      (error "oops")
      (display-warning 'outline-skip
                       "Maximum iterations reached in outline-skip"))))

(provide 'outline-skip)
;;; outline-skip.el ends here
