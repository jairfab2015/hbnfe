****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Status de Serviço)                                            *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************

#include "hbclass.ch"
#include "hbnfe.ch"

CLASS hbNFeStatus
   DATA ohbNFe
   DATA cUFWS
   DATA versaoDados
   DATA tpAmb
   DATA cUF

   METHOD execute()
ENDCLASS

METHOD execute() CLASS hbNFeStatus
LOCAL cCN, cUrlWS, cXML, oServerWS, oDOMDoc, cMsgErro,;
      aRetorno := hash(), oFuncoes := hbNFeFuncoes(),;
      cSOAPAction := 'http://www.portalfiscal.inf.br/nfe/wsdl/NfeStatusServico2/nfeConsultaNF2',;
      cFileEnvRes, oError, cXMLResp, cXMLDadosMsg, oCurl, aHeader, retHTTP
   IF ::cUFWS = Nil
      ::cUFWS := ::ohbNFe:cUFWS
   ENDIF
   IF ::versaoDados = Nil
      ::versaoDados := ::ohbNFe:versaoDados
   ENDIF
   IF ::tpAmb = Nil
      ::tpAmb := ::ohbNFe:tpAmb
   ENDIF

  cCN := ::ohbNFe:pegaCNCertificado(::ohbNFe:cSerialCert)

  cXMLDadosMsg := '<consStatServ xmlns="http://www.portalfiscal.inf.br/nfe" versao="2.00">' +;
                    '<tpAmb>'+::tpAmb+'</tpAmb>' +;
                    '<cUF>'+::cUF+'</cUF>' +;
                    '<xServ>STATUS</xServ>' +;
                  '</consStatServ>'

  cXML := '<?xml version="1.0" encoding="utf-8"?>'
  cXML := cXML + '<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
  cXML := cXML +   '<soap12:Header>'
  cXML := cXML +     '<nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeStatusServico2">'
  cXML := cXML +       '<cUF>'+::cUFWS+'</cUF>'
  cXML := cXML +       '<versaoDados>'+::versaoDados+'</versaoDados>'
  cXML := cXML +     '</nfeCabecMsg>'
  cXML := cXML +   '</soap12:Header>'
  cXML := cXML +   '<soap12:Body>'
  cXML := cXML +     '<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/NfeStatusServico2">'
  cXML := cXML +       cXMLDadosMsg
  cXML := cXML +     '</nfeDadosMsg>'
  cXML := cXML +   '</soap12:Body>'
  cXML := cXML +'</soap12:Envelope>'

  cFileEnvRes := oFuncoes:formatDate( DATE(), "YYMMDD")+SUBS(TIME(),1,2)+SUBS(TIME(),4,2)+SUBS(TIME(),7,2)
  TRY
     hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + cFileEnvRes + "-ped-sta.xml", cXMLDadosMsg )
  CATCH
     aRetorno['OK']       := .F.
     aRetorno['MsgErro']  := 'Problema ao gravar pedido de status '+::ohbNFe:pastaEnvRes+"\"+cFileEnvRes+"-ped-sta.xml"
     RETURN(aRetorno)
  END

  cUrlWS := ::ohbNFe:getURLWS(_STATUSSERVICO)
  if cUrlWS = nil
      cMsgErro := "Serviço não mapeado" + HB_EOL()+;
                  "Serviço solicitado : STATUS DO SERVIÇO."
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := cMsgErro
      RETURN(aRetorno)
  endif

  IF ::ohbNFe:nSOAP = HBNFE_CURL
     aHeader = { 'Content-Type: application/soap+xml;charset=utf-8;action="'+cSoapAction+'"',;
                 'SOAPAction: "StatusServico2"',;
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

      IF oServerWS = Nil
         aRetorno['OK'] := .F.
         aRetorno['MsgErro'] := 'Não foi encontrado MSXML2 5.0'
         RETURN(aRetorno)
      ENDIF

      oServerWS:setOption( 3, "CURRENT_USER\MY\"+cCN )
      oServerWS:open("POST", cUrlWS, .F.)
      oServerWS:setRequestHeader("SOAPAction", cSOAPAction )
      oServerWS:setRequestHeader("Content-Type", "application/soap+xml; charset=utf-8")

      oDOMDoc := win_oleCreateObject( _MSXML2_DOMDocument )

      IF oDOMDoc = Nil
         aRetorno['OK'] := .F.
         aRetorno['MsgErro'] := 'Não foi encontrado ' +_MSXML2_DOMDocument
         RETURN(aRetorno)
      ENDIF

      oDOMDoc:async = .F.
      oDOMDoc:validateOnParse  = .T.
      oDOMDoc:resolveExternals := .F.
      oDOMDoc:preserveWhiteSpace = .T.
      oDOMDoc:LoadXML(cXML)

      IF oDOMDoc:parseError:errorCode <> 0 // XML não carregado
         cMsgErro := "Não foi possível carregar o documento pois ele não corresponde ao seu Schema"+HB_EOL()+;
                     " Linha: " + STR(oDOMDoc:parseError:line)+HB_EOL()+;
                     " Caractere na linha: " + STR(oDOMDoc:parseError:linepos)+HB_EOL()+;
                     " Causa do erro: " + oDOMDoc:parseError:reason+HB_EOL()+;
                     " Code: "+STR(oDOMDoc:parseError:errorCode)
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

      //cXMLResp := oFuncoes:pegaTag( HB_ANSITOOEM(oServerWS:responseText), 'retConsStatServ' )
      cXMLResp := oFuncoes:pegaTag( oServerWS:responseText , 'retConsStatServ' )
  ENDIF
  TRY
     hb_MemoWrit( ::ohbNFe:pastaEnvRes + "\" + cFileEnvRes + "-sta.xml", cXMLResp )
  CATCH
     aRetorno['OK']       := .F.
     aRetorno['MsgErro']  := 'Problema ao gravar retorno de status '+::ohbNFe:pastaEnvRes+"\"+cFileEnvRes+"-sta.xml"
     RETURN(aRetorno)
  END
  aRetorno['OK']       := .T.
  aRetorno['MsgErro']  := ""
  aRetorno['tpAmb']    := oFuncoes:pegaTag(cXMLResp, "tpAmb")
  aRetorno['verAplic'] := oFuncoes:pegaTag(cXMLResp, "verAplic")
  aRetorno['cStat']    := oFuncoes:pegaTag(cXMLResp, "cStat")
  aRetorno['xMotivo']  := oFuncoes:pegaTag(cXMLResp, "xMotivo")
  aRetorno['cUF']      := oFuncoes:pegaTag(cXMLResp, "cUF")
  aRetorno['dhRecbto'] := oFuncoes:pegaTag(cXMLResp, "dhRecbto")
  aRetorno['tMed']     := oFuncoes:pegaTag(cXMLResp, "tMed")

  oDOMDoc:=Nil
  oServerWS:=Nil
RETURN(aRetorno)
