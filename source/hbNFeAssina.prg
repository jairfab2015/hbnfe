****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Assinatura Digital)                                           *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
* projeto de apoio para assinatura pem http://wiki.gophp.com.br/index.php?title=Assinar_NFe        *
****************************************************************************************************


#include "hbclass.ch"
#include "hbnfe.ch"

CLASS hbNFeAssina
   DATA   ohbNFe
   DATA   cXmlFile
   DATA   lMemFile
   METHOD Execute()
   ENDCLASS


METHOD Execute() CLASS hbNFeAssina
   LOCAL cXml, oDOMDoc, cMsgErro, aRetorno := hash(), I, ;
         xmlHeaderAntes, xmldsig, dsigns, oCert, oStoreMem, oError, xmlHeaderDepois, ;
         XMLAssinado, posini, SIGNEDKEY, DSIGKEY, SCONTAINER, ;
         SPROVIDER, ETYPE, URI, J, nRandom, cXmlSig // , NFESW_SHOWNORMAL := 1
   LOCAL nP, nResult, PosFim
   LOCAL cXmlTagInicial := "", cXmlTagFinal := "", nCont
   LOCAL aDelimitadores := { ;
      { "<enviMDFe",   "</MDFe></enviMDFe>"   }, ; // MDFE envio - no fonte hbmdfe assina envio completo
      { "<eventoMDFe", "</eventoMDFe>"        }, ; // MDFE evento
      { "<infMDFe",    "</MDFe>"              }, ; // MDFE - antes porque MDFe contém CTe e NFe
      { "<infCte",     "</CTe>"               }, ; // CTE  - antes porque CTe  contém NFe - esquisito mas é infCte e não infCTe
      { "<infNFe",     "</NFe>"               }, ; // NFE
      { "<infCanc",    "</cancNFe>"           }, ; // Cancelamento antigo
      { "<infDPEC",    "</envDPEC>"           }, ; // DPEC
      { "<infInut",    "</inutNFe>"           }, ; // Inutilização
      { "<infEvento",  "</evento>"            }, ; // Evento 110110 carta de correção
      { "<infEvento",  "</evento>"            }, ; // Evento 110111 cancelamento
      { "<infEvento",  "</evento>"            }, ; // Evento 210200 manifestação
      { "<infEvento",  "</evento>"            }, ; // Evento 210210 manifestação
      { "<infEvento",  "</evento>"            }, ; // Evento 210220 manifestação
      { "<infEvento",  "</evento>"            }, ; // Evento 210240 manifestação
      { "<infEvento",  "</evento>"            } }  // Evento 110112 manifesto encerramento

   IF ::lMemFile = NIL
      ::lMemFile = .F.
   ENDIF
   IF ::lMemFile = .T.
      cXml := ::cXmlFile
      IF EMPTY( cXml )
         aRetorno[ 'OK' ]      := .F.
         aRetorno[ 'MsgErro' ] := 'XML de memoria vazio.'
         RETURN aRetorno
      ENDIF
   ELSE
      IF .NOT. File( ::cXmlFile )
         aRetorno[ 'OK' ]      := .F.
         aRetorno[ 'MsgErro' ] := 'Arquivo nao encontrado '+::cXmlFile
         RETURN aRetorno
      ENDIF
      cXml := MEMOREAD(::cXmlFile)
   ENDIF
   IF At( '<Signature', cXml ) <= 0
      FOR nCont = 1 TO Len( aDelimitadores )
         IF aDelimitadores[ nCont, 1 ] $ cXml .AND. aDelimitadores[ nCont, 2 ] $ cXml
            cXmlTagInicial := aDelimitadores[ nCont, 1 ]
            cXmlTagFinal   := aDelimitadores[ nCont, 2 ]
            EXIT
         ENDIF
      NEXT
      IF Empty( cXmlTagInicial ) .OR. Empty( cXmlTagFinal )
         aRetorno[ "OK" ]      := .F.
         aRetorno[ "MsgErro" ] := "Tipo de XML desconhecido" + ::cXmlFile
         RETURN aRetorno
      ENDIF
      I := At( 'Id=', cXml )
      IF I = 0
         aRetorno[ 'OK' ]       := .F.
         aRetorno[ 'MsgErro' ]  := 'Nao encontrei inicio do URI: Id='
         RETURN aRetorno
      ENDIF
      I := At( '"', cXml, I + 2 )
      IF I = 0
         aRetorno[ 'OK' ]       := .F.
         aRetorno[ 'MsgErro' ]  := 'Nao encontrei inicio do URI: aspas inicial'
         RETURN aRetorno
      ENDIF
      J := At( '"', cXml, I + 1 )
      IF J = 0
         aRetorno[ 'OK' ]       := .F.
         aRetorno[ 'MsgErro' ]  := 'Nao encontrei inicio do URI: aspas final'
         RETURN aRetorno
      ENDIF
      URI := Substr( cXml, I + 1, J - I - 1 )

      cXmlSig := [<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">]
      cXmlSig +=    [<SignedInfo>]
      cXmlSig +=       [<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>]
      cXmlSig +=       [<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />]
      cXmlSig +=       [<Reference URI="#] + URI + [">]
      cXmlSig +=          [<Transforms>]
      cXmlSig +=             [<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />]
      cXmlSig +=             [<Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />]
      cXmlSig +=          [</Transforms>]
      cXmlSig +=          [<DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />]
      cXmlSig +=          [<DigestValue>]
      cXmlSig +=          [</DigestValue>]
      cXmlSig +=       [</Reference>]
      cXmlSig +=    [</SignedInfo>]
      cXmlSig +=    [<SignatureValue>]
      cXmlSig +=    [</SignatureValue>]
      cXmlSig +=    [<KeyInfo>]
      IF ::ohbNFe:nSOAP = HBNFE_CURL
         cXmlSig += [<X509Data>]
         cXmlSig += [</X509Data>]
      ENDIF
      cXmlSig +=    [</KeyInfo>]
      cXmlSig += [</Signature>]

      cXml := Substr( cXml, 1, At( cXmlTagFinal, cXml ) - 1 ) + cXmlSig + cXmlTagFinal
  ENDIF

  IF ::ohbNFe:nSOAP = HBNFE_CURL
     // assinar
     nRandom := Random( 1, 9999 )
     hb_MemoWrit( 'xml_' + AllTrim( Str( nRandom ) ) + '.temp', cXml )
     hb_MemoWrit( 'sign_' + AllTrim( Str( nRandom ) ) + '.bat', 'xmlsec\xmlsec --sign --output signed.xml --pkcs12 ' + ;
        ::ohbNFe:cCertPFX + ' --pwd ' + ::ohbNFe:cCertPass + ' --trusted-pem ' + ::ohbNFe:cCertFilePub + ;
        ' --id-attr:Id infNFe xml.temp' )
     //#ifndef __XHARBOUR__
     // No início do Harbour 3.2 o RUN causava problemas. Se for esse o caso, altere aqui
     //   wapi_ShellExecute( 'sign_' + AllTrim( Str( nRandom ) ) + '.bat',, 'sign_' + AllTrim( Str( nRandom ) ) + '.bat' ,,, NFESW_SHOWNORMAL )
     //#else
        RUN ( 'sign_' + AllTrim( Str( nRandom ) ) + '.bat' )
     //#endif
     millisec( 1000 )
     fErase( 'xml_' + AllTrim( Str( nRandom ) ) + '.temp' )
     fErase( 'sign_' + AllTrim( Str( nRandom ) ) + '.bat' )

     XMLAssinado := MemoRead( 'signed.xml' )
     XMLAssinado := StrTran( XMLAssinado, CHR(10), '' )
     XMLAssinado := StrTran( XMLAssinado, CHR(13), '' )

  ELSE // CAPICOM
       // Lendo Header antes de assinar //
       xmlHeaderAntes := ''
       I := At( '?>', cXml )
       IF I > 0
          xmlHeaderAntes := Substr( cXml, 1, I + 1 )
       ENDIF

       TRY

            oDOMDoc := win_oleCreateObject( _MSXML2_DOMDocument )

       CATCH
          aRetorno[ 'OK' ]       := .F.
          aRetorno[ 'MsgErro' ]  := 'Nao consegui carregar ' + _MSXML2_DOMDocument
          RETURN aRetorno
       END
       oDOMDoc:async              := .F.
       oDOMDoc:resolveExternals   := .F.
       oDOMDoc:validateOnParse    := .T.
       oDOMDoc:preserveWhiteSpace := .T.

       TRY

         xmldsig := win_oleCreateObject( _MSXML2_MXDigitalSignature )

       CATCH
          aRetorno[ 'OK' ]       := .F.
          aRetorno[ 'MsgErro' ]  := 'Nao consegui carregar ' + _MSXML2_MXDigitalSignature
          RETURN aRetorno
       END

       oDOMDoc:LoadXML( cXml )
       IF oDOMDoc:parseError:errorCode <> 0 // XML não carregado
          cMsgErro := "assinar: Nao foi possível carregar o documento pois ele nao corresponde ao seu Schema" + HB_EOL()
          cMsgErro += " Linha: "              + Str( oDOMDoc:parseError:line )   + HB_EOL()
          cMsgErro += " Caractere na linha: " + STR(oDOMDoc:parseError:linepos ) + HB_EOL()
          cMsgErro += " Causa do erro: "      + oDOMDoc:parseError:reason        + HB_EOL()
          cMsgErro += "code: "                + Str( oDOMDoc:parseError:errorCode )
          aRetorno[ 'OK' ]       := .F.
          aRetorno[ 'MsgErro' ]  := cMsgErro
          RETURN aRetorno
       ENDIF

       DSIGNS = "xmlns:ds='http://www.w3.org/2000/09/xmldsig#'"
       oDOMDoc:setProperty( 'SelectionNamespaces', DSIGNS )

       xmldsig:signature := oDOMDoc:selectSingleNode( './/ds:Signature' )
       IF ( xmldsig:signature = NIL )
          aRetorno[ 'OK' ]       := .F.
          aRetorno[ 'MsgErro' ]  := 'E preciso carregar o template antes de assinar.'
          RETURN aRetorno
       ENDIF

       oCert:=::ohbNFe:pegaObjetoCertificado( ::ohbNFe:cSerialCert )
       IF oCert == NIL
          aRetorno[ 'OK' ]       := .F.
          aRetorno[ 'MsgErro' ]  := 'Certificado nao encontrado, Favor revisar a instalacao do Certificado'
          RETURN aRetorno
       ENDIF

       oStoreMem := win_oleCreateObject( "CAPICOM.Store" )

       TRY
          oStoreMem:open( _CAPICOM_MEMORY_STORE, 'Memoria', _CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED )
       CATCH oError
         cMsgErro := "Falha ao criar espaco certificado na memoria " + HB_EOL() + ;
                 	 "Error: "     + Transform( oError:GenCode, NIL )   + ";" + HB_EOL() + ;
                  	 "SubC: "      + Transform( oError:SubCode, NIL )   + ";" + HB_EOL() + ;
                 	 "OSCode: "    + Transform( oError:OsCode,  NIL )   + ";" + HB_EOL() + ;
                 	 "SubSystem: " + Transform( oError:SubSystem, NIL ) + ";" + HB_EOL() + ;
                	 "Mensagem: "  + oError:Description
          aRetorno[ 'OK' ]       := .F.
          aRetorno[ 'MsgErro' ]  := cMSgErro
          RETURN aRetorno
       END

       TRY
          oStoreMem:Add( oCert )
       CATCH oError
         cMsgErro := "Falha ao adicionar certificado na memoria "+HB_EOL()+ ;
                 	 "Error: "     + Transform( oError:GenCode, NIL )   + ";" + HB_EOL() + ;
                  	 "SubC: "      + Transform( oError:SubCode, NIL )   + ";" + HB_EOL() + ;
                 	 "OSCode: "    + Transform( oError:OsCode, NIL )    + ";" + HB_EOL() + ;
                 	 "SubSystem: " + Transform( oError:SubSystem, NIL ) + ";" + HB_EOL() + ;
                	 "Mensagem: "  + oError:Description
          aRetorno[ 'OK' ]       := .F.
          aRetorno[ 'MsgErro' ]  := cMSgErro
          RETURN aRetorno
       END

       xmldsig:store := oStoreMem

       //---> Dados necessários para gerar a assinatura

       TRY
          eType      := oCert:PrivateKey:ProviderType
          sProvider  := oCert:PrivateKey:ProviderName
          sContainer := oCert:PrivateKey:ContainerName
          dsigKey    := xmldsig:createKeyFromCSP( eType, sProvider, sContainer, 0 )
       CATCH
          aRetorno[ 'OK' ]       := .F.
          aRetorno[ 'MsgErro' ]  := 'Erro ao criar a chave do CSP, talvez o certificado nao esteja instalado corretamente.'
          RETURN aRetorno
       END
       IF ( dsigKey = NIL )
          aRetorno[ 'OK' ]       := .F.
          aRetorno[ 'MsgErro' ]  := 'Erro ao criar a chave do CSP.'
          RETURN aRetorno
       ENDIF

       TRY
          signedKey := xmldsig:sign( dsigKey, 2 )
       CATCH
          aRetorno[ 'OK' ]       := .F.
          aRetorno[ 'MsgErro' ]  := 'Erro ao criar a chave do CSP, talvez o certificado nao esteja instalado corretamente.'
          RETURN aRetorno
       END

       IF ( signedKey <> NIL )
          XMLAssinado := oDOMDoc:xml
          XMLAssinado := StrTran( XMLAssinado, CHR(10), '' )
          XMLAssinado := StrTran( XMLAssinado, CHR(13), '' )
          PosIni      := At( '<SignatureValue>', XMLAssinado ) + Len( '<SignatureValue>' )
          XMLAssinado := Substr( XMLAssinado, 1, PosIni - 1 ) + StrTran( Substr( XMLAssinado, PosIni,len( XMLAssinado ) ), ' ', '' )
          PosIni      := At( '<X509Certificate>', XMLAssinado ) - 1
          nP          := At( '<X509Certificate>', XMLAssinado )
          nResult     := 0
          DO WHILE nP != 0
             nResult := nP
             nP = At( '<X509Certificate>', XMLAssinado, nP + 1 )
          ENDDO
          PosFim := nResult
          // hb_MemoWrit( '35canc5.xml', XMLAssinado )

          XMLAssinado := Substr( XMLAssinado, 1, PosIni ) + Substr( XMLAssinado, PosFim, Len( XMLAssinado ) )
          // hb_MemoWrit( '35canc6.xml', XMLAssinado )
       ELSE
          aRetorno[ 'OK' ]       := .F.
          aRetorno[ 'MsgErro' ]  := 'Assinatura Falhou.'
          RETURN aRetorno
       ENDIF

       IF xmlHeaderAntes <> ''
          I := At( XMLAssinado, '?>' )
          IF I > 0
             xmlHeaderDepois := Substr( XMLAssinado, 1, I + 1 )
             IF xmlHeaderAntes <> xmlHeaderDepois
                //  ? "entrou stuff"
                // XMLAssinado := StuffString( XMLAssinado, 1, length( xmlHeaderDepois ), xmlHeaderAntes )
             ENDIF
          ELSE
             XMLAssinado := xmlHeaderAntes + XMLAssinado
          ENDIF
       ENDIF
   ENDIF

   TRY
      IF ::lMemFile = .T.
         aRetorno[ 'XMLAssinado' ] := XMLAssinado
      ELSE
         aRetorno[ 'XMLAssinado' ] := XMLAssinado
         hb_MemoWrit( ::cXmlFile, XmlAssinado )
      ENDIF
   CATCH oError
     cMsgErro := "Falha ao gravar XML assinado " + HB_EOL() + ;
             	 "Error: "     + Transform( oError:GenCode, NIL )   + ";" + HB_EOL() + ;
              	 "SubC: "      + Transform( oError:SubCode, NIL )   + ";" + HB_EOL() + ;
             	 "OSCode: "    + Transform( oError:OsCode,  NIL )   + ";" + HB_EOL() + ;
             	 "SubSystem: " + Transform( oError:SubSystem, NIL ) + ";" + HB_EOL() + ;
            	 "Mensagem: "  + oError:Description
      aRetorno[ 'OK' ]       := .F.
      aRetorno[ 'MsgErro' ]  := cMSgErro
      RETURN aRetorno
   END

   oDOMDoc          := NIL // Harbour 3.2 nao precisa
   aRetorno[ 'OK' ] := .T.
   RETURN aRetorno
