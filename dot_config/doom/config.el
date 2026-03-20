;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; This is the main handwritten Doom config.
;;
;; Keep day-to-day behavior here. The other top-level files stay separate only
;; because Doom expects them:
;; - init.el: module selection
;; - packages.el: package declarations
;; - profiles.el: profile/XDG wiring

;;; Identity and Paths

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, and file templates. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

(setq org-directory "~/org/"
      custom-file (expand-file-name "custom.el" doom-state-dir))

;;; UI and Appearance

;; Uncomment and adjust when you want to pin fonts explicitly.
;; (setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))

(setq doom-theme 'doom-one
      display-line-numbers-type t)

;;; Editing Behavior

;; Keep general editor defaults here.

;;; Completion and Navigation

;; Keep non-language completion and search tuning here.

;;; Org Workflow

;; Keep capture, agenda, notes, and writing behavior here.

;;; Tools and Integrations

;; Keep external tooling and workflow integrations here.

;;; Keybindings

;; Keep custom `map!' bindings here.

;;; Generated State

;; Keep Customize output out of this file so the handwritten config stays
;; readable. Emacs will write to `doom-state-dir'/custom.el instead.
(load custom-file 'noerror 'nomessage)
