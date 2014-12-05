*****************************************************************
* ZE_CAPICOM - ASSINATURA DIGITAL                   *
* 2012.01.01
*****************************************************************

*----------------------------------------------------------------
// Nota: requer CAPICOM e Microsoft XML 5.0


#include "common.ch"
#include "hbclass.ch"
#include "capicom.ch"

FUNCTION AssinaXml( cTxtXml, cCertCN )
   LOCAL nPosIni, nPosFim, xmlHeaderAntes, xmlHeaderDepois
   LOCAL XMLAssinado, cURI, cRetorno, lIsLibCurl := .F.
   LOCAL aDelimitadores, nCont
   LOCAL cXmlTagInicio := "", cXmlTagFinal := ""

   aDelimitadores := { ;
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

   // Define Tipo de Documento

   IF AT( [<Signature], cTxtXml) <= 0
      FOR nCont = 1 TO Len( aDelimitadores )
         IF aDelimitadores[ nCont, 1 ] $ cTxtXml .AND. aDelimitadores[ nCont, 2 ] $ cTxtXml
            cXmlTagInicio := aDelimitadores[ nCont, 1 ]
            cXmlTagFinal  := aDelimitadores[ nCont, 2 ]
            EXIT
         ENDIF
      NEXT

      IF Empty( cXmlTagInicio ) .OR. Empty( cXmlTagFinal )
         cRetorno := "Documento não identificado"
         RETURN cRetorno
      ENDIF
      // Pega URI
      nPosIni := At( [Id=], cTxtXml )
      IF nPosIni = 0
         cRetorno := "Não encontrado início do URI: Id="
         RETURN cRetorno
      ENDIF
      nPosIni := HB_AT( ["], cTxtXml, nPosIni + 2 )
      IF nPosIni = 0
         cRetorno := "Não encontrado início do URI: aspas inicial"
         RETURN cRetorno
      ENDIF
      nPosFim := HB_AT( ["], cTxtXml, nPosIni + 1 )
      IF nPosFim = 0
         cRetorno := "Não encontrado início do URI: aspas final"
         RETURN cRetorno
      ENDIF
      cURI := Substr( cTxtXml, nPosIni + 1, nPosFim - nPosIni - 1 )

      // Adiciona bloco de assinatura no local apropriado
      cTxtXml := Substr( cTxtXml, 1, At( cXmlTagFinal, cTxtXml ) - 1 ) + SignatureNode( cURI, lIsLibCurl ) + cXmlTagFinal
   ENDIF

//   HB_MemoWrit( "NFE\Ultimo-1.XML", cTxtXml )
   // Lendo Header antes de assinar //
   xmlHeaderAntes := ''
   nPosIni := AT( [?>], cTxtXml )
   IF nPosIni > 0
      xmlHeaderAntes := Substr( cTxtXml, 1, nPosIni + 1 )
   ENDIF

   XmlAssinado := cTxtXml
   cRetorno    := CapicomSignature( @XmlAssinado, cCertCn )
   IF cRetorno != "OK"
      RETURN cRetorno
   ENDIF
   IF xmlHeaderAntes <> ""
      nPosIni := At( XMLAssinado, [?>] )
      IF nPosIni > 0
         xmlHeaderDepois := Substr( XMLAssinado, 1, nPosIni + 1 )
         IF xmlHeaderAntes <> xmlHeaderDepois
            * ? "entrou stuff"
            * XMLAssinado := StuffString( XMLAssinado, 1, Length( xmlHeaderDepois ), xmlHeaderAntes )
         ENDIF
      ELSE
         XMLAssinado := xmlHeaderAntes + XMLAssinado
      ENDIF
   ENDIF
   cTxtXml  := XmlAssinado
   cRetorno := "OK"
   RETURN cRetorno
*----------------------------------------------------------------


STATIC FUNCTION CapicomSignature( cTxtXml, cCertCn )
   LOCAL oDOMDoc, nPosIni, nPosFim, xmldsig, dsigns, oCert, oStoreMem, oError
   LOCAL XMLAssinado, SIGNEDKEY, DSIGKEY, SCONTAINER, SPROVIDER, ETYPE, cRetorno, nP, nResult

   BEGIN SEQUENCE
      oDOMDoc := Win_OleCreateObject( "MSXML2.DOMDocument.5.0" )
   RECOVER
      cRetorno := "Não carregado MSXML2.DOMDocument.5.0"
      RETURN cRetorno
   END SEQUENCE

   oDOMDoc:async = .F.
   oDOMDoc:resolveExternals := .F.
   oDOMDoc:validateOnParse  = .T.
   oDOMDoc:preserveWhiteSpace = .T.

   BEGIN SEQUENCE
      xmldsig := Win_OleCreateObject( "MSXML2.MXDigitalSignature.5.0")
   RECOVER
      cRetorno := "Não carregado MSXML2.MXDigitalSignature.5.0"
      RETURN cRetorno
   END SEQUENCE

   oDOMDoc:LoadXML( cTxtXml )
   IF oDOMDoc:parseError:errorCode <> 0 // XML não carregado
      cRetorno := "Assinar: Não foi possivel carregar o documento pois ele não corresponde ao seu Schema" + HB_EOL()
      cRetorno += " Linha: " + Str(oDOMDoc:parseError:line)+HB_EOL()
      cRetorno += " Caractere na linha: " + Str(oDOMDoc:parseError:linepos)+HB_EOL()
      cRetorno += " Causa do erro: " + oDOMDoc:parseError:reason+HB_EOL()
      cRetorno += "code: "+STR(oDOMDoc:parseError:errorCode)
      RETURN cRetorno
   ENDIF

   DSIGNS = "xmlns:ds='http://www.w3.org/2000/09/xmldsig#'"
   oDOMDoc:setProperty('SelectionNamespaces', DSIGNS)

   IF .NOT. "</Signature>" $ cTxtXml
      RETURN "Bloco Assinatura não encontrado"
   ENDIF
   BEGIN SEQUENCE
      xmldsig:signature := oDOMDoc:selectSingleNode(".//ds:Signature")
   RECOVER
      cRetorno := "Template de assinatura não encontrado"
      RETURN cRetorno
   END SEQUENCE

   oCert:= pegaObjetoCertificado( cCertCn )
   IF oCert == NIL
      cRetorno := "Certificado não encontrado"
      RETURN cRetorno
   ENDIF

   oStoreMem := Win_OleCreateObject( "CAPICOM.Store" )
   BEGIN SEQUENCE WITH { | oError | Break( oError ) }
      oStoreMem:open( _CAPICOM_MEMORY_STORE, 'Memoria', _CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED )
   RECOVER USING oError
      cRetorno := "Falha ao criar espaço certificado na memoria " + HB_EOL()
      cRetorno += "Error: "     + Transform( oError:GenCode, NIL ) + ";" + HB_EOL()
      cRetorno += "SubC: "      + Transform( oError:SubCode, NIL ) + ";" + HB_EOL()
      cRetorno += "OSCode: "    + Transform( oError:OsCode,  NIL ) + ";" + HB_EOL()
      cRetorno += "SubSystem: " + Transform( oError:SubSystem, NIL ) + ";" +HB_EOL()
      cRetorno += "Mensagem: "  + oError:Description
      RETURN cRetorno
   END SEQUENCE

   BEGIN SEQUENCE WITH { | oError | Break( oError ) }
      oStoreMem:Add( oCert )
   RECOVER USING oError
      cRetorno := "Falha ao adicionar certificado na memoria " + HB_EOL()
      cRetorno += "Error: "     + Transform( oError:GenCode, NIL) + ";" + HB_EOL()
      cRetorno += "SubC: "      + Transform( oError:SubCode, NIL) + ";" + HB_EOL()
      cRetorno += "OSCode: "    + Transform( oError:OsCode,  NIL) + ";" + HB_EOL()
      cRetorno += "SubSystem: " + Transform( oError:SubSystem, NIL) + ";" + HB_EOL()
      cRetorno += "Mensagem: "  + oError:Description
      RETURN cRetorno
   END SEQUENCE

   xmldsig:store := oStoreMem

   //---> Dados necessários para gerar a assinatura
   eType := oCert:PrivateKey:ProviderType
   sProvider := oCert:PrivateKey:ProviderName
   sContainer := oCert:PrivateKey:ContainerName
   dsigKey := xmldsig:CreateKeyFromCSP(eType, sProvider, sContainer, 0)
   IF ( dsigKey = NIL )
      cRetorno := "Erro ao criar a chave do CSP."
      RETURN cRetorno
   ENDIF

   SignedKey := XmlDSig:Sign( DSigKey, 2 )

   IF ( signedKey <> NIL )
      XMLAssinado := oDOMDoc:xml
      XMLAssinado := StrTran( XMLAssinado, Chr(10), "" )
      XMLAssinado := StrTran( XMLAssinado, Chr(13), "" )
      nPosIni     := At( [<SignatureValue>], XMLAssinado ) + Len( [<SignatureValue>] )
      XMLAssinado := Substr( XMLAssinado, 1, nPosIni - 1 ) + StrTran( Substr( XMLAssinado, nPosIni, Len( XMLAssinado ) ), " ", "" )
      nPosIni     := At( [<X509Certificate>], XMLAssinado ) - 1
      nP      := At( [<X509Certificate>], XMLAssinado )
      nResult := 0
      DO WHILE nP<>0
         nResult := nP
         nP := hb_At( [<X509Certificate>], XMLAssinado, nP + 1 )
      ENDDO
      nPosFim     := nResult
      cTxtXml     := Substr( XMLAssinado, 1, nPosIni ) + Substr( XMLAssinado, nPosFim )
   ELSE
      cRetorno := "Assinatura Falhou."
      RETURN cRetorno
   ENDIF
   RETURN "OK"
*----------------------------------------------------------------


STATIC FUNCTION SignatureNode( cUri, lIsLibCurl )
   LOCAL cSignatureNode := ""

   lIsLibCurl := iif( lIsLibCurl == NIL, .F., lIsLibCurl )

   cSignatureNode += [<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">]
   cSignatureNode +=    [<SignedInfo>]
   cSignatureNode +=       [<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>]
   cSignatureNode +=       [<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />]
   cSignatureNode +=       [<Reference URI="#] + cURI + [">]
   cSignatureNode +=       [<Transforms>]
   cSignatureNode +=          [<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />]
   cSignatureNode +=          [<Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />]
   cSignatureNode +=       [</Transforms>]
   cSignatureNode +=       [<DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />]
   cSignatureNode +=       [<DigestValue>]
   cSignatureNode +=       [</DigestValue>]
   cSignatureNode +=       [</Reference>]
   cSignatureNode +=    [</SignedInfo>]
   cSignatureNode +=    [<SignatureValue>]
   cSignatureNode +=    [</SignatureValue>]
   cSignatureNode +=    [<KeyInfo>]
   IF lIsLibCurl
      cSignatureNode += [<X509Data>]
      cSignatureNode += [</X509Data>]
   ENDIF
   cSignatureNode +=    [</KeyInfo>]
   cSignatureNode += [</Signature>]
   RETURN cSignatureNode
*----------------------------------------------------------------


FUNCTION PegaObjetoCertificado( cCertCn )
   LOCAL oStore, oCertificados, oResult := NIL, nCont
   oStore := Win_OleCREATEObject( "CAPICOM.Store" )
   oStore:open( _CAPICOM_CURRENT_USER_STORE, "My", _CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED )
   oCertificados := oStore:Certificates()
   FOR nCont = 1 TO oCertificados:Count()
      IF cCertCN $ oCertificados:Item( nCont ):SubjectName
         oResult := oCertificados:Item( nCont )
         EXIT
      ENDIF
   NEXT
   oCertificados := NIL
   oStore := NIL
   RETURN oResult
*----------------------------------------------------------------

/*
FUNCTION PegaCNCertificado()
   LOCAL cSerialCert, oStore, oCertificados, oResult := NIL, nI, cSubjectName := "", cCN

   cSerialCert := ::cSerialCert
   oStore := win_OleCreateObject( "CAPICOM.Store" )
   IF oStore = NIL
      RETURN ""
   ENDIF
   oStore:open( _CAPICOM_CURRENT_USER_STORE, "My", _CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED )
   oCertificados := oStore:Certificates()
   FOR nI=1 TO oCertificados:Count()
      IF oCertificados:Item( nI ):SerialNumber = cSerialCert
         cSubjectName := oCertificados:Item( nI ):SubjectName
      ENDIF
   NEXT
   cCN := ""
   FOR nI = AT( "CN=", cSubjectName ) + 3 TO Len( cSubjectName )
      IF Substr( cSubjectName, nI, 1 ) == ","
         EXIT
      ENDIF
      cCN += Substr( cSubjectName, nI, 1 )
   NEXT
   RETURN cCN
*----------------------------------------------------------------


FUNCTION PegaPropriedadesCertificado()
   LOCAL oStore, oCertificados, aRetorno := hash(), nI, cSerialCert

   cSerialCert := ::cSerialCert
   oStore := win_OleCreateObject( "CAPICOM.Store" )
   oStore:open( _CAPICOM_CURRENT_USER_STORE, "My", _CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED )
   oCertificados := oStore:Certificates()
   aRetorno[ 'OK' ] := .F.
   FOR nI = 1 TO oCertificados:Count()
      IF oCertificados:Item( nI ):SerialNumber = cSerialCert
         aRetorno[ 'OK'] := .T.
         aRetorno[ 'SerialNumber' ] := oCertificados:Item( nI ):SerialNumber
         aRetorno[ 'ValidToDate' ] := oCertificados:Item( nI ):ValidToDate
         aRetorno[ 'HasPRIVATEKey' ] := oCertificados:Item( nI ):HasPRIVATEKey
         aRetorno[ 'SubjectName' ] := oCertificados:Item( nI ):SubjectName
         aRetorno[ 'IssuerName' ] := oCertificados:Item( nI ):IssuerName
         aRetorno[ 'Thumbprint' ] := oCertificados:Item( nI ):Thumbprint
         aRetorno[ 'getInfo' ] := oCertificados:Item( nI ):getInfo(0)
      ENDIF
   NEXT
   RETURN aRetorno
*----------------------------------------------------------------
*/

