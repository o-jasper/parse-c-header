
(defpackage :run-julia
  (:use :common-lisp :alexandria :header-ffi :to-julia)
  (:export ffi-gl)
  (:documentation "Runs for producing julia code to load stuff."))

(in-package :run-julia)

(defun not-type(type) ;TODO this is lazy..
  nil)

(defun default-select (code &key (not-type #'not-type))
  (destructuring-bind (&optional name first second &rest ignore) code
    (declare (ignore ignore))
    (case name
      (:typedef (not (or (and (listp second) (eql (car second) :struct))
			 (funcall not-type first))))
      (:struct  nil)
      (t        t))))

;TODO absolute directory sucks...
(defun ffi (&key include lib (lib-var lib)
	    (src-dir "/home/jasper/proj/common-lisp/parse-c-header/src/run/")
	    (where-file lib-var)
	    (where (format nil "~a/../julia-src/autogenerated/~a.j" 
			   src-dir where-file))
	    (select #'default-select))
  "FFI to julia (explore a bit with `:select #'print`)"
  (with-open-file (stream (print where)
			  :direction :output :if-exists :supersede 
			  :if-does-not-exist :create)
    (format stream "#Autogenerated, hopefully stays that way!~%")
    (format stream "~a = dlopen(\"~a\")~2%" lib-var lib)
    (let ((*string-conv* #'string-downcase))
      (header-ffi include (lambda (code)
			    (when (funcall select code)
			      (to-julia code
					:dlopen-lib lib-var :stream stream)))
		  :defines-p t))))

;TODO needed modifications. Figure out how to apply them..
(defun ffi-gl()
  (ffi :include "GL/gl.h" :lib "libGL" :lib-var "lib_gl"
       :select 
       (lambda (code)
	 (unless (and (eql (car code) :define)
		      (stringp (cadr code))
		      (find (cadr code) ;TODO missing 
			    '("WIN32_LEAN_AND_MEAN" "APIENTRY" "APIENTRYP"
			      "GLAPIENTRYP" "GLAPI")
			    :test #'string=))
	   (default-select code)))))
(defun ffi-glu()
  (ffi :include "GL/glu.h" :lib "libGLU" :lib-var "lib_glu"))

(defun ffi-sdl ()
  "TODO doesn't work."
  (ffi :include "SDL/SDL.h" :lib "libSDL" :lib-var "lib_sdl"))

(defun ffi-acpi ()
  "TODO unusably incomplete"
  (ffi :include "libacpi.h" :lib "libacpi" :lib-var "lib_acpi"))

;(ffi-acpi)
;(ffi-gl)
;(ffi-glu)
