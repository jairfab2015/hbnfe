****************************************************************************************************
* Funcoes e Classes Relativas a CCe                                                                *
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

CLASS hbNFeCCe
   DATA ohbNFe
   DATA cUFWS
   DATA versaoDados
   DATA tpAmb
   DATA idLote INIT '1'
   DATA cUF
   DATA cCNPJ
   DATA cChaveNFe
   DATA dDataEvento
   DATA cHoraEvento
   DATA cUTC
   DATA dhEvento

   DATA nEvento
   DATA Evento EXPORTED

   METHOD execute()
   METHOD AddEvento()
ENDCLASS

METHOD execute() CLASS hbNFeCCe
LOCAL cCN, cUrlWS, cXML, oServerWS, oDOMDoc, cXMLResp, cMsgErro, aRetorno := hash(),;
      oFuncoes := hbNFeFuncoes(), cSOAPAction := 'http://www.portalfiscal.inf.br/nfe/wsdl/RecepcaoEvento',;
      oError, cXMLDadosMsg, cXmlDadosMsg2, nI, cSeq, ;
      cId, cCondUso, cXMLResp2, cXMLResp3, cXMLResp4, oAssina, aRetornoAss, oValida, aRetornoVal, nPos

   IF ::cUFWS = Nil
      ::cUFWS := ::ohbNFe:cUFWS
   ENDIF
   IF ::versaoDados = Nil
      ::versaoDados := ::ohbNFe:versaoDadosCCe
   ENDIF
   IF ::tpAmb = Nil
      ::tpAmb := ::ohbNFe:tpAmb
   ENDIF
   IF ::dhEvento = Nil
      ::dhEvento := oFuncoes:FormatDate(::dDataEvento,"YYYY-MM-DD","-")+'T'+::cHoraEvento+::cUTC
   ENDIF

   cCN := ::ohbNFe:pegaCNCertificado(::ohbNFe:cSerialCert)

   cUrlWS := ::ohbNFe:getURLWS(_EVENTO)
   if cUrlWS = nil
       cMsgErro := "Serviço não mapeado"+ HB_EOL()+;
                   "Serviço solicitado : CCe"
       aRetorno['OK']       := .F.
       aRetorno['MsgErro']  := cMsgErro
       RETURN(aRetorno)
   endif
   TRY

      oServerWS := win_oleCreateObject( _MSXML2_ServerXMLHTTP )

   CATCH
      cMsgErro := "Serviço não mapeado"+ HB_EOL()+;
                  "Serviço solicitado : CCe"
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := cMsgErro
      RETURN(aRetorno)
   END

   oServerWS:setOption( 3, "CURRENT_USER\MY\"+cCN )
   oServerWS:open("POST", cUrlWS, .F.)
   oServerWS:setRequestHeader("SOAPAction", cSOAPAction)
   oServerWS:setRequestHeader("Content-Type", "application/soap+xml; charset=utf-8")

   cCondUso := 'A Carta de Correcao e disciplinada pelo paragrafo 1o-A do art. 7o do Convenio S/N, '+;
               'de 15 de dezembro de 1970 e pode ser utilizada para regularizacao de erro ocorrido na '+;
               'emissao de documento fiscal, desde que o erro nao esteja relacionado com: '+;
               'I - as variaveis que determinam o valor do imposto tais como: base de calculo, aliquota, '+;
               'diferenca de preco, quantidade, valor da operacao ou da prestacao; '+;
               'II - a correcao de dados cadastrais que implique mudanca do remetente ou do destinatario; '+;
               'III - a data de emissao ou de saida.'
   cXMLDadosMsg := '<envEvento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00">' +;
                       '<idLote>'+::idLote+'</idLote>'
   FOR nI = 1 TO ::nEvento
     IF VAL(::Evento[nI]:nSeqEvento) <= 0 .OR. VAL(::Evento[nI]:nSeqEvento) >= 21
          // fora do schema
     ENDIF
     cId := "ID" + "110110" + ::cChaveNFe + STRZERO(VAL(::Evento[nI]:nSeqEvento),2)
     cXMLDadosMsg2 := '<evento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00">' +;
                       '<infEvento Id="'+cId+'">' +;
                         '<cOrgao>'+::cUF+'</cOrgao>' +;
                         '<tpAmb>'+::tpAmb+'</tpAmb>' +;
                         '<CNPJ>'+::cCNPJ+'</CNPJ>' +;
                         '<chNFe>'+::cChaveNFe+'</chNFe>' +;
                         '<dhEvento>'+::dhEvento+'</dhEvento>' +;
                         '<tpEvento>110110</tpEvento>' +;
                         '<nSeqEvento>'+::Evento[nI]:nSeqEvento+'</nSeqEvento>' +;
                         '<verEvento>'+::versaoDados+'</verEvento>' +;
                         '<detEvento versao="1.00">' +;
                           '<descEvento>Carta de Correcao</descEvento>' +;
                           '<xCorrecao>'+oFuncoes:parseEncode( ::Evento[nI]:xCorrecao )+'</xCorrecao>' +;
                           '<xCondUso>'+cCondUso+'</xCondUso>' +;
                         '</detEvento>' +;
                       '</infEvento>' +;
                     '</evento>'

     oAssina := hbNFeAssina()
     oAssina:ohbNFe := ::ohbNfe // Objeto hbNFe
     oAssina:cXMLFile := cXMLDadosMsg2
     oAssina:lMemFile := .T.
     aRetornoAss := oAssina:execute()
     oAssina := Nil
     IF aRetornoAss['OK'] == .F.
        aRetorno['OK']       := .F.
        aRetorno['MsgErro']  := aRetornoAss['MsgErro']
        RETURN(aRetorno)
     ENDIF
     cXMLDadosMsg2 := aRetornoAss[ 'XMLAssinado' ]
     cXMLDadosMsg += cXMLDadosMsg2
   NEXT
   cXMLDadosMsg += +'</envEvento>'

    hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::cChaveNFe + "-ped-cce.xml", cXMLDadosMsg )

    oValida := hbNFeValida()
    oValida:ohbNFe := ::ohbNfe // Objeto hbNFe
    oValida:cXML := cXMLDadosMsg // Arquivo XML ou ConteudoXML
    aRetornoVal := oValida:execute()
    oValida := Nil
    IF aRetornoVal['OK'] == .F.
       aRetorno['OK'] := .F.
       aRetorno['MsgErro'] := aRetornoVal['MsgErro']
       RETURN(aRetorno)
    ELSE
       aRetorno['Validou'] := .T.
    ENDIF

*    QUIT
   cXML := '<?xml version="1.0" encoding="utf-8"?>'
   cXML := cXML + '<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
   cXML := cXML +   '<soap12:Header>'
   cXML := cXML +     '<nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/RecepcaoEvento">'
   cXML := cXML +       '<cUF>'+::cUFWS+'</cUF>'
   cXML := cXML +       '<versaoDados>'+::versaoDados+'</versaoDados>'
   cXML := cXML +     '</nfeCabecMsg>'
   cXML := cXML +   '</soap12:Header>'
   cXML := cXML +   '<soap12:Body>'
   cXML := cXML +     '<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/RecepcaoEvento">'
   cXML := cXML +        cXMLDadosMsg
   cXML := cXML +     '</nfeDadosMsg>'
   cXML := cXML +   '</soap12:Body>'
   cXML := cXML +'</soap12:Envelope>'

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::cChaveNFe + "-ped-cce.xml", cXMLDadosMsg )
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Problema ao gravar pedido da CCe '+::ohbNFe:pastaEnvRes+"\"+::cChaveNFe+"-ped-cce.xml"
      RETURN(aRetorno)
   END

   oDOMDoc := win_oleCreateObject( _MSXML2_DOMDocument )

   oDOMDoc:async = .F.
   oDOMDoc:validateOnParse  = .T.
   oDOMDoc:resolveExternals := .F.
   oDOMDoc:preserveWhiteSpace = .T.
   oDOMDoc:LoadXML(cXML)
   IF oDOMDoc:parseError:errorCode <> 0 // XML não carregado
      cMsgErro := "Não foi possível carregar o documento pois ele não corresponde ao seu Schema"+HB_EOL() +;
                  " Linha: " + STR(oDOMDoc:parseError:line)+HB_EOL() +;
                  " Caractere na linha: " + STR(oDOMDoc:parseError:linepos)+HB_EOL() +;
                  " Causa do erro: " + oDOMDoc:parseError:reason+HB_EOL() +;
                  "code: "+STR(oDOMDoc:parseError:errorCode)
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := cMsgErro
      RETURN(aRetorno)
   ENDIF
   TRY
      oServerWS:send(oDOMDoc:xml)
   CATCH oError
     cMsgErro := "Falha "+HB_EOL()+ ;
             	 "Error: "  + Transform(oError:GenCode, nil) + ";" +HB_EOL()+ ;
              	 "SubC: "   + Transform(oError:SubCode, nil) + ";" +HB_EOL()+ ;
             	 "OSCode: "  + Transform(oError:OsCode,  nil) + ";" +HB_EOL()+ ;
             	 "SubSystem: " + Transform(oError:SubSystem, nil) + ";" +HB_EOL()+ ;
            	 "Mensangem: " + oError:Description
     aRetorno['OK']       := .F.
     aRetorno['MsgErro']  := cMsgErro
     RETURN(aRetorno)
   END
   DO WHILE oServerWS:readyState <> 4
      millisec(500)
   ENDDO
   cXMLResp := HB_ANSITOOEM(oServerWS:responseText)
*   ? cXMLResp

   IF VAL(oFuncoes:pegaTag(cXMLResp, "cStat"))<>128
     aRetorno['OK']       := .F.
     aRetorno['MsgErro']  := oFuncoes:pegaTag(cXMLResp, "cStat")+'-'+oFuncoes:pegaTag(cXMLResp, "xMotivo")
     RETURN(aRetorno)
   ELSE
      aRetorno['OK']       := .T.
      aRetorno['MsgErro']  := ""
      aRetorno['idLote']   := oFuncoes:pegaTag(cXMLResp, "idLote")
      aRetorno['tpAmb']    := oFuncoes:pegaTag(cXMLResp, "tpAmb")
      aRetorno['cOrgao']   := oFuncoes:pegaTag(cXMLResp, "cOrgao")
      aRetorno['cStat']    := oFuncoes:pegaTag(cXMLResp, "cStat")
      aRetorno['xMotivo']  := oFuncoes:pegaTag(cXMLResp, "xMotivo")
   ENDIF

   cXMLResp2 := oFuncoes:pegaTag( cXMLResp, 'retEnvEvento' )
   cXMLResp4 := oFuncoes:pegaTag( cXMLResp, 'retEvento' )    // Mauricio Cruz - 13/10/2011

   nPos := 1
   nI := 0
   DO WHILE .T.
      nI ++
      cXMLResp3 := oFuncoes:pegaTag(cXMLResp2, "infEvento")
      nPos := AT('</infEvento>',cXMLResp2,nPos) + 1
      cXMLResp2 := SUBS(cXMLResp2 , nPos)

      IF EMPTY( cXMLResp3 ) .OR. nPos <= 0
         EXIT
      ENDIF
      cSeq := ALLTRIM(STR(nI))
      aRetorno['Id_'+cSeq]          := oFuncoes:pegaTag(cXMLResp3, "Id")
      aRetorno['tpAmb_'+cSeq]       := oFuncoes:pegaTag(cXMLResp3, "tpAmb")
      aRetorno['verAplic_'+cSeq]    := oFuncoes:pegaTag(cXMLResp3, "verAplic")
      aRetorno['cOrgao_'+cSeq]      := oFuncoes:pegaTag(cXMLResp3, "cOrgao")
      aRetorno['cStat_'+cSeq]       := oFuncoes:pegaTag(cXMLResp3, "cStat")
      aRetorno['xMotivo_'+cSeq]     := oFuncoes:pegaTag(cXMLResp3, "xMotivo")
      aRetorno['chNFe_'+cSeq]       := oFuncoes:pegaTag(cXMLResp3, "chNFe")
      aRetorno['tpEvento_'+cSeq]    := oFuncoes:pegaTag(cXMLResp3, "tpEvento")
      aRetorno['xEvento_'+cSeq]     := oFuncoes:pegaTag(cXMLResp3, "xEvento")
      aRetorno['nSeqEvento_'+cSeq]  := oFuncoes:pegaTag(cXMLResp3, "nSeqEvento")
      aRetorno['CNPJDest_'+cSeq]    := oFuncoes:pegaTag(cXMLResp3, "CNPJDest")
      aRetorno['CPFDest_'+cSeq]     := oFuncoes:pegaTag(cXMLResp3, "CPFDest")
      aRetorno['emailDest_'+cSeq]   := oFuncoes:pegaTag(cXMLResp3, "emailDest")
      aRetorno['dhRegEvento_'+cSeq] := oFuncoes:pegaTag(cXMLResp3, "dhRegEvento")
      aRetorno['nProt_'+cSeq]       := oFuncoes:pegaTag(cXMLResp3, "nProt")

      // Mauricio Cruz - 13/10/2011
      IF oFuncoes:pegaTag(cXMLResp3, "cStat")<>'135'
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := oFuncoes:pegaTag(cXMLResp3, "xMotivo")
         RETURN(aRetorno)
      ENDIF
   ENDDO
/*
   cXMLResp := '<?xml version="1.0" encoding="UTF-8" ?>' +;
                 '<ProcEventoNFe versao="1.00" xmlns="http://www.portalfiscal.inf.br/nfe">' +;
                   '<evento ' +;
                     oFuncoes:pegaTag(cXMLDadosMsg, 'evento') +;
                   '</evento>' +;
                   '<retEvento>' +;
                     '<infEvento ' +;
                       cXMLResp2 +;
                     '</infEvento>' +;
                   '</retEvento>' +;
                 '</ProcEventoNFe>'
*/
   //  Mauricio Cruz - 13/10/2011
   cXMLResp := '<?xml version="1.0" encoding="UTF-8" ?>' +;
                 '<ProcEventoNFe versao="1.00" xmlns="http://www.portalfiscal.inf.br/nfe">' +;
                   '<evento ' +;
                     oFuncoes:pegaTag(cXMLDadosMsg, 'evento') +;
                   '</evento>' +;
                     '<retEvento ' +;
                       cXMLResp4 +;
                   '</retEvento>' +;
                 '</ProcEventoNFe>'
   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::cChaveNFe + "-cce.xml", cXMLResp )
   CATCH
     aRetorno['OK']       := .F.
     aRetorno['MsgErro']  := 'Problema ao gravar retorno da cce '+::ohbNFe:pastaEnvRes+"\"+::cChaveNFe+"-cce.xml"
     RETURN(aRetorno)
   END
   oDOMDoc:=Nil
   oServerWS:=Nil
RETURN(aRetorno)

METHOD AddEvento() CLASS hbNFeCCe
   IF ::nEvento = Nil
      ::nEvento := 0
   ENDIF
   ::nEvento ++
   IF ::Evento = Nil
      ::Evento := hash()
   ENDIF
   ::Evento[::nEvento] := hbNFeCCeEvento():New()
RETURN Self

CLASS hbNFeCCeEvento
   DATA nSeqEvento
   DATA xCorrecao

   METHOD new() CONSTRUCTOR
ENDCLASS

METHOD new() CLASS hbNFeCCeEvento
   ::nSeqEvento := Nil
   ::xCorrecao  := Nil
RETURN Self
