****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Cancela)                                                      *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modifica��o deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************
#include "common.ch"
#include "hbclass.ch"
#ifndef __XHARBOUR__
   #include "hbwin.ch"
   #include "harupdf.ch"
   #include "hbzebra.ch"
   #include "hbcompat.ch"
   #include "hbcurl.ch"
#endif
#include "hbnfe.ch"

CLASS hbNFeCancela
   DATA ohbNFe
   DATA cUFWS
   DATA versaoDados
   DATA tpAmb
   DATA cNFeFile
   DATA cJustificativa

   DATA cChaveNFe,nProt

   METHOD execute()
ENDCLASS

METHOD execute() CLASS hbNFeCancela
LOCAL cCN, cUrlWS, cXML, cXMLDadosMsg, oServerWS, oDOMDoc, cXMLResp, cMsgErro,;
      aRetorno := hash(), oFuncoes := hbNFeFuncoes(), cSOAPAction := 'http://www.portalfiscal.inf.br/nfe/wsdl/NfeCancelamento2',;
      oAssina, aRetornoAss, oError, cXMLFile, cXMLSai, nPos, oCurl, aHeader, retHTTP

   IF ::cUFWS = Nil
      ::cUFWS := ::ohbNFe:cUFWS
   ENDIF
   IF ::versaoDados = Nil
      ::versaoDados := ::ohbNFe:versaoDados
   ENDIF
   IF ::tpAmb = Nil
      ::tpAmb := ::ohbNFe:tpAmb
   ENDIF

   TRY
      cXMLFile := MEMOREAD( ::cNFeFile )
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Erro ao abrir '+::cNFeFile
      RETURN(aRetorno)
   END

   IF !HB_ISNIL( ::cNFeFile )

      ::cChaveNFe := oFuncoes:pegaTag( oFuncoes:pegaTag( cXMLFile, 'protNFe' ), 'chNFe' )  // Mauricio Cruz - 28/09/2011 alterado pq o nome do arquivo pode estar com o path ex.: c:\user\cruz\appdata\local\temp\.....xml    //::cChaveNFe := SUBS( ::cNFeFile ,1 ,44 )
      ::nProt     := oFuncoes:pegaTag( oFuncoes:pegaTag( cXMLFile, 'protNFe' ), 'nProt' )
      IF EMPTY(::nProt)
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Arquivo '+::cNFeFile+' sem protocolo de envio'
         RETURN(aRetorno)
      ENDIF

   ENDIF

   cXMLDadosMsg := '<cancNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="2.00">';
                     +'<infCanc Id="ID'+::cChaveNFe+'">';
                       +'<tpAmb>'+::tpAmb+'</tpAmb>';
                       +'<xServ>CANCELAR</xServ>';
                       +'<chNFe>'+::cChaveNFe+'</chNFe>';
                       +'<nProt>'+::nProt+'</nProt>';
                       +'<xJust>'+::cJustificativa+'</xJust>';
                     +'</infCanc>';
                  +'</cancNFe>'

   oAssina := hbNFeAssina()
   oAssina:ohbNFe := ::ohbNfe // Objeto hbNFe
   oAssina:cXMLFile := cXMLDadosMsg
   oAssina:lMemFile := .T.
   aRetornoAss := oAssina:execute()
   oAssina := Nil
   IF aRetornoAss['OK'] == .F.
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := aRetornoAss['MsgErro']
      RETURN(aRetorno)
   ENDIF
   cXMLDadosMsg := aRetornoAss['XMLAssinado']

   cXML := '<?xml version="1.0" encoding="utf-8"?>'
   cXML := cXML + '<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
   cXML := cXML +   '<soap12:Header>'
   cXML := cXML +     '<nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeCancelamento2">'
   cXML := cXML +       '<cUF>'+::cUFWS+'</cUF>'
   cXML := cXML +       '<versaoDados>'+::versaoDados+'</versaoDados>'
   cXML := cXML +     '</nfeCabecMsg>'
   cXML := cXML +   '</soap12:Header>'
   cXML := cXML +   '<soap12:Body>'
   cXML := cXML +     '<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeCancelamento2">'
   cXML := cXML + cXMLDadosMsg
   cXML := cXML +     '</nfeDadosMsg>'
   cXML := cXML +   '</soap12:Body>'
   cXML := cXML +'</soap12:Envelope>'

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\NFe" + ::cChaveNFe + "-ped-can.xml", cXMLDadosMsg )
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Problema ao gravar protocolo de pedido '+::ohbNFe:pastaEnvRes+"\"+"NFe"+::cChaveNFe+"-ped-can.xml"
      RETURN(aRetorno)
   END

   cCN := ::ohbNfe:pegaCNCertificado(::ohbNfe:cSerialCert)

   cUrlWS := ::ohbNFe:getURLWS(_CANCELAMENTO)

   oServerWS := win_oleCreateObject( _MSXML2_ServerXMLHTTP )

  IF ::ohbNFe:nSOAP = HBNFE_CURL
     aHeader = { 'Content-Type: application/soap+xml;charset=utf-8;action="'+cSoapAction+'"',;
                 'SOAPAction: "NfeCancelamento2"',;
                 'Content-length: '+ALLTRIM(STR(len(cXML))) }

     #ifndef __XHARBOUR__
       curl_global_init()
       oCurl = curl_easy_init()

       curl_easy_setopt(oCurl, HB_CURLOPT_URL, cUrlWS)
       curl_easy_setopt(oCurl, HB_CURLOPT_PORT , 443)
       curl_easy_setopt(oCurl, HB_CURLOPT_VERBOSE, .F.) // 1
       curl_easy_setopt(oCurl, HB_CURLOPT_HEADER, 1) //retorna o cabeçalho de resposta
       curl_easy_setopt(oCurl, HB_CURLOPT_SSLVERSION, 3)
       curl_easy_setopt(oCurl, HB_CURLOPT_SSL_VERIFYHOST, 0)
       curl_easy_setopt(oCurl, HB_CURLOPT_SSL_VERIFYPEER, 0)
       curl_easy_setopt(oCurl, HB_CURLOPT_SSLCERT, ::ohbNFe:cCertFilePub)
       curl_easy_setopt(oCurl, HB_CURLOPT_KEYPASSWD, ::ohbNFe:cCertPass)
       curl_easy_setopt(oCurl, HB_CURLOPT_SSLKEY, ::ohbNFe:cCertFilePriv)
       curl_easy_setopt(oCurl, HB_CURLOPT_POST, 1)
       curl_easy_setopt(oCurl, HB_CURLOPT_POSTFIELDS, cXML)
       curl_easy_setopt(oCurl, HB_CURLOPT_WRITEFUNCTION, 1)
       curl_easy_setopt(oCurl, HB_CURLOPT_DL_BUFF_SETUP )
       curl_easy_setopt(oCurl, HB_CURLOPT_HTTPHEADER, aHeader )
       curl_easy_perform(oCurl)
       retHTTP := curl_easy_getinfo(oCurl,HB_CURLINFO_RESPONSE_CODE) //informações da conexão

       cXMLResp := ''
       IF retHTTP = 200 // OK
          curl_easy_setopt( ocurl, HB_CURLOPT_DL_BUFF_GET, @cXMLResp )
          cXMLResp := SUBS(cXMLResp,AT('<?xml',cXMLResp))
       ENDIF

       curl_easy_cleanup(oCurl)
       curl_global_cleanup()
     #endif
  ELSE // MSXML
     oServerWS:setOption( 3, "CURRENT_USER\MY\"+cCN )
     oServerWS:open("POST", cUrlWS, .F.)
     oServerWS:setRequestHeader("SOAPAction", cSOAPAction )
     oServerWS:setRequestHeader("Content-Type", "application/soap+xml; charset=utf-8")

     oDOMDoc := win_oleCreateObject( _MSXML2_DOMDocument )

     oDOMDoc:async = .F.
     oDOMDoc:validateOnParse  = .T.
     oDOMDoc:resolveExternals := .F.
     oDOMDoc:preserveWhiteSpace = .T.
     oDOMDoc:LoadXML(cXML)
     IF oDOMDoc:parseError:errorCode <> 0 // XML n�o carregado
        cMsgErro := "N�o foi poss�vel carregar o documento pois ele n�o corresponde ao seu Schema"+HB_EOL() + ;
                    " Linha: " + STR(oDOMDoc:parseError:line)+HB_EOL() + ;
                    " Caractere na linha: " + STR(oDOMDoc:parseError:linepos)+HB_EOL() + ;
                    " Causa do erro: " + oDOMDoc:parseError:reason+HB_EOL() + ;
                    " Code: "+STR(oDOMDoc:parseError:errorCode)
        aRetorno['OK']       := .F.
        aRetorno['MsgErro']  := cMSgErro
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
        aRetorno['MsgErro']  := cMSgErro
        RETURN(aRetorno)
     END
     DO WHILE oServerWS:readyState <> 4
        millisec(500)
     ENDDO
     cXMLResp := HB_ANSITOOEM(oServerWS:responseText)
   ENDIF

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\NFe" + ::cChaveNFe + "-can.xml", cXMLResp )
   CATCH
      aRetorno['OK']       := .T.
      aRetorno['MsgErro']  := 'Problema ao retorno do protocolo '+::ohbNFe:pastaEnvRes+"\NFe"+::cChaveNFe+"-can.xml"
      aRetorno['tpAmb']      := oFuncoes:pegaTag(cXMLResp, "tpAmb")
      aRetorno['verAplic']   := oFuncoes:pegaTag(cXMLResp, "verAplic")
      aRetorno['cStat']      := oFuncoes:pegaTag(cXMLResp, "cStat")
      aRetorno['xMotivo']    := oFuncoes:pegaTag(cXMLResp, "xMotivo")
      aRetorno['cUF']        := oFuncoes:pegaTag(cXMLResp, "cUF")
      aRetorno['chNFe']      := oFuncoes:pegaTag(cXMLResp, "chNFe")
      aRetorno['dhRecbto']   := oFuncoes:pegaTag(cXMLResp, "dhRecbto")
      aRetorno['nProt']      := oFuncoes:pegaTag(cXMLResp, "nProt")
      aRetorno['digVal']     := oFuncoes:pegaTag(cXMLResp, "digVal")
      aRetorno['retCancNFe'] := cXMLResp
      RETURN(aRetorno)
   END
   TRY
      hb_MemoWrit( ::ohbNFe:pastaCancelamento + "\NFe" + ::cChaveNFe + "-can.xml", cXMLResp )
   CATCH
      aRetorno['OK']       := .T.
      aRetorno['MsgErro']  := 'Problema ao retorno do protocolo '+::ohbNFe:pastaCancelamento+"\NFe"+::cChaveNFe+"-can.xml"
      aRetorno['tpAmb']      := oFuncoes:pegaTag(cXMLResp, "tpAmb")
      aRetorno['verAplic']   := oFuncoes:pegaTag(cXMLResp, "verAplic")
      aRetorno['cStat']      := oFuncoes:pegaTag(cXMLResp, "cStat")
      aRetorno['xMotivo']    := oFuncoes:pegaTag(cXMLResp, "xMotivo")
      aRetorno['cUF']        := oFuncoes:pegaTag(cXMLResp, "cUF")
      aRetorno['chNFe']      := oFuncoes:pegaTag(cXMLResp, "chNFe")
      aRetorno['dhRecbto']   := oFuncoes:pegaTag(cXMLResp, "dhRecbto")
      aRetorno['nProt']      := oFuncoes:pegaTag(cXMLResp, "nProt")
      aRetorno['digVal']     := oFuncoes:pegaTag(cXMLResp, "digVal")
      aRetorno['retCancNFe'] := cXMLResp
      RETURN(aRetorno)
   END
   cXMLResp := oFuncoes:pegaTag(cXMLResp, "nfeCancelamentoNF2Result")
   aRetorno['OK']         := .T.
   aRetorno['tpAmb']      := oFuncoes:pegaTag(cXMLResp, "tpAmb")
   aRetorno['verAplic']   := oFuncoes:pegaTag(cXMLResp, "verAplic")
   aRetorno['cStat']      := oFuncoes:pegaTag(cXMLResp, "cStat")
   aRetorno['xMotivo']    := oFuncoes:pegaTag(cXMLResp, "xMotivo")
   aRetorno['cUF']        := oFuncoes:pegaTag(cXMLResp, "cUF")
   aRetorno['chNFe']      := oFuncoes:pegaTag(cXMLResp, "chNFe")
   aRetorno['dhRecbto']   := oFuncoes:pegaTag(cXMLResp, "dhRecbto")
   aRetorno['nProt']      := oFuncoes:pegaTag(cXMLResp, "nProt")
   aRetorno['digVal']     := oFuncoes:pegaTag(cXMLResp, "digVal")
   aRetorno['retCancNFe'] := cXMLResp
   // processa protNFe no xml
   IF aRetorno['chNFe'] $ cXMLFile .AND. aRetorno['cStat'] == '101'
      cXMLSai := cXMLFile
      nPos := AT('/protNFe>',cXMLSai)+8
      IF nPos = 0
         nPos := AT('/NFe>',cXMLSai)+4
      ENDIF
      IF nPos = 0
         // problema xml
      ENDIF
      cXMLSai := SUBS(cXMLSai,1,nPos) + ;
                 aRetorno['retCancNFe']
      TRY
         hb_MemoWrit( ::ohbNFe:pastaNFe + "\" + ::cChaveNFe + '-nfe.xml', cXMLSai )
      CATCH
         aRetorno['MsgErro']  := 'Problema ao retorno do protocolo '+::ohbNFe:pastaNFe+"\"+::cChaveNFe+'-nfe.xml'
      END
   ENDIF

   oDOMDoc:=Nil
   oServerWS:=Nil

RETURN(aRetorno)