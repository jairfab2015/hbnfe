****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Retorno Recepção) (RETORNO ENVIO)                             *
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

CLASS hbNFeRetornoRecepcao
   DATA ohbNFe
   DATA cUFWS
   DATA versaoDados
   DATA tpAmb
   DATA nRec

   METHOD execute()
ENDCLASS

METHOD execute() CLASS hbNFeRetornoRecepcao
LOCAL cCN, cUrlWS, cXML, cXMLDadosMsg, oServerWS, oDOMDoc, cXMLResp, cMsgErro, nI,;
      aRetorno := hash(), oFuncoes := hbNFeFuncoes(), cSOAPAction := 'http://www.portalfiscal.inf.br/nfe/wsdl/NfeRetRecepcao2',;
      cXMLResp2, oError, aRetornoNF, oCurl, aHeader, retHTTP

   IF ::cUFWS = Nil
      ::cUFWS := ::ohbNFe:cUFWS
   ENDIF
   IF ::versaoDados = Nil
      ::versaoDados := ::ohbNFe:versaoDados
   ENDIF
   IF ::tpAmb = Nil
      ::tpAmb := ::ohbNFe:tpAmb
   ENDIF

   cXMLDadosMsg := '<consReciNFe xmlns="http://www.portalfiscal.inf.br/nfe" versao="2.00">';
                     +'<tpAmb>'+::tpAmb+'</tpAmb>';
                     +'<nRec>'+::nRec+'</nRec>';
                  +'</consReciNFe>'

   cXML := '<?xml version="1.0" encoding="utf-8"?>'
   cXML := cXML + '<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
   cXML := cXML +   '<soap12:Header>'
   cXML := cXML +     '<nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeRetRecepcao2">'
   cXML := cXML +       '<cUF>'+::cUFWS+'</cUF>'
   cXML := cXML +       '<versaoDados>'+::versaoDados+'</versaoDados>'
   cXML := cXML +     '</nfeCabecMsg>'
   cXML := cXML +   '</soap12:Header>'
   cXML := cXML +   '<soap12:Body>'
   cXML := cXML +     '<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeRetRecepcao2">'
   cXML := cXML + cXMLDadosMsg
   cXML := cXML +     '</nfeDadosMsg>'
   cXML := cXML +   '</soap12:Body>'
   cXML := cXML +'</soap12:Envelope>'

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::nRec + "-ped-rec.xml", cXMLDadosMsg )
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Problema ao gravar pedido de situação do recibo '+::ohbNFe:pastaEnvRes+"\"+::nRec+"-ped-rec.xml"
      RETURN(aRetorno)
   END

   cCN := ::ohbNFe:pegaCNCertificado(::ohbNFe:cSerialCert)

   cUrlWS := ::ohbNFe:getURLWS(_RETRECEPCAO)
  IF ::ohbNFe:nSOAP = HBNFE_CURL
     aHeader = { 'Content-Type: application/soap+xml;charset=utf-8;action="'+cSoapAction+'"',;
                 'SOAPAction: "NfeStatusServico2"',;
                 'Content-length: '+ALLTRIM(STR(len(cXML))) }

     #ifndef __XHARBOUR__
       curl_global_init()
       oCurl = curl_easy_init()

       curl_easy_setopt(oCurl, HB_CURLOPT_URL, cUrlWS)
       curl_easy_setopt(oCurl, HB_CURLOPT_PORT , 443)
       curl_easy_setopt(oCurl, HB_CURLOPT_VERBOSE, .F.) // 1
       curl_easy_setopt(oCurl, HB_CURLOPT_HEADER, 1) //retorna o cabeÃ§alho de resposta
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
       retHTTP := curl_easy_getinfo(oCurl,HB_CURLINFO_RESPONSE_CODE) //informaÃ§Ãµes da conexÃ£o

       cXMLResp := ''
       IF retHTTP = 200 // OK
          curl_easy_setopt( ocurl, HB_CURLOPT_DL_BUFF_GET, @cXMLResp )
          cXMLResp := SUBS(cXMLResp,AT('<?xml',cXMLResp))
       ENDIF

       curl_easy_cleanup(oCurl)
       curl_global_cleanup()
     #endif
  ELSE // MSXML

     oServerWS := win_oleCreateObject( _MSXML2_ServerXMLHTTP )

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
     IF oDOMDoc:parseError:errorCode <> 0 // XML não carregado
        cMsgErro := "Não foi possível carregar o documento pois ele não corresponde ao seu Schema"+HB_EOL() + ;
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
              	 "Mensagem: " + oError:Description
        aRetorno['OK']       := .F.
        aRetorno['MsgErro']  := cMSgErro
        RETURN(aRetorno)
     END
     DO WHILE oServerWS:readyState <> 4
        millisec(500)
     ENDDO
     cXMLResp := HB_ANSITOOEM(oServerWS:responseText)
   ENDIF
   //cXMLResp := oFuncoes:pegaTag( cXMLResp , "nfeRetRecepcao2Result")
   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\debug-pro-rec.xml", cXMLResp )
   CATCH
   END

   cXMLResp := oFuncoes:pegaTag( cXMLResp , "retConsReciNFe") // Ajuste NFe2 - Mauricio Cruz - 31/10/2012


   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + ::nRec + "-pro-rec.xml", cXMLResp )
   CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := 'Problema ao gravar protocolo do recibo '+::ohbNFe:pastaEnvRes+"\"+::nRec+"-pro-rec.xml"
      RETURN(aRetorno)
   END
   aRetorno['OK']       := .T.
   aRetorno['tpAmb']    := oFuncoes:pegaTag(cXMLResp, "tpAmb")
   aRetorno['verAplic'] := oFuncoes:pegaTag(cXMLResp, "verAplic")
   aRetorno['nRec']     := oFuncoes:pegaTag(cXMLResp, "nRec")
   aRetorno['cStat']    := oFuncoes:pegaTag(cXMLResp, "cStat")
   aRetorno['xMotivo']  := oFuncoes:pegaTag(cXMLResp, "xMotivo")
   aRetorno['cUF']      := oFuncoes:pegaTag(cXMLResp, "cUF")
   aRetorno['cMsg']     := oFuncoes:pegaTag(cXMLResp, "cMsg")
   aRetorno['xMsg']     := oFuncoes:pegaTag(cXMLResp, "xMsg")
   cXMLResp2 := oFuncoes:pegaTag(cXMLResp, "protNFe")

   TRY
      hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\debug-aRetorno.xml", cXMLResp2 )
   CATCH
   END

   aRetornoNF := hash()
   nI := 0
   DO WHILE .T.
      nI ++
      aRetorno['NF'+STRZERO(nI,2)+'_tpAmb']    := oFuncoes:pegaTag(cXMLResp2, "tpAmb")
      aRetorno['NF'+STRZERO(nI,2)+'_verAplic'] := oFuncoes:pegaTag(cXMLResp2, "verAplic")
      aRetorno['NF'+STRZERO(nI,2)+'_chNFe']    := oFuncoes:pegaTag(cXMLResp2, "chNFe")
      aRetorno['NF'+STRZERO(nI,2)+'_dhRecbto'] := oFuncoes:pegaTag(cXMLResp2, "dhRecbto")
      aRetorno['NF'+STRZERO(nI,2)+'_nProt']    := oFuncoes:pegaTag(cXMLResp2, "nProt")
      aRetorno['NF'+STRZERO(nI,2)+'_digVal']   := oFuncoes:pegaTag(cXMLResp2, "digVal")
      aRetorno['NF'+STRZERO(nI,2)+'_cStat']    := oFuncoes:pegaTag(cXMLResp2, "cStat") // <cStat>204</cStat>
      aRetorno['NF'+STRZERO(nI,2)+'_xMotivo']  := oFuncoes:pegaTag(cXMLResp2, "xMotivo")
      aRetorno['NF'+STRZERO(nI,2)+'_protNFe']  := "<protNFe "+cXMLResp2+"</protNFe>"
      EXIT
   ENDDO
   aRetorno['nNFs']     := nI

   oDOMDoc:=Nil
   oServerWS:=Nil
RETURN(aRetorno)
