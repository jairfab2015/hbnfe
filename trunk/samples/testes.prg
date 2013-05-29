****************************************************************************************************
* Funcoes e Classes Relativas a Testes das Rotinas da NFE                                          *
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
#include "..\include\hbnfe.ch"

FUNCTION MAIN()
LOCAL oNfe, oStatus, oValida, oConsulta, oConsultaCadastro, oAssina, oCancela,;
      oInutiliza, oEnviaNFe, oRetornoNFe, oDanfe, oIniToXML, oEmail, oCCe, oNF, ;
      oDanfeCCe, aRetorno, cRetorno, nI, cCaminho, oFuncoes := hbNFeFuncoes(),;
      nOption, SW_SHOWNORMAL := 1,;
      hIniData, cPastaSchemas, cSerialCert, cUFWS, tpAmb, versaoDados, cUF, cMun,;
      tpImp, versaoSistema, cXMLFileAssinado, idLote, tpEmis, nRecibo, cChaveNFe,;
      xUF, CNPJ, cXMLFileSemAssinatura, cChaveNfeCanc, nProtCanc, xJustificativa,;
      cXMLFileDanfe, cLogoFile, nLogoStyle, cIniAcbr, ArquivoEmail, cXMLFileCCe

   SET DATE TO BRIT
   SET CENTURY ON
   REQUEST HB_CODEPAGE_PT850 && PARA INDEXAR CAMPOS ACENTUADOS
   HB_SETCODEPAGE("PT850")   && PARA INDEXAR CAMPOS ACENTUADOS

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
   xJustificativa=hIniData['Cancelamento']['xJustificativa']

   cXMLFileDanfe=hIniData['Danfe']['cXMLFileDanfe']
   cLogoFile=hIniData['Danfe']['cLogoFile']
   nLogoStyle=val( hIniData['Danfe']['nLogoStyle'] )
                                 
   cXMLFileCCe=hIniData['CCe']['cXMLFileCCe']
   
   cIniAcbr=hIniData['IniToXML']['cIniAcbr']

   ArquivoEmail=hIniData['Email']['ArquivoEmail']


   oNfe := hbNfe()
   oNfe:cPastaSchemas := cPastaSchemas
   oNFe:cSerialCert := cSerialCert
   oNFe:nSOAP := HBNFE_MXML
   oNFe:cUFWS := cUFWS // UF WebService
   oNFe:tpAmb := tpAmb // Tipo de Ambiente
   oNFe:versaoDados := versaoDados // Versao
   oNFe:versaoDadosCCe := '1.00'
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
   oNFe:cEmailEmitente := "construcao@construcao.com.br"
   oNFe:cSiteEmitente := "www.construcao.com.br"
   oNFe:cDesenvolvedor := "Desenvolvido por FJ Sistemas  +55 18 3652 0559  http://www.fjsistemas.com.br"
   oNFe:cCertPFX := hIniData['Principais']['cCertPFX']
   oNFe:cCertFilePub := hIniData['Principais']['cCertFilePub']
   oNFe:cCertFileKey := hIniData['Principais']['cCertFileKey']
   oNFe:cCertPass := hIniData['Principais']['cCertPass']


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

   DO WHILE .T.
      ? ""
      ? "Escolha o Teste da hbNFe:"
      ? "1) Seleciona Certificado (apenas capicom)"
      ? "2) Retorna CN do Certificado (capicom,)"
      ? "3) Propriedades do Certificado (capicom,)"
      ? "4) Status do Serviço (capicom,curl)"
      ? "5) Valida XML (geral)"
      ? "6) Consulta NFe (capicom,curl)"
      ? "7) Consulta Cadastro (capicom,curl)"
      ? "8) Assina XML (capicom,xmlsec)"
      ? "9) Cancela NFe (capicom,curl)"
      ? "a) Inutiliza Intervalo de NFe (capicom,curl)"
      ? "b) Envia NFe (capicom,curl)"
      ? "c) Consulta Retorno NFe (capicom,curl)"
      ? "d) DANFE (geral)"
      ? "e) Ini To XML (Formato Acbr) (geral)"
      ? "f) Envia Email (geral)"
      ? "g) CC-e"
      ? "h) Gera XML por programação hbNFeCreator"
      ? "i) Imprime a Carta de Correção"
      ? "0) Quit"
      ? "> "

      DO WHILE .T.
        nOption := Inkey( 0 )
        IF nOption <> ASC("0") .AND. nOption <> ASC("1") .AND. nOption <> ASC("2") .AND. nOption <> ASC("3") .AND. nOption <> ASC("4") .AND. nOption <> ASC("5");
            .AND. nOption <> ASC("6") .AND. nOption <> ASC("7") .AND. nOption <> ASC("8") .AND. nOption <> ASC("9") .AND. nOption <> ASC("a") .AND. nOption <> ASC("b");
            .AND. nOption <> ASC("c") .AND. nOption <> ASC("d") .AND. nOption <> ASC("e") .AND. nOption <> ASC("f") .AND. nOption <> ASC("g") .AND. nOption <> ASC("h");
            .AND. nOption <> ASC("i")			 
           LOOP
        ENDIF
        EXIT
      ENDDO
*      ?? Chr( nOption )

      IF     nOption == Asc( "0" )
         EXIT
      ELSEIF nOption == Asc( "1" )
        aRetorno := oNfe:escolheCertificado(.F.)
        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           ? aRetorno['Serial']
        ENDIF
      ELSEIF nOption == Asc( "2" )
        cRetorno := oNfe:pegaCNCertificado()
        ? cRetorno
      ELSEIF nOption == Asc( "3" )
        aRetorno := oNfe:pegaPropriedadesCertificado()
        IF aRetorno['OK'] == .T.
           ? aRetorno['SerialNumber']
           ? aRetorno['ValidToDate']
           ? aRetorno['HasPrivateKey']
           ? aRetorno['SubjectName']
           ? aRetorno['IssuerName']
           ? aRetorno['Thumbprint']
           ? aRetorno['getInfo']
        ENDIF
      ELSEIF nOption == Asc( "4" )
        oStatus := hbNFeStatus()
        oStatus:ohbNFe := oNfe // Objeto hbNFe
        oStatus:tpAmb := '1' // Normal
        oStatus:cUF := cUF // UF
        aRetorno := oStatus:execute()
        oStatus := Nil

        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           ? aRetorno['tpAmb']
           ? aRetorno['verAplic']
           ? aRetorno['cStat']
           ? aRetorno['xMotivo']
           ? aRetorno['cUF']
           ? aRetorno['dhRecbto']
           ? aRetorno['tMed']
        ENDIF
      ELSEIF nOption == Asc( "5" )
        oValida := hbNFeValida()
        oValida:ohbNFe := oNfe // Objeto hbNFe
        oValida:cXML := cXMLFileAssinado // Arquivo XML ou ConteudoXML
        aRetorno := oValida:execute()
        oValida := Nil
        IF aRetorno['OK'] == .F.
           ? aRetorno['nResult']
           ? aRetorno['MsgErro']
        ELSE
           ? "VALIDO"
        ENDIF
      ELSEIF nOption == Asc( "6" )
        oConsulta := hbNFeConsulta()
        oConsulta:ohbNFe := oNfe // Objeto hbNFe
        oConsulta:cChaveNFe := cChaveNFe // Chave ou pode ser um arquivo xml com o parametro cNFeFile
        aRetorno := oConsulta:execute()
        oConsulta := Nil

        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           ? aRetorno['tpAmb']
           ? aRetorno['verAplic']
           ? aRetorno['dhRecbto']
           ? aRetorno['nProt']
           ? aRetorno['digVal']
           ? aRetorno['cStat']
           ? aRetorno['xMotivo']
           ? aRetorno['protNFe']
        ENDIF
      ELSEIF nOption == Asc( "7" )
        oConsultaCadastro := hbNFeConsultaCadastro()
        oConsultaCadastro:ohbNFe := oNfe // Objeto hbNFe
        oConsultaCadastro:cUF := xUF
        oConsultaCadastro:cCNPJ := CNPJ
        aRetorno := oConsultaCadastro:execute()
        oConsultaCadastro := Nil

        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           ? aRetorno['verAplic']
           ? aRetorno['cStat']
           ? aRetorno['xMotivo']
           ? aRetorno['IE']
           ? aRetorno['CNPJ']
           ? aRetorno['cSit']
           ? aRetorno['indCredNFe']
           ? aRetorno['indCredCTe']
           ? aRetorno['xNome']
           ? aRetorno['xRegApur']
           ? aRetorno['CNAE']
           ? aRetorno['dIniAtiv']
           ? aRetorno['dUltSit']
           ? aRetorno['xLgr']
           ? aRetorno['nro']
           ? aRetorno['xBairro']
           ? aRetorno['cMun']
           ? aRetorno['xMun']
           ? aRetorno['CEP']
        ENDIF
      ELSEIF nOption == Asc( "8" )
        oAssina := hbNFeAssina()
        oAssina:ohbNFe := oNfe // Objeto hbNFe
        oAssina:cXMLFile := cXMLFileSemAssinatura
        oAssina:lMemFile := .F.
        aRetorno := oAssina:execute()
        oAssina := Nil

        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           ? "ASSINADO"
        ENDIF
      ELSEIF nOption == Asc( "9" )
         nIDL := 1 // ESSE ID NÃO PODE SE REPETIR NUNCA
         cEST := oFuncoes:pegaTag( oFuncoes:pegaTag( cXMLfile, 'ide' ), 'cUF' )       // pega do XML
         cCNP := oFuncoes:pegaTag( oFuncoes:pegaTag( cXMLfile, 'emit' ),'CNPJ' )      // pega do XML
         cCHV := oFuncoes:pegaTag( oFuncoes:pegaTag( cXMLfile, 'protNFe' ), 'chNFe' ) // pega do XML
         cPROT:= oFuncoes:pegaTag( oFuncoes:pegaTag( cXMLfile, 'protNFe' ), 'nProt' ) // pega do XML

         oCancela:=hbNFeEvento()
         oCancela:ohbNFe      := oNfe
         oCancela:cUF         := cEST
         oCancela:cCNPJ       := cCNP
         oCancela:cChaveNFe   := cCHV
         oCancela:dDataEvento := DATE()
         oCancela:cHoraEvento := TIME()
         oCancela:cUTC        := '-02:00'  // utc de verao -2  de inverno -3
         oCancela:idLote      := ALLTRIM(STR(nIDL))
         oCancela:cTIPevento  := 'Cancelamento'
         oCancela:cIDevento   := '110111'

         oCancela:AddEvento()
         oCancela:Evento[oCancela:nEvento]:nSeqEvento  := '1'
         oCancela:Evento[oCancela:nEvento]:nProt       := cPROT
         oCancela:Evento[oCancela:nEvento]:cJustifica  := 'JUSTIFICATIVA DO CANCELAMENTO'

         aRetorno := oCancela:execute()
         oCancela := Nil

        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           ? aRetorno['tpAmb']
           ? aRetorno['verAplic']
           ? aRetorno['cStat']
           ? aRetorno['xMotivo']
           ? aRetorno['cUF']
           ? aRetorno['chNFe']
           ? aRetorno['dhRecbto']
           ? aRetorno['nProt']
           ? aRetorno['retCancNFe']
        ENDIF
      ELSEIF nOption == Asc( "a" )
        oInutiliza := hbNFeInutiliza()
        oInutiliza:ohbNFe := oNfe // Objeto hbNFe
        oInutiliza:cUF := '35'
        oInutiliza:ano := '11'
        oInutiliza:CNPJ := '13514106000155'
        oInutiliza:mod := '55'
        oInutiliza:serie := '1'
        oInutiliza:nNFIni := '37'
        oInutiliza:nNFFin := '37'
        oInutiliza:cJustificativa := 'teste asjdh jka'
        aRetorno := oInutiliza:execute()
        oInutiliza := Nil

  *      aRetorno := oNfe:inutiliza('41CCD63AFA9EE2C13052D0CAC539965D','35','2.00','2','35','11','11072432000124','55','1','1','1','35110110418360000161550010000000040000000042','teste asjdh jka')
        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           ? aRetorno['ID']
           ? aRetorno['tpAmb']
           ? aRetorno['verAplic']
           ? aRetorno['cStat']
           ? aRetorno['xMotivo']
           ? aRetorno['cUF']
           ? aRetorno['ano']
           ? aRetorno['CNPJ']
           ? aRetorno['mod']
           ? aRetorno['serie']
           ? aRetorno['nNFIni']
           ? aRetorno['nNFFin']
           ? aRetorno['dhRecbto']
           ? aRetorno['nProt']
        ENDIF
      ELSEIF nOption == Asc( "b" )
        oEnviaNFe := hbNFeRecepcaoLote()
        oEnviaNFe:ohbNFe := oNfe // Objeto hbNFe
        oEnviaNFe:idLote := idLote
        oEnviaNFe:aXMLDados := { cXMLFileAssinado }
        oEnviaNFe:lAguardaRetorno := .T.
        aRetorno := oEnviaNFe:execute()
        oEnviaNFe := Nil

        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           ? aRetorno['versao']
           ? aRetorno['tpAmb']
           ? aRetorno['verAplic']
           ? aRetorno['cStat']
           ? aRetorno['xMotivo']
           ? aRetorno['cUF']
           ? aRetorno['dhRecbto']
           ? aRetorno['nRec']
           ? aRetorno['tMed']
        ENDIF
      ELSEIF nOption == Asc( "c" )
        oRetornoNFe := hbNFeRetornoRecepcao()
        oRetornoNFe:ohbNFe := oNfe // Objeto hbNFe
        oRetornoNFe:nRec := nRecibo
        aRetorno := oRetornoNFe:execute()
        oRetornoNFe := Nil

        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           ? aRetorno['tpAmb']
           ? aRetorno['verAplic']
           ? aRetorno['nRec']
           ? aRetorno['cStat']
           ? aRetorno['xMotivo']
           ? aRetorno['cUF']
           ? aRetorno['cMsg']
           ? aRetorno['xMsg']
           FOR nI = 1 TO aRetorno['nNFs']
              ? aRetorno['NF'+STRZERO(nI,2)+'_tpAmb']
              ? aRetorno['NF'+STRZERO(nI,2)+'_verAplic']
              ? aRetorno['NF'+STRZERO(nI,2)+'_chNFe']
              ? aRetorno['NF'+STRZERO(nI,2)+'_dhRecbto']
              ? aRetorno['NF'+STRZERO(nI,2)+'_nProt']
              ? aRetorno['NF'+STRZERO(nI,2)+'_digVal']
              ? aRetorno['NF'+STRZERO(nI,2)+'_cStat']
              ? aRetorno['NF'+STRZERO(nI,2)+'_xMotivo']
              ? aRetorno['NF'+STRZERO(nI,2)+'_protNFe']
           NEXT
        ENDIF
      ELSEIF nOption == Asc( "d" )
        oDanfe := hbNFeDanfe()
        oDanfe:ohbNFe := oNfe // Objeto hbNFe
        oDanfe:cLogoFile  := cLogoFile       // Arquivo da Logo Marca
        oDanfe:nLogoStyle := nLogoStyle      // 1-esquerda, 2-direita, 3-expandido
        oDanfe:lValorDesc := .T.
        oDanfe:nCasasQtd   := 4
        oDanfe:nCasasVUn   := 4
        oDanfe:cArquivoXML := cXMLFileDanfe
        oDanfe:lLaser      := .T. // laser .t., jato .f. (laser maior aproveitamento do papel)
        oDanfe:cFonteNFe   := 'Courier'
        aRetorno := oDanfe:execute()

        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           IF !":" $ oNfe:pastaPDF
              IF oFuncoes:curDrive() = Nil .OR. oFuncoes:curDrive() == ""
                 cCaminho := "\"+CURDIR()+"\"
              ELSE
                 cCaminho := oFuncoes:curDrive()+":\"+CURDIR()+"\"
              ENDIF
           ELSE
              cCaminho := ""
           ENDIF
           #ifndef __XHARBOUR__
              WAPI_SHELLEXECUTE(cCaminho+"\"+oDanfe:cFile,, cCaminho+"\"+oDanfe:cFile ,,, SW_SHOWNORMAL)
           #else
              RUN(cCaminho+"\"+oDanfe:cFile)
           #endif
        ENDIF
      ELSEIF nOption == Asc( "e" )
        oIniToXML := hbNFeIniToXML()
        oIniToXML:ohbNFe := oNfe // Objeto hbNFe
        oIniToXML:cIniFile := cIniAcbr
        oIniToXML:lValida := .T.
        aRetorno := oIniToXML:execute()
        oIniToXML := Nil

        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           ? 'Gerou XML'
        ENDIF
      ELSEIF nOption == Asc( "f" )
        oEmail := hbNFeEmail()
        oEmail:ohbNFe := oNfe // Objeto hbNFe
        oEmail:aFiles := { ArquivoEmail }
*        oEmail:aFiles := { oFuncoes:curDrive()+":\"+CURDIR()+"\"+cXMLFileDanfe,;
*                           oFuncoes:curDrive()+":\"+CURDIR()+"\"+SUBS(cXMLFileDanfe,1,AT("-nfe",cXMLFileDanfe)-1)+'.pdf' }
        oEmail:aTo := 'Fernando <fernando@fjsistemas.com.br>'
        aRetorno := oEmail:execute()
        oEmail := Nil

        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           ? 'Enviou'
        ENDIF
      ELSEIF nOption == Asc( "g" )
        oCCe := hbNFeCCe()
        oCCe:ohbNFe      := oNfe // Objeto hbNFe
        oCCe:cUF         := cUF
        oCCe:cCNPJ       := CNPJ
        oCCe:cChaveNFe   := cChaveNFe
        oCCe:dDataEvento := DATE()
        oCCe:cHoraEvento := TIME()
        oCCe:cUTC        := '-04:00'
        oCCe:idLote      := '5'

        oCCe:AddEvento()
        oCCe:Evento[oCCe:nEvento]:nSeqEvento  := '8'
        oCCe:Evento[oCCe:nEvento]:xCorrecao   := 'Correção do numero do endereço para 759'

        oCCe:AddEvento()
        oCCe:Evento[oCCe:nEvento]:nSeqEvento  := '9'
        oCCe:Evento[oCCe:nEvento]:xCorrecao   := 'Correção do numero do endereço para 759'

        aRetorno := oCCe:execute()


        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           ? aRetorno['idLote']
           ? aRetorno['tpAmb']
           ? aRetorno['cOrgao']
           ? aRetorno['cStat']
           ? aRetorno['xMotivo']

           FOR nI = 1 TO oCCe:nEvento
             ? aRetorno['Id_'+ALLTRIM(STR(nI))]
             ? aRetorno['tpAmb_'+ALLTRIM(STR(nI))]
             ? aRetorno['verAplic_'+ALLTRIM(STR(nI))]
             ? aRetorno['cOrgao_'+ALLTRIM(STR(nI))]
             ? aRetorno['cStat_'+ALLTRIM(STR(nI))]
             ? aRetorno['xMotivo_'+ALLTRIM(STR(nI))]
             ? aRetorno['chNFe_'+ALLTRIM(STR(nI))]
             ? aRetorno['tpEvento_'+ALLTRIM(STR(nI))]
             ? aRetorno['xEvento_'+ALLTRIM(STR(nI))]
             ? aRetorno['nSeqEvento_'+ALLTRIM(STR(nI))]
             ? aRetorno['CNPJDest_'+ALLTRIM(STR(nI))]
             ? aRetorno['CPFDest_'+ALLTRIM(STR(nI))]
             ? aRetorno['emailDest_'+ALLTRIM(STR(nI))]
             ? aRetorno['dhRegEvento_'+ALLTRIM(STR(nI))]
             ? aRetorno['nProt_'+ALLTRIM(STR(nI))]
           NEXT
        ENDIF
        oCCe := Nil
      ELSEIF nOption == Asc( "h" )
         oNF := hbNFeCreator()
         oNF:ohbNFe      := oNfe // Objeto hbNFe
         oNF:lValida := .T.
         oNF:new()
         WITH OBJECT oNF:Ide
           :cUF     := 35
           :cNF     := 88
           :natOp   := 'VENDA'
           :indPag  := 0
           :mod     := 55
           :serie   := 1
           :nNF     := 88
           :dEmi    := CTOD('10/09/2011')
           :dSaiEnt := CTOD('10/09/2011')
           :hSaiEnt := TIME()
           :tpNF    := 1
           :cMunFG  := 3541406
         END WITH
		                && Alterado por Anderson Camilo em 14/08/2012
						
         WITH OBJECT oNF:Ide:NFref     
		                                && Pode se inserir varios documentos referenciados
            :AddRefNFe()
            WITH OBJECT :refNFe[:nItensRefNFe]
               :nNFe  := '35823432498237943211239812903819028391283890'     && NF-e
            END WITH

            :AddRefNFe()
            WITH OBJECT :refNFe[:nItensRefNFe]
               :nNFe  := '11111012040190000150550010000000051000000050'     && NF-e
            END WITH
			
            :AddRefNF()
            WITH OBJECT :refNF[:nItensRefNF]  && NF Modelo 01
               :cUF   := 35
               :AAMM  := '1109'
               :CNPJ  := '12345678901234'
               :mod   := '01'
               :serie := 1
               :nNF   := 000001
            END WITH

            :AddRefNF()
            WITH OBJECT :refNF[:nItensRefNF]  && NF Modelo 01
               :cUF   := 11
               :AAMM  := '1211'
               :CNPJ  := '12345678901234'
               :mod   := '01'
               :serie := 1
               :nNF   := 000123
            END WITH
			
            :AddRefNFP()
            WITH OBJECT :refNFP[:nItensRefNFP]  && NF Produtor Rural
               :cUF   := 11
               :AAMM  := '1211'
               :CNPJ  := '12345678901234'
               :CPF   := ''	
               :IE    := '12345678901234'	
               :mod   := '04'
               :serie := 1
               :nNF   := 000005
            END WITH

            :AddRefNFP()
            WITH OBJECT :refNFP[:nItensRefNFP]  && NF Produtor Rural
               :cUF   := 11
               :AAMM  := '1211'
               :CNPJ  := ''
               :CPF   := '12345678901'	
               :IE    := '12345678901234'	
               :mod   := '04'
               :serie := 1
               :nNF   := 000123456
            END WITH

            :AddRefCTe()
            WITH OBJECT :refCTe[:nItensRefCTe]
               :nCTe  := '11111012040190000150550010000000051000000050'     && CT-e
            END WITH

            :AddRefECF()
            WITH OBJECT :refECF[:nItensRefECF]
               :mod   := '2B'
               :nECF  := '001'
               :nCOO  := '123456'
            END WITH
			
         END WITH

         WITH OBJECT oNF:Ide
            :tpImp   := 1
            :tpEmis  := 1
            :tpAmb   := 2
            :finNFe  := 1
         END WITH
      
         WITH OBJECT oNF:Emi
            :CNPJ    := '11.777.888/0001-99'
            :xNome   := 'EMPRESA TESTE LTDA ME'
            :xFant   := 'EMPRESA TESTE'
            :xLgr    := 'RUA DE TESTE'
            :nro     := '123'
            :xBairro := 'BAIRRO TESTE'
            :cMun    := 3541406
            :xMun    := 'CIDADE DE TESTE'
            :UF      := 'SP'
            :CEP     := '19531-000'
            :fone    := '18 8888-9966'
            :IE      := '888.999.000-111'
            :CNAE    := 13981723
            :CRT     := 1
         END WITH
      
         WITH OBJECT oNF:Dest
            :CNPJ    := '22.777.888/0001-99'
            :xNome   := 'EMPRESA CLIENTE LTDA'
            :xLgr    := 'RUA DE CLIENTE'
            :nro     := '1234'
            :xCpl    := "COMPLEMENTO"
            :xBairro := 'BAIRRO CLIENTE'
            :cMun    := 3541406
            :xMun    := 'CIDADE DE CLIENTE'
            :UF      := 'SP'
            :CEP     := '19531-000'
            :fone    := '18 8888-9966'
            :IE      := '888.999.000-111'
            :email   := 'cliente@provedor.com.br'
         END WITH

         oNF:AddItem()
         WITH OBJECT oNF:Item[oNF:nItens]
            :cProd  := 1
            :cEAN   := ''
            :xProd  := 'PRODUTO 1'
            :NCM    := '28467328'
            :CFOP   := '5102'
            :uCom   := 'PC'
            :qCom   := 4.00
            :vUnCom := 10.00
            :vProd  := 40.00
            :vDesc  := 10.00
            :indTot := 0
            WITH OBJECT :ItemICMS
               :orig    := '0'
               :CSOSN   := '102'
               :modBC   := 0
               :vBC     := 0
               :pICMS   := 0
               :vICMS   := 0
            END WITH
            WITH OBJECT :ItemIPI
               :CST  := '99'
               :vBC  := 0
               :pIPI := 0
               :vIPI := 0
            END WITH
            WITH OBJECT :ItemPIS
               :CST  := '09'
               :vBC  := 0
               :pPIS := 0
               :vPIS := 0
            END WITH
            WITH OBJECT :ItemCOFINS
               :CST     := '09'
               :vBC     := 0
               :pCOFINS := 0
               :vCOFINS := 0
            END WITH
            :AddDI()
            WITH OBJECT :ItemDI[:nItensDI]
               :nDI         := '123'
               :dDI         := CTOD('01/09/2011')
               :xLocDesemb  := 'PARANAGUA'
               :UFDesemb    := 'PR'
               :dDesemb     := CTOD('01/08/2011')
               :cExportador := '231321'
               :AddADI()
               WITH OBJECT :ItemADI[:nItensADI]
                  :nAdicao := '123'
                  :nSeqAdic := 1234
                  :cFabricante := '321321'
               END WITH
            END WITH
         END WITH
      
         oNF:AddItem()
         WITH OBJECT oNF:Item[oNF:nItens]
            :cProd  := 2
            :cEAN   := '7898791635123'
            :xProd  := 'PRODUTO 2'
            :NCM    := '99'
            :CFOP   := '5102'
            :uCom   := 'UN'
            :qCom   := 2.00
            :vUnCom := 15.00
            :vProd  := 30.00
            :vDesc  := 5.00
            :indTot := 0
            WITH OBJECT :ItemICMS
               :orig    := '0'
               :CSOSN   := '102'
               :modBC   := 0
               :vBC     := 0
               :pICMS   := 0
               :vICMS   := 0
            END WITH
            WITH OBJECT :ItemIPI
               :CST  := '99'
               :vBC  := 0
               :pIPI := 0
               :vIPI := 0
            END WITH
            WITH OBJECT :ItemPIS
               :CST  := '09'
               :vBC  := 0
               :pPIS := 0
               :vPIS := 0
            END WITH
            WITH OBJECT :ItemCOFINS
               :CST     := '09'
               :vBC     := 0
               :pCOFINS := 0
               :vCOFINS := 0
            END WITH
         END WITH
      
         WITH OBJECT oNF:Totais:ICMS
            :vBC    := 0
            :vICMS  := 0
            :vBCST  := 0
            :vST    := 0
            :vProd  := 70
            :vFrete := 0
            :vSeg   := 0
            :vDesc  := 15
            :vII    := 0
            :vIPI   := 0
            :vPIS   := 0
            :vCOFINS:= 0
            :vOutro := 0
            :vNF    := 55
         END WITH
      
         WITH OBJECT oNF:transp
            :modFrete := '1'
            WITH OBJECT :transporta
               :CPF    := '777.666.555-44'
               :xNome  := 'TRANSPORTADOR'
               :xEnder := 'ENDERECO TRANSPORTADOR'
               :xMun   := 'CIDADE TRANSPORTADOR'
               :UF     := 'SP'
            END WITH
            WITH OBJECT :veictransp
               :placa := 'AAA1234'
               :UF    := 'PR'
            END WITH
            WITH OBJECT :vol
               :qVol  := 2
               :esp   := 'CAIXA'
               :marca := 'PROPRIA'
               :pesoL := 10.500
               :pesoB := 12.100
            END WITH
         END WITH
      
         WITH OBJECT oNF:cobr
            WITH OBJECT oNF:cobr:fat
               :nFat := '134798'
               :vOrig := 55
               :vDesc := 0
               :vLiq  := 55
            END WITH
            :AddDup()
            WITH OBJECT :ItemDup[:nItensDup]
               :nDup  := '1928'
               :dVenc := CTOD('01/10/2011')
               :vDup  := 25.00
            END WITH
            :AddDup()
            WITH OBJECT :ItemDup[:nItensDup]
               :nDup := '098098'
               :dVenc := CTOD('01/11/2011')
               :vDup  := 20.00
            END WITH
         END WITH
      
         oNF:InfAdic:infCpl := 'kjh ahaJHDAhaDSHDAsd AD AHGD A'
      
         WITH OBJECT oNF:ObsCont
            :AddObs()
            WITH OBJECT :ItemObs[:nItensObs]
               :xCampo := 'CNPJ'
               :xTexto := 'rrwer wer weriu wri'
            END WITH
         END WITH
      
         aRetorno := oNF:geraXML()
         oNF := Nil
         IF aRetorno[ 'OK' ] = .F.
            ? aRetorno[ 'MsgErro' ]
         ELSE
           ? 'Gerou XML'
         ENDIF
      ELSEIF nOption == Asc( "i" )
        oDanfeCCe:= hbNFeDanfeCCe()
        oDanfeCCe:ohbNFe := oNfe // Objeto hbNFe
        oDanfeCCe:cLogoFile       := cLogoFile      // Arquivo da logo marca
        oDanfeCCe:nLogoStyle      := nLogoStyle     // Estilo da Logo Marca  
        oDanfeCCe:cArquivoNFeXML  := cXMLFileDanfe  // Arquivo XML da NF-e
        oDanfeCCe:cArquivoCCeXML  := cXMLFileCCe    // Arquivo XML da CC-e
        oDanfeCCe:lLaser          := .T.            // laser .t., jato .f. (laser maior aproveitamento do papel)
        oDanfeCCe:cFonteCCe       := 'Times'        // Fonte geral da carta de CC-e   -  Times / Helvetica / Courier-Oblique / Courier
        oDanfeCCe:cFonteCorrecoes := 'Courier'      // Fonte do quadro correções      -  Times / Helvetica / Courier-Oblique / Courier-Bold / Courier
        aRetorno := oDanfeCCe:execute()

        IF aRetorno['OK'] == .F.
           ? aRetorno['MsgErro']
        ELSE
           IF !":" $ oNfe:pastaPDF
              IF oFuncoes:curDrive() = Nil .OR. oFuncoes:curDrive() == ""
                 cCaminho := "\"+CURDIR()+"\"
              ELSE
                 cCaminho := oFuncoes:curDrive()+":\"+CURDIR()+"\"
              ENDIF
           ELSE
              cCaminho := ""
           ENDIF
		   
           #ifndef __XHARBOUR__
              WAPI_SHELLEXECUTE(cCaminho+"\"+oDanfeCCe:cFile,, cCaminho+"\"+oDanfeCCe:cFile ,,, SW_SHOWNORMAL)
           #else
              RUN(cCaminho+"\"+oDanfeCCe:cFile)
           #endif
        ENDIF
		 
      ENDIF
      WAIT
      
   ENDDO

RETURN Nil
