****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Assinatura Digital)                                           *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
* projeto de apoio para assinatura pem http://wiki.gophp.com.br/index.php?title=Assinar_NFe        *
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

#define XML_NFE          1
#define XML_CANCEL       2
#define XML_INUTIL       3
#define XML_DEPEC        4
#define XML_EVENTO       5
#define XML_EVENTOCANCEL 6
#define XML_EVENTOMANIF  7
#define XML_CTE          8
#define XML_MDFE         9

#define TAG_INICIO  1
#define TAG_FIM     2
#define TAG_TIPOXML 3


CLASS hbNFeAssina
   DATA ohbNFe
   DATA cXMLFile
   DATA lMemFile

   METHOD execute()
   ENDCLASS

METHOD execute() CLASS hbNFeAssina
   LOCAL cCN, cXML, oServerWS, oDOMDoc, cXMLResp, cMsgErro, aRetorno := hash(), I,;
         xmlHeaderAntes, xmldsig, dsigns, oCert, oStoreMem, oError, xmlHeaderDepois,;
         XMLAssinado, posini, ParseError, oSchema, SIGNEDKEY, DSIGKEY, SCONTAINER,;
         SPROVIDER, ETYPE, TIPO, URI, J, NFESW_SHOWNORMAL := 1, nRandom, cXMLSig
   LOCAL aDelimitadores := { ;
      { "<infMDFe",   "</MDFe>",    XML_MDFE   }, ; // antes porque MDFe contém CTe e NFe
      { "<infCte",    "</CTe>",     XML_CTE    }, ; // antes porque CTe  contém NFe
      { "<infNFe",    "</NFe>",     XML_NFE    }, ;
      { "<infCanc",   "</cancNFe>", XML_CANCEL }, ;
      { "<infDPEC",   "</envDPEC>", XML_DPEC   }, ; // DPEC
      { "<infInut",   "</inutNFe>", XML_INUTIL }, ; // inutilização
      { "<infEvento", "</evento>",  XML_EVENTO }, ; // 110110 carta de correção
      { "<infEvento", "</evento>",  XML_EVENTO }, ; // 110111 cancelamento
      { "<infEvento", "</evento>",  XML_EVENTO }, ; // 210200 manifestação
      { "<infEvento", "</evento>",  XML_EVENTO }, ; // 210210 manifestação
      { "<infEvento", "</evento>",  XML_EVENTO }, ; // 210220 manifestação
      { "<infEvento", "</evento>",  XML_EVENTO }, ; // 210240 manifestação
      { "<infEvento", "</evento>",  XML_EVENTO }  } // 110112 manifesto encerramento

   IF ::lMemFile = Nil
      ::lMemFile = .F.
   ENDIF
   IF ::lMemFile = .T.
      cXML := ::cXMLFile
      IF EMPTY( cXML )
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'XML de memoria vazio.'
         RETURN aRetorno
      ENDIF
   ELSE
      IF !FILE( ::cXMLFile )
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Arquivo nao encontrado '+::cXMLFile
         RETURN aRetorno
      ENDIF
      cXML := MEMOREAD(::cXMLFile)
   ENDIF
   IF AT( '<Signature', cXML ) <= 0
      Tipo = 0
      FOR nCont = 1 TO Len( aDelimitadores )
         IF aDelimitadores[ nCont, TAG_INICIO ] $ cXml .AND. aDelimitadores[ nCont, TAG_FIM ] $ cXml
            Tipo := aDelimitadores[ nCont, TAG_TIPOXML ]
            EXIT
         ENDIF
      NEXT
      IF Tipo == 0
         aRetorno[ "OK" ]      := .F.
         aRetorno[ "MsgErro" ] := "Tipo de XML desconhecido" + ::cXmlFile
         RETURN aRetorno
      ENDIF
      //Tipo := 0
      //I := AT('<infNFe',cXML)
      //Tipo := XML_NFE
      //IF I = 0
      //   I := AT('<infCanc',cXML)
      //   IF I > 0
      //      Tipo := XML_CANCEL
      //   ELSE
      //      I := AT('<infInut',cXML)
      //      IF I > 0
      //         Tipo := XML_INUTIL
      //      ELSE
      //         I := AT('<infEvento', cXML)
      //         IF I > 0
      //           IF '<tpEvento>110111</tpEvento>'$cXML   // Cancelamento por Evento - Mauricio Cruz - 09/10/2012
      //              Tipo := XML_EVENTOCANCEL
      //           ELSEIF '<tpEvento>210200</tpEvento>'$cXML .OR. '<tpEvento>210210</tpEvento>'$cXML .OR. '<tpEvento>210220</tpEvento>'$cXML .OR. '<tpEvento>210240</tpEvento>'$cXML // Manifestação do destinatario - Mauricio Cruz 15/10/2012
      //              Tipo := XML_EVENTOMANIF
      //           ELSE
      //              Tipo := XML_EVENTO
      //           ENDIF
      //         ELSE
      //           Tipo := XML_OUTROS
      //         ENDIF
      //      ENDIF
      //   ENDIF
      //ENDIF
      I := AT('Id=',cXML)
      IF I = 0
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Não encontrei inicio do URI: Id='
         RETURN aRetorno
      ENDIF
      I := AT('"',cXML,I+2)
      IF I = 0
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Não encontrei inicio do URI: aspas inicial'
         RETURN aRetorno
      ENDIF
      J := AT( '"', cXML, I + 1 )
      IF J = 0
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Não encontrei inicio do URI: aspas final'
         RETURN aRetorno
      ENDIF
      URI := SUBS(cXML,I+1,J-I-1)

      cXml := Substr( cXml, 1, At( aDelimitadores[ Tipo, TAG_FIM ], cXml ) - 1 )
      //IF Tipo = XML_NFE
      //   cXML := SUBS(cXML,1,AT('</NFe>',cXML)-1)
      //ELSEIF Tipo = XML_CANCEL
      //   cXML := SUBS(cXML,1,AT('</cancNFe>',cXML)-1)
      //ELSEIF Tipo = XML_INUTIL
      //   cXML := SUBS(cXML,1,AT('</inutNFe>',cXML)-1)
      //ELSEIF Tipo = XML_OUTROS
      //   cXML := SUBS(cXML,1,AT('</envDPEC>',cXML)-1)
      //ELSEIF Tipo = XML_EVENTO .OR. Tipo = XML_EVENTOCANCEL .OR. Tipo = XML_EVENTOMANIF
      //   cXML := SUBS(cXML,1,AT('</evento>',cXML)-1)
      //ENDIF

      IF ::ohbNFe:nSOAP = HBNFE_CURL
        cXMLSig := '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#"><SignedInfo><CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/><SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />' +;
                   '<Reference URI="#'+URI+'">' +;
                   '<Transforms><Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" /><Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" /></Transforms><DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />' +;
                   '<DigestValue></DigestValue></Reference></SignedInfo><SignatureValue></SignatureValue><KeyInfo><X509Data></X509Data></KeyInfo></Signature>'
      ELSE
        cXMLSig := '<Signature xmlns="http://www.w3.org/2000/09/xmldsig#"><SignedInfo><CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/><SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />' +;
                   '<Reference URI="#'+URI+'">' +;
                   '<Transforms><Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" /><Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" /></Transforms><DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />' +;
                   '<DigestValue></DigestValue></Reference></SignedInfo><SignatureValue></SignatureValue><KeyInfo></KeyInfo></Signature>'
      ENDIF
      cXML += cXMLSig

      cXml += aDelimitadores[ Tipo, TAG_FIM ]
      //IF Tipo = XML_NFE
      //   cXML := cXML + '</NFe>'
      //ELSEIF Tipo = XML_CANCEL
      //   cXML := cXML + '</cancNFe>'
      //ELSEIF Tipo = XML_INUTIL
      //   cXML := cXML + '</inutNFe>'
      //ELSEIF Tipo = XML_OUTROS
      //   cXML := cXML + '</envDPEC>'
      //ELSEIF Tipo = XML_EVENTO .OR. Tipo = XML_EVENTOCANCEL .OR. Tipo = XML_EVENTOMANIF
      //   cXML := cXML + '</evento>' //</envEvento>'
      //ENDIF
  ENDIF

  IF ::ohbNFe:nSOAP = HBNFE_CURL
     // assinar
     nRandom := RANDOM( 1, 9999 )
     MEMOWRIT('xml_'+ALLTRIM(STR(nRandom))+'.temp',cXML, .F.)
     MEMOWRIT('sign_'+ALLTRIM(STR(nRandom))+'.bat','xmlsec\xmlsec --sign --output signed.xml --pkcs12 '+::ohbNFe:cCertPFX+' --pwd '+::ohbNFe:cCertPass+' --trusted-pem '+::ohbNFe:cCertFilePub+' --id-attr:Id infNFe xml.temp' , .F.)
     #ifndef __XHARBOUR__
        WAPI_SHELLEXECUTE('sign_'+ALLTRIM(STR(nRandom))+'.bat',, 'sign_'+ALLTRIM(STR(nRandom))+'.bat' ,,, NFESW_SHOWNORMAL)
     #else
        RUN('sign_'+ALLTRIM(STR(nRandom))+'.bat')
     #endif
     millisec(1000)
     FERASE('xml_'+ALLTRIM(STR(nRandom))+'.temp')
     FERASE('sign_'+ALLTRIM(STR(nRandom))+'.bat')

     XMLAssinado := MEMOREAD('signed.xml')
     XMLAssinado := STRTRAN( XMLAssinado, CHR(10), '' )
     XMLAssinado := STRTRAN( XMLAssinado, CHR(13), '' )

  ELSE // CAPICOM
       // Lendo Header antes de assinar //
       xmlHeaderAntes := ''
       I := AT('?>',cXML)
       IF I > 0
          xmlHeaderAntes := SUBS(cXML,1,I+1)
       ENDIF

       TRY
         #ifdef __XHARBOUR__
            oDOMDoc := xhb_CreateObject( _MSXML2_DOMDocument )
         #else
            oDOMDoc := win_oleCreateObject( _MSXML2_DOMDocument )
         #endif
       CATCH
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'Nao consegui carregar ' + _MSXML2_DOMDocument
          RETURN aRetorno
       END
       oDOMDoc:async = .F.
       oDOMDoc:resolveExternals := .F.
       oDOMDoc:validateOnParse  = .T.
       oDOMDoc:preserveWhiteSpace = .T.

       TRY
         #ifdef __XHARBOUR__
            xmldsig := xhb_CreateObject( _MSXML2_MXDigitalSignature )
         #else
            xmldsig := win_oleCreateObject( _MSXML2_MXDigitalSignature )
         #endif
       CATCH
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'Nao consegui carregar ' + _MSXML2_MXDigitalSignature
          RETURN aRetorno
       END

       oDOMDoc:LoadXML(cXML)
       IF oDOMDoc:parseError:errorCode <> 0 // XML não carregado
          cMsgErro := "assinar: Não foi possível carregar o documento pois ele não corresponde ao seu Schema"+HB_OsNewLine()
          cMsgErro = cMsgErro + " Linha: " + STR(oDOMDoc:parseError:line)+HB_OsNewLine()
          cMsgErro = cMsgErro + " Caractere na linha: " + STR(oDOMDoc:parseError:linepos)+HB_OsNewLine()
          cMsgErro = cMsgErro + " Causa do erro: " + oDOMDoc:parseError:reason+HB_OsNewLine();
                      +"code: "+STR(oDOMDoc:parseError:errorCode)
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := cMsgErro
          RETURN aRetorno
       ENDIF

       DSIGNS = "xmlns:ds='http://www.w3.org/2000/09/xmldsig#'"
       oDOMDoc:setProperty('SelectionNamespaces', DSIGNS)

       xmldsig:signature := oDOMDoc:selectSingleNode('.//ds:Signature')
       IF (xmldsig:signature = nil)
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'É preciso carregar o template antes de assinar.'
          RETURN aRetorno
       ENDIF

       oCert:=::ohbNFe:pegaObjetoCertificado(::ohbNFe:cSerialCert)
       IF oCert == Nil
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'Certificado não encontrado, Favor revisar a instalação do Certificado'
          RETURN aRetorno
       ENDIF

       #ifdef __XHARBOUR__
          oStoreMem := xhb_CreateObject( "CAPICOM.Store" )
       #else
          oStoreMem := win_oleCreateObject( "CAPICOM.Store" )
       #endif

       TRY
          oStoreMem:open(_CAPICOM_MEMORY_STORE,'Memoria',_CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED)
       CATCH oError
         cMsgErro := "Falha ao criar espaço certificado na memoria "+HB_OsNewLine()+ ;
                 	 "Error: "  + Transform(oError:GenCode, nil) + ";" +HB_OsNewLine()+ ;
                  	 "SubC: "   + Transform(oError:SubCode, nil) + ";" +HB_OsNewLine()+ ;
                 	 "OSCode: "  + Transform(oError:OsCode,  nil) + ";" +HB_OsNewLine()+ ;
                 	 "SubSystem: " + Transform(oError:SubSystem, nil) + ";" +HB_OsNewLine()+ ;
                	 "Mensangem: " + oError:Description
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := cMSgErro
          RETURN aRetorno
       END

       TRY
          oStoreMem:Add(oCert)
       CATCH oError
         cMsgErro := "Falha ao adicionar certificado na memoria "+HB_OsNewLine()+ ;
                 	 "Error: "  + Transform(oError:GenCode, nil) + ";" +HB_OsNewLine()+ ;
                  	 "SubC: "   + Transform(oError:SubCode, nil) + ";" +HB_OsNewLine()+ ;
                 	 "OSCode: "  + Transform(oError:OsCode,  nil) + ";" +HB_OsNewLine()+ ;
                 	 "SubSystem: " + Transform(oError:SubSystem, nil) + ";" +HB_OsNewLine()+ ;
                	 "Mensangem: " + oError:Description
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := cMSgErro
          RETURN aRetorno
       END

       xmldsig:store := oStoreMem

       //---> Dados necessários para gerar a assinatura

       TRY
          eType := oCert:PrivateKey:ProviderType
          sProvider := oCert:PrivateKey:ProviderName
          sContainer := oCert:PrivateKey:ContainerName
          dsigKey := xmldsig:createKeyFromCSP(eType, sProvider, sContainer, 0)
       CATCH
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'Erro ao criar a chave do CSP, talvez o certificado não esteja instalado corretamente.'
          RETURN aRetorno
       END
       IF (dsigKey = nil)
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'Erro ao criar a chave do CSP.'
          RETURN aRetorno
       ENDIF

       TRY
          signedKey := xmldsig:sign(dsigKey, 2)
       CATCH
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'Erro ao criar a chave do CSP, talvez o certificado não esteja instalado corretamente.'
          RETURN aRetorno
       END

       IF (signedKey <> nil)
          XMLAssinado := oDOMDoc:xml
          XMLAssinado := STRTRAN( XMLAssinado, CHR(10), '' )
          XMLAssinado := STRTRAN( XMLAssinado, CHR(13), '' )
          PosIni := AT('<SignatureValue>',XMLAssinado)+len('<SignatureValue>')
          XMLAssinado := SUBS(XMLAssinado,1,PosIni-1)+STRTRAN( SUBS(XMLAssinado,PosIni,len(XMLAssinado)), ' ', '' )
          PosIni := AT('<X509Certificate>',XMLAssinado)-1
          nP = AT('<X509Certificate>',XMLAssinado)
          nResult := 0
          DO WHILE nP<>0
             nResult := nP
             nP = AT('<X509Certificate>',XMLAssinado,nP+1)
          ENDDO
          PosFim := nResult
*      MEMOWRIT('35canc5.xml',XMLAssinado,.F.)

          XMLAssinado := SUBS(XMLAssinado,1,PosIni)+SUBS(XMLAssinado,PosFim,len(XMLAssinado))
*      MEMOWRIT('35canc6.xml',XMLAssinado,.F.)
       ELSE
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'Assinatura Falhou.'
          RETURN aRetorno
       ENDIF

       IF xmlHeaderAntes <> ''
          I := at(XMLAssinado,'?>')
          IF I > 0
             xmlHeaderDepois := subs(XMLAssinado,1,I+1)
             IF xmlHeaderAntes <> xmlHeaderDepois
*                ? "entrou stuff"
*                XMLAssinado := StuffString(XMLAssinado,1,length(xmlHeaderDepois),xmlHeaderAntes)
             ENDIF
          ELSE
             XMLAssinado := xmlHeaderAntes + XMLAssinado
          ENDIF
       ENDIF
   ENDIF

   TRY
      IF ::lMemFile = .T.
         aRetorno['XMLAssinado'] := XMLAssinado
      ELSE
         aRetorno['XMLAssinado'] := XMLAssinado
         MEMOWRIT(::cXMLFile,XMLAssinado,.F.)
      ENDIF
   CATCH oError
     cMsgErro := "Falha ao gravar XML assinado "+HB_OsNewLine()+ ;
             	 "Error: "  + Transform(oError:GenCode, nil) + ";" +HB_OsNewLine()+ ;
              	 "SubC: "   + Transform(oError:SubCode, nil) + ";" +HB_OsNewLine()+ ;
             	 "OSCode: "  + Transform(oError:OsCode,  nil) + ";" +HB_OsNewLine()+ ;
             	 "SubSystem: " + Transform(oError:SubSystem, nil) + ";" +HB_OsNewLine()+ ;
            	 "Mensangem: " + oError:Description
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := cMSgErro
      RETURN aRetorno
   END

   oDOMDoc    := nil
   ParseError := nil
   oSchema    := nil
   aRetorno[ 'OK' ] := .T.
   RETURN aRetorno
