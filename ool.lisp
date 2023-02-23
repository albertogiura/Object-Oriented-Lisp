;;;; -*- Mode: Lisp -*-
;;;; ool.lisp

;;;; Giura Alberto 866144

;;; HASH-TABLE A SUPPORTO DI DEF-CLASS
(defparameter *classes-specs* (make-hash-table))

(defun add-class-spec (name class-spec)
  (setf (gethash name *classes-specs*) class-spec))

(defun get-class-spec (name)
  (gethash name *classes-specs*))


;;; DEF-CLASS
(defun def-class (class-name parents &rest slot-value)
  (cond ((null class-name)
	 (error "Class-name non puo' essere nullo."))
	((not (symbolp class-name))
	 (error "Class-name non e' un simbolo."))
	((not (listp parents))
	 (error "Parents non e' una lista."))
	((not (check-parents parents))
	 (error "(Almeno) uno dei parents indicati non e' stato
definito."))
	((not (null (member class-name parents)))
	 (error "Class-name non puo' essere uguale ad un parent."))
	((not (listp slot-value))
	 (error "Le coppie campo-valore devono essere una lista."))
	((oddp (list-length slot-value))
	 (error "Il numero degli argomenti non e' bilanciato."))
	((has-duplicates slot-value)
	 (error "Sono presenti uno o piu' slot-name/method-name
duplicati."))
	((not (null (get-class-spec class-name)))
	 (remhash class-name *classes-specs*)
	 (add-class-spec class-name
			 (list parents
			       (inherit-from-p
				(build-pairs slot-value) parents)))
	 class-name)
	(t (add-class-spec class-name
			   (list parents
				 (inherit-from-p
				  (build-pairs slot-value) parents)))
	   class-name)))


;;; IS-CLASS
(defun is-class (class-name)
  (if (symbolp class-name)
      (if (get-class-spec class-name)
	  T
	NIL)
    NIL))


;;; CHECK-PARENTS
(defun check-parents (parents)
  (if (null parents)
      T
    (if (is-class (car parents))
	(check-parents (cdr parents))
      NIL)))


;;; INHERIT-FROM-P
(defun inherit-from-p (s-input-l parents-l)
  (if (null parents-l)
      s-input-l
    (inherit-from-p
     (slots-to-be-inherited s-input-l
			    (cadr (get-class-spec (car parents-l)))
			    s-input-l)
     (cdr parents-l))))


;;; SLOTS-TO-BE-INHERITED
(defun slots-to-be-inherited (s-input-l s-parent-l c-input-l)
  (if (null s-input-l)
      (append c-input-l s-parent-l)
    (if (null s-parent-l)
	c-input-l
      (slots-to-be-inherited (cdr s-input-l)
			     (slot-remover (caar s-input-l)
					   s-parent-l)
			     c-input-l))))


;;; SLOT-REMOVER
(defun slot-remover (slot-name s-parent-l)
  (if (null s-parent-l)
      NIL
    (if (equal slot-name (caar s-parent-l))
	(slot-remover slot-name (cdr s-parent-l))
      (cons (car s-parent-l)
	    (slot-remover slot-name (cdr s-parent-l))))))


;;; BUILD-PAIRS
(defun build-pairs (slot-value-l)
  (if (null slot-value-l)
      NIL
    (if (and (listp (second slot-value-l))
	     (equal '=> (car (second slot-value-l))))
	(cons (cons (car slot-value-l)
		    (process-method (car slot-value-l)
				    (cdr (second slot-value-l))))
	      (build-pairs (cdr (cdr slot-value-l))))
      (cons (cons (car slot-value-l)
		  (second slot-value-l))
	    (build-pairs (cdr (cdr slot-value-l)))))))


;;; CREATE
(defun create (class-name &rest slot-value)
  (cond ((null (is-class class-name))
	 (error "La classe che si desidera istanziare non e' stata
definita in precedenza."))
	((not (evenp (list-length slot-value)))
	 (error "Gli argomenti sono in numero dispari."))
	((not (<= (list-length slot-value)
		  (* 2 (list-length (cadr (get-class-spec
					   class-name))))))
	 (error "Il numero di slot-value passati eccede il numero di
slot-value della classe da istanziare."))
	((has-duplicates slot-value)
	 (error "Sono presenti uno o piu' slot-name duplicati."))
	((null (valid-slot-check (inherit-from-p (build-pairs
						  slot-value)
						 (list class-name))
				 (cadr (get-class-spec class-name))))
	 (error "Uno o piu' slot-value non validi."))
	(t (cons 'oolinst (cons class-name (inherit-from-p
					    (build-pairs slot-value)
					    (list class-name)))))))

;;; VALID-SLOT-CHECK
(defun valid-slot-check (pairs-l class-slot-l)
  (if (null pairs-l)
      T
    (if (is-there-slot (caar pairs-l) class-slot-l)
	(is-there-slot (caar (cdr pairs-l)) class-slot-l)
      NIL)))


;;; IS-THERE-SLOT
(defun is-there-slot (slot-name s-parent-l)
  (if (null s-parent-l)
      NIL
    (if (equal slot-name (caar s-parent-l))
	T
      (is-there-slot slot-name (cdr s-parent-l)))))


;;; HAS-DUPLICATES	
(defun has-duplicates (slot-value-l)
  (cond ((null slot-value-l) nil)
        ((member (car slot-value-l) (cddr slot-value-l)) t)
        (t (has-duplicates (cddr slot-value-l)))))


;;; IS-INSTANCE
(defun is-instance (value &optional (class-name T))
  (if (and (listp value)
	   (>= (list-length value) 2)
	   (symbolp class-name)
	   (eql (car value) 'oolinst)
	   (not (null (is-class (second value))))
	   (valid-slot-check (cddr value)
			     (cadr (get-class-spec (second value)))))
      (cond ((null (eql class-name T))
	     (not (null (member class-name
				(retrieve-parents (second value))))))
	    ((eql class-name T) T))
    (error "Value non e' un'istanza o class-name non rispetta il
formato atteso in input per is-instance.")))


;;; RETRIEVE-PARENTS
(defun retrieve-parents (parent)
  (if (null parent)
      NIL
    (append (car (get-class-spec parent))
	    (retrieve-parents (caar (get-class-spec parent))))))


;;; <<
(defun << (instance slot-name)
  (if (and (not (null instance))
	   (not (null slot-name))
	   (is-instance instance)
	   (symbolp slot-name))
      (if (not (null (get-slot (cddr instance) slot-name)))
	  (cdr (get-slot (cddr instance) slot-name))
	(error "Slot-name o metodo non trovato nell'istanza."))
    (error "Parametri in input per << non validi.")))


;;; GET-SLOT
(defun get-slot (slot-pairs slot-name)
  (if (null slot-pairs)
      NIL
    (if (equal (car (car slot-pairs))
	       slot-name)
	(cons slot-name
	      (cdr (car slot-pairs)))
      (get-slot (cdr slot-pairs) slot-name))))


;;; <<*
(defun <<* (instance &rest slot-name-l)
  (get-slot-w-list instance slot-name-l))					


;;; GET-SLOT-W-LIST				
(defun get-slot-w-list (instance slot-name-l)
  (cond ((null slot-name-l)
	 (error "Lista di attributi non puo' essere vuota."))
	((= (list-length slot-name-l) 1)
	 (if (symbolp instance)
	     (<< (eval instance) (car slot-name-l))
	   (<< instance (car slot-name-l))))
	(t (if (symbolp instance)
	       (get-slot-w-list (<< (eval instance)
				    (car slot-name-l))
				(cdr slot-name-l))
	     (get-slot-w-list (<< instance (car slot-name-l))
			      (cdr slot-name-l))))))

;;; PROCESS-METHOD	 
(defun process-method (method-name method-spec)
  (setf (fdefinition method-name)
	(lambda (this &rest arglist)
	  (apply (<< this method-name)
		 (append (list this) arglist))))
  (eval (rewrite-method method-spec)))


;;; REWRITE-METHOD
(defun rewrite-method (method-spec)
  (list 'lambda (append '(this)
			(car method-spec))
	(cons 'progn (cdr method-spec))))

;;;; end of file -- ool.lisp
