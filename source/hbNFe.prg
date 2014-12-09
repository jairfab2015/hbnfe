****************************************************************************************************
* Funcoes e Classes Relativas a NFE                                                                *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************
*xsd.exe cancNFe_v1.07.xsd xmldsig-core-schema_v1.01.xsd /l:vb /c /n:cancNFe /edb /o:"c:\tmp"


#include "hbclass.ch"
#include "hbnfe.ch"

CLASS hbNFe
   // Parametros Principais hbNFe
   DATA oSefaz
   DATA cPastaSchemas
   DATA cPastaLogs
   DATA nSOAP        INIT 1
   DATA cSerialCert
   DATA cCertPFX
   DATA cCertFilePub
   DATA cCertFileKey
   DATA cCertPass
   DATA SubjectName

   DATA cUFWS
   DATA tpAmb
   DATA versaoDados
   DATA versaoDadosCCe
   DATA tpEmis
   DATA cDesenvolvedor

   DATA empresa_UF
   DATA empresa_cMun
   DATA empresa_tpImp
   DATA empresaUF
   DATA versaoSistema
   DATA cEmailEmitente INIT ""
   DATA cSiteEmitente INIT ""

   DATA cEmail_Subject
   DATA cEmail_MsgTexto
   DATA cEmail_MsgHTML
   DATA cEmail_ServerIP
   DATA cEmail_From
   DATA cEmail_User
   DATA cEmail_Pass
   DATA nEmail_PortSMTP
   DATA lEmail_Conf
   DATA lEmail_SSL
   DATA lEmail_Aut

   DATA pastaNFe
   DATA pastaCancelamento
   DATA pastaPDF
   DATA pastaInutilizacao
   DATA pastaDPEC
   DATA pastaEnvRes

   DATA nLogoStyle    // adcionado - Mauricio Cruz - 28/09/2011
   DATA ImprimirHora  // adcionado - Mauricio Cruz - 05/10/2011

   METHOD Init()
   // Metodos Nfe
   METHOD getURLWS(nTipoServico)
   METHOD xUFTocUF(xUF)
   METHOD cUFToxUF(cUF)

   // Metodos Certificados
   METHOD escolheCertificado(lTentaRegistrar)
   METHOD pegaObjetoCertificado()
   METHOD pegaCNCertificado()
   METHOD pegaPropriedadesCertificado()
   METHOD UAC(nValue)
   METHOD erroCurl(nError)
ENDCLASS


METHOD Init() CLASS hbNFe
   ::oSefaz := SefazClass():New()
   RETURN NIL


METHOD escolheCertificado(lTentaRegistrar) CLASS hbNFe
******************************************************************************
*Retorna o numero de serie do certificado                                    *
*Baseado na função PEGA_CERTIFICADO do Leonardo Machado - 03/05/2010 sygecom *
******************************************************************************
LOCAL oCertSelecao, oCertificados, oStore, cMsgErro := "", aRetorno := hash()
   IF lTentaRegistrar = Nil
      lTentaRegistrar := .F.
   ENDIF
   IF ::nSOAP = HBNFE_CURL
      aRetorno['OK']       := .T.
      RETURN(aRetorno)
   ENDIF

   TRY

      oStore := win_oleCreateObject( "CAPICOM.Store" )

   CATCH
      IF lTentaRegistrar
         //IF SN('Esta faltando arquivos para funcionamento da NF-e, deseja baixar agora ?')
         //   MYRUN2(CAMINHO_EXE()+'\instala_nfe.bat')
         //ENDIF
  	   ENDIF
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := IF(EMPTY(cMsgErro),"Registrado CAPICOM tente novamente",cMsgErro)
      RETURN(aRetorno)
   END

	TRY
	  oStore:open(_CAPICOM_CURRENT_USER_STORE,'My',_CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED)
	  oCertificados := oStore:Certificates() // Lista de Certificados
	  oCertSelecao  := oCertificados:Select("Selecione o certificado para uso da Nfe","Selecione o certificado",.F.)
	  IF oCertSelecao:Count() > 0
        aRetorno['OK']            := .T.
        aRetorno['Serial']        := oCertSelecao:Item(1):SerialNumber
        aRetorno['IssuerName']    := oCertSelecao:Item(1):IssuerName     // add 27/09/2011 -> Mauricio Cruz
        aRetorno['SubjectName']   := oCertSelecao:Item(1):SubjectName    // add 27/09/2011 -> Mauricio Cruz
        aRetorno['Thumbprint']    := oCertSelecao:Item(1):Thumbprint     // add 27/09/2011 -> Mauricio Cruz
        aRetorno['ValidFromDate'] := oCertSelecao:Item(1):ValidFromDate  // add 27/09/2011 -> Mauricio Cruz
        aRetorno['ValidToDate']   := oCertSelecao:Item(1):ValidToDate    // add 26/09/2011 -> Mauricio Cruz
        aRetorno['Version']       := oCertSelecao:Item(1):Version        // add 27/09/2011 -> Mauricio Cruz
     ELSE
        aRetorno['OK']      := .F.
        aRetorno['MsgErro'] := 'Certificado não localizado'
	  ENDIF
	CATCH
      aRetorno['OK']       := .F.
      aRetorno['MsgErro']  := "Certificado não localizado"
	   Return(aRetorno)
	END
	// Propriedades de Certificados

   oCertSelecao := Nil
   oCertificados := Nil
   oStore := Nil
Return(aRetorno)

METHOD UAC(nValue) CLASS hbNFe
***********************************************************************************************************
* Desabilita o UAC Função Baseda Forum usuario rochinha, e modificado para harbour era baseado em fivewin *
***********************************************************************************************************
   // EnableLUA
   // 0-Desativar
   // 1-Ativar
   #ifdef __XHARBOUR__
   #else
      win_regWrite( "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\EnableLUA", nValue )
   #endif
RETURN 0

METHOD pegaObjetoCertificado() CLASS hbNFe
LOCAL oStore, oCertificados, oResult := Nil, nI
Local cSerialCert    := ::cSerialCert
Local SubjectName    := ::SubjectName

  IF ::nSOAP = HBNFE_CURL
     Return Nil
  ENDIF

  SubjectName := IF(!EMPTY( SubjectName ),Upper(Alltrim( SubjectName )), SubjectName )
  TRY

     oStore := win_oleCreateObject( "CAPICOM.Store" )

  CATCH

  END
  IF oStore=nIL
     Return oResult
  ENDIF
  TRY
     oStore:open(_CAPICOM_CURRENT_USER_STORE,'My',_CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED)
  CATCH

  END
  IF oStore=nIL
     Return oResult
  ENDIF

  oCertificados:=oStore:Certificates()
  FOR nI=1 TO oCertificados:Count()
     IF !EMPTY( cSerialCert )
        IF oCertificados:Item(nI):SerialNumber = cSerialCert
           oResult := oCertificados:Item(nI)
           EXIT
        ENDIF
     ELSEIF !EMPTY( SubjectName )
        IF Upper( Alltrim(oCertificados:Item(nI):SubjectName) ) == SubjectName
           oResult := oCertificados:Item(nI)
           EXIT
        ENDIF
     ENDIF
  NEXT
  oCertificados := Nil
  oStore := Nil
RETURN(oResult)

METHOD pegaCNCertificado() CLASS hbNFe
LOCAL cSerialCert, oStore, oCertificados, oResult := Nil, nI, cSubjectName := "", cCN
  cSerialCert := ::cSerialCert
  TRY

     oStore := win_oleCreateObject( "CAPICOM.Store" )

  CATCH
  END
  IF oStore = Nil
     RETURN("")
  ENDIF
  oStore:open(_CAPICOM_CURRENT_USER_STORE,'My',_CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED)
  oCertificados:=oStore:Certificates()
  FOR nI=1 TO oCertificados:Count()
     IF oCertificados:Item(nI):SerialNumber = cSerialCert
        cSubjectName := oCertificados:Item(nI):SubjectName
     ENDIF
  NEXT
  cCN := ""
  FOR nI=AT("CN=",cSubjectName)+3 TO LEN(cSubjectName)
     IF SUBS(cSubjectName,nI,1) == ","
        EXIT
     ENDIF
     cCN += SUBS(cSubjectName,nI,1)
  NEXT
  oCertificados := Nil
  oStore := Nil
RETURN(cCN)

METHOD pegaPropriedadesCertificado() CLASS hbNFe
LOCAL oStore, oCertificados, aRetorno := hash(), nI, cSerialCert
  cSerialCert := ::cSerialCert

  oStore := win_oleCreateObject( "CAPICOM.Store" )

  oStore:open(_CAPICOM_CURRENT_USER_STORE,'My',_CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED)
  oCertificados:=oStore:Certificates()
  aRetorno['OK'] := .F.
  FOR nI=1 TO oCertificados:Count()
     IF oCertificados:Item(nI):SerialNumber = cSerialCert
        aRetorno['OK'] := .T.
        aRetorno['SerialNumber'] := oCertificados:Item(nI):SerialNumber
        aRetorno['ValidToDate'] := oCertificados:Item(nI):ValidToDate
        aRetorno['HasPrivateKey'] := oCertificados:Item(nI):HasPrivateKey
        aRetorno['SubjectName'] := oCertificados:Item(nI):SubjectName
        aRetorno['IssuerName'] := oCertificados:Item(nI):IssuerName
        aRetorno['Thumbprint'] := oCertificados:Item(nI):Thumbprint
        aRetorno['getInfo'] := oCertificados:Item(nI):getInfo(0)
     ENDIF
  NEXT
RETURN(aRetorno)

METHOD getURLWS(nTipoServico) CLASS hbNFe
LOCAL cUrlWS, aUrlWS := {}

IF ::tpEmis == '3' .OR. ::tpEmis == '5' // SCAN  // NACIONAL
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://www.scan.fazenda.gov.br/NFeStatusServico2/NFeStatusServico2.asmx'  , 'https://hom.nfe.fazenda.gov.br/SCAN/NfeStatusServico2/NfeStatusServico2.asmx') } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://www.scan.fazenda.gov.br/NfeConsulta2/NfeConsulta2.asmx'            , 'https://hom.nfe.fazenda.gov.br/SCAN/NfeConsulta2/NfeConsulta2.asmx') } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://www.scan.fazenda.gov.br/NfeRecepcao2/NfeRecepcao2.asmx'            , 'https://hom.nfe.fazenda.gov.br/SCAN/NfeRecepcao2/NfeRecepcao2.asmx') } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://www.scan.fazenda.gov.br/NfeRetRecepcao2/NfeRetRecepcao2.asmx'      , 'https://hom.nfe.fazenda.gov.br/SCAN/NfeRetRecepcao2/NfeRetRecepcao2.asmx') } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://www.scan.fazenda.gov.br/NfeCancelamento2/NfeCancelamento2.asmx'    , 'https://hom.nfe.fazenda.gov.br/SCAN/NfeCancelamento2/NfeCancelamento2.asmx') } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://www.scan.fazenda.gov.br/NfeInutilizacao2/NfeInutilizacao2.asmx'    , 'https://hom.nfe.fazenda.gov.br/SCAN/NfeInutilizacao2/NfeInutilizacao2.asmx') } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'       , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx ') } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://www.scan.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'        , 'https://hom.nfe.fazenda.gov.br/SCAM/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx'  , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'         , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::tpEmis == '6'   // SVC - AN
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://www.svc.fazenda.gov.br/NfeStatusServico2/NfeStatusServico2.asmx'  , 'https://hom.svc.fazenda.gov.br/NfeStatusServico2/NfeStatusServico2.asmx') } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://www.svc.fazenda.gov.br/NfeConsulta2/NfeConsulta2.asmx'            , 'https://hom.svc.fazenda.gov.br/NfeConsulta2/NfeConsulta2.asmx') } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://www.svc.fazenda.gov.br/NfeRecepcao2/NfeRecepcao2.asmx'            , 'https://hom.svc.fazenda.gov.br/NfeRecepcao2/NfeRecepcao2.asmx') } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://www.svc.fazenda.gov.br/NfeRetRecepcao2/NfeRetRecepcao2.asmx'      , 'https://hom.svc.fazenda.gov.br/NfeRetRecepcao2/NfeRetRecepcao2.asmx') } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://www.svc.fazenda.gov.br/NfeInutilizacao2/NfeInutilizacao2.asmx'    , 'https://hom.svc.fazenda.gov.br/NfeInutilizacao2/NfeInutilizacao2.asmx') } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://www.svc.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'        , 'https://hom.svc.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::tpEmis == '7'   // SVC - RS
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx'  , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx') } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx'            , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx') } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/Nferecepcao/NFeRecepcao2.asmx'            , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/Nferecepcao/NFeRecepcao2.asmx') } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/NfeRetRecepcao/NfeRetRecepcao2.asmx'      , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/NfeRetRecepcao/NfeRetRecepcao2.asmx') } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.sefaz.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx'              , 'https://homologacao.nfe.sefaz.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx' ) } )
ELSEIF ::cUFWS $ "13" // AM
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.sefaz.am.gov.br/services2/services/NfeStatusServico2'         , 'https://homnfe.sefaz.am.gov.br/services2/services/NfeStatusServico2' ) } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.sefaz.am.gov.br/services2/services/NfeConsulta2'              , 'https://homnfe.sefaz.am.gov.br/services2/services/NfeConsulta2' ) } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.sefaz.am.gov.br/services2/services/NfeRecepcao2'              , 'https://homnfe.sefaz.am.gov.br/services2/services/NfeRecepcao2' ) } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.sefaz.am.gov.br/services2/services/NfeRetRecepcao2'           , 'https://homnfe.sefaz.am.gov.br/services2/services/NfeRetRecepcao2' ) } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.am.gov.br/services2/services/NfeCancelamento2'          , 'https://homnfe.sefaz.am.gov.br/services2/services/NfeCancelamento2' ) } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.am.gov.br/services2/services/NfeInutilizacao2'          , 'https://homnfe.sefaz.am.gov.br/services2/services/NfeInutilizacao2' ) } )
   aAdd( aUrlWS, { _CONSULTACADASTRO , IIF( ::tpAmb='1' , 'https://nfe.sefaz.am.gov.br/services2/services/cadconsultacadastro2'      , 'https://homnfe.sefaz.am.gov.br/services2/services/cadconsultacadastro2' ) } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.sefaz.am.gov.br/services2/services/RecepcaoEvento'            , 'https://homnfe.sefaz.am.gov.br/services2/services/RecepcaoEvento' ) } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'      , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'        , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::cUFWS $ "29" // BA
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ba.gov.br/webservices/nfenw/NfeStatusServico2.asmx'     , 'https://hnfe.sefaz.ba.gov.br/webservices/nfenw/NfeStatusServico2.asmx' ) } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.sefaz.ba.gov.br/webservices/nfenw/NfeConsulta2.asmx'          , 'https://hnfe.sefaz.ba.gov.br/webservices/nfenw/NfeConsulta2.asmx' ) } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ba.gov.br/webservices/nfenw/NfeRecepcao2.asmx'          , 'https://hnfe.sefaz.ba.gov.br/webservices/nfenw/NfeRecepcao2.asmx' ) } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ba.gov.br/webservices/nfenw/NfeRetRecepcao2.asmx'       , 'https://hnfe.sefaz.ba.gov.br/webservices/nfenw/NfeRetRecepcao2.asmx' ) } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ba.gov.br/webservices/nfenw/NfeCancelamento2.asmx'      , 'https://hnfe.sefaz.ba.gov.br/webservices/nfenw/NfeCancelamento2.asmx' ) } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ba.gov.br/webservices/nfenw/NfeInutilizacao2.asmx'      , 'https://hnfe.sefaz.ba.gov.br/webservices/nfenw/NfeInutilizacao2.asmx' ) } )
   aAdd( aUrlWS, { _CONSULTACADASTRO , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ba.gov.br/webservices/nfenw/CadConsultaCadastro2.asmx'  , 'https://hnfe.sefaz.ba.gov.br/webservices/nfenw/CadConsultaCadastro2.asmx' ) } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ba.gov.br/webservices/sre/RecepcaoEvento.asmx'          , 'https://hnfe.sefaz.ba.gov.br/webservices/sre/RecepcaoEvento.asmx' ) } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'      , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'        , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::cUFWS $ "23" // CE
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ce.gov.br/nfe2/services/NfeStatusServico2'              , 'https://nfeh.sefaz.ce.gov.br/nfe2/services/NfeStatusServico2' ) } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.sefaz.ce.gov.br/nfe2/services/NfeConsulta2'                   , 'https://nfeh.sefaz.ce.gov.br/nfe2/services/NfeConsulta2' ) } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ce.gov.br/nfe2/services/NfeRecepcao2'                   , 'https://nfeh.sefaz.ce.gov.br/nfe2/services/NfeRecepcao2' ) } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ce.gov.br/nfe2/services/NfeRetRecepcao2'                , 'https://nfeh.sefaz.ce.gov.br/nfe2/services/NfeRetRecepcao2' ) } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ce.gov.br/nfe2/services/NfeCancelamento2'               , 'https://nfeh.sefaz.ce.gov.br/nfe2/services/NfeCancelamento2' ) } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ce.gov.br/nfe2/services/NfeInutilizacao2'               , 'https://nfeh.sefaz.ce.gov.br/nfe2/services/NfeInutilizacao2' ) } )
   aAdd( aUrlWS, { _CONSULTACADASTRO , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ce.gov.br/nfe2/services/CadConsultaCadastro2'           , 'https://nfeh.sefaz.ce.gov.br/nfe2/services/CadConsultaCadastro2' ) } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.sefaz.ce.gov.br/nfe2/services/RecepcaoEvento'                 , 'https://nfeh.sefaz.ce.gov.br/nfe2/services/RecepcaoEvento' ) } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'      , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'        , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::cUFWS $ "50" // MS
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.fazenda.ms.gov.br/producao/services2/NfeStatusServico2'       , 'https://homologacao.nfe.ms.gov.br/homologacao/services2/NfeStatusServico2' ) } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.fazenda.ms.gov.br/producao/services2/NfeConsulta2'            , 'https://homologacao.nfe.ms.gov.br/homologacao/services2/NfeConsulta2' ) } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.fazenda.ms.gov.br/producao/services2/NfeRecepcao2'            , 'https://homologacao.nfe.ms.gov.br/homologacao/services2/NfeRecepcao2' ) } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.fazenda.ms.gov.br/producao/services2/NfeRetRecepcao2'         , 'https://homologacao.nfe.ms.gov.br/homologacao/services2/NfeRetRecepcao2' ) } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe.fazenda.ms.gov.br/producao/services2/NfeCancelamento2'        , 'https://homologacao.nfe.ms.gov.br/homologacao/services2/NfeCancelamento2' ) } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe.fazenda.ms.gov.br/producao/services2/NfeInutilizacao2'        , 'https://homologacao.nfe.ms.gov.br/homologacao/services2/NfeInutilizacao2' ) } )
   aAdd( aUrlWS, { _CONSULTACADASTRO , IIF( ::tpAmb='1' , 'https://nfe.fazenda.ms.gov.br/producao/services2/CadConsultaCadastro2'    , 'https://homologacao.nfe.ms.gov.br/homologacao/services2/CadConsultaCadastro2' ) } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.fazenda.ms.gov.br/producao/services2/RecepcaoEvento'          , 'https://homologacao.nfe.ms.gov.br/homologacao/services2/RecepcaoEvento' ) } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'      , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'        , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::cUFWS $ "51" // MT
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.sefaz.mt.gov.br/nfews/v2/services/NfeStatusServico2?wsdl'     , 'https://homologacao.sefaz.mt.gov.br/nfews/v2/services/NfeStatusServico2?wsdl' ) } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.sefaz.mt.gov.br/nfews/v2/services/NfeConsulta2?wsdl'          , 'https://homologacao.sefaz.mt.gov.br/nfews/v2/services/NfeConsulta2?wsdl' ) } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.sefaz.mt.gov.br/nfews/v2/services/NfeRecepcao2?wsdl'          , 'https://homologacao.sefaz.mt.gov.br/nfews/v2/services/NfeRecepcao2?wsdl' ) } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.sefaz.mt.gov.br/nfews/v2/services/NfeRetRecepcao2?wsdl'       , 'https://homologacao.sefaz.mt.gov.br/nfews/v2/services/NfeRetRecepcao2?wsdl' ) } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.mt.gov.br/nfews/v2/services/NfeCancelamento2?wsdl'      , 'https://homologacao.sefaz.mt.gov.br/nfews/v2/services/NfeCancelamento2?wsdl' ) } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.mt.gov.br/nfews/v2/services/NfeInutilizacao2?wsdl'      , 'https://homologacao.sefaz.mt.gov.br/nfews/v2/services/NfeInutilizacao2?wsdl' ) } )
   aAdd( aUrlWS, { _CONSULTACADASTRO , IIF( ::tpAmb='1' , 'https://nfe.sefaz.mt.gov.br/nfews/CadConsultaCadastro'                    , 'https://nfe.sefaz.mt.gov.br/nfews/CadConsultaCadastro' ) } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.sefaz.mt.gov.br/nfews/v2/services/RecepcaoEvento?wsdl'        , 'https://homologacao.sefaz.mt.gov.br/nfews/v2/services/RecepcaoEvento?wsdl' ) } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'      , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'        , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::cUFWS $ "52" // GO
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.sefaz.go.gov.br/nfe/services/v2/NfeStatusServico2?wsdl'       , 'https://homolog.sefaz.go.gov.br/nfe/services/v2/NfeStatusServico2?wsdl' ) } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.sefaz.go.gov.br/nfe/services/v2/NfeConsulta2?wsdl'            , 'https://homolog.sefaz.go.gov.br/nfe/services/v2/NfeConsulta2?wsdl' ) } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.sefaz.go.gov.br/nfe/services/v2/NfeRecepcao2?wsdl'            , 'https://homolog.sefaz.go.gov.br/nfe/services/v2/NfeRecepcao2?wsdl' ) } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.sefaz.go.gov.br/nfe/services/v2/NfeRetRecepcao2?wsdl'         , 'https://homolog.sefaz.go.gov.br/nfe/services/v2/NfeRetRecepcao2?wsdl' ) } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.go.gov.br/nfe/services/v2/NfeCancelamento2?wsdl'        , 'https://homolog.sefaz.go.gov.br/nfe/services/v2/NfeCancelamento2?wsdl' ) } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.go.gov.br/nfe/services/v2/NfeInutilizacao2?wsdl'        , 'https://homolog.sefaz.go.gov.br/nfe/services/v2/NfeInutilizacao2?wsdl' ) } )
   aAdd( aUrlWS, { _CONSULTACADASTRO , IIF( ::tpAmb='1' , 'https://nfe.sefaz.go.gov.br/nfe/services/v2/CadConsultaCadastro2?wsdl'    , 'https://homolog.sefaz.go.gov.br/nfe/services/v2/CadConsultaCadastro2?wsdl' ) } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.sefaz.go.gov.br/nfe/services/v2/NfeRecepcaoEvento?wsdl'       , 'https://homolog.sefaz.go.gov.br/nfe/services/v2/NfeRecepcaoEvento?wsdl') } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'      , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'        , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::cUFWS $ "26" // PE
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.sefaz.pe.gov.br/nfe-service/services/NfeStatusServico2'       , 'https://nfehomolog.sefaz.pe.gov.br/nfe-service/services/NfeStatusServico2' ) } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.sefaz.pe.gov.br/nfe-service/services/NfeConsulta2'            , 'https://nfehomolog.sefaz.pe.gov.br/nfe-service/services/NfeConsulta2' ) } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.sefaz.pe.gov.br/nfe-service/services/NfeRecepcao2'            , 'https://nfehomolog.sefaz.pe.gov.br/nfe-service/services/NfeRecepcao2' ) } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.sefaz.pe.gov.br/nfe-service/services/NfeRetRecepcao2'         , 'https://nfehomolog.sefaz.pe.gov.br/nfe-service/services/NfeRetRecepcao2' ) } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.pe.gov.br/nfe-service/services/NfeCancelamento2'        , 'https://nfehomolog.sefaz.pe.gov.br/nfe-service/services/NfeCancelamento2' ) } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.pe.gov.br/nfe-service/services/NfeInutilizacao2'        , 'https://nfehomolog.sefaz.pe.gov.br/nfe-service/services/NfeInutilizacao2' ) } )
   aAdd( aUrlWS, { _CONSULTACADASTRO , IIF( ::tpAmb='1' , 'https://nfe.sefaz.pe.gov.br/nfe-service/services/CadConsultaCadastro2'    , 'https://nfe.sefaz.pe.gov.br/nfe-service/services/CadConsultaCadastro2' ) } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.sefaz.pe.gov.br/nfe-service/services/RecepcaoEvento'          , 'https://nfehomolog.sefaz.pe.gov.br/nfe-service/services/RecepcaoEvento' ) } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'      , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'        , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::cUFWS == "35" // SP
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.fazenda.sp.gov.br/nfeweb/services/nfestatusservico2.asmx'     , 'https://homologacao.nfe.fazenda.sp.gov.br/nfeweb/services/NfeStatusServico2.asmx') } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.fazenda.sp.gov.br/nfeweb/services/nfeconsulta2.asmx'          , 'https://homologacao.nfe.fazenda.sp.gov.br/nfeweb/services/NfeConsulta2.asmx') } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.fazenda.sp.gov.br/nfeweb/services/nferecepcao2.asmx'          , 'https://homologacao.nfe.fazenda.sp.gov.br/nfeweb/services/NfeRecepcao2.asmx') } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.fazenda.sp.gov.br/nfeweb/services/nferetrecepcao2.asmx'       , 'https://homologacao.nfe.fazenda.sp.gov.br/nfeweb/services/NfeRetRecepcao2.asmx') } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe.fazenda.sp.gov.br/nfeweb/services/nfecancelamento2.asmx'      , 'https://homologacao.nfe.fazenda.sp.gov.br/nfeweb/services/NfeCancelamento2.asmx') } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe.fazenda.sp.gov.br/nfeweb/services/nfeinutilizacao2.asmx'      , 'https://homologacao.nfe.fazenda.sp.gov.br/nfeweb/services/NfeInutilizacao2.asmx') } )
   aAdd( aUrlWS, { _CONSULTACADASTRO , IIF( ::tpAmb='1' , 'https://nfe.fazenda.sp.gov.br/nfeweb/services/cadconsultacadastro2.asmx'  , 'https://homologacao.nfe.fazenda.sp.gov.br/nfeWEB/services/cadconsultacadastro2.asmx') } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.fazenda.sp.gov.br/eventosWEB/services/RecepcaoEvento.asmx'    , 'https://homologacao.nfe.fazenda.sp.gov.br/eventosWEB/services/RecepcaoEvento.asmx') } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'      , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'        , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::cUFWS $ "43" // RS
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.sefaz.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx'       , 'https://homologacao.nfe.sefaz.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx') } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.sefaz.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx'                 , 'https://homologacao.nfe.sefaz.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx') } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.sefaz.rs.gov.br/ws/Nferecepcao/NFeRecepcao2.asmx'                 , 'https://homologacao.nfe.sefaz.rs.gov.br/ws/Nferecepcao/NFeRecepcao2.asmx') } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.sefaz.rs.gov.br/ws/NfeRetRecepcao/NfeRetRecepcao2.asmx'           , 'https://homologacao.nfe.sefaz.rs.gov.br/ws/NfeRetRecepcao/NfeRetRecepcao2.asmx') } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.rs.gov.br/ws/NfeCancelamento/NfeCancelamento2.asmx'         , 'https://homologacao.nfe.sefaz.rs.gov.br/ws/NfeCancelamento/NfeCancelamento2.asmx') } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe.sefaz.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao2.asmx'         , 'https://homologacao.nfe.sefaz.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao2.asmx') } )
   aAdd( aUrlWS, { _CONSULTACADASTRO , IIF( ::tpAmb='1' , 'https://sef.sefaz.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx' , 'https://sef.sefaz.rs.gov.br/ws/cadconsultacadastro/cadconsultacadastro2.asmx') } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.sefaz.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx'            , 'https://homologacao.nfe.sefaz.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx') } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://nfe.sefaz.rs.gov.br/ws/nfeConsultaDest/nfeConsultaDest.asmx'          , 'https://homologacao.nfe.sefaz.rs.gov.br/ws/nfeConsultaDest/nfeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://nfe.sefaz.rs.gov.br/ws/nfeDownloadNF/nfeDownloadNF.asmx'              , 'https://homologacao.nfe.sefaz.rs.gov.br/ws/nfeDownloadNF/nfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'            , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx ' ) } )
ELSEIF ::cUFWS == "41" // PR
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe2.fazenda.pr.gov.br/nfe/NFeStatusServico2?wsdl'                , 'https://homologacao.nfe2.fazenda.pr.gov.br/nfe/NFeStatusServico2?wsdl') } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe2.fazenda.pr.gov.br/nfe/NFeConsulta2?wsdl'                     , 'https://homologacao.nfe2.fazenda.pr.gov.br/nfe/NFeConsulta2?wsdl') } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe2.fazenda.pr.gov.br/nfe/NFeRecepcao2?wsdl'                     , 'https://homologacao.nfe2.fazenda.pr.gov.br/nfe/NFeRecepcao2?wsdl') } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe2.fazenda.pr.gov.br/nfe/NFeRetRecepcao2?wsdl'                  , 'https://homologacao.nfe2.fazenda.pr.gov.br/nfe/NFeRetRecepcao2?wsdl') } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe2.fazenda.pr.gov.br/nfe/NFeCancelamento2?wsdl'                 , 'https://homologacao.nfe2.fazenda.pr.gov.br/nfe/NFeCancelamento2?wsdl') } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe2.fazenda.pr.gov.br/nfe/NFeInutilizacao2?wsdl'                 , 'https://homologacao.nfe2.fazenda.pr.gov.br/nfe/NFeInutilizacao2?wsdl') } )
   aAdd( aUrlWS, { _CONSULTACADASTRO , IIF( ::tpAmb='1' , 'https://nfe2.fazenda.pr.gov.br/nfe/CadConsultaCadastro2?wsdl'             , 'https://homologacao.nfe2.fazenda.pr.gov.br/nfe/CadConsultaCadastro2?wsdl') } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe2.fazenda.pr.gov.br/nfe-evento/NFeRecepcaoEvento?wsdl'         , 'https://homologacao.nfe2.fazenda.pr.gov.br/nfe-evento/NFeRecepcaoEvento?wsdl') } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'      , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'        , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::cUFWS == "31" // MG
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.fazenda.mg.gov.br/nfe2/services/NfeStatus2'                   , 'https://hnfe.fazenda.mg.gov.br/nfe2/services/NfeStatus2' ) } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.fazenda.mg.gov.br/nfe2/services/NfeConsulta2'                 , 'https://hnfe.fazenda.mg.gov.br/nfe2/services/NfeConsulta2' ) } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.fazenda.mg.gov.br/nfe2/services/NfeRecepcao2'                 , 'https://hnfe.fazenda.mg.gov.br/nfe2/services/NfeRecepcao2' ) } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.fazenda.mg.gov.br/nfe2/services/NfeRetRecepcao2'              , 'https://hnfe.fazenda.mg.gov.br/nfe2/services/NfeRetRecepcao2') } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe.fazenda.mg.gov.br/nfe2/services/NfeCancelamento2'             , 'https://hnfe.fazenda.mg.gov.br/nfe2/services/NfeCancelamento2') } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe.fazenda.mg.gov.br/nfe2/services/NfeInutilizacao2'             , 'https://hnfe.fazenda.mg.gov.br/nfe2/services/NfeInutilizacao2') } )
   aAdd( aUrlWS, { _CONSULTACADASTRO , IIF( ::tpAmb='1' , 'https://nfe.fazenda.mg.gov.br/nfe2/services/cadconsultacadastro2'         , 'https://hnfe.fazenda.mg.gov.br/nfe2/services/cadconsultacadastro2') } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.fazenda.mg.gov.br/nfe2/services/RecepcaoEvento'               , 'https://hnfe.fazenda.mg.gov.br/nfe2/services/RecepcaoEvento') } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'      , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'        , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::cUFWS $ "32" // ES
   IF DATE()<=CTOD('03/02/2014') // ATÉ ESSA DATA VAI USAR SVAN, DEPOIS MUDA PARA SVRS, DEPOIS QUE ALCANÇAR ESSA DATA PODEMOS DEIXAR TUDO NO IF LÁ DE BAIXO(SVRS)
      aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeStatusServico2/NfeStatusServico2.asmx' , 'https://hom.sefazvirtual.fazenda.gov.br/NfeStatusServico2/NfeStatusServico2.asmx') } )
      aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeConsulta2/NfeConsulta2.asmx'           , 'https://hom.sefazvirtual.fazenda.gov.br/NfeConsulta2/NfeConsulta2.asmx') } )
      aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeRecepcao2/NfeRecepcao2.asmx'           , 'https://hom.sefazvirtual.fazenda.gov.br/NfeRecepcao2/NfeRecepcao2.asmx') } )
      aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeRetRecepcao2/NfeRetRecepcao2.asmx'     , 'https://hom.sefazvirtual.fazenda.gov.br/NfeRetRecepcao2/NfeRetRecepcao2.asmx') } )
      aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeCancelamento2/NfeCancelamento2.asmx'   , 'https://hom.sefazvirtual.fazenda.gov.br/NfeCancelamento2/NfeCancelamento2.asmx') } )
      aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeInutilizacao2/NfeInutilizacao2.asmx'   , 'https://hom.sefazvirtual.fazenda.gov.br/NfeInutilizacao2/NfeInutilizacao2.asmx') } )
      aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'       , 'https://hom.sefazvirtual.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx') } )
      aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'              , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
      aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx'         , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
      aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'                , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
   ELSE
      aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx'    , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx') } )
      aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx'              , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx') } )
      aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/Nferecepcao/NFeRecepcao2.asmx'              , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/Nferecepcao/NFeRecepcao2.asmx') } )
      aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/NfeRetRecepcao/NfeRetRecepcao2.asmx'        , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/NfeRetRecepcao/NfeRetRecepcao2.asmx') } )
      aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/NfeCancelamento/NfeCancelamento2.asmx'      , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/NfeCancelamento/NfeCancelamento2.asmx') } )
      aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao2.asmx'      , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao2.asmx') } )
      aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx'         , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx') } )
      aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'              , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
      aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx'         , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
      aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'                , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
   ENDIF
ELSEIF ::cUFWS $ "21,15,22" // MA, PA, PI  // SVAN
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeStatusServico2/NfeStatusServico2.asmx' , 'https://hom.sefazvirtual.fazenda.gov.br/NfeStatusServico2/NfeStatusServico2.asmx') } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeConsulta2/NfeConsulta2.asmx'           , 'https://hom.sefazvirtual.fazenda.gov.br/NfeConsulta2/NfeConsulta2.asmx') } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeRecepcao2/NfeRecepcao2.asmx'           , 'https://hom.sefazvirtual.fazenda.gov.br/NfeRecepcao2/NfeRecepcao2.asmx') } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeRetRecepcao2/NfeRetRecepcao2.asmx'     , 'https://hom.sefazvirtual.fazenda.gov.br/NfeRetRecepcao2/NfeRetRecepcao2.asmx') } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeCancelamento2/NfeCancelamento2.asmx'   , 'https://hom.sefazvirtual.fazenda.gov.br/NfeCancelamento2/NfeCancelamento2.asmx') } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeInutilizacao2/NfeInutilizacao2.asmx'   , 'https://hom.sefazvirtual.fazenda.gov.br/NfeInutilizacao2/NfeInutilizacao2.asmx') } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'       , 'https://hom.sefazvirtual.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx') } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'              , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx'         , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'                , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ELSEIF ::cUFWS $ "12,27,13,16,24,53,50,25,33,11,14,42,28,17" // AC, AL, AM, AP, RN, DF, MS, PB, RJ, RO, RR, SC, SE, TO  // SVRS
   aAdd( aUrlWS, { _STATUSSERVICO    , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx'    , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/NfeStatusServico/NfeStatusServico2.asmx') } )
   aAdd( aUrlWS, { _CONSULTAPROTOCOLO, IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx'              , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/NfeConsulta/NfeConsulta2.asmx') } )
   aAdd( aUrlWS, { _RECEPCAO         , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/Nferecepcao/NFeRecepcao2.asmx'              , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/Nferecepcao/NFeRecepcao2.asmx') } )
   aAdd( aUrlWS, { _RETRECEPCAO      , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/NfeRetRecepcao/NfeRetRecepcao2.asmx'        , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/NfeRetRecepcao/NfeRetRecepcao2.asmx') } )
   aAdd( aUrlWS, { _CANCELAMENTO     , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/NfeCancelamento/NfeCancelamento2.asmx'      , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/NfeCancelamento/NfeCancelamento2.asmx') } )
   aAdd( aUrlWS, { _INUTILIZACAO     , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao2.asmx'      , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/nfeinutilizacao/nfeinutilizacao2.asmx') } )
   aAdd( aUrlWS, { _EVENTO           , IIF( ::tpAmb='1' , 'https://nfe.sefazvirtual.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx'         , 'https://homologacao.nfe.sefazvirtual.rs.gov.br/ws/recepcaoevento/recepcaoevento.asmx') } )
   aAdd( aUrlWS, { _CONSULTANFEDEST  , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx'              , 'https://hom.nfe.fazenda.gov.br/NFeConsultaDest/NFeConsultaDest.asmx') } )
   aAdd( aUrlWS, { _DOWNLOADNFE      , IIF( ::tpAmb='1' , 'https://www.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx'         , 'https://hom.sefazvirtual.fazenda.gov.br/NfeDownloadNF/NfeDownloadNF.asmx' ) } )
   aAdd( aUrlWS, { _RECPEVENTO       , IIF( ::tpAmb='1' , 'https://www.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx'                , 'https://hom.nfe.fazenda.gov.br/RecepcaoEvento/RecepcaoEvento.asmx' ) } )
ENDIF
IF ASCAN( aUrlWS, {|a| a[1]==nTipoServico} ) >0
   cUrlWS := aUrlWS[ ASCAN( aUrlWS, {|a| a[1]==nTipoServico} ), 2 ]
ENDIF
RETURN(cUrlWS)


METHOD cUFToxUF(cUF) CLASS hbNFe
LOCAL xUF
 IF   cUF = '11'; xUF :='RO'
  ELSEIF cUF = '12'; xUF :='AC'
  ELSEIF cUF = '13'; xUF :='AM'
  ELSEIF cUF = '14'; xUF :='RR'
  ELSEIF cUF = '15'; xUF :='PA'
  ELSEIF cUF = '16'; xUF :='AP'
  ELSEIF cUF = '17'; xUF :='TO'
  ELSEIF cUF = '21'; xUF :='MA'
  ELSEIF cUF = '22'; xUF :='PI'
  ELSEIF cUF = '23'; xUF :='CE'
  ELSEIF cUF = '24'; xUF :='RN'
  ELSEIF cUF = '25'; xUF :='PB'
  ELSEIF cUF = '26'; xUF :='PE'
  ELSEIF cUF = '27'; xUF :='AL'
  ELSEIF cUF = '28'; xUF :='SE'
  ELSEIF cUF = '29'; xUF :='BA'
  ELSEIF cUF = '31'; xUF :='MG'
  ELSEIF cUF = '32'; xUF :='ES'
  ELSEIF cUF = '33'; xUF :='RJ'
  ELSEIF cUF = '35'; xUF :='SP'
  ELSEIF cUF = '41'; xUF :='PR'
  ELSEIF cUF = '42'; xUF :='SC'
  ELSEIF cUF = '43'; xUF :='RS'
  ELSEIF cUF = '50'; xUF :='MS'
  ELSEIF cUF = '51'; xUF :='MT'
  ELSEIF cUF = '52'; xUF :='GO'
  ELSEIF cUF = '53'; xUF :='DF'
 ENDIF
RETURN(xUF)

METHOD xUFTocUF(xUF) CLASS hbNFe
LOCAL cUF
 IF   xUF ='RO'; cUF := '11'
  ELSEIF xUF ='AC'; cUF := '12'
  ELSEIF xUF ='AM'; cUF := '13'
  ELSEIF xUF ='RR'; cUF := '14'
  ELSEIF xUF ='PA'; cUF := '15'
  ELSEIF xUF ='AP'; cUF := '16'
  ELSEIF xUF ='TO'; cUF := '17'
  ELSEIF xUF ='MA'; cUF := '21'
  ELSEIF xUF ='PI'; cUF := '22'
  ELSEIF xUF ='CE'; cUF := '23'
  ELSEIF xUF ='RN'; cUF := '24'
  ELSEIF xUF ='PB'; cUF := '25'
  ELSEIF xUF ='PE'; cUF := '26'
  ELSEIF xUF ='AL'; cUF := '27'
  ELSEIF xUF ='SE'; cUF := '28'
  ELSEIF xUF ='BA'; cUF := '29'
  ELSEIF xUF ='MG'; cUF := '31'
  ELSEIF xUF ='ES'; cUF := '32'
  ELSEIF xUF ='RJ'; cUF := '33'
  ELSEIF xUF ='SP'; cUF := '35'
  ELSEIF xUF ='PR'; cUF := '41'
  ELSEIF xUF ='SC'; cUF := '42'
  ELSEIF xUF ='RS'; cUF := '43'
  ELSEIF xUF ='MS'; cUF := '50'
  ELSEIF xUF ='MT'; cUF := '51'
  ELSEIF xUF ='GO'; cUF := '52'
  ELSEIF xUF ='DF'; cUF := '53'
 ENDIF
RETURN(cUF)

METHOD erroCurl(nError) CLASS hbNFe
LOCAL cCode
  cCode := hash()
  //[Informational 1xx]
  cCode['100']="Continue"
  cCode['101']="Switching Protocols"
  //[Successful 2xx]
  cCode['200']="OK"
  cCode['201']="Created"
  cCode['202']="Accepted"
  cCode['203']="Non-Authoritative Information"
  cCode['204']="No Content"
  cCode['205']="Reset Content"
  cCode['206']="Partial Content"
  //[Redirection 3xx]
  cCode['300']="Multiple Choices"
  cCode['301']="Moved Permanently"
  cCode['302']="Found"
  cCode['303']="See Other"
  cCode['304']="Not Modified"
  cCode['305']="Use Proxy"
  cCode['306']="(Unused)"
  cCode['307']="Temporary Redirect"
  //[Client Error 4xx]
  cCode['400']="Bad Request"
  cCode['401']="Unauthorized"
  cCode['402']="Payment Required"
  cCode['403']="Forbidden"
  cCode['404']="Not Found"
  cCode['405']="Method Not Allowed"
  cCode['406']="Not Acceptable"
  cCode['407']="Proxy Authentication Required"
  cCode['408']="Request Timeout"
  cCode['409']="Conflict"
  cCode['410']="Gone"
  cCode['411']="Length Required"
  cCode['412']="Precondition Failed"
  cCode['413']="Request Entity Too Large"
  cCode['414']="Request-URI Too Long"
  cCode['415']="Unsupported Media Type"
  cCode['416']="Requested Range Not Satisfiable"
  cCode['417']="Expectation Failed"
  //[Server Error 5xx]
  cCode['500']="Internal Server Error"
  cCode['501']="Not Implemented"
  cCode['502']="Bad Gateway"
  cCode['503']="Service Unavailable"
  cCode['504']="Gateway Timeout"
  cCode['505']="HTTP Version Not Supported"
RETURN(cCode[ALLTRIM(STR(nError))])
****************************************************************
* Funcao em C para registrar DLL Baseda Forum usuario rochinha *
****************************************************************
#pragma BEGINDUMP
   #include <hbapi.h>
	#include <windows.h>
	typedef LONG ( * PDLLREGISTERSERVER ) ( void );
	HB_FUNC( REGISTERSERVER )
	{
	   HMODULE hDll = LoadLibrary( hb_parc( 1 ) );
	   LONG lReturn = 0;
	   if( hDll )
	   {
	      FARPROC pRegisterServer = GetProcAddress( hDll, "DllRegisterServer" );
	      if( pRegisterServer )
	         lReturn = ( ( PDLLREGISTERSERVER ) pRegisterServer )();
	      FreeLibrary( hDll );
	   }
	   hb_retnl( lReturn );
	}
#pragma ENDDUMP

