****************************************************************************************************
* Funcoes e Classes Relativas a Funcoes NFE                                                        *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificaÁ„o deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************

#include "common.ch"
#include "fileio.ch"
#include "hbclass.ch"
#ifndef __XHARBOUR__
   #include "hbcompat.ch"
#endif
#include "HBXML.ch"

CLASS hbNFeFuncoes
*  // Funcoes de Texto
   METHOD pegaTag(cXML, cTag)
   METHOD eliminaString(cString,cEliminar)
   METHOD parseEncode( cTexto, lExtendido )
   METHOD parseDecode( cTexto )
   METHOD strTostrval( cString, nCasas )
*  // Funcoes de B.O.
   METHOD validaEAN(cCodigoBarras)
   METHOD validaPlaca(cPlaca)
*  // Funcoes de Data
   METHOD FormatDate(dData,cMascara,cSeparador)
   METHOD DesFormatDate(cData)
*  // Funcoes de Valores
   METHOD ponto(nValor,nTamanho,nDecimais,cTipo,cSigla)
*  // Funcoes de Diretorios
   METHOD curDrive()
*  // Funcoes de Calculos
   METHOD modulo11(cStr,nPeso1,nPeso2)
   METHOD BringToDate(cStr)
   Method RemoveAcentuacao(cText)
   Method XMLnaArray(cXml,cFirst)
ENDCLASS

METHOD BringToDate(cStr) CLASS hbNFeFuncoes
/*
   transforma a data do XML em formado data
   Mauricio Cruz - 09/10/2012
*/
LOCAL dRET:=CTOD(STRZERO(VAL(SUBSTR(cStr,9,2)),2)+'/'+STRZERO(VAL(SUBSTR(cStr,6,2)),2)+'/'+LEFT(cSTR,4))
RETURN(dRET)

METHOD eliminaString(cString,cEliminar) CLASS hbNFeFuncoes
LOCAL cRetorno, nI
   cRetorno := ""
   FOR nI=1 TO LEN(cString)
      IF !SUBS(cString,Ni,1) $ cEliminar
         cRetorno += SUBS(cString,Ni,1)
      ENDIF
   NEXT
RETURN(cRetorno)

METHOD pegaTag(cXML, cTag) CLASS hbNFeFuncoes
LOCAL cRetorno, cTagInicio,cTagFim
   cTagInicio := "<"+cTag //+">"
   cTagFim := "</"+cTag+">"
   cRetorno := SUBS( cXML, AT(cTagInicio,cXML)+LEN(cTagInicio)+1, AT(cTagFim,cXML)-(AT(cTagInicio,cXML)+LEN(cTagInicio)+1) )
RETURN(cRetorno)

METHOD FormatDate(dData,cMascara,cSeparador) CLASS hbNFeFuncoes
LOCAL cResultado

   IF cSeparador=Nil
      cSeparador="/"
   ENDIF
   cResultado:=""
   IF cMascara     == "DD"+cSeparador+"MM"+cSeparador+"YYYY"
      cResultado = SUBS(DTOC(dData),1,2)+cSeparador+SUBS(DTOC(dData),4,2)+cSeparador+SUBS(DTOC(dData),7,4)
   ELSEIF cMascara == "YYYY"+cSeparador+"MM"+cSeparador+"DD"
      cResultado = SUBS(DTOC(dData),7,4)+cSeparador+SUBS(DTOC(dData),4,2)+cSeparador+SUBS(DTOC(dData),1,2)
   ELSEIF cMascara == "YYYY"+cSeparador+"DD"+cSeparador+"MM"
      cResultado = SUBS(DTOC(dData),7,4)+cSeparador+SUBS(DTOC(dData),1,2)+cSeparador+SUBS(DTOC(dData),4,2)
   ELSEIF cMascara == "MM"+cSeparador+"YYYY"
      cResultado = SUBS(DTOC(dData),4,2)+cSeparador+SUBS(DTOC(dData),7,4)
   ELSEIF cMascara == "DD"+cSeparador+"MM"+cSeparador+"YY"
      cResultado = SUBS(DTOC(dData),1,2)+cSeparador+SUBS(DTOC(dData),4,2)+cSeparador+SUBS(DTOC(dData),9,2)
   ELSEIF cMascara == "YY"+cSeparador+"MM"+cSeparador+"DD"
      cResultado = SUBS(DTOC(dData),9,2)+cSeparador+SUBS(DTOC(dData),4,2)+cSeparador+SUBS(DTOC(dData),1,2)
   ELSEIF cMascara == "YY"+cSeparador+"DD"+cSeparador+"MM"
      cResultado = SUBS(DTOC(dData),9,2)+cSeparador+SUBS(DTOC(dData),1,2)+cSeparador+SUBS(DTOC(dData),4,2)
   ELSEIF cMascara == "MM"+cSeparador+"YY"
      cResultado = SUBS(DTOC(dData),4,2)+cSeparador+SUBS(DTOC(dData),9,2)
   ELSEIF cMascara == "DD"+cSeparador+"MM"
      cResultado = SUBS(DTOC(dData),1,2)+cSeparador+SUBS(DTOC(dData),4,2)
   ELSEIF cMascara == "YYYY"
      cResultado = SUBS(DTOC(dData),7,4)
   ELSEIF cMascara == "YY"
      cResultado = SUBS(DTOC(dData),9,2)
   ELSEIF cMascara == "YYMM"
      cResultado = SUBS(DTOC(dData),9,2)+SUBS(DTOC(dData),4,2)
   ELSEIF cMascara == "MM"
      cResultado = SUBS(DTOC(dData),4,2)
   ELSEIF cMascara == "YYMMDD"
      cResultado = SUBS(DTOC(dData),9,2)+SUBS(DTOC(dData),4,2)+SUBS(DTOC(dData),1,2)
   ELSEIF cMascara == "YYDDMM"
      cResultado = SUBS(DTOC(dData),9,2)+SUBS(DTOC(dData),1,2)+SUBS(DTOC(dData),4,2)
   ELSEIF cMascara == "DD"
      cResultado = SUBS(DTOC(dData),1,2)
   ENDIF

RETURN(cResultado)


********  PONTUACAO DE VALORES *********
METHOD ponto(nValor,nTamanho,nDecimais,cTipo,cSigla) CLASS hbNFeFuncoes
LOCAL cRetorno, nIncPonto, nQuantidadeMaior
  IF nTamanho = Nil
     nTamanho = 13
  ENDIF
  IF nDecimais = Nil
     nDecimais = 2
  ENDIF
  IF cTipo = Nil
     cTipo= "normal"
  ENDIF
  IF cSigla = Nil
     cSigla = ""
  ENDIF
  IF nValor = 0  .AND. cTipo="branco"
     cRetorno=SPACE(nTamanho)
  ELSE
     cRetorno=TRANSFORM(nValor,"@E 999,999,999,999,999.9999")
     &&                   999,999,999,999,999.9999
     &&                   123456789012346578901324
     &&      20.0         --------------------
     &&       5.0                       -----
     &&       9.0                   ---------
     &&      13.4                    -------------
     &&      13.2                  -------------
     &&      13.3                   -------------
     &&      16.0             ----------------
     &&      16.2               ----------------

     IF nDecimais = 0
        IF (LEN(ALLTRIM(cRetorno))-5) > nTamanho
           nQuantidadeMaior := (LEN(ALLTRIM(cRetorno))-5) - nTamanho
           FOR nIncPonto = 1 TO nQuantidadeMaior
              cRetorno := AtRepl( ".", cRetorno, "", 1 )
           NEXT
           cRetorno=SPAC(24-LEN(cRetorno))+cRetorno
        ENDIF
        cRetorno=SUBS(cRetorno,24-nTamanho-3-1,nTamanho)
        IF SUBS(cRetorno,nTamanho,1) == ","
           cRetorno := " "+SUBS(cRetorno,1,nTamanho-1)
        ENDIF
     ELSE
        IF (LEN(ALLTRIM(cRetorno))-(5-(nDecimais+1))) > nTamanho
           nQuantidadeMaior := (LEN(ALLTRIM(cRetorno))-(5-(nDecimais+1))) - nTamanho
           FOR nIncPonto = 1 TO nQuantidadeMaior
              cRetorno := AtRepl( ".", cRetorno, "", 1 )
           NEXT
           cRetorno=SPAC(24-LEN(cRetorno))+cRetorno
        ENDIF
        cRetorno=SUBS(cRetorno,24-nTamanho-3+nDecimais,nTamanho)
     ENDIF

     IF EMPTY(SUBS(cRetorno,1,2)) .AND. !EMPTY(cSigla)
        cRetorno=SUBS(cSigla,1,2)+SUBS(cRetorno,3, (nTamanho-2) )
     ELSEIF EMPTY(SUBS(cRetorno,1,1)) .AND. !EMPTY(cSigla)
        cRetorno=SUBS(cSigla,1,1)+SUBS(cRetorno,2, (nTamanho-1) )
     ENDIF

  ENDIF
RETURN(cRetorno)

METHOD curDrive() CLASS hbNFeFuncoes
#ifdef __XHARBOUR__
   RETURN( CURDRIVE() )
#else
   RETURN( HB_CURDRIVE() )
#endif

* modulo11 Baseado na funÁ„o modulo11 do maligno
METHOD modulo11(cStr,nPeso1,nPeso2) CLASS hbNFeFuncoes  // mÛdulo 11, com pesos nPeso1 (inicial) a nPeso2 (final), que
LOCAL nTot := 0                                         // ser„o utilizados no multiplicador dos dÌgitos, apanhados da
LOCAL nMul := nPeso1                                    // direita para a esquerda. Tal multiplicador ser· reciclado e
LOCAL i                                                 // voltar· para nPeso1, quando o limite (nPeso2) for atingido.

FOR i := Len(cStr) TO 1 STEP -1
  nTot += VAL(SubStr(cStr,i,1)) * nMul
  nMul := IF(nMul=nPeso2, nPeso1, nMul+1)
NEXT

RETURN IF(nTot%11 < 2, "0", STR(11-(nTot%11),1))

METHOD parseEncode( cTexto, lExtendido ) CLASS hbNFeFuncoes
LOCAL cRetorno, aFrom, aTo, aFromTo, nI, nI2
   // especiais
   if lExtendido=nil
      lExtendido:=.f.
   endif

   aFrom := { '&', 'Ä', 'á', 'â', '"', "'", '<', '>', '∫', '™' }
   aTo   := { '&amp;', '«', 'Á', 'Î', '&quot;', '&#39;', '&lt;', '&gt;', '&#176;', '&#170;' }
   cRetorno := cTexto
   FOR nI = 1 TO LEN(aFrom)
      if lExtendido
         if nI<>5 // para esse n„o deve remover
            cRetorno := STRTRAN( cRetorno, aFrom[nI], aTo[nI] )
         endif
      else
         cRetorno := STRTRAN( cRetorno, aFrom[nI], aTo[nI] )
      endif
   NEXT
   // normais
   aFromTo := { {'·„‰‡‚', 'a'},;
                {'¡√ƒ¿¬', 'A'},;
                {'ÈÎ‡Í' , 'e'},;
                {'…À» ' , 'E'},;
                {'ÌÔÏÓ' , 'i'},;
                {'ÕœÃŒ' , 'I'},;
                {'ÛıˆÚÙ', 'o'},;
                {'”’÷“‘', 'O'},;
                {'˙¸˘˚' , 'u'},;
                {'⁄‹Ÿ€' , 'U'},;
                {'«'    , 'C'},;
                {'Á'    , 'c'};
              }
   FOR nI = 1 TO LEN( aFromTo )
      FOR nI2 = 1 TO LEN( aFromTo[nI,1] )
         cRetorno := STRTRAN( cRetorno, SUBS(aFromTo[nI,1],nI2,1), aFromTo[nI,2] )
      NEXT nI2
   NEXT nI
RETURN(cRetorno)

METHOD parseDecode( cTexto ) CLASS hbNFeFuncoes
LOCAL cRetorno, aFrom, aTo, nI
   aTo := { '&', '"', "'", '<', '>', '∫', '™' }
   aFrom := { '&amp;', '&quot;', '&#39;', '&lt;', '&gt;', '&#176;', '&#170;' }

   FOR nI=1 TO LEN(aFrom)
      cRetorno := STRTRAN( cTexto, aFrom[nI], aTo[nI] )
   NEXT
RETURN(cRetorno)

METHOD strTostrval( cString, nCasas ) CLASS hbNFeFuncoes
LOCAL cRetorno
   IF nCasas = Nil
      nCasas = 2
   ENDIF
   cRetorno := STRTRAN( cString, ',' , '.' )
   cRetorno := VAL( cRetorno )
   cRetorno := ALLTRIM( STR( cRetorno ,20, nCasas) )
RETURN(cRetorno)

METHOD validaEAN(cCodigoBarras) CLASS hbNFeFuncoes // funÁ„o adaptada do Dr_Spock_Two do forum pctoledo
LOCAL nInd, nUnidade, nDigito, lRetorno   := .f., aPosicao[12], aRetorno := Array(2)
   IF STRZERO(LEN(TRIM(cCodigoBarras)), 2,0) $ "08 13 14"
      IF LEN(TRIM(cCodigoBarras)) == 8
         cCodigoBarras := STRZERO(LEN(ALLTRIM(cCodigoBarras)), 13, 0)
      ELSEIF LEN(TRIM(cCodigoBarras)) == 14
         cCodigoBarras := RIGHT(cCodigoBarras, 13)
      ENDIF
      FOR nInd := 1 TO 12
         aPosicao[nInd] := VAL(SUBS(cCodigoBarras, nInd, 1))
      NEXT
      nUnidade := VAL(RIGHT(STR(((aPosicao[2]+aPosicao[4]+aPosicao[6]+aPosicao[8]+aPosicao[10]+aPosicao[12])*3) + ( aPosicao[1]+aPosicao[3]+aPosicao[5]+aPosicao[7]+aPosicao[9]+aPosicao[11])), 1))
      nDigito  := IF((10-nUnidade ) > 9, 0, 10-nUnidade)
      lRetorno := nDigito = VAL(RIGHT(ALLTRIM(cCodigoBarras), 1))
      IF !lRetorno
         aRetorno[2] := "O digito verificador esta incorreto !"
      ENDIF
   ELSE
      IF LEN( TRIM ( cCodigoBarras ) ) = 0
         lRetorno := .T.
      ELSE
         aRetorno[2] := "O tamanho do campo devera conter 8, 13 ou 14 digitos !"
      ENDIF
   ENDIF
   aRetorno[1] := lRetorno
RETURN aRetorno

METHOD validaPlaca(cPlaca) CLASS hbNFeFuncoes
   LOCAL lRetorno := .T., nI
   IF LEN(cPlaca) = 7
      FOR nI = 1 TO LEN(cPlaca)
         IF nI <= 3 // letras
            IF SUBS( cPlaca, nI, 1 ) $ '0123456789'
               EXIT
            ENDIF
         ELSE
            IF !SUBS( cPlaca, nI, 1 ) $ '0123456789'
               EXIT
            ENDIF
         ENDIF
      NEXT
   ELSE
      lRetorno := .F.
   ENDIF
   RETURN lRetorno





Method RemoveAcentuacao(cText) CLASS hbNFeFuncoes
  cText:= StrTran(cText,"√","A")
  cText:= StrTran(cText,"¬","A")
  cText:= StrTran(cText,"¡","A")
  cText:= StrTran(cText,"ƒ","A")
  cText:= StrTran(cText,"¿","A")
  cText:= StrTran(cText,"„","a")
  cText:= StrTran(cText,"‚","a")
  cText:= StrTran(cText,"·","a")
  cText:= StrTran(cText,"‰","a")
  cText:= StrTran(cText,"‡","a")

  cText:= StrTran(cText,"…","E")
  cText:= StrTran(cText," ","E")
  cText:= StrTran(cText,"À","E")
  cText:= StrTran(cText,"»","E")
  cText:= StrTran(cText,"È","e")
  cText:= StrTran(cText,"Í","e")
  cText:= StrTran(cText,"Î","e")
  cText:= StrTran(cText,"Ë","e")
  cText:= StrTran(cText,"Õ","I")

  cText:= StrTran(cText,"Œ","I")
  cText:= StrTran(cText,"œ","I")
  cText:= StrTran(cText,"Ã","I")
  cText:= StrTran(cText,"Ì","i")
  cText:= StrTran(cText,"Ó","i")
  cText:= StrTran(cText,"Ô","i")
  cText:= StrTran(cText,"Ï","i")

  cText:= StrTran(cText,"”","O")
  cText:= StrTran(cText,"’","O")
  cText:= StrTran(cText,"‘","O")
  cText:= StrTran(cText,"Û","O")
  cText:= StrTran(cText,"÷","O")
  cText:= StrTran(cText,"“","O")
  cText:= StrTran(cText,"ı","o")
  cText:= StrTran(cText,"Ù","o")
  cText:= StrTran(cText,"Û","o")
  cText:= StrTran(cText,"ˆ","o")
  cText:= StrTran(cText,"Ú","o")
  cText := StrTran(cText,"∫","")
  cText:= StrTran(cText,CHR(176),"")

  cText:= StrTran(cText,"€","U")
  cText:= StrTran(cText,"⁄","U")
  cText:= StrTran(cText,"‹","U")
  cText:= StrTran(cText,"Ÿ","U")
  cText:= StrTran(cText,"˚","u")
  cText:= StrTran(cText,"˙","u")
  cText:= StrTran(cText,"¸","u")
  cText:= StrTran(cText,"˘","u")

  cText := StrTran(cText,"«","C")
  cText := StrTran(cText,"Á","c")
  cText := StrTran(cText,"&")
return(cText)




/*
   Recebe a data no formato 'yyyy-mm-ddThh:mm:ss' e retorna uma data xBase
   Mauricio Cruz - 23/05/2013
*/
METHOD DesFormatDate( cData ) CLASS hbNFeFuncoes
   LOCAL dRet
   IF At( 'T', cData ) > 0
      cData := Left( cData, At( 'T', cData ) - 1 )
   ENDIF
   dRet := Ctod( Right( cData, 2 ) + '/' + Substr( cData, 6, 2 ) + '/' + Left( cData, 4 ) )
   RETURN dRet



Method XMLnaArray(cXml,cFirst) CLASS hbNFeFuncoes
/*
   Retorna um XML na array
   Armando Pinto /  Mauricio Cruz - 31/05/2013
    - cXml = caminho do arquivo xml
    - cFirst = tag inicial que deseja comecar a ler
   {NOME DA TAG, CONTEUDO DA TAG, NIVEL}
*/
LOCAL oXmlDoc := TXmlDocument():new()
LOCAL oXmlNode, oXmlIter
LOCAL aRetorno:={}, aTOK
LOCAL cPath
LOCAL CTe_GERAIS:=oCTe_GERAIS()
LOCAL cNod

HB_GCAll(.T.)

cXml:=Memoread( cXml )
cXML:=LIMPA_STR_XML_HTML(cXML)
cXML:=HtmlToAnsi(STRTRAN(STRTRAN( cXml ,'<![CDATA['),']]>'))
cXML:=CTe_GERAIS:rgLimpaString( cXml )
cXML:=LIMPA_STR_XML(cXML)

oXMlDoc:read(  CTe_GERAIS:rgLimpaString( cXml ) )
IF oXMlDoc=NIL
   RETURN(aRetorno)
ENDIF

oXmlNode:=oXmlDoc:findFirst(cFirst)
IF oXmlNode=NIL
   RETURN(aRetorno)
ENDIF

oXmlIter:=TXmlIterator():new( oXmlNode )
IF oXmlNode=NIL
   RETURN(aRetorno)
ENDIF

WHILE .T.
   oXmlNode := oXmlIter:next()
   IF oXmlNode == NIL
      EXIT
   ENDIF
   TRY
      cPath:=SUBSTR(STRTRAN(oXMLNode:Path(),'/','.'),2,LEN(oXMLNode:Path()))
   CATCH
      cPath:=''
   END
   aTOK:=HB_ATokens( cPath,".",.F.,.F.)
   IF LEN(aTOK)>=2
      cNOD:=aTOK[LEN(aTOK)-1]
   ELSE
      cNOD:=''
   ENDIF
   AADD(aRetorno, {oXMLNode:cName,oXMLNode:cData,cPath,cNOD })
ENDDO

Return(aRetorno)


#pragma BeginDump
#include "windows.h"
#include "hbapi.h"

typedef INT (WINAPI * _CONSISTEINSCRICAOESTADUAL)(const char *szInscr_Est,const char *szEstado);

HB_FUNC( HBNFE_CONSISTEINSCRICAOESTADUAL )
{
   HINSTANCE handle = LoadLibrary( "ie32_dll3.dll" );
   if ( handle )
   {
      const char *szInscr_Est = hb_parcx(1);
      const char *szEstado = hb_parcx(2);
      _CONSISTEINSCRICAOESTADUAL pFunc;

      pFunc = ( _CONSISTEINSCRICAOESTADUAL ) GetProcAddress( handle,"ConsisteInscricaoEstadual");
      hb_retni( pFunc( szInscr_Est,szEstado ));
      FreeLibrary( handle );
   }
}
#pragma EndDump


*************************
FUNCTION HBNFE_CNPJ(FCGC)
*************************
LOCAL T :=0,  TT
LOCAL CCNPJ := SPACE(18)

LOCAL PARTEA1 := SUBS(FCGC,1,2)  //   Divide a
LOCAL PARTEA2 := SUBS(FCGC,3,3)  //   variavel
LOCAL PARTEA3 := SUBS(FCGC,6,3)  //     em 5
LOCAL PARTEA4 := SUBS(FCGC,9,4) //    partes
LOCAL PARTEA5 := SUBS(FCGC,13,2) //    partes

LOCAL PARTE1
LOCAL PARTE2
LOCAL PARTE3
LOCAL PARTE4
LOCAL PARTE5

CCNPJ = PARTEa1+PARTEa2+PARTEa3+PARTEa4 // Junta as 4 partes

FOR TT =  12 TO 5 STEP -1                         //
        T = T + VAL(SUBS(CCNPJ,TT,1)) * (14 - TT)  //
NEXT TT                                           //
FOR TT =  4 TO 1 STEP -1                          //
        T = T + VAL(SUBS(CCNPJ,TT,1)) * (6 - TT)   //   Processa
NEXT TT                                           //  os calculos
TT :=  T - (INT(T/11)*11)                         //     para
IF TT < 2                                         //   verificar
        TT :=  0                                  //   o primeiro
ELSE                                              //    digito
        TT :=  11 - TT                            //
ENDIF                                             //
CCNPJ =  CCNPJ + STR(TT,1) // Junta o primeiro digito com as 4 primeiras partes

T= 0 // Zera a variavel para inicio do novo calculo
FOR TT =  13 TO 6 STEP -1                         //
        T = T + VAL(SUBS(CCNPJ,TT,1)) * (15 - TT)  //
NEXT TT                                           //
FOR TT =  5 TO 1 STEP -1                          //
        T = T + VAL(SUBS(CCNPJ,TT,1)) * (7 - TT)   //    Processa
NEXT TT                                           //    o calculo
TT :=  T - (INT(T/11)*11)                         //  para verificar
IF TT < 2                                         //    o segundo
        TT :=  0                                  //     digito
ELSE                                              //
        TT :=  11 - TT                            //
ENDIF                                             //
CCNPJ =  CCNPJ + STR(TT,1) // Junta o segundo digito ao restante inicial

PARTE1 = SUBS(CCNPJ,1,2)  //
PARTE2 = SUBS(CCNPJ,3,3)  //  Divide novamente
PARTE3 = SUBS(CCNPJ,6,3)  //     a variavel
PARTE4 = SUBS(CCNPJ,9,4)  //  agora em 5 partes
PARTE5 = SUBS(CCNPJ,13,2) //
CCNPJ = PARTE1+PARTE2+PARTE3+PARTE4+PARTE5               // Monta a variavel conforme um CCNPJ verdadeiro
IF CCNPJ != PARTEa1+PARTEa2+PARTEa3+PARTEa4+PARTEa5
   RETURN .F.
ENDIF
RETURN .T.


************************
FUNCTION HBNFE_CPF(FCPF)
************************
LOCAL T :=0,  TT
LOCAL CCPF :=  SPACE(11)

LOCAL PARTE1
LOCAL PARTE2
LOCAL PARTE3
LOCAL PARTE4

LOCAL PARTEA1 := SUBS(FCPF,1,3)  //    Divide a variavel
LOCAL PARTEA2 := SUBS(FCPF,4,3)  //          em 3
LOCAL PARTEA3 := SUBS(FCPF,7,3)  //         Partes
LOCAL PARTEA4 := SUBS(FCPF,10,2)  //        Partes

CCPF = PARTEA1+PARTEA2+PARTEA3 // Junta as 3 partes

FOR TT =  1 TO 9                                //
    T = T + VAL(SUBS(CCPF,TT,1)) * (11 - TT) //
NEXT TT                                         //
TT :=  T - (INT(T/11)*11)                       //  Processa os calculos
IF TT < 2                                       //     para verificar
   TT :=  0                                //    o primeiro digito
ELSE                                            //
   TT :=  11 - TT                          //
ENDIF                                           //
CCPF =  CCPF + STR(TT,1) // Junta o primeiro digito com as 3 primeiras partes

T= 0 // Zera a variavel para inicio do novo calculo
FOR TT =  2 TO 9                                //
        T = T + VAL(SUBS(CCPF,TT,1)) * (12 - TT) //
NEXT TT                                         //
T = T + VAL(SUBS(CCPF,10,1)) * 2                 //
TT :=  T - (INT(T/11)*11)                       //  Processa os calculos
IF TT < 2                                       //     para verificar
        TT :=  0                                //    o segundo digito
ELSE                                            //
        TT :=  11 - TT                          //
ENDIF                                           //
CCPF =  CCPF + STR(TT,1) // Junta o segundo digito ao restante inicial

PARTE1 = SUBS(CCPF,1,3)  //
PARTE2 = SUBS(CCPF,4,3)  // Divide novamente a variavel
PARTE3 = SUBS(CCPF,7,3)  //    agora em 4 partes
PARTE4 = SUBS(CCPF,10,2) //
CCPF = PARTE1+PARTE2+PARTE3+PARTE4         // Monta a variavel conforme um CCPF verdadeiro
IF CCPF !=PARTEA1+PARTEA2+PARTEA3+PARTEA4
   RETURN .F.
ENDIF
RETURN .T.

/*
   retorna o codigo do estado
   Mauricio Cruz - 21/09/2011
*/
FUNCTION CODIGO_UF( cEST, nORDRET )
   LOCAL aEST := {}, cRET := "", nBUSCA := 1, nScan

   nOrdRet := iif( nOrdRet == NIL, 2, nOrdRet )
   IF nORDRET = 1
      nBUSCA := 2
   ELSEIF nORDRET = 2
      nBUSCA := 1
   ENDIF

   //AADD(aEST,{ UF , CÛdigo UF , Unidade da FederaÁ„o , ¡rea (Km2) })

   AADD( aEST, { 'RO', '11', 'RondÙnia',            '237576167'  } )
   AADD( aEST, { 'AC', '12', 'Acre',                '152581388'  } )
   AADD( aEST, { 'AM', '13', 'Amazonas',            '1570745680' } )
   AADD( aEST, { 'RR', '14', 'Roraima',             '224298980'  } )
   AADD( aEST, { 'PA', '15', 'Par·',                '1247689515' } )
   AADD( aEST, { 'AP', '16', 'Amap·',               '142814585'  } )
   AADD( aEST, { 'TO', '17', 'Tocantins',           '277620914'  } )
   AADD( aEST, { 'MA', '21', 'Maranh„o',            '331983293'  } )
   AADD( aEST, { 'PI', '22', 'PiauÌ',               '251529186'  } )
   AADD( aEST, { 'CE', '23', 'Cear·',               '148825602'  } )
   AADD( aEST, { 'RN', '24', 'Rio Grande do Norte', '52796791'   } )
   AADD( aEST, { 'PB', '25', 'ParaÌba',             '56439838'   } )
   AADD( aEST, { 'PE', '26', 'Pernambuco',          '98311616'   } )
   AADD( aEST, { 'AL', '27', 'Alagoas',             '27767661'   } )
   AADD( aEST, { 'SE', '28', 'Sergipe',             '21910348'   } )
   AADD( aEST, { 'BA', '29', 'Bahia',               '564692669'  } )
   AADD( aEST, { 'MG', '31', 'Minas Gerais',        '586528293'  } )
   AADD( aEST, { 'ES', '32', 'EspÌrito Santo',      '46077519'   } )
   AADD( aEST, { 'RJ', '33', 'Rio de Janeiro',      '43696054'   } )
   AADD( aEST, { 'SP', '35', 'S„o Paulo',           '248209426'  } )
   AADD( aEST, { 'PR', '41', 'Paran·',              '199314850'  } )
   AADD( aEST, { 'SC', '42', 'Santa Catarina',      '95346181'   } )
   AADD( aEST, { 'RS', '43', 'Rio Grande do Sul',   '281748538'  } )
   AADD( aEST, { 'MS', '50', 'Mato Grosso do Sul',  '357124962'  } )
   AADD( aEST, { 'MT', '51', 'Mato Grosso',         '903357908'  } )
   AADD( aEST, { 'GO', '52', 'Goi·s',               '340086698'  } )
   AADD( aEST, { 'DF', '53', 'Distrito Federal',    '5801937'    } )

   nSCAN := ASCAN( aEST, { | x | Upper( Alltrim( x[ nBUSCA ] ) ) = Upper( Alltrim( cEST ) ) } )
   IF nSCAN > 0
      cRET := aEST[ nSCAN, nORDRET ]
   ENDIF
   RETURN cRET


/*
   Remove conjuntos de caracteres em HTML que n„o pode ser convertido para n„o dar problema na leitura do XML
   Mauricio Cruz - 13/02/2014
*/
FUNCTION LIMPA_STR_XML_HTML( cXML )
   cXML := STRTRAN( cXML, '&gt;' )
   cXML := STRTRAN( cXML, '&lt;' )
   RETURN cXML

/*
   Remove e corrige caracteres para a leitura do XML
   Mauricio Cruz - 13/02/2014
*/
FUNCTION LIMPA_STR_XML(cXML)
   cXML := STRTRAN( cXML, ' >', '>' )
   cXML := STRTRAN( cXML, 'infA dic', 'infAdic' )
   cXML := STRTRAN( cXML, 'Sig natureValue', 'SignatureValue' )
   cXML := STRTRAN( cXML, '<BR>', ';' )
   cXML := STRTRAN( cXML, '<Br>', ';' )
   cXML := STRTRAN( cXML, '<br>', ';' )
   cXML := STRTRAN( cXML, '<bR>', ';' )
   cXML := STRTRAN( cXML, '<bR>', ';' )
   cXML := STRTRAN( cXML, CHR(10), ';' )
   cXML := STRTRAN( cXML, CHR(13), ';' )
   cXML := STRTRAN( cXML, CHR(10) + CHR(13),';' )
   cXML := STRTRAN( cXML, CHR(13) + CHR(10),';' )
   cXML := STRTRAN( cXML, '"2.00"xmlns', '"2.00" xmlns' )
   cXML := STRTRAN( cXML, 'NFexmlns', 'NFe xmlns' )
   cXML := STRTRAN( cXML, 'infNFeId', 'infNFe Id' )
   cXML := STRTRAN( cXML, '"versao="2.00"', '" versao="2.00"' )
   cXML := STRTRAN( cXML, 'detnItem', 'det nItem' )
   cXML := STRTRAN( cXML, 'CanonicalizationMethodAlgorithm', 'CanonicalizationMethod Algorithm' )
   cXML := STRTRAN( cXML, 'ReferenceURI', 'Reference URI' )
   cXML := STRTRAN( cXML, 'TransformAlgorithm', 'Transform Algorithm' )
   cXML := STRTRAN( cXML, 'DigestMethodAlgorithm', 'DigestMethod Algorithm' )
   cXML := STRTRAN( cXML, 'ReferenceURI', 'Reference URI' )
   cXML := STRTRAN( cXML, 'Signaturexmlns', 'Signature xmlns' )
   cXML := STRTRAN( cXML, 'protNFexmlns', 'protNFe xmlns' )
   cXML := STRTRAN( cXML, 'infProtId', 'infProt Id' )
   cXML := STRTRAN( cXML, 'SignedIn fo', 'SignedInfo' )
   cXML := STRTRAN( cXML, 'É' )
   cXML := STRTRAN( cXML, '/ xNome','/xNome' )
   RETURN cXML


/*
   O objetivo desta funÁ„o È montar o "node" do XML com menos fonte.
   Ao invÈs de "<cliente>" + cliente->Codigo + "</cliente>"
   SÛ usar  XmlTag( "cliente", cliente->Codigo )
   Fica um fonte menor e mais legÌvel
   E quando o conte˙do for vazio, o node vira "<cliente />"
*/
FUNCTION XmlTag( cTag, xValue )
   LOCAL cXml

   IF Empty( xValue )
      cXml := "<" + cTag + " />"
   ELSE
      cXml := "<" + cTag + ">" + xValue + "</" + cTag + ">"
   ENDIF
   RETURN cXml
