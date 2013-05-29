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

CLASS hbNFeFuncoes
*  // Funcoes de Texto
   METHOD pegaTag(cXMLcXML, cTag)
   METHOD eliminaString(cString,cEliminar)
   METHOD parseEncode( cTexto, lExtendido )
   METHOD parseDecode( cTexto )
   METHOD strTostrval( cString )
*  // Funcoes de B.O.
   METHOD validaEAN(cCodigoBarras)
   METHOD validaPlaca(cPlaca)
*  // Funcoes de Data
   METHOD FormatDate(dData,cMascara)
*  // Funcoes de Valores
   METHOD ponto(nValor,nTamanho,nDecimais,cTipo,cSigla)
*  // Funcoes de Diretorios
   METHOD curDrive()
*  // Funcoes de Calculos
   METHOD modulo11(cStr,nPeso1,nPeso2)
   METHOD BringToDate(cStr)
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
Local nInd := 0, nUnidade := 0, nDigito := 0, lRetorno   := .f., aPosicao[12], aRetorno
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
RETURN (aRetorno)

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
RETURN (lRetorno)

#pragma BeginDump
#include "windows.h"
#include "hbapi.h"

typedef INT (WINAPI * _CONSISTEINSCRICAOESTADUAL)(const char *szInscr_Est,const char *szEstado);

HB_FUNC( CONSISTEINSCRICAOESTADUAL )
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


*******************
FUNCTION CNPJ(FCGC)
*******************
LOCAL T :=0,  TT := 0,  TTT :=  0
LOCAL CCNPJ := SPACE(18)

LOCAL PARTEA1 := SUBS(FCGC,1,2)  //   Divide a
LOCAL PARTEA2 := SUBS(FCGC,3,3)  //   variavel
LOCAL PARTEA3 := SUBS(FCGC,6,3)  //     em 5
LOCAL PARTEA4 := SUBS(FCGC,9,4) //    partes
LOCAL PARTEA5 := SUBS(FCGC,13,2) //    partes

LOCAL PARTE1 := ''
LOCAL PARTE2 := ''
LOCAL PARTE3 := ''
LOCAL PARTE4 := ''
LOCAL PARTE5 := ''

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

******************
FUNCTION CPF(FCPF)
******************
LOCAL T :=0,  TT :=0,  TTT :=  0
LOCAL CCPF :=  SPACE(11)

LOCAL PARTE1 := ''
LOCAL PARTE2 := ''
LOCAL PARTE3 := ''
LOCAL PARTE4 := ''

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

FUNCTION CODIGO_UF(cEST)
/*
   retorna o codigo do estado
   Mauricio Cruz - 21/09/2011
*/
LOCAL aEST:={},cRET:=""

//AADD(aEST,{ UF , CÛdigo UF , Unidade da FederaÁ„o , ¡rea (Km2) })

AADD(aEST,{'RO','11','RondÙnia','237576167' })
AADD(aEST,{'AC','12','Acre','152581388'})
AADD(aEST,{'AM','13','Amazonas','1570745680'})
AADD(aEST,{'RR','14','Roraima','224298980'})
AADD(aEST,{'PA','15','Par·','1247689515'})
AADD(aEST,{'AP','16','Amap·','142814585'})
AADD(aEST,{'TO','17','Tocantins','277620914'})
AADD(aEST,{'MA','21','Maranh„o','331983293'})
AADD(aEST,{'PI','22','PiauÌ','251529186'})
AADD(aEST,{'CE','23','Cear·','148825602'})
AADD(aEST,{'RN','24','Rio Grande do Norte','52796791'})
AADD(aEST,{'PB','25','ParaÌba','56439838'})
AADD(aEST,{'PE','26','Pernambuco','98311616'})
AADD(aEST,{'AL','27','Alagoas','27767661'})
AADD(aEST,{'SE','28','Sergipe','21910348'})
AADD(aEST,{'BA','29','Bahia','564692669'})
AADD(aEST,{'MG','31','Minas Gerais','586528293'})
AADD(aEST,{'ES','32','EspÌrito Santo','46077519'})
AADD(aEST,{'RJ','33','Rio de Janeiro','43696054'})
AADD(aEST,{'SP','35','S„o Paulo','248209426'})
AADD(aEST,{'PR','41','Paran·','199314850'})
AADD(aEST,{'SC','42','Santa Catarina','95346181'})
AADD(aEST,{'RS','43','Rio Grande do Sul','281748538'})
AADD(aEST,{'MS','50','Mato Grosso do Sul','357124962'})
AADD(aEST,{'MT','51','Mato Grosso','903357908'})
AADD(aEST,{'GO','52','Goi·s','340086698'})
AADD(aEST,{'DF','53','Distrito Federal','5801937'})

nSCAN:=ASCAN(aEST,{|x| Upper(Alltrim(x[1]))=Upper(Alltrim(cEST)) })
IF nSCAN>0
   cRET:=aEST[nSCAN,2]
ENDIF

RETURN(cRET)
