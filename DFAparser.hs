module DFAparser
-- Un parser para DFAs (Automatas Finitos Deterministas) partiendo del modulo Ejercicio5c.hs
--
    (
      DFA (..)          -- tipo de datos para DFAs
    , parserDFA         -- parser para DFAs
    , parserSpace
    )
where
--
import HuttonParsing
--import Data.Char -- importar algunas funciones relativas a Char
--
import Data.Set as S
    (Set, fromList) -- Finite Sets
    --, toList, empty, insert, intersection, member, unions
-- import Data.List (elem)

--
-- Ejercicios anteriores:
-- import Ejercicio1 -- Si es necesario algo
-- import Ejercicio2 -- Si es necesario algo
-- import Ejercicio3 -- Si es necesario algo

--
------------------------------------------------------------------------
------------------------------------------------------------------------

-- Automatas Finitos Deterministas, DFAs (Deterministic Finite Automata): ----------------
--
-- DFA con parametros para estados y simbolos: -----------------------------------------
data DFA state symbol -- A = (Q, Sigma, delta, q0, F)
    = DFA -- Una tupla para M = (Q,S,e,Delta,S,F)
        ( String                            -- Nombre del DFA
        , S.Set state                       -- conjunto de estados Q
        , S.Set symbol                      -- conjunto de símbolos Sigma
        , S.Set ((state,symbol), state)     -- {((q,s), q') | q,q' in Q, s in Sigma} delta
                                            -- representa la funcion delta : (Q x S) -> Q
        , state                             -- estados inicial q0
        , S.Set state                       -- conjunto de estados de aceptación F
        )
        deriving (Show, Eq)
--
--

-- showDFA FALTA.


-- OBJETIVO: un parser para DFAs
-- tipo del input:
-- "A1= (Q={q0 q1} Sigma={s0 s1} delta={((q0 s0) q1) ((q0 s1) q0)} qInit=q0 F={q1})"

------------------------------------------
--

------------------------------
-- RENOMBRAMOS algunos parsers y funciones de Hutton para claridad en la explicacion

-- charTOparser es una funcion que, dada un caracter,
-- construye un parser que tiene exito solo si el input comienza con dicho caracter.
charTOparser :: Char -> Parser Char
charTOparser    = char   -- la funcion "char" de Hutton la llamamos charTOparser

stringTOparser :: String -> Parser String
stringTOparser  = string -- la funcion "string" de Hutton la llamamos stringTOparser

parserSpace :: Parser ()
parserSpace     = space  -- la funcion "space" de Hutton la llamamos parserSpace

parserTOtoken :: Parser a -> Parser a
parserTOtoken   = token  -- funcion que transforma un parser en token (Hutton)
--
------------------------------
--
-- funcion que transforma un char en un token
charTOtoken :: Char -> Parser Char
charTOtoken c   = parserTOtoken (charTOparser c)

-- funcion que transforma un string en token
stringTOtoken :: String -> Parser String
stringTOtoken str  = parserTOtoken (stringTOparser str)
--
------------------------------
--



--parser para <estado> ::= q<digitos>+  -- q seguido de uno o mas digitos.
-- En forma equivalente (SIN usar X^+)
-- <unoOmasDigitos> ::=  Digito | Digito <unoOmasDigitos>
--parser para <estado> ::= q   -- q seguido de uno o mas digitos.

-- Otro parser para uno o mas digitos
-- NO funciona REVISAR. <============= manyDigit y someDigit son MUTUAMENTE recursivos
-- someDigit :: Parser [Char]
-- someDigit =
--     do
--         d <- digit
--         return [d]
--     <|>
--     do
--         d   <- digit
--         ld  <- someDigit
--         return (d : ld)
--
-- DEFINICION CORRECTA
-- (revisando el codigo de many y some en
-- https://hackage.haskell.org/package/base-4.20.0.1/docs/Control-Applicative.html#v:many  ):
--
-- -- many v = some v <|> pure []
-- manyDigit :: Parser [Char]
-- manyDigit =
--     someDigit <|> pure []
--
-- -- some v = (:) <$> v <*> many v
-- someDigit :: Parser [Char]
-- someDigit = do
--     d   <- digit
--     ld  <- manyDigit
--     return (d:ld)
--

--
------------------------------

--
--------------------------------------------------------------------------
-- Clase 28ago2024:

-- Necesitamos que partes del input se comporten como "tokens"
-- Def. Un token es un parser con "cero o mas blancos" antes y despues del parser.
--      Donde un "blanco" es cualquier carater que se despleiga como blanco en un texto.
--      Por ejemplo, espacio en blanco, tabuladores, caracters para cambio de línea.

-- Hutton nos da una funcion, token, que convierte un parser en un token.
--  Nosotros la renombramos a parserTOtoken.

------------------------------

-- Para definir un token para "{", usando la funcion que transforma un parser en un token:
tokenLlaveIzq :: Parser Char
tokenLlaveIzq = charTOtoken '{'

tokenLlaveDer :: Parser Char
tokenLlaveDer = charTOtoken '}'

------------------------------
tokenParenIzq :: Parser Char
tokenParenIzq = charTOtoken '('

tokenParenDer :: Parser Char
tokenParenDer = charTOtoken ')'
------------------------------


-- OBJETIVO: un parser para DFAs
-- tipo del input:
-- "A1= (Q={q0 q1} Sigma={s0 s1} delta={((q0 s0) q1) ((q0 s1) q0)} qInit=q0 F={q1})"

------------------------------
-- Parser para el nombre de un DFA, e.g. "A1",
-- El nombre de un DFA es "A" seguida de uno o mas digitos
-- <NombreDFA> :: = <LetraA> <Digitos>^+
parserNombreDFA :: Parser [Char]
parserNombreDFA =
    do
        letraA          <- charTOparser 'A' -- <LetraA>
        unoOmasDigitos  <- (some digit)     -- uno o mas digitos, <Digitos>^+
        return (letraA : unoOmasDigitos)

tokenNombreDFA :: Parser [Char]
tokenNombreDFA = parserTOtoken parserNombreDFA
------------------------------


------------------------------
parserEstado :: Parser [Char]
parserEstado =
    do
        char_q          <- (token (char 'q'))--charTOparser 'q'
        unoOmasDigitos  <- (some digit) -- uno o mas digitos (digit= parser un digito).
        return (char_q:unoOmasDigitos)

tokenEstado :: Parser String
tokenEstado = parserTOtoken parserEstado

tokenEq :: Parser Char
tokenEq = charTOtoken '='

-- Un parser para un conjunto de estados usando tokens:
-- e.g. Q={q0 q1}
parserQestados :: Parser (Set [Char])
parserQestados = -- con tokens:
    do
        _           <- charTOtoken 'Q' -- deshechamos 'Q'
        _           <- tokenEq -- deshechamos '='
        _           <- tokenLlaveIzq -- deshechamos {
        listaEdos   <- (some tokenEstado) -- uno o mas tokens de estado
        _           <- tokenLlaveDer -- deshechamos }
        return (fromList listaEdos) -- regresa el conjunto de listaEdos
--

--
------------------------------------------
-- Un parser y un token para simbolos:
--
-- Defininimos un simbolo como 's' seguida de uno o mas digitos
--              <simbolo> :: = s (digito)^+

parserSimbolo :: Parser [Char]
parserSimbolo =
    do
        char_s          <- charTOparser 's'
        unoOmasDigitos  <- (some digit) -- uno o mas digitos (digit= parser un digito).
        return (char_s:unoOmasDigitos)

tokenSimbolo :: Parser String
tokenSimbolo = parserTOtoken parserSimbolo
------------------------------------------
--
-- Un parser para el componente del DFA "  Sigma  = {  s0 s1 } "
parserSigmaSym :: Parser (Set [Char])
parserSigmaSym = -- con tokens:
    do
        _               <- stringTOtoken "Sigma" -- deshechamos "Sigma"
        _               <- tokenEq -- deshechamos '='
        _               <- tokenLlaveIzq -- deshechamos {
        listaSimbolos   <- (some tokenSimbolo) -- uno o mas tokens de simbolo
        _               <- tokenLlaveDer -- deshechamos }
        return (fromList listaSimbolos) -- regresa el conjunto de listaSimbolos
--


-- Parser parserEstadosFin " F = {  q1 q7 }  xxxxx"
-- Un parser para un conjunto de estados Finales (usando tokens):
parserEstadosFin :: Parser (Set [Char])
parserEstadosFin = -- con tokens:
    do
        _               <- charTOtoken 'F' -- deshechamos 'F'
        _               <- tokenEq -- deshechamos '='
        _               <- tokenLlaveIzq -- deshechamos {
        listaEdosFin    <- (some tokenEstado) -- uno o mas tokens de estado
        _               <- tokenLlaveDer -- deshechamos }
        return (fromList listaEdosFin) -- regresa el conjunto de listaEdosFin
--

------------------------------------------
--

-- Parser para una entrada de la funcion delta de un DFA, e.g. ((q0 s0) q1).
-- La entrada ((q0 s0) q1) representa delta(q0 s0)=q1.
-- Gramatica para dicha entrada es:
-- <EntradaDeLaFuncionDelta> :: = ( ( <Estado> <Simbolo> ) <Estado> )
-- <Estado> :: = q <Digito>^+
--          donde <Digito>^+ representa "unoOmasDigitos"
--          -- <unoOmasDigitos> :: = <Digito> | <Digito> <unoOmasDigitos>
-- <Digito> :: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
-- <Simbolo> :: = s <Digito>^+
parserEntradaFdelta :: Parser ((String, String), String)
parserEntradaFdelta = -- e.g. ((q0 s0) q1), que representa
    do
        _   <- tokenParenIzq -- deshechamos '('
        _   <- tokenParenIzq -- deshechamos '('
        q   <- tokenEstado   -- parser token para un estado
        s   <- tokenSimbolo
        _   <- tokenParenDer -- deshechamos ')'
        q'  <- tokenEstado
        _   <- tokenParenDer -- deshechamos ')'
        return ((q,s), q')
--


-- Parser para la funcion delta de un DFA,
-- e.g. delta={((q0 s0) q1) ((q0 s1) q0)}
parserFdelta :: Parser (Set ((String, String), String))
parserFdelta =
    do
        _               <- stringTOtoken "delta" -- deshechamos "delta"
        _               <- tokenEq -- deshechamos '='
        _               <- tokenLlaveIzq -- deshechamos {
        listaEntFdelta  <- (some parserEntradaFdelta) -- una o mas entradas de delta
        _               <- tokenLlaveDer -- deshechamos }
        return (fromList listaEntFdelta) -- regresa el conjunto de entradas de delta
--

------------------------------

-- Parser para el Estado Inicial, e.g " qInit = q0 "
-- <EstadoInicial> ::= qInit = <Estado>
-- <Estado> :: = q <Digito>^+
--          donde <Digito>^+ representa "unoOmasDigitos"
--          <unoOmasDigitos> :: = <Digito> | <Digito> <unoOmasDigitos>

parserEstadoInit :: Parser String
parserEstadoInit =
    do
        _ <- stringTOtoken "qInit"
        _ <- tokenEq
        edoInit <- tokenEstado
        return edoInit
--
------------------------------
--

--
------------------------------------------------------------------------
------------------------------------------------------------------------
--

-- OBJETIVO: un parser para DFAs
-- tipo del input:
-- "A1= (Q={q0 q1} Sigma={s0 s1} delta={((q0 s0) q1) ((q0 s1) q0)} qInit=q0 F={q1})"

-- Parser para un DFA,
-- e.g. "A1= (Q={q0 q1} Sigma={s0 s1} delta={((q0 s0) q1) ((q0 s1) q0)} qInit=q0 F={q1})"
-- <DFA>               ::= <NombreDFA> = ( <ConjuntoEstados> <ConjuntoSimbolos>
--                         <FuncionDelta> <EstadoInicial> <ConjuntoEdosFin> )
-- <NombreDFA>         ::= A <Digito>^+
-- <ConjuntoEstados>   ::= Q = { <Estado>^+ }
-- <ConjuntoSimbolos>  ::= Sigma = { <Simbolo>^+ }
-- <FuncionDelta>      ::= delta = { <EntradaFdelta>^+ }
-- <EstadoInicial>     ::= qInit = <Estado>
-- <ConjuntoEdosFin>   ::= F = { <Estado>^+ }
-- <Estado>            ::= q <Digito>^+
-- <Simbolo>           ::= s <Digito>^+
-- <EntradaFdelta>     ::= ( ( <Estado> <Simbolo> ) <Estado> )
--

-- e.g. "A1= (Q={q0 q1} Sigma={s0 s1} delta={((q0 s0) q1) ((q0 s1) q0)} qInit=q0 F={q1})"
-- la delta representa delta: QxSigma -> Q; y ((q0 s0) q1) representa delta(q0 s0)=q1
parserDFA :: Parser (DFA [Char] [Char])
parserDFA =
    do -- compone en secuencia un grupo de parser
        nombreDFA       <- tokenNombreDFA   --1 parser para el nombre del DFA
        _               <- tokenEq          --  deshechamos '='
        _               <- tokenParenIzq    --  deshechamos '('
        conjEstadosQ    <- parserQestados   --2 parser para una lista de estados
        conjSimbolos    <- parserSigmaSym   --3 parser para una lista de simbolos
        conjFdelta      <- parserFdelta     --4 parser para funcion delta
        edoInicial      <- parserEstadoInit --5 parser para un estado
        conjEdosFinales <- parserEstadosFin --6 parser para Estados Finales
        _               <- tokenParenDer    --  deshechamos ')'
        return (DFA (nombreDFA, conjEstadosQ, conjSimbolos
                    , conjFdelta, edoInicial, conjEdosFinales))
        -- DFA (String, Set state, Set symbol,
        --     Set ((state, symbol), state), state, Set state)
--


