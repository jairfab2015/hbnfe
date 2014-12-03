#include "inkey.ch"

PROCEDURE Main
   LOCAL GetList := {}, cChave := Pad( "3514" + Replicate( "0", 16 ) + "55", 44, "0" ), oSefaz

   SetMode( 25, 80 )
   CLS
   DO WHILE .T.
      @ 4, 0 SAY "Chave:" GET cChave PICTURE "@9"
      READ

      IF Lastkey() == K_ESC
         EXIT
      ENDIF

      oSefaz := SefazClass():New()
      @ 6, 0 SAY ""
      IF Substr( cChave, 21, 2 ) == "55" // NFE
         ? oSefaz:NfeConsulta( cChave, "" )
      ELSEIF Substr( cChave, 21, 2 ) == "57" // CTE
         oSefaz:cProjeto := "cte"
         ? oSefaz:CteConsulta( cChave, "" )
      ELSEIF Substr( cChave, 21, 2 ) == "58" // MDFE
         oSefaz:cProjeto := "mdfe"
         ? oSefaz:MdfeConsulta( cChave, "" )
      ELSE
         ? "Documento nao identificado"
      ENDIF
      @ 5, 0 SAY XmlNode( oSefaz:cXmlRetorno, "cStat" )
   ENDDO
   RETURN