;;; ob-snowflake.el --- Org Babel support for Snowflake CLI -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Roman Greschni

;; Author: Roman Greschni
;; Maintainer: Roman Greschni
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (org "9.5"))
;; Keywords: outlines, processes, tools, sql
;; URL: https://github.com/greshny/ob-snowflake
;; SPDX-License-Identifier: MIT

;;; Commentary:

;; Execute Org source blocks through the Snowflake CLI.
;;
;; #+begin_src snowflake :connection default :database EXAMPLE_DB :schema PUBLIC :results output
;; select current_user(), current_role(), current_warehouse();
;; #+end_src

;;; Code:

(require 'ob)
(require 'org)
(require 'subr-x)

(defgroup ob-snowflake nil
  "Org Babel support for Snowflake SQL via the snow CLI."
  :group 'org-babel)

(defcustom ob-snowflake-command "snow"
  "Snowflake CLI executable."
  :type 'string
  :group 'ob-snowflake)

(defcustom ob-snowflake-default-connection "default"
  "Default Snowflake CLI connection name."
  :type 'string
  :group 'ob-snowflake)

(defcustom ob-snowflake-default-format "TABLE"
  "Default Snowflake CLI output format.
Valid values are TABLE, JSON, JSON_EXT, and CSV.  Set to nil to let the
Snowflake CLI choose its default."
  :type '(choice (const :tag "Snowflake CLI default" nil)
                 (string :tag "Format"))
  :group 'ob-snowflake)

(defun ob-snowflake--param (name params)
  "Return string value for NAME from Org Babel PARAMS."
  (let ((value (cdr (assq name params))))
    (cond
     ((null value) nil)
     ((stringp value) value)
     ((symbolp value) (symbol-name value))
     ((numberp value) (number-to-string value))
     (t nil))))

(defun ob-snowflake--option (option value)
  "Return a shell-quoted OPTION VALUE pair, or nil when VALUE is nil."
  (when value
    (format "%s %s" option (shell-quote-argument value))))

(defun ob-snowflake--command (body params)
  "Build a `snow sql' command for BODY and Org Babel PARAMS."
  (let* ((connection (or (ob-snowflake--param :connection params)
                         ob-snowflake-default-connection))
         (format (or (ob-snowflake--param :format params)
                     ob-snowflake-default-format)))
    (string-join
     (delq nil
           (list (shell-quote-argument ob-snowflake-command)
                 "sql"
                 "--connection"
                 (shell-quote-argument connection)
                 (ob-snowflake--option "--role" (ob-snowflake--param :role params))
                 (ob-snowflake--option "--warehouse" (ob-snowflake--param :warehouse params))
                 (ob-snowflake--option "--database" (ob-snowflake--param :database params))
                 (ob-snowflake--option "--schema" (ob-snowflake--param :schema params))
                 (ob-snowflake--option "--format" format)
                 "-q"
                 (shell-quote-argument body)))
     " ")))

;;;###autoload
(defun org-babel-execute:snowflake (body params)
  "Execute BODY as Snowflake SQL via the Snowflake CLI.

Supported header arguments:

  :connection default      Snowflake CLI connection name.
  :role MY_ROLE            Override the configured role.
  :warehouse MY_WAREHOUSE  Override the configured warehouse.
  :database MY_DATABASE    Override the configured database.
  :schema PUBLIC           Override the configured schema.
  :format CSV              Override output format: TABLE, JSON, JSON_EXT, CSV."
  (org-babel-eval (ob-snowflake--command body params) ""))

(add-to-list 'org-src-lang-modes '("snowflake" . sql))

(provide 'ob-snowflake)
;;; ob-snowflake.el ends here
