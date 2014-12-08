*****************************************************************
* hbnfeAssina - ASSINATURA DIGITAL                   *
*****************************************************************

#define _CAPICOM_STORE_OPEN_READ_ONLY                 0           // Somente Smart Card em Modo de Leitura

#define _CAPICOM_MEMORY_STORE                         0
#define _CAPICOM_LOCAL_MACHINE_STORE                  1
#define _CAPICOM_CURRENT_USER_STORE                   2
#define _CAPICOM_ACTIVE_DIRECTORY_USER_STORE          3
#define _CAPICOM_SMART_CARD_USER_STORE                4

#define _CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED           2
#define _CAPICOM_CERTIFICATE_FIND_SHA1_HASH           0           // Retorna os Dados Criptografados com Hash SH1
#define _CAPICOM_CERTIFICATE_FIND_EXTENDED_PROPERTY   6
#define _CAPICOM_CERTIFICATE_FIND_TIME_VALID          9           // Retorna Certificados Válidos
#define _CAPICOM_CERTIFICATE_FIND_KEY_USAGE           12          // Retorna Certificados que contém dados.
#define _CAPICOM_DIGITAL_SIGNATURE_KEY_USAGE          0x00000080  // Permitir o uso da Chave Privada para assinatura Digital
#define _CAPICOM_AUTHENTICATED_ATTRIBUTE_SIGNING_TIME 0           // Este atributo contém o tempo em que a assinatura foi criada.
#define _CAPICOM_INFO_SUBJECT_SIMPLE_NAME             0           // Retorna o nome de exibição do certificado.
#define _CAPICOM_ENCODE_BASE64                        0           // Os dados são guardados como uma string base64-codificado.
#define _CAPICOM_E_CANCELLED                          -2138568446 // A operação foi cancelada pelo usuário.
#define _CERT_KEY_SPEC_PROP_ID                        6
#define _CAPICOM_CERT_INFO_ISSUER_EMAIL_NAME          0
#define _SIG_KEYINFO                                  2

#define XMLNFE          1
#define XMLCTE          2
#define XMLCANCELAMENTO 3
#define XMLINUTILIZACAO 4
#define XMLDEPEC        5
#define XMLEVENTO       6

#include "common.ch"
#include "hbclass.ch"

FUNCTION AssinaXml( cTxtXml, cCertCN )
   LOCAL oDOMDoc, nPosIni, nPosFim, xmlHeaderAntes, xmldsig, dsigns, oCert, oStoreMem, oError, xmlHeaderDepois
   LOCAL XMLAssinado, ParseError, oSchema, SIGNEDKEY, DSIGKEY, SCONTAINER, SPROVIDER, ETYPE, cURI, cRetorno, nP, nResult
   LOCAL aDelimitadores, nCont, cXmlTagInicial, cXmlTagFinal

   aDelimitadores := { ;
      { "<enviMDFe", "</MDFe></enviMDFe>" }, ;
      { "<eventoMDFe", "</eventoMDFe>" }, ;
      { "<infMDFe", "</MDFe>" }, ;
      { "<infCte", "</CTe>" }, ;
      { "<infNFe", "</NFe>" }, ;
      { "<infDPEC", "</envDPEC>" }, ;
      { "<infInut", "<inutNFe>" }, ;
      { "<infCanc", "</cancNFe>" }, ;
      { "<infInut",  "</inutNFe>" }, ;
      { "<infEvento", "</evento>" } }

   // Define Tipo de Documento

   IF AT( [<Signature], cTxtXml) <= 0
      cXmlTagInicial := ""
      cXmlTagFinal := ""
      FOR nCont = 1 TO Len( aDelimitadores )
         IF aDelimitadores[ nCont, 1 ] $ cTxtXml .AND. aDelimitadores[ nCont, 2 ] $ cTxtXml
            cXmlTagInicial := aDelimitadores[ nCont, 1 ]
            cXmlTagFinal := aDelimitadores[ nCont, 2 ]
            EXIT
         ENDIF
      NEXT
      IF Empty( cXmlTagInicial ) .OR. Empty( cXmlTagFinal )
         cRetorno := "Nao identificado documento"
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
      IF cXmlTagFinal $ cTxtXml
         cTxtXml := Substr( cTxtXml, 1, At( cXmlTagFinal, cTxtXml ) - 1 ) + SignatureNode( cURI ) + cXmlTagFinal
      ENDIF
   ENDIF

//   HB_MemoWrit( "NFE\Ultimo-1.XML", cTxtXml )
   // Lendo Header antes de assinar //
   xmlHeaderAntes := ''
   nPosIni := AT( [?>], cTxtXml )
   IF nPosIni > 0
      xmlHeaderAntes := Substr( cTxtXml, 1, nPosIni + 1 )
   ENDIF

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
      RETURN "ERRO: Bloco Assinatura não encontrado"
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
      cRetorno += "Error: "  + Transform( oError:GenCode, NIL ) + ";" + HB_EOL()
      cRetorno += "SubC: "   + Transform( oError:SubCode, NIL ) + ";" + HB_EOL()
      cRetorno += "OSCode: "  + Transform( oError:OsCode,  NIL ) + ";" + HB_EOL()
      cRetorno += "SubSystem: " + Transform( oError:SubSystem, NIL ) + ";" +HB_EOL()
      cRetorno += "Mensagem: " + oError:Description
      RETURN cRetorno
   END SEQUENCE

   BEGIN SEQUENCE WITH { | oError | Break( oError ) }
      oStoreMem:Add( oCert )
   RECOVER USING oError
      cRetorno := "Falha ao adicionar certificado na memoria " + HB_EOL()
      cRetorno += "Error: "  + Transform( oError:GenCode, NIL) + ";" + HB_EOL()
      cRetorno += "SubC: "   + Transform( oError:SubCode, NIL) + ";" + HB_EOL()
      cRetorno += "OSCode: "  + Transform( oError:OsCode,  NIL) + ";" + HB_EOL()
      cRetorno += "SubSystem: " + Transform( oError:SubSystem, NIL) + ";" + HB_EOL()
      cRetorno += "Mensagem: " + oError:Description
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
      nPosIni := At( [<SignatureValue>], XMLAssinado ) + Len( [<SignatureValue>] )
      XMLAssinado := Substr( XMLAssinado, 1, nPosIni - 1 ) + StrTran( Substr( XMLAssinado, nPosIni, Len( XMLAssinado ) ), " ", "" )
      nPosIni := At( [<X509Certificate>], XMLAssinado ) - 1
      nP = At( [<X509Certificate>], XMLAssinado )
      nResult := 0
      DO WHILE nP<>0
         nResult := nP
         nP = HB_AT( [<X509Certificate>], XMLAssinado, nP + 1 )
      ENDDO
      nPosFim := nResult
      XMLAssinado := Substr( XMLAssinado, 1, nPosIni ) + Substr( XMLAssinado, nPosFim, Len( XMLAssinado ) )
   ELSE
      cRetorno := "Assinatura Falhou."
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
   cTxtXml := XmlAssinado
   cRetorno := "OK"
   oDOMDoc := NIL
   ParseError := NIL
   oSchema := NIL
   RETURN cRetorno
*----------------------------------------------------------------


STATIC FUNCTION SignatureNode( cUri )
   Local cSignatureNode := ""
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
