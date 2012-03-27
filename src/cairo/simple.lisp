(in-package :xcb.clx.demos)

;; Arc demo from cairographics.org/samples/
(defun cairo-arc (w h surface)
  (let* ((ctx (cairo:create-context surface))
         (size (min h w))
         (xc (/ w 2.0))
         (yc (/ h 2.0))
         (radius (- (/ size 2.0) (/ size 10.0)))
         (angle1 (* 45.0 (/ pi 180.0)))
         (angle2 (* 180.0 (/ pi 180.0))))
    (unwind-protect
         (cairo:with-context (ctx)
           (cairo:set-source-rgb 1 1 1)
           (cairo:paint)

           (cairo:set-source-rgb 0 0 0)
           (cairo:set-line-width 10.0)
           (cairo:arc xc yc radius angle1 angle2)
           (cairo:stroke)

           (cairo:set-source-rgba 1 0.2 0.2 0.6)
           (cairo:set-line-width 6.0)
           (cairo:arc xc yc 10.0 0 (* 2.0 pi))
           (cairo:fill-path)

           (cairo:arc xc yc radius angle1 angle1)
           (cairo:line-to xc yc)
           (cairo:arc xc yc radius angle2 angle2)
           (cairo:line-to xc yc)
           (cairo:stroke))
      (cairo:destroy ctx))))

(defun cairo-run (demo-name &key (screen 0) (w 300) (h 300))
  (let* ((display (open-display ""))
         (xwin (make-x-window display :screen screen
                                      :x 0 :y 0 :w w :h h)))
    (with-display display
      (map-window xwin)
      (display-force-output display))
    (let ((surface (cairo:create-xcb-surface xwin)))
      (unwind-protect
           (event-case (display :force-output-p t
                                :discard-p t)
             (:exposure (count)
               (when (= 0 count) (funcall demo-name w h surface)) nil)
             (:button-press () t)
             (:configure-notify (height width)
               (unless (and (= width w) (= height h))
                (setf w width)
                (setf h height)
                (cairo:xcb-surface-set-size surface w h)
                (funcall demo-name w h surface))
               nil)
             (:client-message (type data)
               (when (and (eq type :wm_protocols)
                          (= (elt data 0) (find-atom display :wm_delete_window)))
                 t)))
        (cairo:destroy surface)
        (destroy-window xwin)
        (close-display display)))))