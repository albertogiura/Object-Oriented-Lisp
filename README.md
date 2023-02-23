# Object-Oriented-Lisp
OO Lisp con ereditarietà multipla

PRIMITIVE PRINCIPALI

> def-class - (class-name parents &rest slot-value)


La funzione consente la definizione di classi dati in input 
un class-name, una lista (eventualmente vuota) di parents e una lista
variabile di slot-values (che si distinguono in attributi della classe
e metodi).
Funzioni ausiliarie presenti nel codice quali build-pairs
si occupano materialmente di eseguire tale distinzione e costruire appunto
le coppie della forma (K . V) da associare alle varie classi. 
Alcuni controlli, a priori, seppur non esplicitamente richiesti, 
sono eseguiti. La definzione di una classe, ad esempio, fallisce quando:
class-name non è un simbolo, parents non è una lista, class-name è anche
presente nella lista di parents, vi sono duplicati tra gli slot-values o
essi sono in numero dispari (mancando così un valore per un campo) oppure
più comunemente si cerca di definire una sottoclasse di una classe non già
definita. Le informazioni circa le classi definite vengono salvate in una
hash-table e sono accessibili utilizzando class-name come chiave (mentre
method-specs è il valore associato). Il formato scelto per le classi è il
seguente ((parents) ((K . V)*)) ovvero una lista, avente
come primo elemento una lista di parents seguita da una association list,
ovvero una lista di cons-cells rappresentante le varie coppie chiave-valore.
A differenza di quanto sperimentato per Prolog, qui non vi sono vincoli
sulla ridefinizioni delle classi. Bisogna comunque tenere in considerazione
lo stato inconsistente in cui si troverà il sistema ed, in particolare, 
le istanze se esse non vengono a loro volta ridefinte.



> create - (class-name &rest slot-value)


La funzione consente di instanziare una classe precedentemente definita
e nel farlo si cura di verificare che non si stiano cercando di inserire
tra gli slot-values attributi che non rispettano la definizione della 
classe che viene istanziata. Richiama la funzione inherit-from-p
per ereditare gli eventuali slot che non vengono ridefiniti all'atto
della creazione dell'istanza. Anche qui per quanto riguarda il ruolo 
giocato dall'ereditarietà multipla, nella scelta dell'attributo da 
associare all'istanza e, di conseguenza, da reperire con la funzione <<
all'atto della create si scansiona la lista di parents 
(l'ordine conta) e si eredita l'attributo/metodo eventualmente presente 
in più classi solo dalla prima utile. Per le istanze, il formato scelto
è il seguente: (oolinst class-name (K . V)* ).
In analogia a quanto fatto con Prolog, il codice non previene che si
possano, volendo, ridefinire dei metodi ereditati dalle classi.


> << - (instance slot-name) 


Estrae il valore di un campo da una classe.


> <<* - (instance &rest slot-name-l)


Estrae il valore da una classe percorrendo una catena di attributi.


> process-method - (method-name method-spec)


Richiamata dalla build-pairs quando questa individua il pattern di un
metodo. Crea una funzione anonima che si preoccupi di recuperare 
il codice vero e proprio del metodo nell’istanza (sfrutta <<), e 
di chiamarlo con tutti gli argomenti del caso. INfine associa la 
suddetta lambda al nome del metodo.

> rewrite-method (method-spec)

Aggiunge l'argomento this al metodo
