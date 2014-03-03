/*
 *  XPublic()
 *  Clase para el reemplazo de Variables Publicas
 *  Version 2.0
 *
 *  Andrade A. Daniel   // WILSON ALVES
 *  Rosario - Santa Fe - Argentina
 *  andrade_2knews@hotmail.com
 *  http://www.dbwide.com.ar
 *
 *  Aportes: Eduardo Rizzolo  [ER]
 *
 *  DATAS
 * aFields    - Arreglo de variables
 * cFieldName    - Nombre ultima variable accedida
 * nFieldPos     - Valor ultimo variable accedida
 *
 * METODOS
 * New()    - Contructor
 * Add()    - Agrega/define nueva variable
 * Del()    - Borra variable
 * Get()    - Accede a una veriable directamente
 * Set()    - Define nuevo valor directamente
 * GetPos() - Obtener la posición en el array
 * Release()   - Borra todas las variables
 * IsDef()     - Chequea si una variable fue definida
 * Clone()     - Clona la DATA aFields
 * nCount() - Devuelve cantidad de variables definidas
 * Save()      - Salva DATA aFields
 * Restore()   - Restaura DATA aFields
 *
 *  NOTA
 * Para acceder al valor de una variable, se puede hacer de 2 formas,
 * una directa usando oPub:Get("Codigo") o por Prueba/Error oPub:Codigo,
 * este último es mas simple de usar pero más lento.
 *
 * Para definir un nuevo valor a una variable tambien puede ser por 2 formas,
 * directamente por oPub:Set("Codigo", "ABC" ), o por Prueba/Error
 * oPub:Codigo := "ABC".
 *
 * Atencion: Los metodos Get() y Set() no controlan si la variable existe,
 * para ganar en velocidad.
 *
 * Las variables definidas NO son case sensitive.
 *
 *  ULTIMAS
 * Se guarda el Nombre y Posición de la última variable accedida para incrementar
 * la velocidad. (Implementado por Eduardo Rizzolo)
 *
 * EJEMPLO  -- V 2.0
 * FUNCTION Test()
 * LOCAL oP := XPublic():New(), aSave, nFieldPos
 *
 * oP:Add("Codigo")     // Defino variable sin valor inicial
 * oP:Add("Precio", 1.15)     // Defino variable con valor inicial
 * oP:Add("Cantidad", 10 )
 * oP:Add("TOTAL" )
 *
 * // Acceso a variables por prueba/error
 * oP:Total := oP:Precio * oP:Cantidad
 *
 * // Definicion y Acceso a variables directamente
 * oP:Set("Total", oP:Get("precio") * oP:Get("CANTIDAD") )
 *
 * oP:Del("Total")         // Borro una variable
 * ? oP:IsDef("TOTAL")     // Varifico si existe una variable
 *
 * nFieldPos := oP:GetPos("Total") // Obtengo la posición en el array
 * oP:aFields[nFieldPos,2] := 0      // Modifico el Valor en el array directo
 *
 * aSave := oP:Save()      // Guardo las Variables
 * oP:Release()         // Borro TODAS las variables
 * oP:Restore( aSave )     // Restauro las variables
 *
 * oP:End()       // Termino
 *
 * RETURN NIL
 *
 *
 * ****************************************************
 *  Version 2.1
 *  EM 18/05/2002
 *  Por Wilson Alves
 *  wolverine@sercomtel.com.br
 *  Inserido lAutomaticVars
 *  Se lAutomaticVars igual TRUE as varáveis são definidas automaticamente quando atribuido valor

 *  Version 2.2 WILSON ALVES
 *  20/11/2008  - Adicionado metodos SetArray,SetValue
 *                Adicionado propriedade
 */

#include "hbclass.ch"
#include "error.ch"


FUNCTION XTESTE()
LOCAL oP  := TPublic():New(.T.)

   op:Nome       := "Wilson Alves"
   op:Endereco   := "Rua Espirito Santo,653 - Sala 402 - Centro"
   op:Cidade     := "Londrina-PR"
   op:Celular    := "43 3026-7661"
   op:Empresa    := "CASTELO Porto Software"
   op:Email	     := 'wilson@casteloporto.com.br'
   op:Site       := 'www.casteloporto.com.br'

   ? op:Nome,op:Endereco,op:Cidade,op:celular,op:empresa


   op:End()

RETURN NIL



//----------------------------------------------------------------------------
CLASS TPublic FROM XPublic
//----------------------------------------------------------------------------

ENDCLASS

//----------------------------------------------------------------------------
CLASS XPublic // Andrade Daniel (2001-2002) - WILSON ALVES 2003 --->>
//----------------------------------------------------------------------------
   DATA aFields
   DATA nFieldPos  AS NUMERIC     INIT 0   READONLY // [by ER]
   DATA cFieldName AS CHARACTER   INIT ""  READONLY // [by ER]

   DATA lAutomaticVars AS LOGICAL INIT .T.

   METHOD New() CONSTRUCTOR
   METHOD End()       INLINE ::Release()

   METHOD Add( cFieldName, xValue )
   METHOD Del( cFieldName )
   METHOD Get( cFieldName )
   METHOD Set( cFieldName, xValue )

   METHOD GetPos( cFieldName )

   METHOD Release()
   METHOD IsDef( cFieldName )

   METHOD Clone()     INLINE AClone( ::aFields )
   METHOD nCount()    INLINE Len( ::aFields )

   METHOD Save()               INLINE AClone( ::aFields )
   METHOD Restore( aFields )   INLINE ::aFields := AClone( aFields )

   METHOD SetArray( cFieldName, oObj )
   METHOD SetValue

   METHOD Check( cField, uDefault )

   ERROR HANDLER OnError( cMsg, nError )

ENDCLASS

//----------------------------------------------------------------------------
METHOD New(lAutomaticVars) CLASS XPublic
//----------------------------------------------------------------------------

   ::aFields := {}

   lAutomaticVars :=IF(HB_ISNIL(lAutomaticVars),.T.,lAutomaticVars)

   ::lAutomaticVars:=lAutomaticVars

RETURN Self

//----------------------------------------------------------------------------
METHOD Add( cFieldName, xValue ) CLASS XPublic             // [by ER]
//----------------------------------------------------------------------------

   IF cFieldName != NIL

      IF (::nFieldPos := AScan( ::aFields, { |e,n| e[1] == AllTrim(Upper(cFieldName)) } )) != 0

         ::aFields[::nFieldPos,2] := xValue

      ELSE
         aAdd( ::aFields, { AllTrim(Upper(cFieldName)), xValue } )
         ::nFieldPos := Len(::aFields)
      ENDIF

      ::cFieldName  := cFieldName
   ENDIF

RETURN Self

//----------------------------------------------------------------------------
METHOD Check( cField, xValue, lPublic )
//----------------------------------------------------------------------------
   LOCAL nPos

   lPublic:=IF(lPublic==NIL, .F., lPublic)

   IF ( nPos:= ::GetPos( cField ) )  == 0

      IF lPublic
         ::ADD( cField , TPublic():New(.T.))
      ELSE
         ::ADD( cField , xValue )
      ENDIF

   ELSE

      IF ::aFields[ nPos , 2 ]  == Nil .And. lPublic
         ::aFields[ nPos , 2 ]  :=  TPublic():New( .T. )
      ENDIF

   ENDIF

RETURN Nil

//----------------------------------------------------------------------------
METHOD Del( cFieldName ) CLASS XPublic
//----------------------------------------------------------------------------
   LOCAL nFieldPos

   IF cFieldName != NIL
      IF (nFieldPos := AScan( ::aFields, { |e,n| e[1] == AllTrim(Upper(cFieldName)) } )) != 0
         aDel( ::aFields, nFieldPos )
         ::aFields := aSize( ::aFields, Len(::aFields) - 1 )

         ::nFieldPos   := 0
         ::cFieldName  := ""
      ENDIF
   ENDIF

RETURN Self

//----------------------------------------------------------------------------
METHOD Get( cFieldName ) CLASS XPublic                  // [by ER]
//----------------------------------------------------------------------------

   IF cFieldName != ::cFieldName
      ::nFieldPos   := AScan( ::aFields, { |e,n| e[1] == AllTrim(Upper(cFieldName)) } )
      ::cFieldName  := cFieldName
   ENDIF

RETURN ::aFields[::nFieldPos,2]

//----------------------------------------------------------------------------
METHOD SetValue(nFieldPos, oObj )
//----------------------------------------------------------------------------

AADD(::aFields[nFieldPos,2],oObj)

RETURN Nil


//----------------------------------------------------------------------------
METHOD SetArray( cFieldName, oObj )
//----------------------------------------------------------------------------

   cFieldName:=upper( Alltrim( cFieldName ) )

   ::nFieldPos:= AScan( ::aFields, { |e,n| e[1] == cFieldName  } )

   IF (::nFieldPos==0)

      AAdd(::aFields , { cFieldName , oObj } )

      ::nFieldPos:=Len(::aFields)
   ENDIF

RETURN ::nFieldPos

//----------------------------------------------------------------------------
METHOD Set( cFieldName, xValue ) CLASS XPublic             // [by ER]
//----------------------------------------------------------------------------

   cFieldName    := AllTrim(Upper(cFieldName))

   IF cFieldName != ::cFieldName
      ::nFieldPos   := AScan( ::aFields, { |e,n| e[1] == cFieldName } )
      ::cFieldName  := cFieldName
   ENDIF

   ::aFields[::nFieldPos,2] := xValue

RETURN Self

//----------------------------------------------------------------------------
METHOD GetPos( cFieldName ) CLASS XPublic
//----------------------------------------------------------------------------

   cFieldName    := AllTrim(Upper(cFieldName))
   ::cFieldName  := cFieldName

RETURN ::nFieldPos := AScan( ::aFields, { |e,n| e[1] == cFieldName } )


//----------------------------------------------------------------------------
METHOD Release() CLASS XPublic
//----------------------------------------------------------------------------

   AEval(::aFields,{|item| IF(hb_isobject(item) .and. Upper( Item:classname ) $ 'XPUPLIC,TPUBLIC', Item:End(),) } )

   ASize( ::aFields , 0 )

   ::aFields := Nil

   ::cFieldName  := ""
   ::nFieldPos   := 0

RETURN Nil

//----------------------------------------------------------------------------
METHOD IsDef( cFieldName ) CLASS XPublic                // [by ER]
//----------------------------------------------------------------------------
   LOCAL lOk := .F.

   IF cFieldName != NIL
      IF (::nFieldPos := AScan( ::aFields, { |e,n| e[1] == AllTrim(Upper(cFieldName)) } )) != 0
         ::cFieldName := cFieldName
         lOk := .T.
      ENDIF
   ENDIF

RETURN lOk

//----------------------------------------------------------------------------
#ifdef __HARBOUR__
   METHOD OnError( uParam1 )
      LOCAL cMsg := __GetMessage()
      LOCAL nError := If( SubStr( cMsg, 1, 1 ) == "_", 1005, 1004 )
#else
   METHOD OnError( cMsg, nError )
#endif

   LOCAL nField

   cMsg := Upper( AllTrim( cMsg ))

   IF SubStr( cMsg, 1, 1 ) == "_"

      cMsg := SubStr( cMsg, 2 )

      IF cMsg == Upper(::cFieldName)

         #ifdef __HARBOUR__
            ::aFields[::nFieldPos,2] := uParam1
         #else
            ::aFields[::nFieldPos,2] := GetParam( 1, 1 )
         #endif

      ELSEIF ( ::nFieldPos := AScan( ::aFields, { |e,n| e[1] == cMsg } ) ) != 0

         ::cFieldName           := cMsg

         #ifdef __HARBOUR__
            ::aFields[::nFieldPos,2] := uParam1
         #else
            ::aFields[::nFieldPos,2] := GetParam( 1, 1 )
         #endif

      ELSE

         IF !::lAutomaticVars

            WITH OBJECT ErrorNew()

               :SubSystem   = "BASE"
               :SubCode     = nError
               :Severity    = ES_ERROR
               :Description = "Message not found"
               :Operation   = ::ClassName + ":" + cMsg

               Eval( ErrorBlock(), hb_qWith() )

            END OBJECT

            ::cFieldName  := ""
            ::nFieldPos   := 0
         ELSE

            ::ADD(cmsg)

            #ifdef __HARBOUR__
               ::aFields[::nFieldPos,2] := uParam1
            #else
               ::aFields[::nFieldPos,2] := GetParam( 1, 1 )
            #endif

         ENDIF
      ENDIF

   ELSE


      IF cMsg == Upper(::cFieldName)           // [by ER]

         RETURN ::aFields[::nFieldPos,2]

      ELSEIF ( ::nFieldPos := AScan( ::aFields, { |e,n| Upper(Alltrim(e[1])) == Upper(Alltrim(cMsg)) } ) ) != 0

         ::cFieldName  := cMsg

         RETURN ::aFields[::nFieldPos,2]
      ELSE

         IF !::lAutomaticVars


            WITH OBJECT ErrorNew()

               :SubSystem   = "BASE"
               :SubCode     = nError
               :Severity    = ES_ERROR
               :Description = "Message not found"
               :Operation   = ::ClassName + ":" + cMsg

               Eval( ErrorBlock(), hb_qWith() )

            END OBJECT

         ELSE
            AADD( ::aFields,{cMsg,''})
            RETURN ''
         ENDIF

         ::cFieldName  := ""
         ::nFieldPos   := 0

      ENDIF

   ENDIF

RETURN NIL
