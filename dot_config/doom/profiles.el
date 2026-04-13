;;; profiles.el -*- mode: emacs-lisp; -*-

((default
  ;; Keep Doom's bootloader and user config XDG-native so the profile runtime
  ;; lands in XDG data/cache/state rather than under EMACSDIR/.local.
  (user-emacs-directory . "~/.config/emacs/")
  (doom-user-dir . "~/.config/doom/")))
