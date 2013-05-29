****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Consulta Cadastro)                                            *
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
   #include "hbcurl.ch"
#endif
#include "hbnfe.ch"

CLASS hbNFeConsultaCadastro
   DATA ohbNFe
   DATA cUFWS
   DATA versaoDados
   DATA cUF
   DATA cCNPJ

   METHOD execute()
ENDCLASS

METHOD execute() CLASS hbNFeConsultaCadastro
LOCAL cCN, cUrlWS, cXML, oServerWS, oDOMDoc, cXMLResp, cMsgErro, aRetorno := hash(),;
      oFuncoes := hbNFeFuncoes(), cSOAPAction := 'http://www.portalfiscal.inf.br/nfe/wsdl/CadConsultaCadastro2',;
      cFileEnvRes, oError, cXMLDados, oCurl, aHeader, retHTTP

   IF ::cUFWS = Nil
      ::cUFWS := ::ohbNFe:cUFWS
   ENDIF
   IF ::versaoDados = Nil
      ::versaoDados := ::ohbNFe:versaoDados
   ENDIF

   cCN := ::ohbNFe:pegaCNCertificado(::ohbNFe:cSerialCert)

   cUrlWS := ::ohbNFe:getURLWS(_CONSULTACADASTRO)
   if cUrlWS = nil
      cMsgErro := "Serviço indisponível na Sefaz" + HB_OSNEWLINE()      +;
                  "Consulte através do Site do Sintegra"
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := cMsgErro
      RETURN(aRetorno)
   endif

   cXMLDados := '<ConsCad xmlns="http://www.portalfiscal.inf.br/nfe" versao="2.00">';
                  +'<infCons>';
                    +'<xServ>CONS-CAD</xServ>';
                    +'<UF>'+::cUF+'</UF>';
                    +'<CNPJ>'+::cCNPJ+'</CNPJ>';
                  +'</infCons>';
                +'</ConsCad>'

   cXML := '<?xml version="1.0" encoding="utf-8"?>'
   cXML := cXML + '<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
   cXML := cXML +   '<soap12:Header>'
   cXML := cXML +     '<nfeCabecMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/CadConsultaCadastro2">'
   cXML := cXML +       '<cUF>'+::cUFWS+'</cUF>'
   cXML := cXML +       '<versaoDados>'+::versaoDados+'</versaoDados>'
   cXML := cXML +     '</nfeCabecMsg>'
   cXML := cXML +   '</soap12:Header>'
   cXML := cXML +   '<soap12:Body>'

   cXML := cXML +     '<nfeDadosMsg xmlns="http://www.portalfiscal.inf.br/nfe/wsdl/CadConsultaCadastro2">'
   cXML := cXML + cXMLDados
   cXML := cXML +     '</nfeDadosMsg>'

   cXML := cXML +   '</soap12:Body>'
   cXML := cXML +'</soap12:Envelope>'
   cFileEnvRes := ::cCNPJ+oFuncoes:formatDate( DATE(), "YYMMDD")+SUBS(TIME(),1,2)+SUBS(TIME(),4,2)+SUBS(TIME(),7,2)
   TRY
      MEMOWRIT(::ohbNFe:pastaEnvRes+"\"+cFileEnvRes+"-ped-cad.xml",cXMLDados,.F.)
   CATCH
      aRetorno['OK']       := .T.
      aRetorno['MsgErro']  := 'Problema ao gravar pedido do cadastro '+::ohbNFe:pastaEnvRes+"\"+cFileEnvRes+"-ped-cad.xml"
      RETURN(aRetorno)
   END

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
     #ifdef __XHARBOUR__
        oServerWS := xhb_CreateObject( "MSXML2.ServerXMLHTTP.5.0" )
     #else
        oServerWS := win_oleCreateObject( "MSXML2.ServerXMLHTTP.5.0")
     #endif
     oServerWS:setOption( 3, "CURRENT_USER\MY\"+cCN )
     oServerWS:open("POST", cUrlWS, .F.)
     oServerWS:setRequestHeader("SOAPAction", cSOAPAction)
     oServerWS:setRequestHeader("Content-Type", "application/soap+xml; charset=utf-8")
  
     #ifdef __XHARBOUR__
        oDOMDoc := xhb_CreateObject( "MSXML2.DOMDocument.5.0" )
     #else
        oDOMDoc := win_oleCreateObject( "MSXML2.DOMDocument.5.0")
     #endif
     oDOMDoc:async = .F.
     oDOMDoc:validateOnParse  = .T.
     oDOMDoc:resolveExternals := .F.
     oDOMDoc:preserveWhiteSpace = .T.
     oDOMDoc:LoadXML(cXML)
     IF oDOMDoc:parseError:errorCode <> 0 // XML não carregado
        cMsgErro := "Não foi possível carregar o documento pois ele não corresponde ao seu Schema"+HB_OsNewLine() + ;
                    " Linha: " + STR(oDOMDoc:parseError:line)+HB_OsNewLine() + ;
                    " Caractere na linha: " + STR(oDOMDoc:parseError:linepos)+HB_OsNewLine() + ;
                    " Causa do erro: " + oDOMDoc:parseError:reason+HB_OsNewLine() + ;
                    " Code: "+STR(oDOMDoc:parseError:errorCode)
        aRetorno['OK']       := .F.
        aRetorno['MsgErro']  := cMsgErro
        RETURN(aRetorno)
     ENDIF
     TRY
        oServerWS:send(oDOMDoc:xml)
     CATCH oError
        cMsgErro := "Falha "+HB_OsNewLine()+ ;
                 	"Error: "  + Transform(oError:GenCode, nil) + ";" +HB_OsNewLine()+ ;
                 	"SubC: "   + Transform(oError:SubCode, nil) + ";" +HB_OsNewLine()+ ;
                 	"OSCode: "  + Transform(oError:OsCode,  nil) + ";" +HB_OsNewLine()+ ;
                 	"SubSystem: " + Transform(oError:SubSystem, nil) + ";" +HB_OsNewLine()+ ;
                 	"Mensangem: " + oError:Description
        aRetorno['OK']       := .F.
        aRetorno['MsgErro']  := cMsgErro
        RETURN(aRetorno)
     END
     DO WHILE oServerWS:readyState <> 4
        millisec(500)
     ENDDO
     cXMLResp := HB_ANSITOOEM(oServerWS:responseText)
   ENDIF
   cXMLResp := oFuncoes:pegaTag( cXMLResp , 'retConsCad' )
   TRY
      MEMOWRIT(::ohbNFe:pastaEnvRes+"\"+cFileEnvRes+"-cad.xml",cXMLResp,.F.)
   CATCH
      aRetorno['OK']       := .T.
      aRetorno['MsgErro']  := 'Problema ao gravar retorno do cadastro '+::ohbNFe:pastaEnvRes+"\"+cFileEnvRes+"-cad.xml"
      aRetorno['verAplic']   := oFuncoes:pegaTag(cXMLResp, "verAplic")
      aRetorno['cStat']      := oFuncoes:pegaTag(cXMLResp, "cStat")
      aRetorno['xMotivo']    := oFuncoes:pegaTag(cXMLResp, "xMotivo")
      aRetorno['IE']         := oFuncoes:pegaTag(cXMLResp, "IE")
      aRetorno['CNPJ']       := oFuncoes:pegaTag(cXMLResp, "CNPJ")
      aRetorno['cSit']       := oFuncoes:pegaTag(cXMLResp, "cSit")
      aRetorno['indCredNFe'] := oFuncoes:pegaTag(cXMLResp, "indCredNFe")
      aRetorno['indCredCTe'] := oFuncoes:pegaTag(cXMLResp, "indCredCTe")
      aRetorno['xNome']      := oFuncoes:pegaTag(cXMLResp, "xNome")
      aRetorno['xRegApur']   := oFuncoes:pegaTag(cXMLResp, "xRegApur")
      aRetorno['CNAE']       := oFuncoes:pegaTag(cXMLResp, "CNAE")
      aRetorno['dIniAtiv']   := oFuncoes:pegaTag(cXMLResp, "dIniAtiv")
      aRetorno['dUltSit']    := oFuncoes:pegaTag(cXMLResp, "dUltSit")
      aRetorno['xLgr']       := oFuncoes:pegaTag(cXMLResp, "xLgr")
      aRetorno['nro']        := oFuncoes:pegaTag(cXMLResp, "nro")
      aRetorno['xBairro']    := oFuncoes:pegaTag(cXMLResp, "xBairro")
      aRetorno['cMun']       := oFuncoes:pegaTag(cXMLResp, "cMun")
      aRetorno['xMun']       := oFuncoes:pegaTag(cXMLResp, "xMun")
      aRetorno['CEP']        := oFuncoes:pegaTag(cXMLResp, "CEP")
      RETURN(aRetorno)
   END
   aRetorno['OK']         := .T.
   aRetorno['MsgErro']    := ""
   aRetorno['verAplic']   := oFuncoes:pegaTag(cXMLResp, "verAplic")
   aRetorno['cStat']      := oFuncoes:pegaTag(cXMLResp, "cStat")
   aRetorno['xMotivo']    := oFuncoes:pegaTag(cXMLResp, "xMotivo")
   aRetorno['IE']         := oFuncoes:pegaTag(cXMLResp, "IE")
   aRetorno['CNPJ']       := oFuncoes:pegaTag(cXMLResp, "CNPJ")
   aRetorno['cSit']       := oFuncoes:pegaTag(cXMLResp, "cSit")
   aRetorno['indCredNFe'] := oFuncoes:pegaTag(cXMLResp, "indCredNFe")
   aRetorno['indCredCTe'] := oFuncoes:pegaTag(cXMLResp, "indCredCTe")
   aRetorno['xNome']      := oFuncoes:pegaTag(cXMLResp, "xNome")
   aRetorno['xRegApur']   := oFuncoes:pegaTag(cXMLResp, "xRegApur")
   aRetorno['CNAE']       := oFuncoes:pegaTag(cXMLResp, "CNAE")
   aRetorno['dIniAtiv']   := oFuncoes:pegaTag(cXMLResp, "dIniAtiv")
   aRetorno['dUltSit']    := oFuncoes:pegaTag(cXMLResp, "dUltSit")
   aRetorno['xLgr']       := oFuncoes:pegaTag(cXMLResp, "xLgr")
   aRetorno['nro']        := oFuncoes:pegaTag(cXMLResp, "nro")
   aRetorno['xBairro']    := oFuncoes:pegaTag(cXMLResp, "xBairro")
   aRetorno['cMun']       := oFuncoes:pegaTag(cXMLResp, "cMun")
   aRetorno['xMun']       := oFuncoes:pegaTag(cXMLResp, "xMun")
   aRetorno['CEP']        := oFuncoes:pegaTag(cXMLResp, "CEP")

   oDOMDoc:=Nil
   oServerWS:=Nil
RETURN(aRetorno)
