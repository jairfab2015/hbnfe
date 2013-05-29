
#include "common.ch"
#include "hbclass.ch"
#include "hbwin.ch"
#include "harupdf.ch"
#include "hbzebra.ch"
#include "hbcompat.ch"
#Include "hwgui.ch"
STATIC Thisform

FUNCTION testenfe_hwgui( ... )
 RETURN _testenfe_hwgui( HB_AParams() )

FUNCTION _testenfe_hwgui(  )


 LOCAL  vSerCert := "" , vUFWS := "" , vtpAmb := "" , vUF := "" , vXMLAssinado := "" , vChaveConsulta := ""
  LOCAL oDlg, oButtonex1, oButtonex2, oButtonex3, oButtonex4, oButtonex5, oButtonex6, oButtonex7 ;
        , oButtonex8, oButtonex9, oButtonex10, oButtonex11, oButtonex12, oButtonex13, oButtonex14, oButtonex15 ;
        , oRichedit1, oLabel1, oLabel2, oLabel3, oLabel4, oSerCert, oUFWS, otpAmb ;
        , oLabel5, oXMLAssinado, oLabel6, oChaveConsulta
LOCAL oStatus, oValida, oConsulta, oConsultaCadastro, oAssina, oCancela,;
      oInutiliza, oEnviaNFe, oRetornoNFe, oDanfe, oIniToXML, oEmail,;
      aRetorno, cRetorno, nI, cCaminho
LOCAL  oFuncoes := hbNFeFuncoes(),;
      nOption
LOCAL      hIniData, cPastaSchemas, cSerialCert, cUFWS, tpAmb, versaoDados, cUF, cMun,;
      tpImp, versaoSistema, cXMLFileAssinado, idLote, tpEmis, nRecibo, cChaveNFe,;
      xUF, CNPJ, cXMLFileSemAssinatura, cChaveNfeCanc, nProtCanc, xJustificativa,;
      cXMLFileDanfe, cIniAcbr, ArquivoEmail
PRIVATE vRichedit1
PUBLIC oNfe

   SET DATE TO BRIT
   SET CENTURY ON
   REQUEST HB_CODEPAGE_PT850 &&& PARA INDEXAR CAMPOS ACENTUADOS
   HB_SETCODEPAGE("PT850")   &&& PARA INDEXAR CAMPOS ACENTUADOS

   hIniData := HB_ReadIni( "teste.ini" )
   cPastaSchemas=hIniData['Principais']['cPastaSchemas']
   cSerialCert=hIniData['Principais']['cSerialCert']
   cUFWS=hIniData['Principais']['cUFWS']
   tpAmb=hIniData['Principais']['tpAmb']
   versaoDados=hIniData['Principais']['versaoDados']
   cUF=hIniData['Principais']['cUF']
   cMun=hIniData['Principais']['cMun']
   tpImp=hIniData['Principais']['tpImp']
   versaoSistema=hIniData['Principais']['versaoSistema']

   cXMLFileAssinado=hIniData['Envio']['cXMLFileAssinado']
   idLote=hIniData['Envio']['idLote']
   tpEmis=hIniData['Envio']['tpEmis']

   nRecibo=hIniData['Retorno']['nRecibo']

   cChaveNFe=hIniData['Consulta']['cChaveNFe']

   xUF=hIniData['Cadastro']['xUF']
   CNPJ=hIniData['Cadastro']['CNPJ']

   cXMLFileSemAssinatura=hIniData['Assinatura']['cXMLFileSemAssinatura']

   cChaveNfeCanc=hIniData['Cancelamento']['cChaveNfeCanc']
   nProtCanc=hIniData['Cancelamento']['nProtCanc']
   xJustificativa=hIniData['Cancelamento']['xJustificativa']

   cXMLFileDanfe=hIniData['Danfe']['cXMLFileDanfe']

   cIniAcbr=hIniData['IniToXML']['cIniAcbr']

   ArquivoEmail=hIniData['Email']['ArquivoEmail']


   oNfe := hbNfe()
   oNfe:cPastaSchemas := cPastaSchemas
   oNFe:cSerialCert := cSerialCert
   oNFe:cUFWS := cUFWS // UF WebService
   oNFe:tpAmb := tpAmb // Tipo de Ambiente
   oNFe:versaoDados := versaoDados // Versao
   oNFe:tpEmis := tpEmis //normal/scan/dpec/fs/fsda
   oNFe:empresa_UF := cUF
   oNFe:empresa_cMun := cMun
   oNFe:empresa_tpImp := tpImp
   oNFe:versaoSistema := versaoSistema
   oNFe:pastaNFe := "nfe"
   oNFe:pastaCancelamento := "canc"
   oNFe:pastaPDF := "pdf"
   oNFe:pastaInutilizacao := "inut"
   oNFe:pastaDPEC := "dpec"
   oNFe:pastaEnvRes := "envresp"

   oNFe:cEmail_Subject  := hIniData['Email']['email_assunto']
   oNFe:cEmail_MsgTexto := hIniData['Email']['email_txt']
   oNFe:cEmail_MsgHTML  := hIniData['Email']['email_html']
   oNFe:cEmail_ServerIP := hIniData['Email']['email_smtp']
   oNFe:cEmail_From     := hIniData['Email']['email_from']
   oNFe:cEmail_User     := hIniData['Email']['email_usuario']
   oNFe:cEmail_Pass     := hIniData['Email']['email_senha']
   oNFe:nEmail_PortSMTP := VAL( hIniData['Email']['email_porta'] )
   oNFe:lEmail_Conf     := IF( hIniData['Email']['email_confirmacao'] == '.T.',.T.,.F.)
   oNFe:lEmail_SSL      := IF( hIniData['Email']['email_SSL'] == '.T.',.T.,.F.)
   oNFe:lEmail_Aut      := IF( hIniData['Email']['email_aut'] == '.T.',.T.,.F.)

  INIT DIALOG oDlg TITLE "Form1" ;
    AT 0,130 SIZE 886,516 NOEXIT  ;
     STYLE WS_POPUP+WS_CAPTION+WS_SYSMENU+WS_SIZEBOX+DS_CENTER;
     ON INIT {||oninit()}
    Thisform := oDlg

   @ 6,125 BUTTONEX oButtonex1 CAPTION "escolheCertificado"   SIZE 147,32 ;
        STYLE WS_TABSTOP  ;
        ON CLICK {|| oButtonex1_onClick(  ) }
   @ 159,125 BUTTONEX oButtonex2 CAPTION "CN certificado"   SIZE 145,32 ;
        STYLE WS_TABSTOP
   @ 312,125 BUTTONEX oButtonex3 CAPTION "Propriedades Certificado"   SIZE 163,32 ;
        STYLE WS_TABSTOP  ;
        ON CLICK {|| oButtonex3_onClick( oNfe ) }
   @ 484,125 BUTTONEX oButtonex4 CAPTION "Status Serviço"   SIZE 98,32 ;
        STYLE WS_TABSTOP 
   @ 595,125 BUTTONEX oButtonex5 CAPTION "Valida XML"   SIZE 98,32 ;
        STYLE WS_TABSTOP 
   @ 704,125 BUTTONEX oButtonex6 CAPTION "Consulta NFe"   SIZE 98,32 ;
        STYLE WS_TABSTOP
   @ 8,161 BUTTONEX oButtonex7 CAPTION "Consulta Cadastro"   SIZE 122,32 ;
        STYLE WS_TABSTOP 
   @ 143,161 BUTTONEX oButtonex8 CAPTION "AssinaXML"   SIZE 98,32 ;
        STYLE WS_TABSTOP 
   @ 250,161 BUTTONEX oButtonex9 CAPTION "Cancela NFe"   SIZE 98,32 ;
        STYLE WS_TABSTOP
   @ 356,161 BUTTONEX oButtonex10 CAPTION "Inutiliza"   SIZE 98,32 ;
        STYLE WS_TABSTOP
   @ 467,161 BUTTONEX oButtonex11 CAPTION "Envia (Recepção)"   SIZE 116,32 ;
        STYLE WS_TABSTOP
   @ 596,161 BUTTONEX oButtonex12 CAPTION "Retorno (RetRecepção)"   SIZE 152,32 ;
        STYLE WS_TABSTOP
   @ 10,198 BUTTONEX oButtonex13 CAPTION "DANFE"   SIZE 98,32 ;
        STYLE WS_TABSTOP
   @ 131,197 BUTTONEX oButtonex14 CAPTION "IniToXML (AcBr)"   SIZE 106,32 ;
        STYLE WS_TABSTOP
   @ 251,197 BUTTONEX oButtonex15 CAPTION "Email"   SIZE 98,32 ;
        STYLE WS_TABSTOP
   @ 351,197 BUTTONEX oButtonex16 CAPTION "Sair"   SIZE 98,32 ;
        STYLE WS_TABSTOP  ;
        ON CLICK {|| Thisform:close() }
   @ 11,251 RICHEDIT oRichedit1 TEXT vRichedit1 SIZE 854,248 ;
        STYLE ES_MULTILINE +WS_BORDER+ES_AUTOVSCROLL +WS_VSCROLL
   @ 9,9 SAY oLabel1 CAPTION "Serial Cert"  SIZE 80,21
   @ 10,35 SAY oLabel2 CAPTION "UFWS"  SIZE 80,21
   @ 12,63 SAY oLabel3 CAPTION "tpAmb"  SIZE 80,21
   @ 13,91 SAY oLabel4 CAPTION "UF Emp"  SIZE 80,21
   @ 104,10 GET oSerCert VAR vSerCert SIZE 165,24
   @ 105,40 GET oUFWS VAR vUFWS SIZE 80,24
   @ 108,71 GET otpAmb VAR vtpAmb SIZE 80,24
   @ 110,101 GET oUF VAR vUF SIZE 80,24
   @ 285,11 SAY oLabel5 CAPTION "XMLAssinado"  SIZE 92,21
   @ 397,12 GET oXMLAssinado VAR vXMLAssinado SIZE 402,24
   @ 287,34 SAY oLabel6 CAPTION "Chave Consulta"  SIZE 105,21
   @ 403,44 GET oChaveConsulta VAR vChaveConsulta SIZE 389,24

   ACTIVATE DIALOG oDlg


RETURN oDlg:lresult

STATIC FUNCTION oninit
Thisform:oButtonex2:disable()
Thisform:oButtonex4:disable()
Thisform:oButtonex5:disable()
Thisform:oButtonex6:disable()
Thisform:oButtonex7:disable()
Thisform:oButtonex8:disable()
Thisform:oButtonex9:disable()
Thisform:oButtonex10:disable()
Thisform:oButtonex11:disable()
Thisform:oButtonex12:disable()
Thisform:oButtonex13:disable()
Thisform:oButtonex14:disable()
Thisform:oButtonex15:disable()
RETURN(.T.)
STATIC FUNCTION oButtonex1_onClick
aRetorno := oNfe:escolheCertificado(.F.)
IF aRetorno['OK'] == .F.
   vRichedit1 := ALLTRIM(Thisform:oRichEdit1:getText())+CHR(13)+aRetorno['MsgErro']
ELSE
   vRichedit1 := ALLTRIM(Thisform:oRichEdit1:getText())+CHR(13)+aRetorno['Serial']
ENDIF
Thisform:oRichEdit1:setText(vRichedit1)
RETURN .T.

FUNCTION oButtonex3_onClick( oNfe )
LOCAL lResult, aRetorno
   lResult := .F.
   nThreadHandle := hb_threadStart ( {|| aRetorno := pegaCert( oNfe, @lResult  ) })
   DO WHILE !lResult
	   hwg_DoEvents()
	ENDDO
   hb_THREADWAITFORALL()

  IF aRetorno['OK'] == .T.
     vRichedit1 := ALLTRIM(Thisform:oRichEdit1:getText())+CHR(13)+;
                   aRetorno['SerialNumber']+CHR(13)+;
                   DTOC(aRetorno['ValidToDate'])+CHR(13)+;
                   IF(aRetorno['HasPrivateKey']=.T.,'.T.','.F.')+CHR(13)+;
                   aRetorno['SubjectName']+CHR(13)+;
                   aRetorno['IssuerName']+CHR(13)+;
                   aRetorno['Thumbprint']+CHR(13)+;
                   aRetorno['getInfo']
  ELSE
     vRichedit1 := ALLTRIM(Thisform:oRichEdit1:getText())+CHR(13)+'erro'
  ENDIF
  Thisform:oRichEdit1:setText(vRichedit1)
RETURN .T.

FUNC pegaCert(oxNfe, lResult)
LOCAL aRetorno
   aRetorno := oxNfe:pegaPropriedadesCertificado()
   lResult := .T.
RETURN(aRetorno)

