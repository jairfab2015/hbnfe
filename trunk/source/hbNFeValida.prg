****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Valida XML)                                                   *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************
#include "common.ch"
#include "hbclass.ch"
#ifndef __XHARBOUR__
   #include "hbwin.ch"
   #include "harupdf.ch"
   #include "hbzebra.ch"
   #include "hbcompat.ch"
#endif
#include "hbnfe.ch"

CLASS hbNFeValida
   DATA ohbNFe
   DATA cXML

   METHOD execute()
ENDCLASS

METHOD execute() CLASS hbNFeValida
LOCAL I, Tipo, cXML, oDOMDoc, oSchema, cMsgErro, aRetorno := hash(), cPastaSchemas,;
      cSchemaFilename, oError, ParseError, nResult

  cPastaSchemas := ::ohbNFe:cPastaSchemas
  IF ".xml" $ lower(::cXML) // Arquivo
     IF !FILE(::cXML)
        aRetorno['OK']       := .F.
        aRetorno['nResult']  := 0
        aRetorno['MsgErro']  := 'Arquivo não encontrado '+::cXML
        RETURN(aRetorno)
     ENDIF
     TRY
        cXML := MEMOREAD(::cXML)
     CATCH
        aRetorno['OK']       := .F.
        aRetorno['nResult']  := 0
        aRetorno['MsgErro']  := 'Problema ao ler '+::cXML
        RETURN(aRetorno)
     END
  ELSE // Memoria
     cXML := ::cXML
  ENDIF
  I := AT('<infNFe',cXML)
  Tipo := 1
  IF I = 0
     I := AT('<infCanc',cXML)
     IF I > 0
        Tipo := 2
     ELSE
        I := AT('<infInut',cXML)
        IF I > 0
           Tipo := 3
        ELSE
           I := AT('<infEvento', cXML)
           IF I > 0
              IF '<tpEvento>110111</tpEvento>'$cXML   // Cancelamento por Evento - Mauricio Cruz - 09/10/2012
                 Tipo := 6
              ELSEIF '<tpEvento>210200</tpEvento>'$cXML .OR. '<tpEvento>210210</tpEvento>'$cXML .OR. '<tpEvento>210220</tpEvento>'$cXML .OR. '<tpEvento>210240</tpEvento>'$cXML // Manifestação do destinatario - Mauricio Cruz 15/10/2012
                 Tipo := 7
              ELSE
                 Tipo := 5
              ENDIF
           ELSE
              Tipo := 4
           ENDIF
        ENDIF
     ENDIF
  ENDIF
  
  #ifdef __XHARBOUR__
     oDOMDoc := xhb_CreateObject( _MSXML2_DOMDocument )
  #else
     oDOMDoc := win_oleCreateObject( _MSXML2_DOMDocument )
  #endif
  oDOMDoc:async = .F.
  oDOMDoc:resolveExternals := .F.
  oDOMDoc:validateOnParse  = .T.
  oDOMDoc:LoadXML(cXML)
  IF oDOMDoc:parseError:errorCode <> 0 // XML não carregado
     cMsgErro := "Não foi possível carregar o documento pois ele não corresponde ao seu Schema"+HB_OsNewLine() +;
                 " Linha: " + STR(oDOMDoc:parseError:line)+HB_OsNewLine() +;
                 " Caractere na linha: " + STR(oDOMDoc:parseError:linepos)+HB_OsNewLine() +;
                 " Causa do erro: " + oDOMDoc:parseError:reason+HB_OsNewLine() +;
                 " Code: "+STR(oDOMDoc:parseError:errorCode)
     aRetorno['OK']       := .F.
     aRetorno['nResult']  := 0
     aRetorno['MsgErro']  := cMsgErro
     RETURN(aRetorno)
  ENDIF
  
  #ifdef __XHARBOUR__
     oSchema := xhb_CreateObject( _MSXML2_XMLSchemaCache )
  #else
     oSchema := win_oleCreateObject( _MSXML2_XMLSchemaCache )
  #endif

  IF EMPTY(cPastaSchemas)
     cPastaSchemas := "\"+CURDIR()
  ENDIF
  IF Tipo = 1
     cSchemaFilename := cPastaSchemas+'\nfe_v2.00.xsd'
  ELSEIF Tipo = 2
     cSchemaFilename := cPastaSchemas+'\cancNFe_v2.00.xsd'
  ELSEIF Tipo = 3
     cSchemaFilename := cPastaSchemas+'\inutNFe_v2.00.xsd'
  ELSEIF Tipo = 4
     cSchemaFilename := cPastaSchemas+'\envDPEC_v1.01.xsd'
  ELSEIF Tipo = 5
     cSchemaFilename := cPastaSchemas+'\envCCe_v1.00.xsd'
  ELSEIF Tipo = 6
     cSchemaFilename := cPastaSchemas+'\envEventoCancNFe_v1.00.xsd'
  ELSEIF Tipo = 7
     cSchemaFilename := cPastaSchemas+'\envConfRecebto_v1.00.xsd'
  ENDIF
  IF !FILE(cSchemaFilename)
     aRetorno['OK']       := .F.
     aRetorno['nResult']  := 0
     aRetorno['MsgErro']  := 'Schema não encontrado '+cSchemaFilename
     RETURN(aRetorno)
  ENDIF
  
  TRY
     oSchema:add( "http://www.portalfiscal.inf.br/nfe", cSchemaFilename )
  CATCH oError
    cMsgErro := "Falha "+HB_OsNewLine()+ ;
            	 "Error: "  + Transform(oError:GenCode, nil) + ";" +HB_OsNewLine()+ ;
            	 "SubC: "   + Transform(oError:SubCode, nil) + ";" +HB_OsNewLine()+ ;
            	 "OSCode: "  + Transform(oError:OsCode,  nil) + ";" +HB_OsNewLine()+ ;
            	 "SubSystem: " + Transform(oError:SubSystem, nil) + ";" +HB_OsNewLine()+ ;
            	 "Mensangem: " + oError:Description
     aRetorno['OK']       := .F.
     aRetorno['nResult']  := 0
     aRetorno['MsgErro']  := cMsgErro
     RETURN(aRetorno)
  END

  oDOMDoc:Schemas := oSchema
  ParseError := oDOMDoc:validate
  nResult := ParseError:errorCode
  cMsgErro   := ParseError:reason
  IF nResult <> 0
     aRetorno['OK']       := .F.
     aRetorno['nResult']  := nResult
     aRetorno['MsgErro']  := cMsgErro
     RETURN(aRetorno)
  ENDIF
  oDOMDoc := nil
  ParseError := nil
  oSchema := nil
  aRetorno['OK'] := .T.

RETURN(aRetorno)
