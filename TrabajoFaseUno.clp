(deftemplate Usuario (slot id))
(deftemplate Juego (slot id))

;; Hechos sobre el usuario
(deftemplate Posee_Plataforma (slot usuario) (slot plataforma))
(deftemplate Prefiere_Genero (slot usuario) (slot genero))
(deftemplate No_Gusta_Genero (slot usuario) (slot genero))
(deftemplate Gusto_Juego (slot usuario) (slot juego))
(deftemplate No_Gusto_Juego (slot usuario) (slot juego))
(deftemplate Jugo_Juego (slot usuario) (slot juego))
(deftemplate Edad_Usuario (slot usuario) (slot edad))
(deftemplate Prefiere_Complejidad (slot usuario) (slot nivel))
(deftemplate Prefiere_Duracion (slot usuario) (slot tipo))
(deftemplate Prefiere_Multiplayer (slot usuario) (slot tipo))

;; Hechos sobre el juego
(deftemplate Titulo_Juego (slot juego) (slot titulo))
(deftemplate Tiene_Genero (slot juego) (slot genero))
(deftemplate Disponible_En (slot juego) (slot plataforma))
(deftemplate Tiene_Complejidad (slot juego) (slot nivel))
(deftemplate Tiene_Duracion (slot juego) (slot tipo))
(deftemplate Tiene_Multiplayer (slot juego) (slot tipo))
(deftemplate Clasificacion_Edad (slot juego) (slot clasificacion))
(deftemplate Similar_A (slot juego1) (slot juego2))
(deftemplate Tiene_Tag (slot juego) (slot tag))

;; Hechos intermedios y finales
(deftemplate Potencial_Recomendacion (slot usuario) (slot juego) (slot prioridad))
(deftemplate Recomendacion_Final (slot usuario) (slot juego) (slot razon))

;; Funciones
(deffunction Es_Inapropiado (?clasif ?edad)
   (if (and (eq ?clasif "18+") (< ?edad 18)) then TRUE else FALSE))

(deffunction Coincide_Preferencia (?pref ?valor)
   (if (or (eq ?pref "Cualquiera") (eq ?pref ?valor)) then TRUE else FALSE))

(deffunction Coincide_Preferencia_Multiplayer (?pref ?valor)
   (if (or (eq ?pref "Cualquiera") (eq ?pref ?valor)) then TRUE else FALSE))

(defglobal ?*limite-recomendaciones* = 3)

(deffunction Limite_Recomendaciones_No_Alcanzado (?usuario)
   (bind ?count 0)
   (do-for-all-facts ((?r Recomendacion_Final)) TRUE
      (if (eq ?r:usuario ?usuario) then (bind ?count (+ ?count 1))))
   (< ?count ?*limite-recomendaciones*))

;; REGLAS

(defrule Filtro_Plataforma_Genero
   (Usuario (id ?u))
   (Juego (id ?j))
   (Prefiere_Genero (usuario ?u) (genero ?g))
   (Tiene_Genero (juego ?j) (genero ?g))
   (Posee_Plataforma (usuario ?u) (plataforma ?p))
   (Disponible_En (juego ?j) (plataforma ?p))
   (not (Jugo_Juego (usuario ?u) (juego ?j)))
   (not (No_Gusto_Juego (usuario ?u) (juego ?j)))
   (not (and (No_Gusta_Genero (usuario ?u) (genero ?g2)) (Tiene_Genero (juego ?j) (genero ?g2))))
   =>
   (assert (Potencial_Recomendacion (usuario ?u) (juego ?j) (prioridad "Baja")))
)

(defrule Filtro_Genero_No_Gustado
   ?f <- (Potencial_Recomendacion (usuario ?u) (juego ?j) (prioridad ?p))
   (No_Gusta_Genero (usuario ?u) (genero ?g))
   (Tiene_Genero (juego ?j) (genero ?g))
   =>
   (retract ?f)
)

(defrule Filtro_Juego_No_Gustado
   ?f <- (Potencial_Recomendacion (usuario ?u) (juego ?j) (prioridad ?p))
   (No_Gusto_Juego (usuario ?u) (juego ?j))
   =>
   (retract ?f)
)

(defrule Filtro_Edad
   ?f <- (Potencial_Recomendacion (usuario ?u) (juego ?j) (prioridad ?p))
   (Edad_Usuario (usuario ?u) (edad ?edad))
   (Clasificacion_Edad (juego ?j) (clasificacion ?clasif))
   (test (Es_Inapropiado ?clasif ?edad))
   =>
   (retract ?f)
)

(defrule Aumento_Prioridad_Por_Complejidad
   ?r <- (Potencial_Recomendacion (usuario ?u) (juego ?j) (prioridad ?p))
   (Prefiere_Complejidad (usuario ?u) (nivel ?c_pref))
   (Tiene_Complejidad (juego ?j) (nivel ?c_juego))
   (test (Coincide_Preferencia ?c_pref ?c_juego))
   =>
   (modify ?r (prioridad "Media"))
)

(defrule Aumento_Prioridad_Por_Duracion
   ?r <- (Potencial_Recomendacion (usuario ?u) (juego ?j) (prioridad ?p))
   (Prefiere_Duracion (usuario ?u) (tipo ?d_pref))
   (Tiene_Duracion (juego ?j) (tipo ?d_juego))
   (test (Coincide_Preferencia ?d_pref ?d_juego))
   =>
   (modify ?r (prioridad "Media"))
)

(defrule Aumento_Prioridad_Por_Multiplayer
   ?r <- (Potencial_Recomendacion (usuario ?u) (juego ?j) (prioridad ?p))
   (Prefiere_Multiplayer (usuario ?u) (tipo ?m_pref))
   (Tiene_Multiplayer (juego ?j) (tipo ?m_juego))
   (test (Coincide_Preferencia_Multiplayer ?m_pref ?m_juego))
   =>
   (modify ?r (prioridad "Media"))
)

(defrule Recomendacion_Por_Similitud
   (Usuario (id ?u))
   (Gusto_Juego (usuario ?u) (juego ?jg))
   (Similar_A (juego1 ?js) (juego2 ?jg))
   (Posee_Plataforma (usuario ?u) (plataforma ?p))
   (Disponible_En (juego ?js) (plataforma ?p))
   (not (Jugo_Juego (usuario ?u) (juego ?js)))
   (not (No_Gusto_Juego (usuario ?u) (juego ?js)))
   (not (Potencial_Recomendacion (usuario ?u) (juego ?js) (prioridad ?)))
   (Edad_Usuario (usuario ?u) (edad ?edad))
   (Clasificacion_Edad (juego ?js) (clasificacion ?clasif))
   (test (not (Es_Inapropiado ?clasif ?edad)))
   =>
   (assert (Potencial_Recomendacion (usuario ?u) (juego ?js) (prioridad "Alta")))
)

(defrule Seleccionar_Recomendacion_Alta
   (Potencial_Recomendacion (usuario ?u) (juego ?j) (prioridad "Alta"))
   (test (Limite_Recomendaciones_No_Alcanzado ?u))
   =>
   (assert (Recomendacion_Final (usuario ?u) (juego ?j) (razon "AltaPrioridad")))
)

(defrule Seleccionar_Recomendacion_Media
   (Potencial_Recomendacion (usuario ?u) (juego ?j) (prioridad "Media"))
   (test (Limite_Recomendaciones_No_Alcanzado ?u))
   =>
   (assert (Recomendacion_Final (usuario ?u) (juego ?j) (razon "MediaPrioridad")))
)

(defrule Seleccionar_Recomendacion_Baja
   (Potencial_Recomendacion (usuario ?u) (juego ?j) (prioridad "Baja"))
   (test (Limite_Recomendaciones_No_Alcanzado ?u))
   =>
   (assert (Recomendacion_Final (usuario ?u) (juego ?j) (razon "BajaPrioridad")))
)

(defrule Imprimir_Recomendaciones
   (Recomendacion_Final (usuario ?u) (juego ?j) (razon ?r))
   =>
   (printout t "Recomendación para el usuario " ?u ": " ?r " - Juego: " ?j crlf)
)
