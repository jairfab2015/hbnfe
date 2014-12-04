/*
   Classes e metodos para os eventos da nota fiscal eletronica (cancelamento e carta de correcao)
   Mauricio Cruz - 09/10/2012 - cruz@sygecom.com.br
   Projeto principal: hbNfe de Fernando Athayde
*/
#include "hbclass.ch"
#include "hbnfe.ch"

CLASS hbNFeEvento
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
   DATA cTIPevento
   DATA cIDevento
   DATA nTipoEvento

   DATA nEvento
   DATA Evento EXPORTED

   METHOD execute()
   METHOD AddEvento()
ENDCLASS

METHOD execute() CLASS hbNFeEvento
LOCAL cCN, cUrlWS, cXML, oServerWS, oDOMDoc, cXMLResp, cMsgErro, aRetorno := hash(),;
      oFuncoes := hbNFeFuncoes(), cSOAPAction := 'http://www.portalfiscal.inf.br/nfe/wsdl/RecepcaoEvento',;
      oError, cXMLDadosMsg,;
      cId, cCondUso, cXMLResp2, cXMLResp3, cXMLResp4, oAssina, aRetornoAss, oValida, aRetornoVal, nPos
LOCAL nI, cXmlDadosMsg2, cSeq

aRetorno['cStat_1']:=''

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
IF ::cTIPevento=NIL
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := 'Tipo de evento não informado'
   RETURN(aRetorno)
ENDIF
IF ::cIDevento=NIL
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := 'ID do evento não informado'
   RETURN(aRetorno)
ENDIF

IF ::nTipoEvento=NIL
   ::nTipoEvento:=_EVENTO
ENDIF

IF ::nTipoEvento=_RECPEVENTO
   cSOAPAction:='http://www.portalfiscal.inf.br/nfe/wsdl/RecepcaoEvento/nfeRecepcaoEvento'
   IF ::tpAmb='2' // em Homologação
      ::cUF:='91'
   ENDIF
ENDIF

TRY
   cCN := ::ohbNFe:pegaCNCertificado(::ohbNFe:cSerialCert)
CATCH
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := 'Não foi possível carregar as informação do certicado digital'
   RETURN(aRetorno)
END
TRY
   cUrlWS := ::ohbNFe:getURLWS( IF(::nTipoEvento=_RECPEVENTO,_RECPEVENTO,_EVENTO))
CATCH
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := 'Não foi possível carregar o link do webservice de eventos'
   RETURN(aRetorno)
END
if cUrlWS = nil
    cMsgErro := "Serviço não mapeado"+ HB_EOL()+;
                "Serviço solicitado : EVENTO"
    aRetorno['OK']       := .F.
    aRetorno['MsgErro']  := cMsgErro
    RETURN(aRetorno)
endif

TRY

   oServerWS := win_oleCreateObject( _MSXML2_ServerXMLHTTP )

CATCH
   cMsgErro := "Serviço não mapeado"+ HB_EOL()+;
               "Serviço solicitado : EVENTO"
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := cMsgErro
   RETURN(aRetorno)
END


TRY
   oServerWS:setOption( 3, "CURRENT_USER\MY\"+cCN )
   oServerWS:open("POST", cUrlWS, .F.)
   oServerWS:setRequestHeader("SOAPAction", cSOAPAction)
   oServerWS:setRequestHeader("Content-Type", "application/soap+xml; charset=utf-8")
CATCH
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := 'Não foi possível iniciar comunicação com webserviçe do SEFAZ '
   RETURN(aRetorno)
END
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

   cId := "ID" + ::cIDevento + ::cChaveNFe + STRZERO(VAL(::Evento[nI]:nSeqEvento),2)  //"110110"
   cXMLDadosMsg2 := '<evento xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00">' +;
                    '<infEvento Id="'+cId+'">' +;
                      '<cOrgao>'+::cUF+'</cOrgao>' +;
                      '<tpAmb>'+::tpAmb+'</tpAmb>' +;
                      '<CNPJ>'+::cCNPJ+'</CNPJ>' +;
                      '<chNFe>'+::cChaveNFe+'</chNFe>' +;
                      '<dhEvento>'+::dhEvento+'</dhEvento>' +;
                      '<tpEvento>'+::cIDevento+'</tpEvento>' +;
                      '<nSeqEvento>'+::Evento[nI]:nSeqEvento+'</nSeqEvento>' +;
                      '<verEvento>'+::versaoDados+'</verEvento>' +;
                      '<detEvento versao="1.00">' +;
                        '<descEvento>'+::cTIPevento+'</descEvento>'       //DESCRIÇÃO DO EVENTO
                        IF ::cIDevento='110110'    // EVENTO DA CARTA DE CORRECAO
                           cXMLDadosMsg2+='<xCorrecao>'+oFuncoes:parseEncode( ::Evento[nI]:cJustifica )+'</xCorrecao>' +;
                                          '<xCondUso>'+cCondUso+'</xCondUso>'
                        ELSEIF ::cIDevento='110111'  // EVENTO DO CANCELAMENTO
                           cXMLDadosMsg2+='<nProt>'+oFuncoes:parseEncode( ::Evento[nI]:nProt )+'</nProt>' +;
                                          '<xJust>'+ALLTRIM(oFuncoes:parseEncode( ::Evento[nI]:cJustifica ))+'</xJust>'
                        ELSEIF ::cIDevento='210240'  // EVENTO DE OPERACAO NAO REALIZADA - MANIFESTACAO DO DESTINATARIO
                           cXMLDadosMsg2+='<xJust>'+ALLTRIM(oFuncoes:parseEncode( ::Evento[nI]:cJustifica ))+'</xJust>'
                        ENDIF
                      cXMLDadosMsg2+='</detEvento>' +;
                    '</infEvento>' +;
                  '</evento>'

   TRY
      oAssina := hbNFeAssina()
      oAssina:ohbNFe := ::ohbNfe // Objeto hbNFe
      oAssina:cXMLFile := cXMLDadosMsg2
      oAssina:lMemFile := .T.
      aRetornoAss := oAssina:execute()
      oAssina := Nil
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Não foi possível assinar o o documento XML do evento.'
      RETURN(aRetorno)
   END

  IF aRetornoAss['OK'] == .F.
     aRetorno['OK']       := .F.
     aRetorno['MsgErro']  := aRetornoAss['MsgErro']
     RETURN(aRetorno)
  ENDIF
  cXMLDadosMsg2 := aRetornoAss[ 'XMLAssinado' ]
  cXMLDadosMsg += cXMLDadosMsg2
NEXT
cXMLDadosMsg += +'</envEvento>'

hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::cChaveNFe + "-ped-evento.xml", cXMLDadosMsg )

TRY
   oValida := hbNFeValida()
   oValida:ohbNFe := ::ohbNfe // Objeto hbNFe
   oValida:cXML := cXMLDadosMsg // Arquivo XML ou ConteudoXML
   aRetornoVal := oValida:execute()
   oValida := Nil
CATCH
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := 'Não foi possível validar o evento.'
   RETURN(aRetorno)
END
IF aRetornoVal['OK'] == .F.
   aRetorno['OK'] := .F.
   aRetorno['MsgErro'] := 'Valida: '+aRetornoVal['MsgErro']
   RETURN(aRetorno)
ELSE
   aRetorno['Validou'] := .T.
ENDIF

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
   hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::cChaveNFe + "-ped-evento.xml", cXMLDadosMsg )
CATCH
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := 'Problema ao gravar pedido de evento '+::ohbNFe:pastaEnvRes+"\"+::cChaveNFe+"-ped-evento.xml"
   RETURN(aRetorno)
END
TRY
   oDOMDoc := win_oleCreateObject( _MSXML2_DOMDocument )

   oDOMDoc:async = .F.
   oDOMDoc:validateOnParse  = .T.
   oDOMDoc:resolveExternals := .F.
   oDOMDoc:preserveWhiteSpace = .T.
   oDOMDoc:LoadXML(cXML)
CATCH
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := 'Não foi possível validar o documento de evento'
   RETURN(aRetorno)
END

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

TRY
   hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::cChaveNFe + "-reps-evento.xml", cXMLResp )
CATCH
END


IF VAL(oFuncoes:pegaTag(cXMLResp, "cStat"))<>128
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := oFuncoes:pegaTag(cXMLResp, "cStat")+'-'+oFuncoes:pegaTag(cXMLResp, "xMotivo")
   RETURN(aRetorno)
ELSE
   aRetorno['OK']       := .T.
   aRetorno['MsgErro']  := ""
   aRetorno['idLote']   := oFuncoes:pegaTag(cXMLResp, "idLote")
   aRetorno['tpAmb']    := oFuncoes:pegaTag(cXMLResp, "tpAmb")
   aRetorno['verAplic'] := oFuncoes:pegaTag(cXMLResp, "verAplic")
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
   hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::cChaveNFe + "-evento.xml", cXMLResp )
CATCH
  aRetorno['OK']       := .F.
  aRetorno['MsgErro']  := 'Problema ao gravar retorno do evento '+::ohbNFe:pastaEnvRes+"\"+::cChaveNFe+"-evento.xml"
  RETURN(aRetorno)
END
oDOMDoc:=Nil
oServerWS:=Nil

RETURN(aRetorno)

METHOD AddEvento() CLASS hbNFeEvento
   IF ::nEvento = Nil
      ::nEvento := 0
   ENDIF
   ::nEvento ++
   IF ::Evento = Nil
      ::Evento := hash()
   ENDIF
   ::Evento[::nEvento] := hbNFaddEvento():New()
RETURN Self

CLASS hbNFaddEvento
   DATA nSeqEvento
   DATA cJustifica
   DATA nProt

   METHOD new() CONSTRUCTOR
ENDCLASS

METHOD new() CLASS hbNFaddEvento
   ::nSeqEvento := Nil
   ::cJustifica  := Nil
   ::nProt      := nil
RETURN Self
