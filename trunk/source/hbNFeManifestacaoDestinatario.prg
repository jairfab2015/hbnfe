/*
   Classes e metodos para a Manifestação do destinatário da nota fiscal eletronica
   Mauricio Cruz - 01/10/2012 - cruz@sygecom.com.br
   Projeto principal: hbNfe de Fernando Athayde
*/

#include "common.ch"
#include "hbclass.ch"
#ifndef __XHARBOUR__
   #include "hbwin.ch"
   #include "harupdf.ch"
   #include "hbzebra.ch"
   #include "hbcompat.ch"
#endif
#include "hbnfe.ch"

CLASS hbNFeManifestacao
   DATA ohbNFe
   DATA cUFWS
   DATA versaoDados
   DATA tpAmb
   DATA xServ
   DATA cCNPJ
   DATA indNFe INIT 0 // 0 = Todas NF-e, 1 = Somente as NF-e que ainda não tiveram manifestação, 2 = Item anterior inluindo NF-e que não tiveram ciência da operacao
   DATA indEmi INIT 0 // 0 = Todos emitentes e remetentes (incluso notas de transferencias), 1 = Somente notas por emissor / rementete diferente do CNPJ informado
   DATA ultNSU INIT 0 // Ultimo NSU recebido
   DATA chNFe

   METHOD ConsultaNFeDest()
   METHOD nfeDownloadNF()
ENDCLASS


METHOD ConsultaNFeDest() CLASS hbNFeManifestacao
/*
   Consulta as notas no sefaz com resposta ou aguardando resposta do manifesto
   Mauricio Cruz - 08/10/2012
*/
LOCAL oServerWS, oDOMDoc, oError, oFuncoes := hbNFeFuncoes()
LOCAL cCN, cUrlWS, cMsgErro, cSOAPAction:='http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsultaDest/nfeConsultaNFDest'
LOCAL cXMLped, cXML, cXMLResp
LOCAL aRetorno:=HASH(), hresNFe:=HASH(), hresCanc:=HASH(), hresCCe:=HASH(), hCOUNT:=HASH()
LOCAL cLinha


IF ::cUFWS = Nil
   ::cUFWS := ::ohbNFe:cUFWS
ENDIF
IF ::versaoDados = Nil
   ::versaoDados := '1.01'
ENDIF
IF ::tpAmb = Nil
   ::tpAmb := ::ohbNFe:tpAmb
ENDIF

IF EMPTY(::cCNPJ)
   aRetorno['OK'] := .F.
   aRetorno['MsgErro'] := 'CNPJ não informado'
   RETURN(aRetorno)
ENDIF

IF ::xServ=NIL .OR. ::xServ<>'CONSULTAR NFE DEST'
   aRetorno['OK'] := .F.
   aRetorno['MsgErro'] := 'Tipo de serviço difere de CONSULTAR NFE DEST'
   RETURN(aRetorno)
ENDIF

cCN := ::ohbNFe:pegaCNCertificado(::ohbNFe:cSerialCert)
cUrlWS := ::ohbNFe:getURLWS(_CONSULTANFEDEST)
if cUrlWS = nil
    cMsgErro := "Serviço não mapeado"+ HB_EOL()+;
                "Serviço solicitado : CONSULTANFEDEST"
    aRetorno['OK']       := .F.
    aRetorno['MsgErro']  := cMsgErro
    RETURN(aRetorno)
endif
TRY
   oServerWS := win_oleCreateObject( _MSXML2_ServerXMLHTTP )

CATCH
   cMsgErro := "Serviço não mapeado"+ HB_EOL()+;
               "Serviço solicitado : CONSULTANFEDEST"
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := cMsgErro
   RETURN(aRetorno)
END


oServerWS:setOption( 3, "CURRENT_USER\MY\"+cCN )
oServerWS:open("POST", cUrlWS, .F.)
oServerWS:setRequestHeader("SOAPAction", cSOAPAction)
oServerWS:setRequestHeader("Content-Type", "text/xml; charset=utf-8")


cXMLped:='<consNFeDest xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.01" >'+;
            '<tpAmb>'+::tpAmb+'</tpAmb>'+;
            '<xServ>'+::xServ+'</xServ>'+;
            '<CNPJ>'+::cCNPJ+'</CNPJ>'+;
            '<indNFe>'+ALLTRIM(STR(::indNFe))+'</indNFe>'+;
            '<indEmi>'+ALLTRIM(STR(::indEmi))+'</indEmi>'+;
            '<ultNSU>'+ALLTRIM(STR(::ultNSU))+'</ultNSU>'+;
         '</consNFeDest>'

TRY
   hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\consNFeDest-ped.xml", cXMLped )
CATCH
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := 'Problema ao gravar pedido de consulta '+::ohbNFe:pastaEnvRes+"\consNFeDest-ped.xml"
   RETURN(aRetorno)
END

cXML:='<?xml version="1.0" encoding="utf-8"?>'+;
      '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+;
         '<soap:Header>'+;
            '<nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsultaDest">'+;
               '<cUF>'+::cUFWS+'</cUF>'+;
               '<versaoDados>'+::versaoDados+'</versaoDados>'+;
            '</nfeCabecMsg>'+;
         '</soap:Header>'+;
         '<soap:Body>'+;
            '<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeConsultaDest">'+cXMLped+'</nfeDadosMsg>'+;
         '</soap:Body>'+;
      '</soap:Envelope>'

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

TRY
   hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\retConsNFeDest.xml", cXMLResp )
CATCH
  aRetorno['OK']       := .F.
  aRetorno['MsgErro']  := 'Problema ao gravar retorno da consulta '+::ohbNFe:pastaEnvRes+"\retConsNFeDest.xml"
  RETURN(aRetorno)
END

cXMLResp := oFuncoes:pegaTag( cXMLResp, 'retConsNFeDest' )

aRetorno['Versao']    := oFuncoes:pegaTag(cXMLResp, "versao")
aRetorno['tpAmb']     := oFuncoes:pegaTag(cXMLResp, "tpAmb")
aRetorno['verAplic']  := oFuncoes:pegaTag(cXMLResp, "verAplic")
aRetorno['cStat']     := oFuncoes:pegaTag(cXMLResp, "cStat")
aRetorno['xMotivo']   := oFuncoes:pegaTag(cXMLResp, "xMotivo")
aRetorno['dhResp']    := oFuncoes:pegaTag(cXMLResp, "dhResp")
aRetorno['indCont']   := oFuncoes:pegaTag(cXMLResp, "indCont")
aRetorno['ultNSU']    := oFuncoes:pegaTag(cXMLResp, "ultNSU")

hCOUNT['resNFe']:=0
hCOUNT['resCanc']:=0
hCOUNT['resCCe']:=0
WHILE .T.
   cLINHA:=SUBSTR(cXMLResp,AT('<ret>',cXMLResp), AT('</ret>',cXMLResp)-AT('<ret>',cXMLResp)+6    )
   cXMLResp:=SUBSTR(cXMLResp,AT('</ret>',cXMLResp)+6,LEN(cXMLResp))

   IF !EMPTY(oFuncoes:pegaTag(cLINHA, "resNFe"))
      hCOUNT['resNFe']++
      hresNFe['NSU_'+STRZERO(hCOUNT['resNFe'],3)]      := SUBSTR(oFuncoes:pegaTag(cLINHA, "resNFe"), AT('"',oFuncoes:pegaTag(cLINHA, "resNFe"))+1, AT('>',oFuncoes:pegaTag(cLINHA, "resNFe"))-AT('"',oFuncoes:pegaTag(cLINHA, "resNFe"))-2   )
      hresNFe['chNFe_'+STRZERO(hCOUNT['resNFe'],3)]    := oFuncoes:pegaTag(cLINHA, "chNFe")
      hresNFe['CNPJ_'+STRZERO(hCOUNT['resNFe'],3)]     := oFuncoes:pegaTag(cLINHA, "CNPJ")
      IF !EMPTY(oFuncoes:pegaTag(cLINHA, "CNPJ"))
         hresNFe['CNPJ_'+STRZERO(hCOUNT['resNFe'],3)]  := oFuncoes:pegaTag(cLINHA, "CNPJ")
      ELSEIF !EMPTY(oFuncoes:pegaTag(cLINHA, "CPF"))
         hresNFe['CPF_'+STRZERO(hCOUNT['resNFe'],3)]   := oFuncoes:pegaTag(cLINHA, "CPF")
      ENDIF
      hresNFe['xNome_'+STRZERO(hCOUNT['resNFe'],3)]    := oFuncoes:pegaTag(cLINHA, "xNome")
      hresNFe['IE_'+STRZERO(hCOUNT['resNFe'],3)]       := oFuncoes:pegaTag(cLINHA, "IE")
      hresNFe['dEmi_'+STRZERO(hCOUNT['resNFe'],3)]     := oFuncoes:BringToDate(oFuncoes:pegaTag(cLINHA, "dEmi"))
      hresNFe['tpNF_'+STRZERO(hCOUNT['resNFe'],3)]     := VAL(oFuncoes:pegaTag(cLINHA, "tpNF"))
      hresNFe['vNF_'+STRZERO(hCOUNT['resNFe'],3)]      := VAL(oFuncoes:pegaTag(cLINHA, "vNF"))
      hresNFe['digVal_'+STRZERO(hCOUNT['resNFe'],3)]   := oFuncoes:pegaTag(cLINHA, "digVal")
      hresNFe['dhRecbto_'+STRZERO(hCOUNT['resNFe'],3)] := oFuncoes:BringToDate(oFuncoes:pegaTag(cLINHA, "dhRecbto"))
      hresNFe['cSitNFe_'+STRZERO(hCOUNT['resNFe'],3)]  := VAL(oFuncoes:pegaTag(cLINHA, "cSitNFe"))
      hresNFe['cSitConf_'+STRZERO(hCOUNT['resNFe'],3)] := VAL(oFuncoes:pegaTag(cLINHA, "cSitConf"))
   ENDIF
   IF !EMPTY(oFuncoes:pegaTag(cLINHA, "resCanc"))
      hCOUNT['resCanc']++
      hresCanc['NSU_'+STRZERO(hCOUNT['resCanc'],3)]      := SUBSTR(oFuncoes:pegaTag(cLINHA, "resCanc"), AT('"',oFuncoes:pegaTag(cLINHA, "resCanc"))+1, AT('>',oFuncoes:pegaTag(cLINHA, "resCanc"))-AT('"',oFuncoes:pegaTag(cLINHA, "resCanc"))-2   )
      hresCanc['chNFe_'+STRZERO(hCOUNT['resCanc'],3)]    := oFuncoes:pegaTag(cLINHA, "chNFe")
      IF !EMPTY(oFuncoes:pegaTag(cLINHA, "CNPJ"))
         hresCanc['CNPJ_'+STRZERO(hCOUNT['resCanc'],3)]  := oFuncoes:pegaTag(cLINHA, "CNPJ")
      ELSEIF !EMPTY(oFuncoes:pegaTag(cLINHA, "CPF"))
         hresCanc['CPF_'+STRZERO(hCOUNT['resCanc'],3)]   := oFuncoes:pegaTag(cLINHA, "CPF")
      ENDIF
      hresCanc['xNome_'+STRZERO(hCOUNT['resCanc'],3)]    := oFuncoes:pegaTag(cLINHA, "xNome")
      hresCanc['IE_'+STRZERO(hCOUNT['resCanc'],3)]       := oFuncoes:pegaTag(cLINHA, "IE")
      hresCanc['dEmi_'+STRZERO(hCOUNT['resCanc'],3)]     := oFuncoes:BringToDate(oFuncoes:pegaTag(cLINHA, "dEmi"))
      hresCanc['tpNF_'+STRZERO(hCOUNT['resCanc'],3)]     := VAL(oFuncoes:pegaTag(cLINHA, "tpNF"))
      hresCanc['vNF_'+STRZERO(hCOUNT['resCanc'],3)]      := VAL(oFuncoes:pegaTag(cLINHA, "vNF"))
      hresCanc['digVal_'+STRZERO(hCOUNT['resCanc'],3)]   := oFuncoes:pegaTag(cLINHA, "digVal")
      hresCanc['dhRecbto_'+STRZERO(hCOUNT['resCanc'],3)] := oFuncoes:BringToDate(oFuncoes:pegaTag(cLINHA, "dhRecbto"))
      hresCanc['cSitNFe_'+STRZERO(hCOUNT['resCanc'],3)]  := VAL(oFuncoes:pegaTag(cLINHA, "cSitNFe"))
      hresCanc['cSitConf_'+STRZERO(hCOUNT['resCanc'],3)] := VAL(oFuncoes:pegaTag(cLINHA, "cSitConf"))
   ENDIF
   IF !EMPTY(oFuncoes:pegaTag(cLINHA, "resCCe"))
      hCOUNT['resCCe']++
      hresCCe['NSU_'+STRZERO(hCOUNT['resCCe'],3)]        := SUBSTR(oFuncoes:pegaTag(cLINHA, "resCCe"), AT('"',oFuncoes:pegaTag(cLINHA, "resCCe"))+1, AT('>',oFuncoes:pegaTag(cLINHA, "resCCe"))-AT('"',oFuncoes:pegaTag(cLINHA, "resCCe"))-2   )
      hresCCe['chNFe_'+STRZERO(hCOUNT['resCCe'],3)]      := oFuncoes:pegaTag(cLINHA, "chNFe")
      hresCCe['dhEvento_'+STRZERO(hCOUNT['resCCe'],3)]   := oFuncoes:BringToDate(oFuncoes:pegaTag(cLINHA, "dhEvento"))
      hresCCe['tpEvento_'+STRZERO(hCOUNT['resCCe'],3)]   := oFuncoes:pegaTag(cLINHA, "tpEvento")
      hresCCe['nSeqEvento_'+STRZERO(hCOUNT['resCCe'],3)] := VAL(oFuncoes:pegaTag(cLINHA, "nSeqEvento"))
      hresCCe['descEvento_'+STRZERO(hCOUNT['resCCe'],3)] := oFuncoes:pegaTag(cLINHA, "descEvento")
      hresCCe['xCorrecao_'+STRZERO(hCOUNT['resCCe'],3)]  := oFuncoes:pegaTag(cLINHA, "xCorrecao")
      hresCCe['tpNF_'+STRZERO(hCOUNT['resCCe'],3)]       := VAL(oFuncoes:pegaTag(cLINHA, "tpNF"))
      hresCCe['dhRecbto_'+STRZERO(hCOUNT['resCCe'],3)]   := oFuncoes:BringToDate(oFuncoes:pegaTag(cLINHA, "dhRecbto"))
   ENDIF

   IF AT('<ret>',cXMLResp)<=0
      EXIT
   ENDIF
ENDDO

aRetorno['OK']     := .T.
aRetorno['resNFe'] :=hresNFe
aRetorno['resCanc']:=hresCanc
aRetorno['resCCe'] :=hresCCe


RETURN(aRetorno)






METHOD nfeDownloadNF() CLASS hbNFeManifestacao
/*
   Pedido de download do XML da nota fiscal eletronica
   Mauricio Cruz - 15/10/2012
*/
LOCAL oFuncoes := hbNFeFuncoes()
LOCAL cCN, cUrlWS, cMsgErro, cXMLped, cXML, cSOAPAction:='http://www.portalfiscal.inf.br/nfe/wsdl/NfeDownloadNF/nfeDownloadNF'
LOCAL aRetorno:=HASH(), cXmlResp, oServerWs, oDomDoc, oError

aRetorno['OK'] := .T.

IF ::cUFWS = Nil
   ::cUFWS := ::ohbNFe:cUFWS
ENDIF
IF ::versaoDados = Nil
   ::versaoDados := '1.00'
ENDIF
IF ::tpAmb = Nil
   ::tpAmb := ::ohbNFe:tpAmb
ENDIF
IF ::xServ=NIL .OR. ::xServ<>'DOWNLOAD NFE'
   aRetorno['OK'] := .F.
   aRetorno['MsgErro'] := 'Tipo de serviço difere de DOWNLOAD NFE'
   RETURN(aRetorno)
ENDIF
IF EMPTY(::cCNPJ)
   aRetorno['OK'] := .F.
   aRetorno['MsgErro'] := 'CNPJ não informado'
   RETURN(aRetorno)
ENDIF
IF ::chNFe=NIL .OR. EMPTY(::chNFe) .OR. LEN(::chNFe)<>44
   aRetorno['OK'] := .F.
   aRetorno['MsgErro'] := 'Chave da nota fiscal eletrônica inválida'
   RETURN(aRetorno)
ENDIF

cCN := ::ohbNFe:pegaCNCertificado(::ohbNFe:cSerialCert)
cUrlWS := ::ohbNFe:getURLWS(_DOWNLOADNFE)
if cUrlWS = nil
    cMsgErro := "Serviço não mapeado"+ HB_EOL()+;
                "Serviço solicitado : DOWNLOADNFE"
    aRetorno['OK']       := .F.
    aRetorno['MsgErro']  := cMsgErro
    RETURN(aRetorno)
endif
TRY
   oServerWS := win_oleCreateObject( _MSXML2_ServerXMLHTTP )
CATCH
   cMsgErro := "Serviço não mapeado"+ HB_EOL()+;
               "Serviço solicitado : DOWNLOADNFE"
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := cMsgErro
   RETURN(aRetorno)
END

oServerWS:setOption( 3, "CURRENT_USER\MY\"+cCN )
oServerWS:open("POST", cUrlWS, .F.)
oServerWS:setRequestHeader("SOAPAction", cSOAPAction)
oServerWS:setRequestHeader("Content-Type", "text/xml; charset=utf-8")


cXMLped:='<downloadNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="1.00" >'+;
            '<tpAmb>'+::tpAmb+'</tpAmb>'+;
            '<xServ>'+::xServ+'</xServ>'+;
            '<CNPJ>'+::cCNPJ+'</CNPJ>'+;
            '<chNFe>'+::chNFe+'</chNFe>'+;
         '</downloadNFe>'

TRY
   hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\downloadNFe-ped.xml", cXMLped )
CATCH
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := 'Problema ao gravar pedido de download da NF-e '+::ohbNFe:pastaEnvRes+"\downloadNFe-ped.xml"
   RETURN(aRetorno)
END

cXML:='<?xml version="1.0" encoding="utf-8"?>'+;
      '<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">'+;
         '<soap:Header>'+;
            '<nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeDownloadNF">'+;
                '<versaoDados>'+::versaoDados+'</versaoDados>'+;
                '<cUF>'+::cUFWS+'</cUF>'+;
             '</nfeCabecMsg>'+;
          '</soap:Header>'+;
          '<soap:Body>'+;
             '<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeDownloadNF">'+cXMLped+'</nfeDadosMsg>'+;
          '</soap:Body>'+;
      '</soap:Envelope>'

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

TRY
   hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\retDownloadNFe.xml", cXMLResp )
CATCH
  aRetorno['OK']       := .F.
  aRetorno['MsgErro']  := 'Problema ao gravar retorno do download da NF-e '+::ohbNFe:pastaEnvRes+"\retDownloadNFe.xml"
  RETURN(aRetorno)
END


cXMLResp := oFuncoes:pegaTag( cXMLResp, 'retDownloadNFe' )

aRetorno['tpAmb']    := oFuncoes:pegaTag( cXMLResp, 'tpAmb' )
aRetorno['verAplic'] := oFuncoes:pegaTag( cXMLResp, 'verAplic' )
aRetorno['cStat']    := oFuncoes:pegaTag( cXMLResp, 'cStat' )
aRetorno['xMotivo']  := oFuncoes:pegaTag( cXMLResp, 'xMotivo' )
aRetorno['dhResp']   := oFuncoes:pegaTag( cXMLResp, 'dhResp' )

cXMLResp := oFuncoes:pegaTag( cXMLResp, 'retNFe' )

aRetorno['chNFe']      := oFuncoes:pegaTag( cXMLResp, 'chNFe' )
aRetorno['cStatNFe']   := oFuncoes:pegaTag( cXMLResp, 'cStat' )
aRetorno['xMotivoNFe'] := oFuncoes:pegaTag( cXMLResp, 'xMotivo' )

cXMLResp := oFuncoes:pegaTag( cXMLResp, 'procNFe' )

aRetorno['XMLNfe'] := '<?xml version="1.0" encoding="UTF-8"?>'+SUBSTR(cXMLResp,28,LEN(cXMLResp))

IF aRetorno['cStatNFe']<>'140'
   aRetorno['OK']       := .F.
   aRetorno['MsgErro']  := aRetorno['cStatNFe']+'-'+aRetorno['xMotivoNFe']
ENDIF

RETURN(aRetorno)













