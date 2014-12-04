****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Valida XML)                                                   *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modifica��o deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************

#include "hbclass.ch"
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
        aRetorno['MsgErro']  := 'Arquivo n�o encontrado '+::cXML
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
              ELSEIF '<tpEvento>210200</tpEvento>'$cXML .OR. '<tpEvento>210210</tpEvento>'$cXML .OR. '<tpEvento>210220</tpEvento>'$cXML .OR. '<tpEvento>210240</tpEvento>'$cXML // Manifesta��o do destinatario - Mauricio Cruz 15/10/2012
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

  oDOMDoc := win_oleCreateObject( _MSXML2_DOMDocument )

  oDOMDoc:async = .F.
  oDOMDoc:resolveExternals := .F.
  oDOMDoc:validateOnParse  = .T.
  oDOMDoc:LoadXML(cXML)
  IF oDOMDoc:parseError:errorCode <> 0 // XML n�o carregado
     cMsgErro := "N�o foi poss�vel carregar o documento pois ele n�o corresponde ao seu Schema" + HB_EOL() + ;
                 " Linha: "              + STR( oDOMDoc:parseError:line )    + HB_EOL() + ;
                 " Caractere na linha: " + STR( oDOMDoc:parseError:linepos ) + HB_EOL() + ;
                 " Causa do erro: "      + oDOMDoc:parseError:reason         + HB_EOL() + ;
                 " Code: " + Str( oDOMDoc:parseError:errorCode )
     aRetorno['OK']       := .F.
     aRetorno['nResult']  := 0
     aRetorno['MsgErro']  := cMsgErro
     RETURN(aRetorno)
  ENDIF

  oSchema := win_oleCreateObject( _MSXML2_XMLSchemaCache )

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
     aRetorno['MsgErro']  := 'Schema n�o encontrado '+cSchemaFilename
     RETURN(aRetorno)
  ENDIF

  TRY
     oSchema:add( "http://www.portalfiscal.inf.br/nfe", cSchemaFilename )
  CATCH oError
    cMsgErro := "Falha " + HB_EOL() + ;
            	 "Error: "     + Transform( oError:GenCode, NIL )   + ";" + HB_EOL() + ;
            	 "SubC: "      + Transform( oError:SubCode, NIL )   + ";" + HB_EOL() + ;
            	 "OSCode: "    + Transform( oError:OsCode,  NIL )   + ";" + HB_EOL() + ;
            	 "SubSystem: " + Transform( oError:SubSystem, NIL ) + ";" + HB_EOL() + ;
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
