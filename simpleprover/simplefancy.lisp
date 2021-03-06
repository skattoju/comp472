(make-package "testprover")

;Have fun.Remember that you need to define your own implementation of
;variablep, i.e. your own representation of logic variables.
;The representation of clauses is rather simple.

;; TP.LISP : A FOL Theorem Prover.
;;
;; Implemented by Ya Yang for W4701, homework #3.
;; (and slightly modified by the TA)
;;
;; - Mauricio
;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This lisp program is a First Order Logic Theorem Prover
;The input is in clause form and the output is either the
;steps of the proof or the claim that can't be proved
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This function makes a copy of a list L to Lcp
;using recursion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(Defun copy (L)

     (let ( (Lcp Nil))
     (cond
           ((null L) (setf Lcp Nil))
           ((atom L) (setf Lcp L))
           (t        (setf Lcp (cons (first L) (copy (rest L))))))))




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Define the structure of a node which records one step of resolving
;that leads to the proof
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defstruct Node
 resolvent      ;the clause derived from resolution
 clause1
 clause2
 subst)         ;the substitution list used by the resolution



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This function decides whether or not a clause is one of those
;resolvent s in the record list
;--> checks if a clause has been recorded.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(Defun inrecord (clause)

 (let ((thenode nil))
     (do ((i (- (length record) 1) (setf i (- i 1))))
         ((= i -1))

         (setf thenode (make-Node :resolvent (Node-resolvent (nth i record))
                                  :clause1   (Node-clause1 (nth i record))
                                  :clause2   (Node-clause2 (nth i record))
                                  :subst     (Node-subst (nth i record))))


         (if (equal clause (Node-resolvent thenode))

             (return-from inrecord  thenode)))

      nil))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This function trace the record list and prints out every
;step taken in the proof
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(Defun trace-solution (record clause)


  (let ( (thenode Nil))
     (cond
          ( (setf thenode (inrecord clause))

            ;if the clause is a resolvent, recurse its two clauses
            (trace-solution record (Node-clause1 thenode))
            (trace-solution record (Node-clause2 thenode))
                        (setf step (+ step 1))
            (format T " ===step ~d ===: ~% ~s + ~s using ~s = ~s ~%"
                   step (Node-clause1 thenode) (Node-clause2 thenode)
                  (Node-subst thenode) (Node-resolvent thenode)))

          ;if the clause is an input, goes back
          (t 'back))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This function tests whether two literals are complementary
;i.e. one positive and one negative literal with the same predicate
;a positive literal is of the form (P t1 .. tn), and a negative
;literal is of the form (~ P t1 .. tn) where ti is a FO term
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(Defun complementary-lits (L1 L2)
      (cond
              ((or (atom L1) (atom L2)) Nil)
              ((eql '~ (car L1)) (eql (cadr L1) (car L2)))
              ((eql '~ (car L2)) (eql (cadr L2) (car L1)))
              (t Nil)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This function determines whether a logic variable "v" appears
;anywhere within some arbitrary first order term "term"
;a term is of the form (f t1 ..tm) where ti is itself a FO term
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(Defun occurs (v term)
      (cond
              ((null term) Nil)
              ((atom term) (eql v term))
              ((atom (car term))  (cond ((eql v (car term)) t)
                                        (t           (occurs v (cdr term)))))
              (t           (or (occurs v (car term)) (occurs v (cdr term))))))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This function determines whether or not two literals are unifiable
;and returns the substitution list making them unified if so
;This functions assumes that the literals are complementary
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(Defun Unifiable (L1 L2)
      (cond
              ((or (atom L1) (atom L2)) 'Fail)
;; if either literal is an atom => fail
              ((eql '~ (car L1))  (Unify (cdr L1) L2))
              (t                  (Unify L1 (cdr L2)))))
;; if the car of L1 is NOT
;; => L2 must be the complement as this function is called only after checking
;; therefore unify cdr of one with the other

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This function returns a substitution list if two literals are
;unifiable. returns an 'fail is not unifiable.Note that the
;substitution list is a list of "dotted pairs"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(Defun Unify (L1 L2)

 (prog (Subst s i)

      (cond
       ((or (atom L1) (atom L2))              ; if L1 or L2 are atoms
        (cond
         ((eql L1 L2) (return Nil))     ; identical, substitution is nil
         ((variablep L1)
          (cond                             ; L1 is a logic variable
           ((Occurs L1 L2) (return 'Fail))  ; L1 occurs in L2, can't unify
           (t       (return (list (cons L1 L2)))))) ;otherwise,
                                                    ;L1 binding to L2

         ((variablep L2)
          (cond          ; ditto for L2
           ((Occurs L2 L1) (return 'Fail))
           (t       (return (list (cons L2 L1))))))
         (t                  (return 'Fail)))) ;otherwise, not unifiable

       ((Not (eql (length L1) (length L2))) (return 'Fail)))

      (setq Subst Nil i -1)        ; i iterates from 0 to (length L1)-1


 Step4  (setq i(+ 1 i))
      (cond ((= i (length L1)) (return Subst)))       ; Termination of loop

      (setq S (Unify (nth i L1) (nth i L2)))  ; Unify the ith term
      (cond
       ((eql S 'Fail) (return 'Fail))
       ((not (null S))
        (setf L1 (sublis S L1))   ;substitute L1 using S
        (setf L2 (sublis S L2))   ;substitute L2 using S
        (setq Subst (append S Subst))))  ;Add S to Subst
      (go Step4)))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This function determines whether an atom is a variable
;We define the form of a variable as ?x
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun variablep(x)
 (and (symbolp x) (eql (char (symbol-name x) 0) '#\?)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This function resolve two clauses C1 and C2 having complementary and
;unifiable literals L1 and L2 with substitution list Subst.
;return the resolvent C
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(Defun Resolve (C1 C2 index1 index2 Subst)
;;where index1 = position of literal L1 & index2 = position of literal L2
 (setf C nil)                         ;initialize the resolvent C

 (format t "this is reolution no ~s ~%" (gensym ":"))

 (do ((i1 0 (setf i1 (+ 1 i1))))      ;apply the substitution to C1
    ((= i1 (length C1)))

      (format t "applying substitution to (C1): ~b ~%" (nth i1 C1))
    (if (/= i1 index1)                ;if not one the complementary term
        (let ()    (setf (nth i1 C1) (sublis Subst (nth i1 C1)))
             (progn (format t "found complement for ~s ~%" (nth i1 C1))
                      (setf C (cons (nth i1 C1) C))))))


 (do ((i2 0 (setf i2 (+ 1 i2))))       ;apply the substitution to C2
    ((= i2 (length C2)))

      (format t "applying substitution to (C2): ~s ~%" (nth i2 C1))
    (if (/= i2 index2)
        (let ()    (setf (nth i2 C2) (sublis Subst (nth i2 C2)))
             (setf C (cons (nth i2 C2) C)))))

 C)       ; return the resolvent clause





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;The function checks whether or not there is a pair of literals
;in the two clauses that are unifiable. If not, return 'fail, otherwise
;resolve the two clauses
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(Defun Check (C1 C2)

 (let ((i1 0) (i2 0) (L1 Nil) (L2 Nil))

  (setf resolvent 'unsolved)
  (do ((i1 0 (setf i1 (+ 1 i1))))  ; loops through C1
      ((= i1 (length C1)))

;; for each C1>>>
;; checks if resolvent was found.

      (if (Not (eq resolvent 'unsolved))
          (return resolvent))         ;complementary and unifiable
                                      ;literals found and resolved.
                                      ;Get out of the function
      ;; check every literal of C2
      ;; with a literal from C1
      (setf L1 (nth i1 C1))           ;nth returns i1th element of C1

      (do ((i2 0 (setf i2 (+ 1 i2)))) ;loops through C2
          ((= i2 (length C2)))
      ;; for each element of C2 ...

          (setf L2 (nth i2 C2))
          (if (and (complementary-lits L1 L2)
                   (Not (eql (setf Subst (Unifiable L1 L2)) 'Fail)))
      ;; checks if L1 and L2 are complements && ;; check if L1 and L2
are unifiable
      ;; if yes proceed with resolution

              (let ()
                (setf C1cp (copy C1))
                (setf C2cp (copy C2))

                      ;;To keep C1, C2 unchanged we make copies and
then apply resolution.
                (setf resolvent (Resolve C1cp C2cp i1 i2 Subst))
                      ;; Resolve is called with Clause1 Clause2
index1 index2 and the Substitution..
                      ;; where index1 = position of literal L1 &
index2 = position of literal L2
                      ;; Save the resolvent
                      ;; save the step by creating a new node in the
proof-tree datastructure
                (setf newnode (make-Node  :resolvent C
                                          :clause1   C1
                                          :clause2   C2
                                          :subst     Subst))
                      ;; Add the new node to the list
                (setf record (append record (list newnode)))
                (return resolvent))
                      ;;return the resolvent for further processing[?]
            )))

      ;; if not resolvable, return unsolved.
  resolvent))




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; proof-node is the main data structure.  Each of the clauses is stored
;;; in such a structure.  The parent links allow retrival of the proof
;;; tree.  New strategies and filters may need to add fields to this
;;; record.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defstruct proof-node
 clause                    ; The clause (either from the axioms or a
                           ; resolvent
 parent                    ; A pointer to the candidate that generated
                           ; this clause.  The candidate contains pointers
                           ; to the two nodes that
                           ; contain the parent clauses.
 binding                   ; The binding list generated by unifying the
                           ; parents
 setofsupport              ; A flag - indicates whether the clause is a
                           ; decendant of the set-of-support.
 (depth 0)                 ; The depth of the node = 1 + the max depth of
                           ; the parents.
 )



(defparameter *resource-limit* 10000000
  "The maximum number of resolutions allowed for proving one theorem")

(defvar *trace-prover* t
  "When T, the prover displays each unification attempt")

(defvar *show-progress* nil
  "When not nil, shows a dot every K resolutions")

(defvar *renaming-table* (make-hash-table)
   "Currently not in use.  Will be used in later versions for displaying
    query variables bindings")

(defvar *axioms* nil
    "A variable used to hold the axioms after reading them")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; proof-result
;;;    A structure used for returning the proof results.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defstruct proof-result
  answer                   ; either T (for success), NIL (for failure)
                           ; or :resource-limit (means that the prover
                           ; stoped due to exhaustion of the alloted
                           ; resources
  n-resolutions            ; The number of resolutions attempted.
  proof                    ; A pointer to the proof-node that contains
                           ; the empty clause.  The proof tree is defined
                           ; by the parent links.
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This is the main procedure which proves the theorem by using
;resolution.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(Defun Prove (Clauses)
;; (theorem axiom-clauses)

 (setf *renaming-table* (make-hash-table))
 (let* (

      (theorem-clauses Clauses)

      (theorem-nodes (loop for c in theorem-clauses
                    collect (make-proof-node :clause c
                                             :setofsupport t)))
      (axiom-nodes (loop for c in Clauses
                    collect (make-proof-node :clause c)))
      (proof-nodes (append axiom-nodes theorem-nodes))

      (predicate-index (make-hash-table))

      (candidates nil)))



  ;; The following code initializes the candidate list.  It takes each
  ;; clause in the axioms+theorem clauses and merges its resolution
  ;; candidate with the the candidate list using the candidate ordering
  ;; strategies to determine the sort order.
  (setf proof-nodes (loop for node in proof-nodes
                          when (apply-initial-clause-filters
                                (proof-node-clause node)
                                proof-nodes)
                          collect node))
  (loop for proof-node in proof-nodes
        for new-candidates = (sort (get-clause-candidates proof-node
                                                 predicate-index)
                                                  #'candidate-ordering)
        do
        (setf candidates (merge 'list
                         new-candidates
                         candidates
                          #'candidate-ordering))
        (update-predicate-index proof-node predicate-index))
  ;; The main loop.  Keeps poping candidates from the candidate list,
  ;; unifying them and adding the new clauses.
  (loop for n-resolutions from 1 with resolvant with binding with
        cand with new-clause with new-candidates do
        (when (and *show-progress* (= (mod n-resolutions
                                           *show-progress*) 0))
              (format t ".")(force-output))
        (when (> n-resolutions *resource-limit*)
                                      ;failure due to time limit
                 (return  (make-proof-result
                             :answer :resource-limit
                             :n-resolutions n-resolutions)))
        (when (null candidates)
                                      ;not a theorem - no proof exists
              (return (make-proof-result
                             :answer nil
                             :n-resolutions n-resolutions)))
        (setf cand (pop candidates))
        (when *trace-prover*
              (format t "~%Trying to unify: ~%    Literal ~d of ~A ~%
  Literal ~d of ~A"
                      (second (first cand))
                      (proof-node-clause (first (first cand)))
                      (second (second cand))
                      (proof-node-clause (first (second cand)))))
        (setf binding (unify-cand cand))
        (when *trace-prover*
              (format t"~%    Unification result: ~A" binding))
        (cond ((not (eql binding +fail+))
               ;; Unification was successful. A new clause is
               ;; generated, and its variables are renamed.
              (setf new-clause
                  (setify
                    (rename-variables
                      (subst-bindings binding (resolve-cand
                                                        cand)) t)))
              (cond ( (apply-clause-filters new-clause proof-nodes)
                      ;; The clause filters allow us to filter out
                      ;; newly generated clauses.

                      (setf resolvant
                            (make-proof-node
                             :clause new-clause
                             :parent cand
                             :setofsupport (or (proof-node-setofsupport
                                                (first (first cand)))
                                               (proof-node-setofsupport
                                                (first (second cand))))
                             :depth (1+ (max (proof-node-depth
                                              (first (first cand)))
                                             (proof-node-depth
                                              (first (second cand)))))
                             :binding binding))
                      (when *trace-prover*
                            (format t "~%    New Clause:~A"
                                    (proof-node-clause resolvant)))
                      (when (null (proof-node-clause resolvant))
                            (return (make-proof-result
                                     :answer t
                                     :n-resolutions n-resolutions
                                     :proof resolvant)))
                      (push resolvant proof-nodes)
                      (setf new-candidates (sort
(get-clause-candidates resolvant
                                                 predicate-index)
                                                 #'candidate-ordering))
                      (setf candidates (merge 'list
                          new-candidates
                          candidates
                          #'candidate-ordering))
                      (update-predicate-index resolvant predicate-index))
                    (t (when *trace-prover*
                             (format t "~%    Clause ~A was filtered out."
                                     new-clause)))))
              (t (when *trace-prover*
                       (format t "~%    Unification failed."))))
              )
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; setify
;;;   Converts a list into a set (i.e. - removes duplicates)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun setify (list &key (test #'equalp)(key #'identity))
 (let ((new-set nil))
  (loop for el in list do (setf new-set (adjoin el new-set :key key
                                             :test test)))
  new-set))



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; proof-result
;;;    A structure used for returning the proof results.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defstruct proof-result
   answer                   ; either T (for success), NIL (for failure)
                            ; or :resource-limit (means that the prover
                            ; stoped due to exhaustion of the alloted
                            ; resources
   n-resolutions            ; The number of resolutions attempted.
   proof                    ; A pointer to the proof-node that contains
                            ; the empty clause.  The proof tree is defined
                            ; by the parent links.
   )



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Resolution strategies
;;;   General explanations are at the header
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Resolution - a structure that determines the resolution strategy
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defstruct resolution
 (candidate-ordering-strategies '(trivial-ordering))
                                       ;A list of functions used to impose a
                                       ;lexicographic order over the set
                                       ;of candidate
 (candidate-filters '(trivial-candidate-filter))
                                       ;A list of filter functions to filter out
                                       ;resolution candidate
 (clause-filters '(trivial-clause-filter))
                                       ;A list of filter functions to filter out
                                       ;a new resolvent
 (initial-clause-filters '(trivial-clause-filter))
                                       ;A list of filter functions to filter out
                                       ;clauses in the initial set.
 )



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Resolutions strategies.
;;;   A resolution strategy is created by filling in the fields of
;;;   the resolution record.  Below a few examples of such
;;;   combinations are given.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defparameter  *default-resolution-strategy*
 (make-resolution
  :candidate-ordering-strategies '(shortest-min-clause shortest-sum)
  :candidate-filters '(setofsupport-filter)
  :clause-filters  '(tautology-filter uniqueness-filter)
  ))

(defparameter *setofsupport-strategy*
 (make-resolution
  :candidate-filters '(setofsupport-filter)
  :clause-filters  '(tautology-filter uniqueness-filter)
  ))

(defparameter *shortest-min-shortest-sum-strategy*
 (make-resolution
  :candidate-ordering-strategies '(shortest-min-clause shortest-sum)
  :clause-filters  '(tautology-filter uniqueness-filter)
  ))

(defparameter *shortest-min-clause-strategy*
 (make-resolution
  :candidate-ordering-strategies '(shortest-min-clause)
  :clause-filters  '(tautology-filter uniqueness-filter)
  ))

(defvar *current-resolution-strategy* *default-resolution-strategy*)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  candidate-ordering
;;;   This function is used by the candidate sorting routines.  We use
;;;   Common Lisp SORT and MERGE.  These functions require a predicate
;;;   that gets two items and return T if the first precedes the second.
;;;   The candidate ordering routine orders the candidates in lexicographic
;;;   order according to the list *candidate-ordering-strategies*.
;;;   The first strategy in the list is the most significant.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun candidate-ordering
 (cand1 cand2 &optional
        (strategies (resolution-candidate-ordering-strategies
                     *current-resolution-strategy*)))
 (cond ((null strategies) t)
       (t (case (funcall (first strategies) cand1 cand2)
             (< t)
             (> nil)
             (= (candidate-ordering cand1 cand2 (rest strategies)))))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Candidate ordering strategies
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun shortest-min-clause (cand1 cand2)
 "A candidate ordering strategy.  Prefers pairs whose minimal clause
 length is shorter"
 (let ((min1 (min (length (proof-node-clause (first (first cand1))))
         (length (proof-node-clause (first (second cand1))))))
       (min2 (min (length (proof-node-clause (first (first cand2))))
         (length (proof-node-clause (first (second cand2)))))))
   (numeric-relation min1 min2)))

(defun numeric-relation (n1 n2)
 (cond ((< n1 n2) '<)((> n1 n2) '>)(t '=)))

(defun shortest-sum (cand1 cand2)
 "A candidate ordering strategy.  Prefers pairs whose sum of clause
 length is shorter"
 (let ((sum1 (+ (length (proof-node-clause (first (first cand1))))
         (length (proof-node-clause (first (second cand1))))))
       (sum2 (+ (length (proof-node-clause (first (first cand2))))
         (length (proof-node-clause (first (second cand2)))))))
   (numeric-relation sum1 sum2)))


(defun trivial-ordering (cand1 cand2)
 "A trivial ordering function.  It should be used when, during the
 experimentation we need to test the prover with no ordering functions"
  (declare(ignore cand1)(ignore cand2)) t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Candidate filtering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun apply-candidate-filters
  (cand &optional
        (filters (resolution-candidate-filters *current-resolution-strategy*)))
  (loop for filter in filters always (funcall filter cand)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Candidate filtering strategies
;;;    To add a strategy define the function according to the example
;;;    below.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun setofsupport-filter (cand)
 "Set of support strategy.  One of the candidate clauses should be a
 decendant of the set of support (the theorem negation)"
 (or (proof-node-setofsupport (first (first cand)))
     (proof-node-setofsupport (first (second cand)))))

(defun trivial-candidate-filter (cand)
 "A trivial filter that always returns T.  Should be used when testing
 the system without cadidate filtering"
  (declare (ignore cand)) t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Clause filtering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun apply-clause-filters
  (clause proof-nodes
  &optional (filters (resolution-clause-filters
                      *current-resolution-strategy*)))
  (loop for filter in filters always (funcall filter clause proof-nodes)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  clause filtering strategies
;;;    To add a strategy define the function according to the example
;;;    below.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun uniqueness-filter (clause proof-nodes)
 "This filter makes sure that we don't add duplicate clause.   It look as
 if it is always worthwhile to keep this filter.  Note however that the
 cost of the test is high and proportional to the number of clauses"
 (not (member clause proof-nodes :key #'proof-node-clause
              :test #'literal-set-equivalence)))

(defun literal-set-equivalence (set1 set2)
 (and (= (length set1)(length set2))
 (subsetp set1 set2 :test #'renaming?)))

(defun tautology-filter (clause &optional proof-nodes)
 (declare (ignore proof-nodes))
 (loop for literal in clause never
       (and (negative-literal literal)
            (member (second literal) clause :test #'equalp))))

(defun trivial-clause-filter (clause nodes)
 "A trivial filter that always returns T.  Should be used when testing
 the system without cadidate filtering"
  (declare (ignore clause)(ignore nodes)) t)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  Initial clause filtering
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun apply-initial-clause-filters
  (clause proof-nodes
  &optional (filters (resolution-initial-clause-filters
                      *current-resolution-strategy*)))
  (loop for filter in filters always (funcall filter clause proof-nodes)))



;; (let ((i1 0) (i2 0) (C1 Nil) (C2 Nil) )
;;
;;     ;choose the first clause from the end of the list
;;     (do ((i1 (- (length Clauses) 1) (setf i1 (- i1 1))))
;;      ((= i1 (- NumOfPre 1))
;;      (format t "itereating over clauses (C1): ~s ~%" (nth i1 Clauses)))
;;                                      ;inner loop over Clauses for
;;                                      ;the choice of C1
;;      (setf C1 (nth i1 Clauses))      ;C1 is from the set of newly
;;                                      ;generated clauses
;;                                      ;choose the second clause from
;;                                      ;the beginning of the list
;;      (do ((i2 0 (setf i2 (+ 1 i2))))
;;          ((= i2 NumOfPre)
;;              (format t "itereating over clauses (C2): ~s with ~s ~%" (nth i2 Clauses) (nth i1 Clauses)))
;;                                      ; outer loop over Clauses for the
;;                                      ; choice of C2
;;
;;          (setf C2 (nth i2 Clauses))  ;C2 is from the set of axioms
;;
;;                                      ;check the two clauses to see
;;                                      ;whether we can resolve them
;;          (setf result (Check C1 C2))
;;                                      ;if the newly derived resolvent
;;                                      ;is identical to someone already
;;                                      ;in the Clauses, we just go to the
;;                                      ;next clause without adding it
;;                                      ;to Clauses and starts all over again
;;          (if (and (Not (eq 'unsolved result))
;;                   (Not (member result Clauses :test 'equal)))
;;                                      ;get out of the function
;;              (return-from Prove result))))
;;     (return-from prove 'Fail)))   ; no clause can resolve, can't prove.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Ordering Strategies **destructive function.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;(defvar *strategy* 1)
;;
;;(defun orderingStrategy(premise strategy)
;;      (cond
;;              ((= *strategy* 1)
;;      ;;shortest first.
;;      ;;sort the premises in increasing order of
;;      ;;their lengths
;;
;;              (setf premise
;;              (sort premise '(lambda (cl1 cl2) (< (length cl1)
;;(length cl2)))))
;;
;;              )
;;              ((= *strategy* 2)
;;      )
;; )
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;This function drives the whole theorem prover
;premises is the set of inputs clauses(axioms)
;negconclusion is the negated conclusion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun ProveDriver (premise negconclusion)

      (setf premise
              (sort premise #'(lambda (cl1 cl2) (< (length cl1)
(length cl2)))))

 ;append the negated conclusion clause to the premises
 (setf CL (append premise (list negconclusion)))

 (setf done 0)
 (setf NumOfPre (- (length CL) 1)) ;to remember the number of axioms input
 (setf record Nil)                 ;initialize the record list

;; delete duplicates --->
;;prune --->

 (loop
      (format t "proving: ~s ~%" CL)
 (setf done (Prove CL))
 (cond

  ((eq done 'Fail)      ; terminate with failure to prove
   (return "The theorem can't be proved"))

  ((eq done Nil)        ;terminate with the proof
   (print  "I found the proof")
   (setf step 0)
   (trace-solution record Nil)
   (return))

  (t                                        ;no resolvents this iteration
   (setf CL (append CL (list done)))))))    ;keep on doing on expanded CL

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; TEST CASES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(Defun ttest0 ()
 (ProveDriver '(( ( ~ E ?x) ( V ?x) (S ?x (f ?x)))
               ( ( ~ E ?u) ( V ?u) (C (f ?x)))
               ( (P c))
               ( (E c))
               ( (Q c))
               ( (W c))
               ( (E c))
               ( (R c))
               ( (~ S c ?y) (P ?y))
               ( (~ P ?z) (~ V ?z)))
             '( (~ p ?w) (~ C ?w))))

(Defun ttest1 ()
 (ProveDriver '( ((A))
                ((M))
                ((~ A) (~ C) (D))
                ((~ M) (C)))
             '((~ D))))


(Defun ttest2 ()
 (ProveDriver '( ((mother amity betsy))
                ((~ daughter ?u ?w) (mother ?w ?u))
                ((daughter cindy betsy))
                ((~ mother ?x ?y) (~ mother ?y ?z) (grandmother ?x ?z)))
             '((~ grandmother ?g cindy))))

(Defun ttest3 ()
 (ProveDriver '( ((man marcus))
                ((prompeian marcus))
                ((~ prompeian ?x) (roman ?x))
                ((ruler caesar))
                ((~ roman ?x) (loyalto ?x caesar) (hate ?x caesar))
                ((~ man ?x) (~ ruler ?y) (~ trytoassassinate ?x ?y)
(~ loyalto ?x ?y))
                      ((trytoassassinate marcus caesar)))
             '((~ hate marcus caesar))))

(Defun ttest4 ()
 (ProveDriver '( ((B ?x) (~ C ?x) (D ?x))
                ((C ?x) (~ E ?x))
                ((C ?x) (~ F ?x))
                ((G John))
                ((E Helen))
                ((G Helen))
                ((~ D ?x) (A ?x))
                ((~ G ?x) (~ B ?x))
                ((H Helen)))
 '((~ A Helen) )))

(Defun ttest5 ()
       (ProveDriver '( ((dog d))
                       ((owns jack d))
                       ((~ cat ?u) (animal ?u))
                       ((~ dog ?y) (~ owns ?x ?y) (animallover ?x))
                       ((~ animallover ?z) (~ animal ?w) (~ kills ?z ?w))
                       ((kills jack tuna) (kills curiosity tuna))
                       ((cat tuna)))
      '(~ curiosity kills cat)))

(Defun ttest6 ()
       (ProveDriver '((V1) (V2) (V3) (V4) (V5) (V6) (V7) (V8) (V9) (V10)
(V11) (V12) (V13) (V14) (V15) (V16) (V17) (V18) (V19) (V20) (V21)
(V22) (V23) (V24) (V25) (V26) (V27) (V28) (V29))
      '((~ V1 V2 V3 V4 V5 V6 V7 V8 V9 V10 V11 V12 V13 V14 V15 V16 V17 V18
V19 V20 V21 V22 V23 V24 V25 V26 V27 V28 V29))))


(Defun ttest7 ()
       (Prove '(
( (~ V0) (~ V1) (~ V2) (~ V3) (~ V4) (~ V5) )
( V0 (~ V1) (~ V2) (~ V3) (~ V4) (~ V5) )
( (~ V0) V1 (~ V2) (~ V3) (~ V4) (~ V5) )
( V0 V1 (~ V2) (~ V3) (~ V4) (~ V5) )
( (~ V0) (~ V1) V2 (~ V3) (~ V4) (~ V5) )
( V0 (~ V1) V2 (~ V3) (~ V4) (~ V5) )
( (~ V0) V1 V2 (~ V3) (~ V4) (~ V5) )
( V0 V1 V2 (~ V3) (~ V4) (~ V5) )
( (~ V0) (~ V1) (~ V2) V3 (~ V4) (~ V5) )
( V0 (~ V1) (~ V2) V3 (~ V4) (~ V5) )
( (~ V0) V1 (~ V2) V3 (~ V4) (~ V5) )
( V0 V1 (~ V2) V3 (~ V4) (~ V5) )
( (~ V0) (~ V1) V2 V3 (~ V4) (~ V5) )
( V0 (~ V1) V2 V3 (~ V4) (~ V5) )
( (~ V0) V1 V2 V3 (~ V4) (~ V5) )
( V0 V1 V2 V3 (~ V4) (~ V5) )
( (~ V0) (~ V1) (~ V2) (~ V3) V4 (~ V5) )
( V0 (~ V1) (~ V2) (~ V3) V4 (~ V5) )
( (~ V0) V1 (~ V2) (~ V3) V4 (~ V5) )
( V0 V1 (~ V2) (~ V3) V4 (~ V5) )
( (~ V0) (~ V1) V2 (~ V3) V4 (~ V5) )
( V0 (~ V1) V2 (~ V3) V4 (~ V5) )
( (~ V0) V1 V2 (~ V3) V4 (~ V5) )
( V0 V1 V2 (~ V3) V4 (~ V5) )
( (~ V0) (~ V1) (~ V2) V3 V4 (~ V5) )
( V0 (~ V1) (~ V2) V3 V4 (~ V5) )
( (~ V0) V1 (~ V2) V3 V4 (~ V5) )
( V0 V1 (~ V2) V3 V4 (~ V5) )
( (~ V0) (~ V1) V2 V3 V4 (~ V5) )
( V0 (~ V1) V2 V3 V4 (~ V5) )
( (~ V0) V1 V2 V3 V4 (~ V5) )
( V0 V1 V2 V3 V4 (~ V5) )
( (~ V0) (~ V1) (~ V2) (~ V3) (~ V4) V5 )
( V0 (~ V1) (~ V2) (~ V3) (~ V4) V5 )
( (~ V0) V1 (~ V2) (~ V3) (~ V4) V5 )
( V0 V1 (~ V2) (~ V3) (~ V4) V5 )
( (~ V0) (~ V1) V2 (~ V3) (~ V4) V5 )
( V0 (~ V1) V2 (~ V3) (~ V4) V5 )
( (~ V0) V1 V2 (~ V3) (~ V4) V5 )
( V0 V1 V2 (~ V3) (~ V4) V5 )
( (~ V0) (~ V1) (~ V2) V3 (~ V4) V5 )
( V0 (~ V1) (~ V2) V3 (~ V4) V5 )
( (~ V0) V1 (~ V2) V3 (~ V4) V5 )
( V0 V1 (~ V2) V3 (~ V4) V5 )
( (~ V0) (~ V1) V2 V3 (~ V4) V5 )
( (~ V0) V1 V2 V3 (~ V4) V5 )
( V0 V1 V2 V3 (~ V4) V5 )
( (~ V0) (~ V1) (~ V2) (~ V3) V4 V5 )
( V0 (~ V1) (~ V2) (~ V3) V4 V5 )
( (~ V0) V1 (~ V2) (~ V3) V4 V5 )
( V0 V1 (~ V2) (~ V3) V4 V5 )
( V0 (~ V1) V2 (~ V3) V4 V5 )
( (~ V0) V1 V2 (~ V3) V4 V5 )
( V0 V1 V2 (~ V3) V4 V5 )
( (~ V0) (~ V1) (~ V2) V3 V4 V5 )
( V0 (~ V1) (~ V2) V3 V4 V5 )
( (~ V0) V1 (~ V2) V3 V4 V5 )
( V0 V1 (~ V2) V3 V4 V5 )
( (~ V0) (~ V1) V2 V3 V4 V5 )
( V0 (~ V1) V2 V3 V4 V5 )
((~ V0) V1 V2 V3 V4 V5 ))
)
)

(Defun ttest8 ()
      (Prove '((16 30 95)
((not 16) 30 95)
((not 30) 35 78)
((not 30) (not 78) 85)
((not 78) (not 85) 95)
(8 55 100)
(8 55 (not 95))
(9 52 100)
(9 73 (not 100))
((not 8) (not 9) 52)
(38 66 83)
(38 66 ?83)
((not 38) 83 87)
((not 52) 83 (not 87))
(66 74 (not 83))
((not 52) (not 66) 89)
((not 52) 73 (not 89))
((not 52) 73 (not 74))
((not 8) (not 73) (not 95))
(40 (not 55) 90)
((not 40) (not 55) 90)
(25 35 82)
((not 25) 82 (not 90))
((not 55) (not 82) (not 90))
(11 75 84)
(11 (not 75) 96)
(23 (not 75) (not 96))
((not 11) 23 (not 35))
((not 23) 29 65)
(29 (not 35) (not 65))
((not 23) (not 29) 84)
((not 35) 54 70)
((not 54) 70 77)
(19 (not 77) (not 84))
((not 19) (not 54) 70)
(22 68 81)
((not 22) 48 81)
((not 22) (not 48) 93)
(3 (not 48) (not 93))
(7 18 (not 81))
((not 7) 56 (not 81))
(3 18 (not 56))
((not 18) 47 68)
((not 18) (not 47) (not 81))
((not 3) 68 77)
((not 3) (not 77) (not 84))
(19 (not 68) (not 70))
((not 19) (not 68) 74)
((not 68) (not 70) (not 74))
(54 61 (not 62))
(50 53 (not 62))
((not 50) 61 (not 62))
((not 27) 56 93)
(4 14 76)
(4 (not 76) 96)
((not 4) 14 80)
((not 14) (not 68) 80)
((not 10) (not 39) (not 89))
(1 49 (not 81))
(1 26 (not 49))
(17 (not 26) (not 49))
((not 1) 17 (not 40))
(16 51 (not 89))
(16 ?51 (not 89))
((not 9) 57 60)
(12 45 (not 51))
(2 12 69)
(2 (not 12) 40)
((not 12) (not 51) 69)
((not 33) 60 (not 98))
(5 (not 32) (not 66))
(2 (not 47) (not 100))
((not 42) 64 83)
(20 (not 42) (not 64))
(20 (not 48) 98)
((not 20) 50 98)
((not 32) (not 50) 98)
((not 24) 37 (not 73))
((not 24) (not 37) (not 100))
((not 57) 71 81)
((not 37) 40 (not 91))
(31 42 81)
((not 31) 42 72)
((not 31) 42 (not 72))
(7 (not 19) 25)
((not 1) (not 25) (not 94))
((not 15) (not 44) 79)
((not 6) 31 46)
((not 39) 41 88)
(28 (not 39) 43)
(28 (not 43) (not 88))
((not 4) (not 28) (not 88))
((not 30) (not 39) (not 41))
((not 29) 33 88)
((not 16) 21 94)
((not 10) 26 62)
((not 11) (not 64) 86)
((not 6) (not 41) 76)
(38 (not 46) 93)
(38 (not 46) ?93)
(26 (not 37) 94)
(26 (not 37) ?94)
((not 26) 53 (not 79))
(78 87 (not 94))
(65 76 (not 87))
(23 51 (not 62))
(23 ?51 (not 62))
((not 11) (not 36) 57)
(41 59 (not 65))
((not 56) 72 (not 91))
(13 (not 20) (not 46))
((not 13) 15 79)
((not 17) 47 (not 60))
((not 13) (not 44) 99)
((not 7) (not 38) 67)
(37 (not 49) 62)
((not 14) (not 17) (not 79))
((not 13) (not 15) (not 22))
(32 (not 33) (not 34))
(24 45 48)
(21 24 (not 48))
((not 36) 64 (not 85))
(10 (not 61) 67)
((not 5) 44 59)
((not 80) (not 85) (not 99))
(6 37 (not 97))
((not 21) (not 34) 64)
((not 5) 44 46)
(58 (not 76) 97)
((not 21) (not 36) 75)
((not 15) 58 (not 59))
((not 58) (not 76) (not 99))
((not 2) 15 33)
((not 26) 34 (not 57))
((not 18) (not 82) (not 92))
(27 (not 80) (not 97))
(6 32 63)
((not 34) (not 86) 92)
(13 (not 61) 97)
((not 28) 43 (not 98))
(5 39 (not 86))
(39 (not 45) 92)
(27 (not 43) 97)
(13 (not 58) (not 86))
((not 28) (not 67) (not 93))
((not 69) 85 99)
(42 71 (not 72))
(10 (not 27) (not 63))
((not 59) 63 (not 83))
(36 86 (not 96))
((not 2) 36 75)
((not 59) (not 71) 89)
(36 (not 67) 91)
(36 (not 60) 63)
((not 63) 91 (not 93))
(25 87 92)
((not 21) 49 (not 71))
((not 2) 10 22)
(6 (not 18) 41)
(6 71 (not 92))
((not 53) (not 69) (not 71))
((not 2) (not 53) (not 58))
(43 (not 45) (not 96))
(34 (not 45) (not 69))
(63 (not 86) (not 98))
)))