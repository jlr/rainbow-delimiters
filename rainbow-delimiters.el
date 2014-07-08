;;; rainbow-delimiters.el --- Highlight nested parens, brackets, braces a different color at each depth.

;; Copyright (C) 2010-2013 Jeremy Rayman.
;; Author: Jeremy Rayman <opensource@jeremyrayman.com>
;; Maintainer: Jeremy Rayman <opensource@jeremyrayman.com>
;; Created: 2010-09-02
;; Version: 1.3.6
;; Keywords: faces, convenience, lisp, matching, tools, rainbow, rainbow parentheses, rainbow parens
;; EmacsWiki: http://www.emacswiki.org/emacs/RainbowDelimiters
;; Github: http://github.com/jlr/rainbow-delimiters
;; URL: http://github.com/jlr/rainbow-delimiters/raw/master/rainbow-delimiters.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;;
;; Rainbow-delimiters is a “rainbow parentheses”-like mode which highlights
;; parentheses, brackets, and braces according to their depth. Each
;; successive level is highlighted in a different color. This makes it easy
;; to spot matching delimiters, orient yourself in the code, and tell which
;; statements are at a given level.
;;
;; Great care has been taken to make this mode FAST. You shouldn't see
;; any discernible change in scrolling or editing speed while using it,
;; even in delimiter-rich languages like Clojure, Lisp, and Scheme.
;;
;; Default colors are subtle, with the philosophy that syntax highlighting
;; shouldn't be visually intrusive. Color schemes are always a matter of
;; taste.  If you take the time to design a new color scheme, please share
;; (even a simple list of colors works) on the EmacsWiki page or via github.
;; EmacsWiki: http://www.emacswiki.org/emacs/RainbowDelimiters
;; Github: http://github.com/jlr/rainbow-delimiters


;;; Installation:

;; 1. Place rainbow-delimiters.el on your emacs load-path.
;;
;; 2. Compile the file (necessary for speed):
;; M-x byte-compile-file <location of rainbow-delimiters.el>
;;
;; 3. Add the following to your dot-emacs/init file:
;; (require 'rainbow-delimiters)
;;
;; 4. Activate the mode in your init file.
;;    You can choose to enable it only in certain modes, or Emacs-wide:
;;
;; - To enable it only in certain modes, add lines like the following:
;; (add-hook 'clojure-mode-hook 'rainbow-delimiters-mode)
;;
;; - To enable it in all programming-related emacs modes (Emacs 24+):
;; (add-hook 'prog-mode-hook 'rainbow-delimiters-mode)
;;
;; - To activate the mode globally, add to your init file:
;; (global-rainbow-delimiters-mode)
;;
;; - To temporarily activate rainbow-delimiters mode in an open buffer:
;; M-x rainbow-delimiters-mode
;;
;; - To toggle global-rainbow-delimiters-mode:
;; M-x global-rainbow-delimiters-mode

;;; Customization:

;; To customize various options, including the color scheme:
;; M-x customize-group rainbow-delimiters
;;
;; deftheme / color-theme.el users:
;; You can specify custom colors by adding the appropriate faces to your theme.
;; - Faces take the form of:
;;   'rainbow-delimiters-depth-#-face' with # being the depth.
;;   Depth begins at 1, the outermost color.
;;   Faces exist for depths 1-9.
;; - The unmatched delimiter face (normally colored red) is:
;;   'rainbow-delimiters-unmatched-face'


;;; Change Log:

;; 1.0 - Initial release.
;; 1.1 - Stop tracking each delimiter's depth independently.
;;       This had lead to confusing results when viewing clojure
;;       code. Instead, just color based on current nesting inside
;;       all delimiters combined.
;;     - Added 'all-delimiters' faces to apply a color scheme to
;;       all delimiters at once. Other faces inherit from this group.
;; 1.1.1 - Change color scheme to a lighter, more subtle style.
;; 1.1.2: (2011-03-25)
;;  - Add an unmatched-delimiter face and correct problem with
;;    coloring of text following unmatched closing delims.
;; 1.2: (2011-03-28)
;;  - Unify delimiter faces: all delimiter types now use the same depth
;;    faces, of form 'rainbow-delimiters-depth-#-face'.
;; 1.2.1: (2011-03-29)
;;  - Conform to ELPA conventions.
;; 1.3: (2011-05-24)
;;  - Add separate color schemes for light and dark background modes.
;;  - Checkboxes to enable/disable highlighting for each delimiter type.
;;  - Improvements to Customize interface.
;;  - Infinite depth support by cycling through defined faces repeatedly.
;;  - Documentation changes.
;; 1.3.1 (2011-05-25)
;;  - Light color theme appears entirely grey on SRGB monitors. Revert to
;;    old color theme until a nicer light background theme can be added.
;;  - Correct typo in the installation step for users of dark backgrounds.
;; 1.3.2 (2011-10-14)
;;  - Add 'global-rainbow-delimiters-mode'.
;;  - Respect syntax of current buffer major-mode so delimiters
;;    highlight correctly in non-lisp languages.
;; 1.3.3 (2011-11-25)
;;  - Backwards compatibility with Emacs versions prior to 23.2.
;;    Defines "with-silent-modifications" if undefined.
;; 1.3.4 (2012-04-27)
;;  - Further optimize highlighting speed. Benchmarks show 2x improvement.
;;  - Color scheme for light backgrounds.
;;  - Eliminate bottleneck seen in certain large files.
;;    A large file which revealed this bottleneck now highlights ~40x faster.
;;  - Correct broken/incorrect highlighting reported in certain languages.

;;; TODO:

;; - Add support for independent depth tracking of each delimiter type
;;   for users of C-like languages.
;; - Python style - increase depth with each new indentation.
;; - Add support for nested tags (XML, HTML)
;; - Set up proper example defthemes for rainbow-delimiters faces.
;; - Intelligent support for other languages: Ruby, LaTeX tags, et al.

;;; Issues:

;; - Rainbow-delimiters mode does not appear to change the color of
;;   delimiters when Org-mode is also enabled.


;;; Code:

;; Note: some of the functions in this file have been inlined for speed.
;; Inlining functions can cause problems with debugging. To debug these
;; functions more easily, change defsubst -> defun.
;; http://www.gnu.org/s/emacs/manual/html_node/elisp/Compilation-Tips.html

;;; Customize interface:

(defgroup rainbow-delimiters nil
  "Highlight nested parentheses, brackets, and braces according to their depth."
  :prefix "rainbow-delimiters-"
  :link '(url-link :tag "Website for rainbow-delimiters (EmacsWiki)"
                   "http://www.emacswiki.org/emacs/RainbowDelimiters")
  :group 'applications)

(defgroup rainbow-delimiters-faces nil
  "Faces for successively nested pairs of delimiters.

When depth exceeds innermost defined face, colors cycle back through."
  :tag "Color Scheme"
  :group 'rainbow-delimiters
  :link '(custom-group-link "rainbow-delimiters")
  :link '(custom-group-link :tag "Toggle Delimiters" "rainbow-delimiters-toggle-delimiter-highlighting")
  :prefix 'rainbow-delimiters-faces-)

;; Choose which delimiters you want to highlight in your preferred language:

(defgroup rainbow-delimiters-toggle-delimiter-highlighting nil
  "Choose which delimiters to highlight."
  :tag "Toggle Delimiters"
  :group 'rainbow-delimiters
  :link '(custom-group-link "rainbow-delimiters")
  :link '(custom-group-link :tag "Color Scheme" "rainbow-delimiters-faces"))

(defcustom rainbow-delimiters-highlight-parens-p t
  "Enable highlighting of nested parentheses -- ().

Non-nil (default) enables highlighting of parentheses.
Nil disables parentheses highlighting."
  :tag "Highlight Parentheses?"
  :type 'boolean
  :group 'rainbow-delimiters-toggle-delimiter-highlighting)

(defcustom rainbow-delimiters-highlight-brackets-p t
  "Enable highlighting of nested brackets -- [].

Non-nil (default) enables highlighting of brackets.
Nil disables bracket highlighting."
  :tag "Highlight Brackets?"
  :type 'boolean
  :group 'rainbow-delimiters-toggle-delimiter-highlighting)

(defcustom rainbow-delimiters-highlight-braces-p t
  "Enable highlighting of nested braces -- {}.

Non-nil (default) enables highlighting of braces.
Nil disables brace highlighting."
  :tag "Highlight Braces?"
  :type 'boolean
  :group 'rainbow-delimiters-toggle-delimiter-highlighting)


;;; Faces:

;; Unmatched delimiter face:
(defface rainbow-delimiters-unmatched-face
  '((((background light)) (:foreground "#88090B"))
    (((background dark)) (:foreground "#88090B")))
  "Face to highlight unmatched closing delimiters in."
  :group 'rainbow-delimiters-faces)

;; Mismatched delimiter face:
(defface rainbow-delimiters-mismatched-face
  '((((background light)) (:foreground "#88090B"))
    (((background dark)) (:foreground "#88090B")))
  "Face to highlight mismatched closing delimiters in."
  :group 'rainbow-delimiters-faces)

;; Faces for highlighting delimiters by nested level:
(defface rainbow-delimiters-depth-1-face
  '((((background light)) (:foreground "#707183"))
    (((background dark)) (:foreground "grey55")))
  "Nested delimiters face, depth 1 - outermost set."
  :tag "Rainbow Delimiters Depth 1 Face -- OUTERMOST"
  :group 'rainbow-delimiters-faces)

(defface rainbow-delimiters-depth-2-face
  '((((background light)) (:foreground "#7388d6"))
    (((background dark)) (:foreground "#93a8c6")))
  "Nested delimiters face, depth 2."
  :group 'rainbow-delimiters-faces)

(defface rainbow-delimiters-depth-3-face
  '((((background light)) (:foreground "#909183"))
    (((background dark)) (:foreground "#b0b1a3")))
  "Nested delimiters face, depth 3."
  :group 'rainbow-delimiters-faces)

(defface rainbow-delimiters-depth-4-face
  '((((background light)) (:foreground "#709870"))
    (((background dark)) (:foreground "#97b098")))
  "Nested delimiters face, depth 4."
  :group 'rainbow-delimiters-faces)

(defface rainbow-delimiters-depth-5-face
  '((((background light)) (:foreground "#907373"))
    (((background dark)) (:foreground "#aebed8")))
  "Nested delimiters face, depth 5."
  :group 'rainbow-delimiters-faces)

(defface rainbow-delimiters-depth-6-face
  '((((background light)) (:foreground "#6276ba"))
    (((background dark)) (:foreground "#b0b0b3")))
  "Nested delimiters face, depth 6."
  :group 'rainbow-delimiters-faces)

(defface rainbow-delimiters-depth-7-face
  '((((background light)) (:foreground "#858580"))
    (((background dark)) (:foreground "#90a890")))
  "Nested delimiters face, depth 7."
  :group 'rainbow-delimiters-faces)

(defface rainbow-delimiters-depth-8-face
  '((((background light)) (:foreground "#80a880"))
    (((background dark)) (:foreground "#a2b6da")))
  "Nested delimiters face, depth 8."
  :group 'rainbow-delimiters-faces)

(defface rainbow-delimiters-depth-9-face
  '((((background light)) (:foreground "#887070"))
    (((background dark)) (:foreground "#9cb6ad")))
  "Nested delimiters face, depth 9."
  :group 'rainbow-delimiters-faces)

;;; Faces 10+:
;; NOTE: Currently unused. Additional faces for depths 9+ can be added on request.

(defconst rainbow-delimiters-max-face-count 9
  "Number of faces defined for highlighting delimiter levels.

Determines depth at which to cycle through faces again.")

(defvar rainbow-delimiters-outermost-only-face-count 0
  "Number of faces to be used only for N outermost delimiter levels.

This should be smaller than `rainbow-delimiters-max-face-count'.")

;;; Face utility functions

(defsubst rainbow-delimiters-depth-face (depth)
  "Return face name for DEPTH as a symbol 'rainbow-delimiters-depth-DEPTH-face'.

For example: `rainbow-delimiters-depth-1-face'."
  (intern-soft
   (concat "rainbow-delimiters-depth-"
           (number-to-string
            (or
             ;; Our nesting depth has a face defined for it.
             (and (<= depth rainbow-delimiters-max-face-count)
                  depth)
             ;; Deeper than # of defined faces; cycle back through to
             ;; `rainbow-delimiters-outermost-only-face-count' + 1.
             ;; Return face # that corresponds to current nesting level.
             (+ 1 rainbow-delimiters-outermost-only-face-count
                (mod (- depth rainbow-delimiters-max-face-count 1)
                     (- rainbow-delimiters-max-face-count
                        rainbow-delimiters-outermost-only-face-count)))))
           "-face")))

;;; Parse partial sexp cache

;; If the block inside the delimiters is too big (where "too big" is
;; in some way related to `jit-lock-chunk-size'), `syntax-ppss' will
;; for some reason return wrong depth. Is it because we're misusing
;; it? Is it because it's buggy? Nobody knows. But users do notice it,
;; and have reported it as a bug. Hence this workaround: don't use
;; `syntax-ppss' at all, use the low-level primitive instead. However,
;; naively replacing `syntax-ppss' with `parse-partial-sexp' slows
;; down the delimiter highlighting noticeably in big files. Therefore,
;; we build a simple cache around it. This brings the speed to around
;; what it used to be, while fixing the bug. See issue #25.

(defvar rainbow-delimiters-parse-partial-sexp-cache nil
  "Cache of the last `parse-partial-sexp' call.

It's a list of conses, where car is the position for which `parse-partial-sexp'
was called and cdr is the result of the call.
The list is ordered descending by car.")
(make-variable-buffer-local 'rainbow-delimiters-parse-partial-sexp-cache)

(defconst rainbow-delimiters-parse-partial-sexp-cache-max-span 20000)

(defun rainbow-delimiters-syntax-ppss-flush-cache (beg _end)
  "Flush the `parse-partial-sexp' cache starting from position BEG."
  (let ((it rainbow-delimiters-parse-partial-sexp-cache))
    (while (and it (>= (caar it) beg))
      (setq it (cdr it)))
    (setq rainbow-delimiters-parse-partial-sexp-cache it)))

(defsubst rainbow-delimiters-syntax-ppss-run (from to oldstate cache-nearest-after)
  "Run `parse-partial-sexp' from FROM to TO starting with state OLDSTATE.

CACHE-NEAREST-AFTER should be a list of cache entries starting at the first
entry after TO, or nil if there's no such entry.
Intermediate `parse-partial-sexp' results are added to the cache."
  (if (= from to)
      (parse-partial-sexp from to nil nil oldstate)
    (while (< from to)
      (let ((newpos (min to (+ from rainbow-delimiters-parse-partial-sexp-cache-max-span))))
        (let ((state (parse-partial-sexp from newpos nil nil oldstate)))
          (if (/= newpos to)
              (if cache-nearest-after
                  (push (cons newpos state) (cdr cache-nearest-after))
                (push (cons newpos state) rainbow-delimiters-parse-partial-sexp-cache)))
          (setq oldstate state
                from newpos))))
    oldstate))

(defsubst rainbow-delimiters-syntax-ppss (pos)
  "Parse-Partial-Sexp State at POS, defaulting to point.

The returned value is the same as that of `parse-partial-sexp' from
`point-min' to POS, except that positions 2 and 6 cannot be relied
upon.

This is essentialy `syntax-ppss', only specific to rainbow-delimiters
to work around a bug."
  (save-excursion
    (let ((it rainbow-delimiters-parse-partial-sexp-cache)
          (prev nil))
      (while (and it (>= (caar it) pos))
        (setq prev it)
        (setq it (cdr it)))
      (let* ((nearest-after (if (consp prev) prev nil))
             (nearest-before (if (consp it) (car it) it))
             (nearest-before-pos (if nearest-before (car nearest-before) (point-min)))
             (nearest-before-data (if nearest-before (cdr nearest-before) nil)))
        (rainbow-delimiters-syntax-ppss-run nearest-before-pos pos nearest-before-data nearest-after)))))

;;; Nesting level

(defvar rainbow-delimiters-syntax-table nil
  "Syntax table (inherited from `major-mode''s) which uses all delimiters.

When `rainbow-delimiters-mode' is first activated, it sets this variable and
the other rainbow-delimiters specific syntax tables based on the current
`major-mode'.
The syntax table is constructed by the function
`rainbow-delimiters-make-syntax-table'.")

;; syntax-table: used with syntax-ppss for determining current depth.
(defun rainbow-delimiters-make-syntax-table (syntax-table)
  "Inherit SYNTAX-TABLE and add delimiters intended to be highlighted by mode."
  (let ((table (copy-syntax-table syntax-table)))
    (modify-syntax-entry ?\( "()  " table)
    (modify-syntax-entry ?\) ")(  " table)
    (modify-syntax-entry ?\[ "(]" table)
    (modify-syntax-entry ?\] ")[" table)
    (modify-syntax-entry ?\{ "(}" table)
    (modify-syntax-entry ?\} "){" table)
    table))

(defsubst rainbow-delimiters-depth (loc)
  "Return # of nested levels of parens, brackets, braces LOC is inside of."
  (let ((depth
         (with-syntax-table rainbow-delimiters-syntax-table
           (car (rainbow-delimiters-syntax-ppss loc)))))
    (if (>= depth 0)
        depth
      0))) ; ignore negative depths created by unmatched closing parens.


;;; Text properties

;; Backwards compatibility: Emacs < v23.2 lack macro 'with-silent-modifications'.
(eval-and-compile
  (unless (fboundp 'with-silent-modifications)
    (defmacro with-silent-modifications (&rest body)
      "Defined by rainbow-delimiters.el for backwards compatibility with Emacs < 23.2.
 Execute BODY, pretending it does not modify the buffer.
If BODY performs real modifications to the buffer's text, other
than cosmetic ones, undo data may become corrupted.

This macro will run BODY normally, but doesn't count its buffer
modifications as being buffer modifications.  This affects things
like buffer-modified-p, checking whether the file is locked by
someone else, running buffer modification hooks, and other things
of that nature.

Typically used around modifications of text-properties which do
not really affect the buffer's content."
      (declare (debug t) (indent 0))
      (let ((modified (make-symbol "modified")))
        `(let* ((,modified (buffer-modified-p))
                (buffer-undo-list t)
                (inhibit-read-only t)
                (inhibit-modification-hooks t)
                deactivate-mark
                ;; Avoid setting and removing file locks and checking
                ;; buffer's uptodate-ness w.r.t the underlying file.
                buffer-file-name
                buffer-file-truename)
           (unwind-protect
               (progn
                 ,@body)
             (unless ,modified
               (restore-buffer-modified-p nil))))))))

(defsubst rainbow-delimiters-propertize-delimiter (loc depth match)
  "Highlight a single delimiter at LOC according to DEPTH and MATCH.

LOC is the location of the character to add text properties to.
DEPTH is the nested depth at LOC, which determines the face to use.

Sets text properties:
`font-lock-face' to the appropriate delimiter face.
`rear-nonsticky' to prevent color from bleeding into subsequent characters typed by the user."
  (with-silent-modifications
    (let ((delim-face (if (<= depth 0)
                          'rainbow-delimiters-unmatched-face
                        (if match
                            (rainbow-delimiters-depth-face depth)
                          'rainbow-delimiters-mismatched-face))))
      ;; (when (eq depth -1) (message "Unmatched delimiter at char %s." loc))
      (add-text-properties loc (1+ loc)
                           `(font-lock-face ,delim-face
                             rear-nonsticky t)))))


(defsubst rainbow-delimiters-unpropertize-delimiter (loc)
  "Remove text properties set by rainbow-delimiters mode from char at LOC."
  (with-silent-modifications
    (remove-text-properties loc (1+ loc)
                            '(font-lock-face nil
                              rear-nonsticky nil))))

(defvar rainbow-delimiters-escaped-char-predicate nil)
(make-variable-buffer-local 'rainbow-delimiters-escaped-char-predicate)

(defvar rainbow-delimiters-escaped-char-predicate-list
  '((emacs-lisp-mode . rainbow-delimiters-escaped-char-predicate-emacs-lisp)
    (inferior-emacs-lisp-mode . rainbow-delimiters-escaped-char-predicate-emacs-lisp)
    (lisp-mode . rainbow-delimiters-escaped-char-predicate-lisp)
    (scheme-mode . rainbow-delimiters-escaped-char-predicate-lisp)
    (clojure-mode . rainbow-delimiters-escaped-char-predicate-lisp)
    (inferior-scheme-mode . rainbow-delimiters-escaped-char-predicate-lisp)
    ))

(defun rainbow-delimiters-escaped-char-predicate-emacs-lisp (loc)
  "Non-nil iff the character at LOC is escaped as per Emacs Lisp rules."
  (or (and (eq (char-before loc) ?\?) ; e.g. ?) - deprecated, but people use it
           (not (and (eq (char-before (1- loc)) ?\\) ; special case: ignore ?\?
                     (eq (char-before (- loc 2)) ?\?))))
      (and (eq (char-before loc) ?\\) ; escaped char, e.g. ?\) - not counted
           (eq (char-before (1- loc)) ?\?))))

(defun rainbow-delimiters-escaped-char-predicate-lisp (loc)
  "Non-nil iff the character at LOC is escaped as per some generic Lisp rules."
  (eq (char-before loc) ?\\))

(defsubst rainbow-delimiters-char-ineligible-p (loc)
  "Return t if char at LOC should be skipped, e.g. if inside a comment.

Returns t if char at loc meets one of the following conditions:
- Inside a string.
- Inside a comment.
- Is an escaped char, e.g. ?\)"
  (let ((parse-state (rainbow-delimiters-syntax-ppss loc)))
    (or
     (nth 3 parse-state)                ; inside string?
     (nth 4 parse-state)                ; inside comment?
     (and rainbow-delimiters-escaped-char-predicate
          (funcall rainbow-delimiters-escaped-char-predicate loc)))))


(defsubst rainbow-delimiters-apply-color (delim depth match loc)
  "Apply color for DEPTH and MATCH to DELIM at LOC following user settings.

DELIM is a string specifying delimiter type.
DEPTH is the delimiter depth, or corresponding face # if colors are repeating.
LOC is location of character (delimiter) to be colorized."
  (and
   ;; Ensure user has enabled highlighting of this delimiter type.
   (symbol-value (intern-soft
                  (concat "rainbow-delimiters-highlight-" delim "s-p")))
   (rainbow-delimiters-propertize-delimiter loc
                                            depth
                                            match)))


;;; JIT-Lock functionality

;; Used to skip delimiter-by-delimiter `rainbow-delimiters-propertize-region'.
(defconst rainbow-delimiters-delim-regex "\\(\(\\|\)\\|\\[\\|\\]\\|\{\\|\}\\)"
  "Regex matching all opening and closing delimiters the mode highlights.")

;; main function called by jit-lock:
(defsubst rainbow-delimiters-propertize-region (start end)
  "Highlight delimiters in region between START and END.

Used by jit-lock for dynamic highlighting."
  (setq rainbow-delimiters-escaped-char-predicate
        (cdr (assoc major-mode rainbow-delimiters-escaped-char-predicate-list)))
  (save-excursion
    (goto-char start)
    ;; START can be anywhere in buffer; determine the nesting depth at START loc
    (let ((depth (rainbow-delimiters-depth start))
          (delimiter-stack nil))
      (while (and (< (point) end)
                  (re-search-forward rainbow-delimiters-delim-regex end t))
        (backward-char) ; re-search-forward places point after delim; go back.
        (unless (rainbow-delimiters-char-ineligible-p (point))
          (let ((delim (char-after (point)))
                (match t))
            (if (or (eq ?\( delim) (eq ?\[ delim) (eq ?\{ delim))
                (setq delimiter-stack (cons delim delimiter-stack))
              (let ((old-delimiter (first delimiter-stack)))
                (when (or (and (eq ?\( old-delimiter)
                               (not (eq ?\) delim)))
                          (and (eq ?\[ old-delimiter)
                               (not (eq ?\] delim)))
                          (and (eq ?\{ old-delimiter)
                               (not (eq ?\} delim))))
                  (setq match nil)))
              (setq delimiter-stack (rest delimiter-stack)))


            (cond ((eq ?\( delim)       ; (
                   (setq depth (1+ depth))
                   (rainbow-delimiters-apply-color "paren" depth match (point)))
                  ((eq ?\) delim)       ; )
                   (rainbow-delimiters-apply-color "paren" depth match (point))
                   (setq depth (or (and (<= depth 0) 0) ; unmatched paren
                                   (1- depth))))
                  ((eq ?\[ delim)       ; [
                   (setq depth (1+ depth))
                   (rainbow-delimiters-apply-color "bracket" depth match (point)))
                  ((eq ?\] delim)       ; ]
                   (rainbow-delimiters-apply-color "bracket" depth match (point))
                   (setq depth (or (and (<= depth 0) 0) ; unmatched bracket
                                   (1- depth))))
                  ((eq ?\{ delim)       ; {
                   (setq depth (1+ depth))
                   (rainbow-delimiters-apply-color "brace" depth match (point)))
                  ((eq ?\} delim)       ; }
                   (rainbow-delimiters-apply-color "brace" depth match (point))
                   (setq depth (or (and (<= depth 0) 0) ; unmatched brace
                                   (1- depth)))))))
        ;; move past delimiter so re-search-forward doesn't pick it up again
        (forward-char)))))

(defun rainbow-delimiters-unpropertize-region (start end)
  "Remove highlighting from delimiters between START and END."
  (save-excursion
    (goto-char start)
    (while (and (< (point) end)
                (re-search-forward rainbow-delimiters-delim-regex end t))
      ;; re-search-forward places point 1 further than the delim matched:
      (rainbow-delimiters-unpropertize-delimiter (1- (point))))))


;;; Minor mode:

(defun rainbow-delimiters-mode-turn-on ()
  "Set up `rainbow-delimiters-mode'."
  ;; Flush the ppss cache now in case there's something left in there.
  (setq rainbow-delimiters-parse-partial-sexp-cache nil)
  (add-hook 'before-change-functions 'rainbow-delimiters-syntax-ppss-flush-cache t t)
  (add-hook 'change-major-mode-hook 'rainbow-delimiters-mode-turn-off nil t)
  (jit-lock-register 'rainbow-delimiters-propertize-region t)
  ;; Create necessary syntax tables inheriting from current major-mode.
  (set (make-local-variable 'rainbow-delimiters-syntax-table)
       (rainbow-delimiters-make-syntax-table (syntax-table))))

(defun rainbow-delimiters-mode-turn-off ()
  "Tear down `rainbow-delimiters-mode'."
  (kill-local-variable 'rainbow-delimiters-syntax-table)
  (rainbow-delimiters-unpropertize-region (point-min) (point-max))
  (jit-lock-unregister 'rainbow-delimiters-propertize-region)
  (remove-hook 'change-major-mode-hook 'rainbow-delimiters-mode-turn-off t)
  (remove-hook 'before-change-functions 'rainbow-delimiters-syntax-ppss-flush-cache t))

;;;###autoload
(define-minor-mode rainbow-delimiters-mode
  "Highlight nested parentheses, brackets, and braces according to their depth."
  nil "" nil ; No modeline lighter - it's already obvious when the mode is on.
  (if rainbow-delimiters-mode
      (rainbow-delimiters-mode-turn-on)
    (rainbow-delimiters-mode-turn-off)))

;;;###autoload
(defun rainbow-delimiters-mode-enable ()
  "Enable `rainbow-delimiters-mode'."
  (rainbow-delimiters-mode 1))

;;;###autoload
(defun rainbow-delimiters-mode-disable ()
  "Disable `rainbow-delimiters-mode'."
  (rainbow-delimiters-mode 0))

;;;###autoload
(define-globalized-minor-mode global-rainbow-delimiters-mode
  rainbow-delimiters-mode rainbow-delimiters-mode-enable)

(provide 'rainbow-delimiters)

;;; rainbow-delimiters.el ends here
