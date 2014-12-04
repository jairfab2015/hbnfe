*****************************************************************
* ZE_XMLFUN - FUNCOES XML                                       *
* José M. C. Quintas                                            *
*****************************************************************

*----------------------------------------------------------------


FUNCTION XmlTransform( cXml )
   LOCAL nCont, cRemoveTag, lUtf8

   cRemoveTag := { ;
      [<?xml version="1.0" encoding="utf-8"?>], ; // Petrobras inventou de usar assim
      [<?xml version="1.0" encoding="UTF-8"?>] }  // Alguns usam assim

   FOR nCont = 1 TO Len( cRemoveTag )
      cXml := StrTran( cXml, cRemoveTag[ nCont ], "" )
   NEXT
   IF .NOT. ["] $ cXml // Petrobras usa aspas simples
      cXml := StrTran( cXml, ['], ["] )
   ENDIF

   lUtf8 := .F.
   IF Substr( cXml, 1, 1 ) $ Chr(239) + Chr(187) + Chr(191)
      lUtf8 := .T.
   ENDIF
   FOR nCont = 128 TO 159
      IF Chr( nCont ) $ cXml
         lUtf8 := .T.
      ENDIF
   NEXT
   IF lUtf8
      cXml := hb_Utf8ToStr( cXml )
   ENDIF
   FOR nCont = 1 TO 2
      cXml := StrTran( cXml, Chr(26), "" )
      cXml := StrTran( cXml, Chr(13), "" )
      cXml := StrTran( cXml, Chr(10), "" )
      IF Substr( cXml, 1, 1 ) $ Chr(239) + Chr(187) + Chr(191)
         cXml := Substr( cXml, 2 )
      ENDIF
      cXml := StrTran( cXml, " />", "/>" ) // Diferenca entre versoes do emissor
      cXml := StrTran( cXml, Chr(195) + Chr(173), "i" ) // i acentuado minusculo
      cXml := StrTran( cXml, Chr(195) + Chr(135), "C" ) // c cedilha maiusculo
      cXml := StrTran( cXml, Chr(195) + Chr(141), "I" ) // i acentuado maiusculo
      cXml := StrTran( cXml, Chr(195) + Chr(163), "a" ) // a acentuado minusculo
      cXml := StrTran( cXml, Chr(195) + Chr(167), "c" ) // c acentuado minusculo
      cXml := StrTran( cXml, Chr(195) + Chr(161), "a" ) // a acentuado minusculo
      cXml := StrTran( cXml, Chr(195) + Chr(131), "A" ) // a acentuado maiusculo
      cXml := StrTran( cXml, Chr(194) + Chr(186), "o." ) // numero simbolo
      cXml := StrTran( cXml, " />", "/>" ) // Diferenca entre versoes do emissor
      // so pra corrigir no MySql
      cXml := StrTran( cXml, "+" + Chr(129), "A" )
      cXml := StrTran( cXml, "+" + Chr(137), "E" )
      cXml := StrTran( cXml, "+" + Chr(131), "A" )
      cXml := StrTran( cXml, "+" + Chr(135), "C" )
      cXml := StrTran( cXml, "?" + Chr(167), "c" )
      cXml := StrTran( cXml, "?" + Chr(163), "a" )
      cXml := StrTran( cXml, "?" + Chr(173), "i" )
      cXml := StrTran( cXml, "?" + Chr(131), "A" )
      cXml := StrTran( cXml, "?" + Chr(161), "a" )
      cXml := StrTran( cXml, "?" + Chr(141), "I" )
      cXml := StrTran( cXml, "?" + Chr(135), "C" )
      cXml := StrTran( cXml, Chr(195) + Chr(156), "a" )
      cXml := StrTran( cXml, Chr(195) + Chr(159), "A" )
      cXml := StrTran( cXml, "?" + Chr(129), "A" )
      cXml := StrTran( cXml, "?" + Chr(137), "E" )
      cXml := StrTran( cXml, Chr(195) + "?", "C" )
      cXml := StrTran( cXml, "?" + Chr(149), "O" )
      cXml := StrTran( cXml, "?" + Chr(154), "U" )
      cXml := StrTran( cXml, "+" + Chr(170), "o" )
      cXml := StrTran( cXml, "?" + Chr(128), "A" )
      cXml := StrTran( cXml, Chr(195) + Chr(166), "e" )
      cXml := StrTran( cXml, Chr(135) + Chr(227), "ca" )
      cXml := StrTran( cXml, "n" + Chr(227), "na" )
      cXml := StrTran( cXml, Chr(162), "o" )
   NEXT
   RETURN cXml


FUNCTION XmlNode( cXml, cNode, lComTag )
   LOCAL mInicio, mFim, cResultado := ""
   lComTag := iif( lComTag == NIL,.F., lComTag )
   IF " " $ cNode
      cNode := Substr( cNode, 1, At( " ", cNode ) - 1 )
   ENDIF
   mInicio := At( "<" + cNode, cXml )
   IF mInicio != 0
      IF .NOT. lComTag
         mInicio := mInicio + Len( cNode ) + 2
         IF mInicio != 1 .AND. Substr( cXml, mInicio - 1, 1 ) != ">" // Quando tem elementos no bloco
            mInicio := AtStart( ">", cXml, mInicio ) + 1
         ENDIF
      ENDIF
   ENDIF
   IF mInicio != 0
      mFim = AtStart( "</" + cNode + ">", cXml, mInicio )
      IF mFim != 0
         mFim -=1
         IF lComTag
            mFim := mFim + Len( cNode ) + 3
         ENDIF
      ENDIF
      IF mFim <> 0
         cResultado := Substr( cXml, mInicio, mFim - mInicio + 1 )
      ENDIF
   ENDIF
   RETURN cResultado


FUNCTION XmlElement( cXml, cElement )
   LOCAL mInicio, mFim, cResultado := ""
   mInicio := At( cElement + "=", cXml )
   IF mInicio != 0
      mInicio += 1
      mInicio := AtStart( "=", cXml, mInicio ) + 2
   ENDIF
   mFim    := AtStart( ["], cXml, mInicio ) - 1
   IF mInicio >0 .AND. mFim > 0 .AND. mFim > mInicio
      cResultado = Substr( cXml, mInicio, mFim - mInicio + 1 )
   ENDIF
   RETURN cResultado


FUNCTION XmlDate( cData )
   LOCAL dDate
   dDate := Ctod( Substr( cData, 9, 2 ) + "/" + Substr( cData, 6, 2 ) + "/" + Substr( cData, 1, 4 ) )
   RETURN dDate


FUNCTION XmlTag( cTag, cConteudo )
   LOCAL cTexto := ""
   cConteudo := Iif( cConteudo == NIL, "", cConteudo )
   cConteudo := AllTrim( cConteudo )
   IF Len( Trim( cConteudo ) ) = 0
      cTexto := [<]+ cTag + [/>]
   ELSE
      cConteudo := AllTrim( cConteudo )
      IF Len( cConteudo ) == 0
         cConteudo := " "
      ENDIF
      cTexto := cTexto + [<] + cTag + [>] + cConteudo + [</] + cTag + [>]
   ENDIF
   RETURN cTexto


FUNCTION AtStart( cSearch, cString, nStart, nEnd )
   LOCAL nPosicao
   nStart := iif( nStart == NIL, 1, nStart )
   nEnd := iif( nEnd == NIL, Len( cString ), nEnd )
   nPosicao := At( cSearch, Substr( cString, nStart, nEnd ) )
   IF nPosicao != 0
      nPosicao := nPosicao + nStart -1
   ENDIF
   RETURN nPosicao


// Existem 5 caracteres de uso especial no XML:
// (<) &lt. (>) &gt. (&) &amp. (") &quot e (') &apos.
//

FUNCTION UTF8( cTexto )
   cTexto := StrTran( cTexto, "&", "&amp;" )
   RETURN cTexto


FUNCTION DateXml( dDate )
   RETURN Transform( Dtos( dDate ), "@R 9999-99-99" )


FUNCTION DateTimeXml( dDate, cTime )
   cTime := iif( cTime == NIL, Time(), cTime )
   RETURN Transform( Dtos( dDate ), "@R 9999-99-99" ) + "T" + cTime + "+04:00"


FUNCTION NumberXml( nValue, nDecimals )
   RETURN Ltrim( Str( nValue, 16, nDecimals ) )


FUNCTION SoNumeros( cTxt )
   LOCAL cTxt2 := "", nCont
   FOR nCont = 1 TO Len( cTxt )
      IF Substr( cTxt, nCont, 1 ) $ "0123456789"
         cTxt2 += Substr( cTxt, nCont, 1 )
      ENDIF
   NEXT
   RETURN cTxt2