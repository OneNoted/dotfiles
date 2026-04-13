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
      custom-file (expand-file-name "custom.el" doom-state-dir)
      projectile-project-search-path '(("~/Projects/" . 3)))

;;; UI and Appearance

;; Use the official Catppuccin theme package with the Mocha flavor.
(setq catppuccin-flavor 'mocha)

(setq doom-font (font-spec :family "JetBrainsMono Nerd Font")
      doom-theme 'catppuccin
      display-line-numbers-type t)

(defun my/dashboard-pacman-banner ()
  "Return the PacMan banner used by the Neovim dashboard."
  (propertize
   (mapconcat
    #'identity
    '(""
      "                      ██████                     "
      "                  ████▒▒▒▒▒▒████                 "
      "                ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒██               "
      "              ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██             "
      "            ██▒▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒               "
      "            ██▒▒▒▒▒▒  ▒▒▓▓▒▒▒▒▒▒  ▓▓▓▓           "
      "            ██▒▒▒▒▒▒  ▒▒▓▓▒▒▒▒▒▒  ▒▒▓▓           "
      "          ██▒▒▒▒▒▒▒▒▒▒    ▒▒▒▒▒▒▒▒    ██         "
      "          ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██         "
      "          ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██         "
      "          ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██         "
      "          ██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██         "
      "          ██▒▒██▒▒▒▒▒▒██▒▒▒▒▒▒▒▒██▒▒▒▒██         "
      "          ████  ██▒▒██  ██▒▒▒▒██  ██▒▒██         "
      "          ██      ██      ████      ████         "
      "                                                 "
      "")
    "\n")
   'face '+dashboard-banner))

;; Reuse the Neovim dashboard banner and suppress Doom's image splash so the
;; ASCII art is the only logo shown in terminal and GUI sessions.
(setq +dashboard-ascii-banner-fn #'my/dashboard-pacman-banner
      fancy-splash-image 'ignore)

;;; Editing Behavior

;; Keep general editor defaults here.

;;; Completion and Navigation

;; Keep non-language completion and search tuning here.

;;; Org Workflow

;; Keep capture, agenda, notes, and writing behavior here.

;;; Tools and Integrations

;; Keep external tooling and workflow integrations here.

(after! magit
  (setq magit-repository-directories projectile-project-search-path))

;;; Keybindings

;; Keep custom `map!' bindings here.

;;; Generated State

;; Keep Customize output out of this file so the handwritten config stays
;; readable. Emacs will write to `doom-state-dir'/custom.el instead.
(load custom-file 'noerror 'nomessage)
