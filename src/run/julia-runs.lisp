
(defpackage :run-julia
  (:use :common-lisp :alexandria :header-ffi :to-julia)
  (:export ffi-gl ffi-glu ffi-sdl ffi-acpi)
  (:documentation "Runs for producing julia code to load stuff.
 (currently not everything works!)"))

(in-package :run-julia)

(defun not-type(type) ;TODO this is lazy..
  (declare (ignore type))
  nil)

(defun default-select (code &key (not-type #'not-type))
  (destructuring-bind (&optional name first second &rest ignore) code
    (declare (ignore ignore))
    (case name
      (:typedef (not (or (and (listp second) (eql (car second) :struct))
			 (funcall not-type first))))
      (:struct  nil)
      (t        t))))

(defun ffi (&key include lib (lib-var lib)
	    (project-dir (error "don't know project directory"))
	    (where-file lib-var)
	    (where (format nil "~a/julia-src/autoffi/~a.j"
			   project-dir where-file))
	    (select #'default-select))
  "FFI to julia (explore a bit with `:select #'print`"
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

(defun ffi-gl (&key (project-dir (error "don't know project directory")))
  (ffi :include "GL/gl.h" :lib "libGL" :lib-var "gl"
       :project-dir project-dir
       :select 
       (lambda (code)
	 (unless (and (eql (car code) :define)
		      (stringp (cadr code))
		      (find (cadr code) ;TODO missing 
			    '("WIN32_LEAN_AND_MEAN" "APIENTRY" "APIENTRYP"
			      "GLAPIENTRYP" "GLAPI")
			    :test #'string=))
	   (default-select code)))))
(defun ffi-glu (&key (project-dir (error "don't know project directory")))
  (ffi :include "GL/glu.h" :lib "libGLU" :lib-var "glu" 
       :project-dir project-dir))
       
(defun ffi-sdl (&key (project-dir (error "don't know project directory")))
  "TODO doesn't work."
  (ffi :include "SDL/SDL.h" :lib "libSDL" :lib-var "sdl"
       :project-dir project-dir))

(defun ffi-acpi (&key (project-dir (error "don't know project directory")))
  "TODO unusably incomplete"
  (ffi :include "libacpi.h" :lib "libacpi" :lib-var "acpi"
       :project-dir project-dir))

(defun ffi-cairo (&key (project-dir (error "don't know project directory")))
  (ffi :include "cairo/cairo.h" :lib "libcairo" :lib-var "cairo"
       :project-dir project-dir))

;WARNING the path is absolute.
(let ((abs-path "/home/jasper/proj/common-lisp/parse-c-header"))
;  (ffi-acpi :project-dir abs-path)
;  (ffi-gl :project-dir abs-path)
;  (ffi-glu :project-dir abs-path)
  (ffi-cairo :project-dir abs-path))
