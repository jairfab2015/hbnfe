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

   IF ::lMemFile = Nil
      ::lMemFile = .F.
   ENDIF
   IF ::lMemFile = .T.
      cXML := ::cXMLFile
      IF EMPTY( cXML )
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'XML de memoria vazio.'
         RETURN(aRetorno)
      ENDIF
   ELSE
      IF !FILE( ::cXMLFile )
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Arquivo nao encontrado '+::cXMLFile
         RETURN(aRetorno)
      ENDIF
      cXML := MEMOREAD(::cXMLFile)
   ENDIF
   IF AT('<Signature',cXML) <= 0
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
      I := AT('Id=',cXML)
      IF I = 0
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Não encontrei inicio do URI: Id='
         RETURN(aRetorno)
      ENDIF
      I := AT('"',cXML,I+2)
      IF I = 0
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Não encontrei inicio do URI: aspas inicial'
         RETURN(aRetorno)
      ENDIF
      J := AT('"',cXML,I+1)
      IF J = 0
         aRetorno['OK']       := .F.
         aRetorno['MsgErro']  := 'Não encontrei inicio do URI: aspas final'
         RETURN(aRetorno)
      ENDIF
      URI := SUBS(cXML,I+1,J-I-1)

      IF Tipo = 1
         cXML := SUBS(cXML,1,AT('</NFe>',cXML)-1)
      ELSEIF Tipo = 2
         cXML := SUBS(cXML,1,AT('</cancNFe>',cXML)-1)
      ELSEIF Tipo = 3
         cXML := SUBS(cXML,1,AT('</inutNFe>',cXML)-1)
      ELSEIF Tipo = 4
         cXML := SUBS(cXML,1,AT('</envDPEC>',cXML)-1)
      ELSEIF Tipo = 5 .OR. Tipo = 6 .OR. Tipo=7
         cXML := SUBS(cXML,1,AT('</evento>',cXML)-1)
      ENDIF

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

      IF Tipo = 1
         cXML := cXML + '</NFe>'
      ELSEIF Tipo = 2
         cXML := cXML + '</cancNFe>'
      ELSEIF Tipo = 3
         cXML := cXML + '</inutNFe>'
      ELSEIF Tipo = 4
         cXML := cXML + '</envDPEC>'
      ELSEIF Tipo = 5 .OR. Tipo = 6 .OR. Tipo=7
         cXML := cXML + '</evento>' //</envEvento>'
      ENDIF
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
            oDOMDoc := xhb_CreateObject( "MSXML2.DOMDocument.5.0" )
         #else
            oDOMDoc := win_oleCreateObject( "MSXML2.DOMDocument.5.0")
         #endif
       CATCH
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'Nao consegui carregar MSXML2.DOMDocument.5.0'
          RETURN(aRetorno)
       END
       oDOMDoc:async = .F.
       oDOMDoc:resolveExternals := .F.
       oDOMDoc:validateOnParse  = .T.
       oDOMDoc:preserveWhiteSpace = .T.
    
       TRY
         #ifdef __XHARBOUR__
            xmldsig := xhb_CreateObject( "MSXML2.MXDigitalSignature.5.0" )
         #else
            xmldsig := win_oleCreateObject( "MSXML2.MXDigitalSignature.5.0")
         #endif
       CATCH
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'Nao consegui carregar MSXML2.MXDigitalSignature.5.0'
          RETURN(aRetorno)
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
          RETURN(aRetorno)
       ENDIF

       DSIGNS = "xmlns:ds='http://www.w3.org/2000/09/xmldsig#'"
       oDOMDoc:setProperty('SelectionNamespaces', DSIGNS)

       xmldsig:signature := oDOMDoc:selectSingleNode('.//ds:Signature')
       IF (xmldsig:signature = nil)
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'É preciso carregar o template antes de assinar.'
          RETURN(aRetorno)
       ENDIF

       oCert:=::ohbNFe:pegaObjetoCertificado(::ohbNFe:cSerialCert)
       IF oCert == Nil
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'Certificado não encontrado, Favor revisar a instalação do Certificado'
          RETURN(aRetorno)
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
          RETURN(aRetorno)
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
          RETURN(aRetorno)
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
          RETURN(aRetorno)
       END

       IF (dsigKey = nil)
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'Erro ao criar a chave do CSP.'
          RETURN(aRetorno)
       ENDIF

       TRY
          signedKey := xmldsig:sign(dsigKey, 2)
       CATCH
          aRetorno['OK']       := .F.
          aRetorno['MsgErro']  := 'Erro ao criar a chave do CSP, talvez o certificado não esteja instalado corretamente.'
          RETURN(aRetorno)
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
          RETURN(aRetorno)
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
      RETURN(aRetorno)
   END

   oDOMDoc := nil
   ParseError := nil
   oSchema := nil
   aRetorno['OK'] := .T.
RETURN(aRetorno)
