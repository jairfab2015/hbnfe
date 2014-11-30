****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Conversão INI formato AcBr para XML)                          *
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
#include "hbnfe.ch"

// So pra evitar erro de compilação no Harbour
// Mas significa que a rotina dá erro aonde usa esta variável
MEMVAR oNFe

CLASS hbNFeIniToXML
   DATA ohbNFe
   DATA cIniFile
   DATA cXMLFile
   DATA lValida    // Assina e Valida

   DATA aIde
   DATA aRefNfe       // notas referenciadas - Mauricio Cruz - 18/01/2012
   DATA aEmit
   DATA aDest
   DATA aRetirada
   DATA aEntrega
   DATA aICMSTotal
  	DATA aISSTotal
  	DATA aRetTrib
  	DATA aTransp
  	DATA aRetTransp
  	DATA aVeicTransp
  	DATA aReboque
  	DATA aFatura
  	DATA aDuplicatas
  	DATA aInfAdic
  	DATA aObsCont
  	DATA aObsFisco
  	DATA aProcRef
   DATA aExporta
  	DATA aCompra
  	DATA aInfProt

   DATA aItem
   DATA aItemDI
   DATA aItemAdi
   DATA aItemICMS
   DATA aItemICMSPart
   DATA aItemICMSST
   DATA aItemICMSSN101
   DATA aItemICMSSN102
   DATA aItemICMSSN201
   DATA aItemICMSSN202
   DATA aItemICMSSN500
   DATA aItemICMSSN900
   DATA aItemIPI
   DATA aItemII
   DATA aItemPIS
   DATA aItemPISST
   DATA aItemCOFINS
   DATA aItemCOFINSST
   DATA aItemISSQN
   DATA lCriaSaiNfe INIT .F.   // se deve criar ou não o SAINFE.TXT.  Mauricio Cruz - 28/11/2011
   DATA aItemCOMB
	  DATA lMostra_imp_danfe INIT .F.

   DATA cXMLSaida
   METHOD execute()
   METHOD criaNFe(hIniData,cIniFile)
   METHOD incluiTag(cTag,cValor)
   METHOD REGRAS_NFE(aMSGvld,cChaveNFe,nItem)
ENDCLASS

METHOD execute() CLASS hbNFeIniToXML
LOCAL aRetorno := hash(), hIniData, cComando, cXML, oAssina, aRetornoAss, oValida, aRetornoVal, oCancela, aRetornoCan
LOCAL oStatus, aRetornoSta
   IF ::lValida = Nil
      ::lValida := .F.
   ENDIF

   IF !FILE( ::cIniFile )
      aRetorno['OK'] := .F.
      aRetorno['MsgErro'] := 'Arquivo não encontrado '+::cIniFile
      RETURN(aRetorno)
   ENDIF

   aRetorno['OK'] := .T.

   cXML := MEMOREAD( ::cIniFile )
   cComando := SUBS( cXML, 1, AT("(", cXML )-1)

   hIniData := HB_ReadIni( ::cIniFile )  // ESSA FUNÇÃO ORIGINAL DO XHARBOUR TEM UM PROBLEMA E LÊ APENAS 1024 BYTS, POR ISSO FOI MUDADO PARA ESSA HBNFE_ReadIni() QUE LÊ 4096BYTS
   IF "CRIAR" $ UPPER(cComando)
      aRetorno := ::criaNFe(hIniData,::cIniFile)
      IF ::lCriaSaiNfe
         IF aRetorno[ 'OK' ] = .T.
            hb_MemoWrit( "SAINFE.TXT", "OK: Gerado" )
         ELSE
            hb_MemoWrit( "SAINFE.TXT", "ERRO: " + aRetorno[ 'MsgErro' ] )
         ENDIF
      ENDIF
   ELSEIF "ASSINAR" $ UPPER(cComando)

      oAssina := hbNFeAssina()
      oAssina:ohbNFe := ::ohbNfe // Objeto hbNFe
      oAssina:cXMLFile := SUBS( cXML, AT("(", cXML )+2, AT(")", cXML )-2)
      oAssina:lMemFile := .F.
      aRetornoAss := oAssina:execute()
      oAssina := Nil

      IF aRetornoAss['OK'] == .F.
         aRetorno['OK'] := .F.
         aRetorno['MsgErro'] := aRetornoAss['MsgErro']
      ELSE
         aRetorno['Assinou'] := .T.
      ENDIF
      IF ::lCriaSaiNfe
         IF aRetorno[ 'OK' ] = .T.
            hb_MemoWrit( "SAINFE.TXT", "OK: Assinado" )
         ELSE
            hb_MemoWrit( "SAINFE.TXT", "ERRO: " + aRetorno[ 'MsgErro' ] )
         ENDIF
      ENDIF
   ELSEIF "VALIDAR" $ UPPER(cComando)
      oValida := hbNFeValida()
      oValida:ohbNFe := ::ohbNfe // Objeto hbNFe
      oValida:cXML := SUBS( cXML, AT("(", cXML )+2, AT(")", cXML )-2)
      aRetornoVal := oValida:execute()
      oValida := Nil
      IF aRetornoVal['OK'] == .F.
         aRetorno['OK'] := .F.
         aRetorno['MsgErro'] := aRetornoVal['MsgErro']
      ELSE
         aRetorno['Validou'] := .T.
      ENDIF
      IF ::lCriaSaiNfe
         IF aRetorno[ 'OK' ] = .T.
            hb_MemoWrit( "SAINFE.TXT", "OK: Validado" )
         ELSE
            hb_MemoWrit( "SAINFE.TXT", "ERRO: " + aRetorno[ 'MsgErro' ] )
         ENDIF
      ENDIF
   ELSEIF "CANCELAR" $ UPPER(cComando)
      oCancela := hbNFeCancela()
      oCancela:ohbNFe := oNfe // Objeto hbNFe
      oCancela:cNFeFile := SUBS( cXML, AT("(", cXML )+1, AT(",", cXML )-1)
      oCancela:cJustificativa := SUBS( cXML, AT(",", cXML )+1, AT(")", cXML )-1)
      aRetornoCan := oCancela:execute()
      oCancela := Nil
      IF aRetornoCan['OK'] == .F.
         aRetorno['OK'] := .F.
         aRetorno['MsgErro'] := aRetornoCan['MsgErro']
      ELSE
         aRetorno['Cancelou'] := .T.
         aRetorno['cStat']      := aRetornoCan['cStat']
         aRetorno['xMotivo']    := aRetornoCan['xMotivo']
         aRetorno['cUF']        := aRetornoCan['cUF']
         aRetorno['chNFe']      := aRetornoCan['chNFe']
         aRetorno['dhRecbto']   := aRetornoCan['dhRecbto']
         aRetorno['nProt']      := aRetornoCan['nProt']
         aRetorno['digVal']     := aRetornoCan['digVal']
         aRetorno['retCancNFe'] := aRetornoCan['retCancNFe']
      ENDIF
      IF ::lCriaSaiNfe
         IF aRetorno[ 'OK' ] = .T.
            hb_MemoWrit( "SAINFE.TXT", "OK: Cancelado" + HB_EOL() + ;
                                   "cStat="+aRetorno['cStat'] + HB_EOL() + ;
                                   "xMotivo="+aRetorno['xMotivo'] + HB_EOL() + ;
                                   "cUF="+aRetorno['cUF'] + HB_EOL() + ;
                                   "chNFe="+aRetorno['chNFe'] + HB_EOL() + ;
                                   "dhRecbto="+aRetorno['dhRecbto'] + HB_EOL() + ;
                                   "nProt="+aRetorno['nProt'] + HB_EOL() + ;
                                   "digVal="+aRetorno['digVal'] + HB_EOL() + ;
                                   "xml="+aRetorno['retCancNFe'] ;
                                   )
         ELSE
            hb_MemoWrit( "SAINFE.TXT", "ERRO: " + aRetorno[ 'MsgErro' ] )
         ENDIF
      ENDIF
   ELSEIF "ENVIAR" $ UPPER(cComando)
   ELSEIF "IMPRIMIR" $ UPPER(cComando)
   ELSEIF "CONSULTARNFE" $ UPPER(cComando)
   ELSEIF "STATUS" $ UPPER(cComando)
      oStatus := hbNFeStatus()
      oStatus:ohbNFe := ::ohbNfe // Objeto hbNFe
      oStatus:tpAmb := ::ohbNfe:tpAmb // Normal
      oStatus:cUF := ::ohbNfe:cUFWS
      aRetornoSta := oStatus:execute()
      oStatus := Nil
      aRetorno := aRetornoSta
      IF ::lCriaSaiNfe
         IF aRetorno[ 'OK' ] = .T.
            hb_MemoWrit( "SAINFE.TXT", "OK: "  + HB_EOL() + ;
                                   "tpAmb="    + aRetorno['tpAmb'] + HB_EOL() + ;
                                   "verAplic=" + aRetorno['verAplic'] + HB_EOL() + ;
                                   "cStat="    + aRetorno['cStat'] + HB_EOL() + ;
                                   "xMotivo="  + aRetorno['xMotivo'] + HB_EOL() + ;
                                   "cUF="      + aRetorno['cUF'] + HB_EOL() + ;
                                   "dhRecbto=" + aRetorno['dhRecbto'] + HB_EOL() + ;
                                   "tMed="     + aRetorno['tMed'] ;
                                   )
         ELSE
            hb_MemoWrit( "SAINFE.TXT", "ERRO: " + aRetorno[ 'MsgErro' ] )
         ENDIF
      ENDIF
   ENDIF

   cXML := Nil

RETURN(aRetorno)

METHOD criaNFe(hIniData,cIniFile) CLASS hbNFeIniToXML
LOCAL oFuncoes := hbNFeFuncoes(), aRetorno := hash(), cDV, cChaveNFe, ;
      oAssina, aRetornoAss, oValida, aRetornoVal,;
      nICob, nNICob, nItem, nNItem, nObs, nAdi, nDI, mI, mY
LOCAL nItnRef:=0
LOCAL aMSGvld:={}
LOCAL cOBSFISCO, cOBSADICIONAL

   aRetorno['OK'] := .T.

   cChaveNFe := ::ohbNFe:empresa_UF + ;
             oFuncoes:FormatDate(CTOD(hIniData['Identificacao']['Emissao']),"YYMM","") + ;
             PADL(ALLTRIM(hIniData['Emitente']['CNPJ']),14,'0') + ;
             STRZERO( VAL(hIniData['Identificacao']['Modelo']), 2) + ;
             STRZERO( VAL(hIniData['Identificacao']['Serie']), 3) + ;
             STRZERO( VAL(hIniData['Identificacao']['Numero']), 9) + ;
             ::ohbNFe:tpEmis + ;
             STRZERO( VAL(hIniData['Identificacao']['Numero']), 8)

   cDV := oFuncoes:modulo11( cChaveNFe, 2, 9 )
   cChaveNFe += cDV

   ::aIde := hash()
  	::aIde[ "cUF" ] := ::ohbNFe:empresa_UF
  	::aIde[ "cNF" ] := STRZERO(VAL(hIniData['Identificacao']['Codigo']),8)
   ::aIde[ "natOp" ] := oFuncoes:parseEncode( hIniData['Identificacao']['NaturezaOperacao'] )
  	::aIde[ "indPag" ] := hIniData['Identificacao']['FormaPag']
  	::aIde[ "mod" ] := hIniData['Identificacao']['Modelo']
  	::aIde[ "serie" ] := hIniData['Identificacao']['Serie']
  	::aIde[ "nNF" ] := ALLTRIM(STR(VAL(hIniData['Identificacao']['Numero'])))
  	::aIde[ "dEmi" ] := oFuncoes:FormatDate(CTOD(hIniData['Identificacao']['Emissao']),"YYYY-MM-DD","-")
   TRY
	   ::aIde[ "dSaiEnt" ] := oFuncoes:FormatDate(CTOD(hIniData['Identificacao']['Saida']),"YYYY-MM-DD","-")
   CATCH
      ::aIde[ "dSaiEnt" ] := ''
   END
  	TRY
   	::aIde[ "hSaiEnt" ] := hIniData['Identificacao']['hSaiEnt']
   CATCH
      ::aIde[ "hSaiEnt" ] := ''
   END
  	::aIde[ "tpNF" ] := hIniData['Identificacao']['Tipo']
  	::aIde[ "cMunFG" ] := hIniData['Emitente']['CidadeCod'] //::ohbNFe:empresa_cMun // codigo ibge empresa

   // NOTAS REFERENCIADAS   - Mauricio Cruz - 18/01/2012
    ::aRefNfe:=hash()
   WHILE .T.
      nItnRef++
      TRY
         ::aRefNfe['refNF'+STRZERO(nItnRef,3)]  := hIniData['NFRef'+STRZERO(nItnRef,3)]['Tipo']
      CATCH
         nItnRef--
         EXIT
      END
      ::aRefNfe['refNFe'+STRZERO(nItnRef,3)] := hIniData['NFRef'+STRZERO(nItnRef,3)]['refNFe']
      IF !hIniData['NFRef'+STRZERO(nItnRef,3)]['Tipo']='NFe'
         ::aRefNfe['refNF'+STRZERO(nItnRef,3)]  := '1A'
      ENDIF
      ::aRefNfe['cUF'+STRZERO(nItnRef,3)]    := hIniData['NFRef'+STRZERO(nItnRef,3)]['cUF']
      ::aRefNfe['AAMM'+STRZERO(nItnRef,3)]   := hIniData['NFRef'+STRZERO(nItnRef,3)]['AAMM']
      ::aRefNfe['CNPJ'+STRZERO(nItnRef,3)]   := hIniData['NFRef'+STRZERO(nItnRef,3)]['CNPJ']
      ::aRefNfe['mod'+STRZERO(nItnRef,3)]    := hIniData['NFRef'+STRZERO(nItnRef,3)]['Modelo']
      ::aRefNfe['serie'+STRZERO(nItnRef,3)]  := hIniData['NFRef'+STRZERO(nItnRef,3)]['Serie']
      ::aRefNfe['nNF'+STRZERO(nItnRef,3)]    := hIniData['NFRef'+STRZERO(nItnRef,3)]['nNF']
   ENDDO


	::aIde[ "tpImp" ] := ::ohbNFe:empresa_tpImp // 1 - retrato 2-paisagem
	::aIde[ "tpEmis" ] := ::ohbNFe:tpEmis  // 1-normal scan fsda...

   IF VAL(::aIde[ "tpEmis" ])=3 .OR. VAL(::aIde[ "tpEmis" ])=5 .OR. VAL(::aIde[ "tpEmis" ])=6 .OR. VAL(::aIde[ "tpEmis" ])=7  // SE FOR MODO SCAN / SVC...
      ::aIde[ "dhCont" ] := ALLTRIM(STR(YEAR(CTOD(hIniData['Identificacao']['dhCont']))))+'-'+;
                            ALLTRIM(STRZERO( MONTH(CTOD(hIniData['Identificacao']['dhCont'])),2 ))+'-'+;
                            ALLTRIM(STRZERO( DAY(CTOD(hIniData['Identificacao']['dhCont'])),2 )) +'T'+;
                            ALLTRIM(hIniData['Identificacao']['contHr'])
      ::aIde[ "xJust" ] :=   hIniData['Identificacao']['xJust']
   ENDIF

	::aIde[ "cDV" ] := cDV // Digito verificador chave nfe
	::aIde[ "tpAmb" ] := ::ohbNFe:tpAmb // 1- producao 2-homologacao
	IF hIniData['Identificacao']['Finalidade'] = '0'
	   ::aIde[ "finNFe" ] := '1'
	ELSE
   	::aIde[ "finNFe" ] := hIniData['Identificacao']['Finalidade'] // finalidade 1-normal/ 2-complementar/ 3- de ajuste
   ENDIF
	::aIde[ "procEmi" ] := '0' //0 - emissão de NF-e com aplicativo do contribuinte 1 - emissão de NF-e avulsa pelo Fisco 2 - emissão de NF-e avulsa pelo contribuinte com seu certificado digital, através do site do Fisco 3- emissão NF-e pelo contribuinte com aplicativo fornecido pelo Fisco.
	::aIde[ "verProc" ] := ::ohbNFe:versaoSistema // versao sistema


 ::aEmit := hash()
	::aEmit[ "CNPJ" ] := hIniData['Emitente']['CNPJ']
	::aEmit[ "CPF" ] := '' // avulso pelo fisco
 ::aEmit[ "xNome" ] := oFuncoes:parseEncode( hIniData['Emitente']['Razao'] )
	::aEmit[ "xFant" ] := oFuncoes:parseEncode( hIniData['Emitente']['Fantasia'] )
	::aEmit[ "xLgr" ] := oFuncoes:parseEncode( hIniData['Emitente']['Logradouro'] )
	::aEmit[ "nro" ] := hIniData['Emitente']['Numero']
	::aEmit[ "xCpl" ] := oFuncoes:parseEncode( hIniData['Emitente']['Complemento'] )
	::aEmit[ "xBairro" ] := oFuncoes:parseEncode( hIniData['Emitente']['Bairro'] )
	::aEmit[ "cMun" ] := hIniData['Emitente']['CidadeCod']
	::aEmit[ "xMun" ] := oFuncoes:parseEncode( hIniData['Emitente']['Cidade'] )
	::aEmit[ "UF" ] := hIniData['Emitente']['UF']
	::aEmit[ "CEP" ] := hIniData['Emitente']['CEP']
	TRY
    	::aEmit[ "cPais" ] := hIniData['Emitente']['PaisCod']
    	::aEmit[ "xPais" ] := hIniData['Emitente']['Pais']
	CATCH
   	::aEmit[ "cPais" ] := '1058'
    	::aEmit[ "xPais" ] := 'BRASIL'
	END
   TRY
	   ::aEmit[ "fone" ] := oFuncoes:eliminaString(hIniData['Emitente']['Fone'], ".-/ ()")
   CATCH
      ::aEmit[ "fone" ] := ''
   END
	::aEmit[ "IE" ] := oFuncoes:eliminaString(hIniData['Emitente']['IE'], ".-/ ")
	TRY
   	::aEmit[ "IEST" ] := hIniData['Emitente']['IEST']
	CATCH
   	::aEmit[ "IEST" ] := ''
	END
	TRY
   	::aEmit[ "IM" ] := hIniData['Emitente']['IM']
	CATCH
   	::aEmit[ "IM" ] := ''
	END
	TRY
   	::aEmit[ "CNAE" ] := hIniData['Emitente']['CNAE']
	CATCH
   	::aEmit[ "CNAE" ] := ''
	END
	TRY
   	::aEmit[ "CRT" ] := hIniData['Emitente']['CRT']
	CATCH
   	::aEmit[ "CRT" ] := '1'
	END

   ::aDest := hash()
   IF LEN( hIniData['Destinatario']['CNPJ'] ) <= 11 .AND. hIniData['Destinatario']['UF'] <>'EX'  // Mauricio Cruz - 03/10/2011
   	::aDest[ "CPF" ] := hIniData['Destinatario']['CNPJ']
   ELSE
   	::aDest[ "CNPJ" ] := hIniData['Destinatario']['CNPJ']
   ENDIF
   IF ::ohbNFe:tpAmb='2' .AND. hIniData['Destinatario']['UF'] <>'EX'   // Mauricio Cruz - 03/10/2011
      //::aDest[ "CNPJ" ] := '99999999000191'
   ENDIF

   IF ::ohbNFe:tpAmb='2'    // Mauricio Cruz - 30/09/2011
      ::aDest[ "xNome" ] := 'NF-E EMITIDA EM AMBIENTE DE HOMOLOGACAO - SEM VALOR FISCAL'
   ELSE
      ::aDest[ "xNome" ] := oFuncoes:parseEncode( hIniData['Destinatario']['NomeRazao'] )
   ENDIF

	::aDest[ "xLgr" ] := oFuncoes:parseEncode( hIniData['Destinatario']['Logradouro'] )
	IF !EMPTY( hIniData['Destinatario']['Numero'] )
   	::aDest[ "nro" ] := hIniData['Destinatario']['Numero']
   ELSE
   	::aDest[ "nro" ] := '0'
   ENDIF
	::aDest[ "xCpl" ] := oFuncoes:parseEncode( hIniData['Destinatario']['Complemento'] )
	::aDest[ "xBairro" ] := oFuncoes:parseEncode( hIniData['Destinatario']['Bairro'] )
	::aDest[ "cMun" ] := hIniData['Destinatario']['CidadeCod']
	::aDest[ "xMun" ] := oFuncoes:parseEncode( hIniData['Destinatario']['Cidade'] )
	::aDest[ "UF" ] := hIniData['Destinatario']['UF']
   IF !EMPTY(hIniData['Destinatario']['CEP']) .AND. hIniData['Destinatario']['UF'] <>'EX'  // Mauricio Cruz - 04/10/2011 (Motivo de exportacao)
	   ::aDest[ "CEP" ] := hIniData['Destinatario']['CEP']
   ENDIF
	TRY
	   IF !EMPTY( hIniData['Destinatario']['PaisCod'] )
      	::aDest[ "cPais" ] := hIniData['Destinatario']['PaisCod']
      	::aDest[ "xPais" ] := hIniData['Destinatario']['Pais']
      ELSE
      	::aDest[ "cPais" ] := '1058'
      	::aDest[ "xPais" ] := 'BRASIL'
      ENDIF
	CATCH
   	::aDest[ "cPais" ] := '1058'
    	::aDest[ "xPais" ] := 'BRASIL'
	END



   TRY   // Alterado - Mauricio Cruz - 30/09/2011
      IF !EMPTY( hIniData['Destinatario']['Fone'] )
         ::aDest[ "fone" ] := oFuncoes:eliminaString(hIniData['Destinatario']['Fone'], ".-/ ()")
      ELSE
         ::aDest[ "fone" ] := ''
      ENDIF
   CATCH
      ::aDest[ "fone" ] := ''
   END

   TRY           // Alterado por Anderson Camilo 25/10/2011
      ::aDest[ "IE" ] := oFuncoes:eliminaString(hIniData['Destinatario']['IE'], ".-/ ")
   CATCH
      ::aDest[ "IE" ] := ''
   END

	TRY
   	::aDest[ "ISUF" ] := hIniData['Destinatario']['ISUF']
	CATCH
   	::aDest[ "ISUF" ] := ''
	END
	TRY
   	::aDest[ "email" ] := hIniData['Destinatario']['Email']
	CATCH
   	::aDest[ "email" ] := ''
	END

	::aRetirada := hash()
	TRY
    	::aRetirada[ "CNPJ" ]    := hIniData['Retirada']['CNPJ']
    	::aRetirada[ "CPF" ]     := hIniData['Retirada']['CPF']
    	::aRetirada[ "xLgr" ]    := oFuncoes:parseEncode( hIniData['Retirada']['xLgr'] )
    	::aRetirada[ "nro" ]     := hIniData['Retirada']['nro']
    	::aRetirada[ "xCpl" ]    := oFuncoes:parseEncode( hIniData['Retirada']['xCpl'] )
    	::aRetirada[ "xBairro" ] := oFuncoes:parseEncode( hIniData['Retirada']['xBairro'] )
    	::aRetirada[ "cMun" ]    := hIniData['Retirada']['cMun']
    	::aRetirada[ "xMun" ]    := oFuncoes:parseEncode( hIniData['Retirada']['xMun'] )
    	::aRetirada[ "UF" ]      := hIniData['Retirada']['UF']
	CATCH
	END

	::aEntrega := hash()
	TRY
      TRY
    	   ::aEntrega[ "CNPJ" ]    := hIniData['Entrega']['CNPJ']
      CATCH
         ::aEntrega[ "CNPJ" ]    := ''
      END
      TRY
    	   ::aEntrega[ "CPF" ]     := hIniData['Entrega']['CPF']
      CATCH
         ::aEntrega[ "CPF" ]     := ''
      END
    	::aEntrega[ "xLgr" ]    := oFuncoes:parseEncode( hIniData['Entrega']['xLgr'] )
    	::aEntrega[ "nro" ]     := hIniData['Entrega']['nro']
    	::aEntrega[ "xCpl" ]    := oFuncoes:parseEncode( hIniData['Entrega']['xCpl'] )
    	::aEntrega[ "xBairro" ] := oFuncoes:parseEncode( hIniData['Entrega']['xBairro'] )
    	::aEntrega[ "cMun" ]    := hIniData['Entrega']['cMun']
    	::aEntrega[ "xMun" ]    := oFuncoes:parseEncode( hIniData['Entrega']['xMun'] )
    	::aEntrega[ "UF" ]      := hIniData['Entrega']['UF']
	CATCH
	END

 	::aItem := hash()
 	::aItemDI := hash()
  	::aItemAdi := hash()
 	::aItemICMS := hash()
  	::aItemIPI := hash()
  	::aItemII := hash()
  	::aItemPIS := hash()
  	::aItemPISST := hash()
	::aItemCOFINS := hash()
	::aItemCOFINSST := hash()
	::aItemCOMB := hash()

   nItem := 0
   DO WHILE .T.
      nItem ++
    	TRY
       	::aItem[ "item"+STRZERO(nItem,3)+"_cProd" ] := hIniData['Produto'+STRZERO(nItem,3)]['Codigo']
    	CATCH
    	   nItem --
       	EXIT
    	END

    	TRY
       	::aItem[ "item"+STRZERO(nItem,3)+"_cEAN" ]     := hIniData['Produto'+STRZERO(nItem,3)]['EAN']
    	CATCH
       	::aItem[ "item"+STRZERO(nItem,3)+"_cEAN" ]     := ''
    	END
    	::aItem[ "item"+STRZERO(nItem,3)+"_xProd" ]    := oFuncoes:parseEncode( hIniData['Produto'+STRZERO(nItem,3)]['Descricao'] )
    	::aItem[ "item"+STRZERO(nItem,3)+"_NCM" ]      := hIniData['Produto'+STRZERO(nItem,3)]['NCM']
    	TRY
       	::aItem[ "item"+STRZERO(nItem,3)+"_EXTIPI" ]   := hIniData['Produto'+STRZERO(nItem,3)]['EXTIPI']
    	CATCH
    	END
    	::aItem[ "item"+STRZERO(nItem,3)+"_CFOP" ]     := hIniData['Produto'+STRZERO(nItem,3)]['CFOP']
    	::aItem[ "item"+STRZERO(nItem,3)+"_uCom" ]     := hIniData['Produto'+STRZERO(nItem,3)]['Unidade']
    	::aItem[ "item"+STRZERO(nItem,3)+"_qCom" ]     := oFuncoes:strTostrval( hIniData['Produto'+STRZERO(nItem,3)]['Quantidade'] , 4 )
    	::aItem[ "item"+STRZERO(nItem,3)+"_vUnCom" ]   := oFuncoes:strTostrval( hIniData['Produto'+STRZERO(nItem,3)]['ValorUnitario'], 5 )
    	::aItem[ "item"+STRZERO(nItem,3)+"_vProd" ]    := oFuncoes:strTostrval( hIniData['Produto'+STRZERO(nItem,3)]['ValorTotal'] )
    	TRY
       	::aItem[ "item"+STRZERO(nItem,3)+"_cEANTrib" ] := hIniData['Produto'+STRZERO(nItem,3)]['cEANTrib']
    	CATCH
       	::aItem[ "item"+STRZERO(nItem,3)+"_cEANTrib" ] := ''
    	END
    	TRY
       	::aItem[ "item"+STRZERO(nItem,3)+"_uTrib" ]    := hIniData['Produto'+STRZERO(nItem,3)]['uTrib']
      CATCH
       	::aItem[ "item"+STRZERO(nItem,3)+"_uTrib" ]    := hIniData['Produto'+STRZERO(nItem,3)]['Unidade']
     END
    	TRY
      	::aItem[ "item"+STRZERO(nItem,3)+"_qTrib" ]    := hIniData['Produto'+STRZERO(nItem,3)]['qTrib']
      CATCH
      	::aItem[ "item"+STRZERO(nItem,3)+"_qTrib" ]    := '0.00'
     END
    	TRY
      	::aItem[ "item"+STRZERO(nItem,3)+"nFCI" ]    := hIniData['Produto'+STRZERO(nItem,3)]['nFCI']
      CATCH
     END
    	TRY
       	::aItem[ "item"+STRZERO(nItem,3)+"_vUnTrib" ]  := oFuncoes:strTostrval( hIniData['Produto'+STRZERO(nItem,3)]['vUnTrib'] )
      CATCH
       	::aItem[ "item"+STRZERO(nItem,3)+"_vUnTrib" ]  := oFuncoes:strTostrval( hIniData['Produto'+STRZERO(nItem,3)]['ValorUnitario'], 5 )
     END
    	TRY
       	::aItem[ "item"+STRZERO(nItem,3)+"_vFrete" ]   := oFuncoes:strTostrval( hIniData['Produto'+STRZERO(nItem,3)]['vFrete'] )
    	CATCH
    	END
    	TRY
      	::aItem[ "item"+STRZERO(nItem,3)+"_vSeg" ]     := oFuncoes:strTostrval( hIniData['Produto'+STRZERO(nItem,3)]['vSeg'] )
    	CATCH
    	END
    	TRY
      	::aItem[ "item"+STRZERO(nItem,3)+"_vDesc" ]    := oFuncoes:strTostrval( hIniData['Produto'+STRZERO(nItem,3)]['ValorDesconto'] )
    	CATCH
    	END
    	TRY
      	::aItem[ "item"+STRZERO(nItem,3)+"_vOutro" ]   := oFuncoes:strTostrval( hIniData['Produto'+STRZERO(nItem,3)]['vOutro'] )
    	CATCH
    	END
    	TRY
      	::aItem[ "item"+STRZERO(nItem,3)+"_indTot" ]   := hIniData['Produto'+STRZERO(nItem,3)]['IndTot']
    	CATCH
      	::aItem[ "item"+STRZERO(nItem,3)+"_indTot" ]   := '1'
    	END
    	TRY
      	::aItem[ "item"+STRZERO(nItem,3)+"_infAdProd" ]   := hIniData['Produto'+STRZERO(nItem,3)]['infAdProd']
    	CATCH
    	END

    	TRY
      	::aItem[ "item"+STRZERO(nItem,3)+"_xPed" ]     := hIniData['Produto'+STRZERO(nItem,3)]['xPed']
    	CATCH
    	END
    	TRY
      	::aItem[ "item"+STRZERO(nItem,3)+"_nItemPed" ] := hIniData['Produto'+STRZERO(nItem,3)]['nItemPed']
    	CATCH
    	END

      TRY
	     	::aItemCOMB[ "item"+STRZERO(nItem,3)+"_cProdANP" ] := hIniData['comb'+STRZERO(nItem,3)]['cProdANP']
			::aItemCOMB[ "item"+STRZERO(nItem,3)+"_CODIF" ] := hIniData['comb'+STRZERO(nItem,3)]['CODIF']
			::aItemCOMB[ "item"+STRZERO(nItem,3)+"_qTemp" ] := oFuncoes:strTostrval( hIniData['comb'+STRZERO(nItem,3)]['qTemp'] , 4 )
			::aItemCOMB[ "item"+STRZERO(nItem,3)+"_UFCons" ] := hIniData['comb'+STRZERO(nItem,3)]['UFCons']
		CATCH
		END


      nDi := 0
      DO WHILE .T.
         nDi ++
        	TRY
            // alterado -> Mauricio Cruz - 04/10/2011
           	//::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+"_nDI" ] := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['nDI']
            ::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+"_nDI" ] := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['NumeroDI']
        	CATCH
        	   nDi --
           	EXIT
        	END
         /* alterado -> Mauricio Cruz - 04/10/2011
      	::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+"_dDI" ]         := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['dDI']
      	::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+"_xLocDesemb" ]  := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['xLocDesemb']
      	::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+"_UFDesemb" ]    := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['UFDesemb']
      	::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+"_dDesemb" ]     := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['dDesemb']
      	::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+"_cExportador" ] := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['cExportador']
         */
      	::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+"_dDI" ]         := STR(YEAR(CTOD(hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['DataRegistroDI'])),4)+'-'+;
                                                                               STRZERO(MONTH(CTOD(hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['DataRegistroDI'])),2)+'-'+;
                                                                               STRZERO(DAY(CTOD(hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['DataRegistroDI'])),2)
      	::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+"_xLocDesemb" ]  := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['LocalDesembaraco']
      	::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+"_UFDesemb" ]    := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['UFDesembaraco']
      	::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+"_dDesemb" ]     := STR(YEAR(CTOD(hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['DataDesembaraco'])),4)+'-'+;
                                                                               STRZERO(MONTH(CTOD(hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['DataDesembaraco'])),2)+'-'+;
                                                                               STRZERO(DAY(CTOD(hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['DataDesembaraco'])),2)
      	::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+"_cExportador" ] := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)]['CodigoExportador']


         nAdi := 0
         DO WHILE .T.
            nAdi++  //  nDi ++  Mauricio Cruz - 04/10/2011
          	TRY
               //alterado -> Mauricio Cruz - 04/10/2011
             	//::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_nAdicao" ] := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)]['nAdicao']
               ::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_nAdicao" ] := hIniData['LADI'+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)]['NumeroAdicao']
          	CATCH
          	   nAdi--   //nDi --  Mauricio Cruz - 04/10/2011
             	EXIT
          	END
            /*  alterado -> Mauricio Cruz - 04/10/2011
          	::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_nSeqAdic" ] := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)]['nSeqAdic']
          	::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_cFabricante" ] := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)]['cFabricante']
          	::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_vDescDI" ]     := hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)]['vDescDI']
            */

          	::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_nSeqAdic" ] := ALLTRIM(STR(nAdi))    //hIniData['DI'+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)]['nSeqAdic']
          	::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_cFabricante" ] := hIniData['LADI'+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)]['CodigoFabricante']
          	::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_vDescDI" ]     := hIniData['LADI'+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)]['DescontoADI']
         ENDDO
      ENDDO

      IF ::lMostra_imp_danfe
         TRY // valor aproximado do imposto
            ::aItemICMS[ "item"+STRZERO(nItem,3)+"vTotTrib" ] := hIniData['IMPOSTO'+STRZERO(nItem,3)]['vTotTrib']
         CATCH
            ::aItemICMS[ "item"+STRZERO(nItem,3)+"vTotTrib" ] := '0.00'
         END
      ENDIF

      TRY
         IF !EMPTY( hIniData['ICMS'+STRZERO(nItem,3)]['Origem'] )
            ::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ]        := hIniData['ICMS'+STRZERO(nItem,3)]['Origem']
         ELSE
            ::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ]        := '0'
         ENDIF
      CATCH
         ::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ]        := '0'
      END
      IF ::aEmit[ "CRT" ] == '3'
        	::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ]       := ''
      	TRY
         	::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ]         := hIniData['ICMS'+STRZERO(nItem,3)]['CST']
      	CATCH
      	END
      ELSE
        	::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ]         := ''
      	TRY
         	::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ]       := hIniData['ICMS'+STRZERO(nItem,3)]['CSOSN']
      	CATCH
      	END
      ENDIF
    	TRY
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBC" ]       := hIniData['ICMS'+STRZERO(nItem,3)]['Modalidade']
    	CATCH
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBC" ]       := '0'
    	END
    	TRY
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBC" ]      := hIniData['ICMS'+STRZERO(nItem,3)]['PercentualReducao']
    	CATCH
         ::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBC" ]      := '0.00'
    	END
    	TRY
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBC" ]         := hIniData['ICMS'+STRZERO(nItem,3)]['ValorBase']
    	CATCH
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBC" ]         := '0.00'
    	END
    	TRY
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMS" ]       := hIniData['ICMS'+STRZERO(nItem,3)]['Aliquota']
    	CATCH
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMS" ]       := '0.00'
    	END
    	TRY
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMS" ]       := hIniData['ICMS'+STRZERO(nItem,3)]['Valor']
    	CATCH
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMS" ]       := '0.00'
    	END
    	TRY
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBCST" ]     := hIniData['ICMS'+STRZERO(nItem,3)]['ModalidadeST']
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ]      := hIniData['ICMS'+STRZERO(nItem,3)]['PercentualMargemST']
    	CATCH
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBCST" ]     := '0'
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ]      := '0.00'
    	END
    	TRY
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ]    := hIniData['ICMS'+STRZERO(nItem,3)]['PercentualReducaoST']
    	CATCH
         ::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ]    := '0.00'    // Mauricio Cruz - 04/10/2011
    	END
    	TRY
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCST" ]       := hIniData['ICMS'+STRZERO(nItem,3)]['ValorBaseST']
      CATCH
         ::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCST" ]       := '0.00'
      END
      TRY
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMSST" ]     := hIniData['ICMS'+STRZERO(nItem,3)]['AliquotaST']
      CATCH
         ::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMSST" ]     := '0.00'
      END
      TRY
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSST" ]     := hIniData['ICMS'+STRZERO(nItem,3)]['ValorST']
      CATCH
         ::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSST" ]     := '0.00'
      END
      TRY
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_UFST" ]        := hIniData['ICMS'+STRZERO(nItem,3)]['UFST']
    	CATCH
       	::aItemICMS[ "item"+STRZERO(nItem,3)+"_UFST" ]        := '0.00'
    	END
    	TRY
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_pBCOp" ]       := hIniData['ICMS'+STRZERO(nItem,3)]['pBCOp']
    	CATCH
    	END
    	TRY
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCSTRet" ]    := hIniData['ICMS'+STRZERO(nItem,3)]['vBCSTRet']
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSSTRet" ]  := hIniData['ICMS'+STRZERO(nItem,3)]['vICMSSTRet']
    	CATCH
      	TRY
         	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCSTRet" ]    := hIniData['ICMS'+STRZERO(nItem,3)]['vBCSTret']
         	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSSTRet" ]  := hIniData['ICMS'+STRZERO(nItem,3)]['vICMSSTret']
      	CATCH
      	END
    	END
    	TRY
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_motDesICMS" ]  := hIniData['ICMS'+STRZERO(nItem,3)]['motDesICMS']
    	CATCH
    	END
    	TRY
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_pCredSN" ]     := hIniData['ICMS'+STRZERO(nItem,3)]['pCredSN']
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vCredICMSSN" ] := hIniData['ICMS'+STRZERO(nItem,3)]['vCredICMSSN']
    	CATCH
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_pCredSN" ]     := '0.00'
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vCredICMSSN" ] := '0.00'
    	END
    	TRY
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCSTDest" ]   := hIniData['ICMS'+STRZERO(nItem,3)]['vBCSTDest']
      	::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSSTDest" ] := hIniData['ICMS'+STRZERO(nItem,3)]['vICMSSTDest']
    	CATCH
    	END

     	TRY
      	::aItemIPI[ "item"+STRZERO(nItem,3)+"_clEnq" ]    := hIniData['IPI'+STRZERO(nItem,3)]['ClasseEnquadramento']
      CATCH
      END
     	TRY
      	::aItemIPI[ "item"+STRZERO(nItem,3)+"_CNPJProd" ] := hIniData['IPI'+STRZERO(nItem,3)]['CNPJProdutor']
      CATCH
      END
     	TRY
      	::aItemIPI[ "item"+STRZERO(nItem,3)+"_cSelo" ]    := hIniData['IPI'+STRZERO(nItem,3)]['CodigoSeloIPI']
      	::aItemIPI[ "item"+STRZERO(nItem,3)+"_qSelo" ]    := hIniData['IPI'+STRZERO(nItem,3)]['QuantidadeSelos']
      CATCH
      END
     	TRY
      	::aItemIPI[ "item"+STRZERO(nItem,3)+"_cEnq" ]     := hIniData['IPI'+STRZERO(nItem,3)]['CodigoEnquadramento']
      CATCH
      	::aItemIPI[ "item"+STRZERO(nItem,3)+"_cEnq" ]     := '999'
      END

     	TRY
       	::aItemIPI[ "item"+STRZERO(nItem,3)+"_CST" ]   := hIniData['IPI'+STRZERO(nItem,3)]['CST']
      	::aItemIPI[ "item"+STRZERO(nItem,3)+"_vBC" ]   := hIniData['IPI'+STRZERO(nItem,3)]['ValorBase']
      	::aItemIPI[ "item"+STRZERO(nItem,3)+"_pIPI" ]  := hIniData['IPI'+STRZERO(nItem,3)]['Aliquota']
      CATCH
      END
     	TRY
       	::aItemIPI[ "item"+STRZERO(nItem,3)+"_qUnid" ] := hIniData['IPI'+STRZERO(nItem,3)]['Quantidade']
      CATCH
      END
     	TRY
      	::aItemIPI[ "item"+STRZERO(nItem,3)+"_vUnid" ] := hIniData['IPI'+STRZERO(nItem,3)]['ValorUnidade']
      CATCH
      END
     	TRY
      	::aItemIPI[ "item"+STRZERO(nItem,3)+"_vIPI" ]  := hIniData['IPI'+STRZERO(nItem,3)]['Valor']
      CATCH
      END

     	TRY
      	::aItemII[ "item"+STRZERO(nItem,3)+"_vBC" ]      := hIniData['II'+STRZERO(nItem,3)]['ValorBase']
      	::aItemII[ "item"+STRZERO(nItem,3)+"_vDespAdu" ] := hIniData['II'+STRZERO(nItem,3)]['ValorDespAduaneiras']
      	::aItemII[ "item"+STRZERO(nItem,3)+"_vII" ]      := hIniData['II'+STRZERO(nItem,3)]['ValorII']
      	::aItemII[ "item"+STRZERO(nItem,3)+"_vIOF" ]     := hIniData['II'+STRZERO(nItem,3)]['ValorIOF']
      CATCH
      END

      TRY
      	::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] := hIniData['PIS'+STRZERO(nItem,3)]['CST']
      	IF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '01,02'
         	::aItemPIS[ "item"+STRZERO(nItem,3)+"_vBC" ]  := oFuncoes:strTostrval( hIniData['PIS'+STRZERO(nItem,3)]['ValorBase'] )
         	::aItemPIS[ "item"+STRZERO(nItem,3)+"_pPIS" ] := hIniData['PIS'+STRZERO(nItem,3)]['Aliquota']
      	   ::aItemPIS[ "item"+STRZERO(nItem,3)+"_vPIS" ] := oFuncoes:strTostrval( hIniData['PIS'+STRZERO(nItem,3)]['Valor'] )
      	ELSEIF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '03'
         	::aItemPIS[ "item"+STRZERO(nItem,3)+"_qBCProd" ]   := oFuncoes:strTostrval( hIniData['PIS'+STRZERO(nItem,3)]['Quantidade'], 4 )
         	::aItemPIS[ "item"+STRZERO(nItem,3)+"_vAliqProd" ] := oFuncoes:strTostrval( hIniData['PIS'+STRZERO(nItem,3)]['ValorAliquota'], 4 )
      	   ::aItemPIS[ "item"+STRZERO(nItem,3)+"_vPIS" ]      := oFuncoes:strTostrval( hIniData['PIS'+STRZERO(nItem,3)]['Valor'] )
      	ELSEIF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '99,49,50,51,52,53,54,55,56,60,61,62,63,64,65,66,67,70,71,72,73,74,75,98'
         	::aItemPIS[ "item"+STRZERO(nItem,3)+"_vBC" ]       := oFuncoes:strTostrval( hIniData['PIS'+STRZERO(nItem,3)]['ValorBase'] )
         	::aItemPIS[ "item"+STRZERO(nItem,3)+"_vPIS" ]      := oFuncoes:strTostrval( hIniData['PIS'+STRZERO(nItem,3)]['Valor'] )
           TRY
           	::aItemPIS[ "item"+STRZERO(nItem,3)+"_qBCProd" ]   := oFuncoes:strTostrval( hIniData['PIS'+STRZERO(nItem,3)]['Quantidade'], 4)
           CATCH
           END
           TRY
           	::aItemPIS[ "item"+STRZERO(nItem,3)+"_vAliqProd" ] := oFuncoes:strTostrval( hIniData['PIS'+STRZERO(nItem,3)]['ValorAliquota'], 4 )
           CATCH
           END
           TRY
         	   ::aItemPIS[ "item"+STRZERO(nItem,3)+"_pPIS" ]      := oFuncoes:strTostrval( hIniData['PIS'+STRZERO(nItem,3)]['Aliquota'] )
           CATCH
         	   ::aItemPIS[ "item"+STRZERO(nItem,3)+"_pPIS" ]      := '0.00'
           END
        ENDIF
      CATCH
      	::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] := '01'
      	::aItemPIS[ "item"+STRZERO(nItem,3)+"_vBC" ]  := '0.00'
        	::aItemPIS[ "item"+STRZERO(nItem,3)+"_pPIS" ] := '0.00'
     	   ::aItemPIS[ "item"+STRZERO(nItem,3)+"_vPIS" ] := '0.00'
      END

     	TRY
      	::aItemPISST[ "vBC" ]       := hIniData['PISST'+STRZERO(nItem,3)]['ValorBase']
      	::aItemPISST[ "pPIS" ]      := hIniData['PISST'+STRZERO(nItem,3)]['AliquotaPerc']
      	::aItemPISST[ "vPIS" ]      := hIniData['PISST'+STRZERO(nItem,3)]['ValorPISST']
      	::aItemPISST[ "qBCProd" ]   := hIniData['PISST'+STRZERO(nItem,3)]['Quantidade']
      	::aItemPISST[ "vAliqProd" ] := hIniData['PISST'+STRZERO(nItem,3)]['AliquotaValor']
      CATCH
      END

     	TRY
        	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] := hIniData['COFINS'+STRZERO(nItem,3)]['CST']
        	IF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '01,02'
          	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vBC" ]     := hIniData['COFINS'+STRZERO(nItem,3)]['ValorBase']
          	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_pCOFINS" ] := hIniData['COFINS'+STRZERO(nItem,3)]['Aliquota']
          	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vCOFINS" ] := oFuncoes:strTostrval( hIniData['COFINS'+STRZERO(nItem,3)]['Valor'] )
        	ELSEIF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '03'
          	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_qBCProd" ]   := hIniData['COFINS'+STRZERO(nItem,3)]['Quantidade']
          	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vAliqProd" ] := hIniData['COFINS'+STRZERO(nItem,3)]['ValorAliquota']
          	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vCOFINS" ]   := oFuncoes:strTostrval( hIniData['COFINS'+STRZERO(nItem,3)]['Valor'] )
        	ELSEIF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '99,49,50,51,52,53,54,55,56,60,61,62,63,64,65,66,67,70,71,72,73,74,75,98'
          	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vBC" ]       := oFuncoes:strTostrval( hIniData['COFINS'+STRZERO(nItem,3)]['ValorBase'] )
          	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vCOFINS" ]   := oFuncoes:strTostrval( hIniData['COFINS'+STRZERO(nItem,3)]['Valor'] )
             TRY
             	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_qBCProd" ]   := hIniData['COFINS'+STRZERO(nItem,3)]['Quantidade']
             CATCH
             END
             TRY
          	   ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vAliqProd" ] := hIniData['COFINS'+STRZERO(nItem,3)]['ValorAliquota']
             CATCH
             END
             TRY
             	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_pCOFINS" ]   := oFuncoes:strTostrval( hIniData['COFINS'+STRZERO(nItem,3)]['Aliquota'] )
             CATCH
             	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_pCOFINS" ]   := '0.00'
             END
        	ENDIF
      CATCH
        	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ]     := '01'
        	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vBC" ]     := '0.00'
        	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_pCOFINS" ] := '0.00'
        	::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vCOFINS" ] := '0.00'
      END

     	TRY
      	::aItemCOFINSST[ "vBC" ] := hIniData['COFINSST'+STRZERO(nItem,3)]['ValorBase']
      	::aItemCOFINSST[ "pCOFINS" ] := hIniData['COFINSST'+STRZERO(nItem,3)]['AliquotaPerc']
      	::aItemCOFINSST[ "vCOFINS" ] := hIniData['COFINSST'+STRZERO(nItem,3)]['ValorCOFINSST']
      	::aItemCOFINSST[ "qBCProd" ] := hIniData['COFINSST'+STRZERO(nItem,3)]['Quantidade']
      	::aItemCOFINSST[ "vAliqProd" ] := hIniData['COFINSST'+STRZERO(nItem,3)]['AliquotaValor']
      CATCH
      END
   ENDDO

 	// totais da NF
	::aICMSTotal := hash()
   TRY
	   ::aICMSTotal[ "vBC" ] := oFuncoes:strTostrval( hIniData['Total']['BaseICMS'] )
   CATCH
      ::aICMSTotal[ "vBC" ] := '0.00'
   END
   TRY
	   ::aICMSTotal[ "vICMS" ] := oFuncoes:strTostrval( hIniData['Total']['ValorICMS'] )
   CATCH
      ::aICMSTotal[ "vICMS" ] := '0.00'
   END
   TRY
	   ::aICMSTotal[ "vBCST" ] := oFuncoes:strTostrval( hIniData['Total']['BaseICMSSubstituicao'] )
   CATCH
      ::aICMSTotal[ "vBCST" ] := '0.00'
   END
   TRY
	   ::aICMSTotal[ "vST" ] := oFuncoes:strTostrval( hIniData['Total']['ValorICMSSubstituicao'] )
   CATCH
      ::aICMSTotal[ "vST" ] := '0.00'
   END
   TRY
	   ::aICMSTotal[ "vProd" ] := oFuncoes:strTostrval( hIniData['Total']['ValorProduto'] )
   CATCH
      ::aICMSTotal[ "vProd" ] := '0.00'
   END
   TRY
	   ::aICMSTotal[ "vFrete" ] := oFuncoes:strTostrval( hIniData['Total']['ValorFrete'] )
   CATCH
      ::aICMSTotal[ "vFrete" ] := '0.00'
   END
  	TRY
    	::aICMSTotal[ "vSeg" ] := oFuncoes:strTostrval( hIniData['Total']['ValorSeguro'] )
   CATCH
    	::aICMSTotal[ "vSeg" ] := '0.00'
   END
  	TRY
   	::aICMSTotal[ "vDesc" ] := oFuncoes:strTostrval( hIniData['Total']['ValorDesconto'] )
   CATCH
   	::aICMSTotal[ "vDesc" ] := '0.00'
   END
  	TRY
   	::aICMSTotal[ "vII" ] := oFuncoes:strTostrval( hIniData['Total']['ValorII'] )
   CATCH
   	::aICMSTotal[ "vII" ] := '0.00'
   END
  	TRY
   	::aICMSTotal[ "vIPI" ] := oFuncoes:strTostrval( hIniData['Total']['ValorIPI'] )
   CATCH
   	::aICMSTotal[ "vIPI" ] := '0.00'
   END
  	TRY
   	::aICMSTotal[ "vPIS" ] := oFuncoes:strTostrval( hIniData['Total']['ValorPIS'] )
   CATCH
   	::aICMSTotal[ "vPIS" ] := '0.00'
   END
  	TRY
   	::aICMSTotal[ "vCOFINS" ] := oFuncoes:strTostrval( hIniData['Total']['ValorCOFINS'] )
   CATCH
   	::aICMSTotal[ "vCOFINS" ] := '0.00'
   END
  	TRY
   	::aICMSTotal[ "vOutro" ] := oFuncoes:strTostrval( hIniData['Total']['ValorOutrasDespesas'] )
   CATCH
   	::aICMSTotal[ "vOutro" ] := '0.00'
   END
   TRY
  	   ::aICMSTotal[ "vNF" ] := oFuncoes:strTostrval( hIniData['Total']['ValorNota'] )
   CATCH
      ::aICMSTotal[ "vNF" ] := '0.00'
      *SHOWMSG('Houve um erro ao tentar localizar o valor total da nota fiscal.')
      *IF _USUARIO()='SYGECOM'
      *   SHOWMSG_EDIT(VALTOPRG(hIniData))
      *ENDIF
   END

   IF ::lMostra_imp_danfe
      ::aICMSTotal[ "vTotTrib" ] := oFuncoes:strTostrval( hIniData['Total']['vTotTrib'] )
   ENDIF

	::aISSTotal := hash()
	TRY
    	::aISSTotal[ "vServ" ] := hIniData['Total']['ValorServicos']
    	::aISSTotal[ "vBC" ] := hIniData['Total']['ValorBaseISS']
    	::aISSTotal[ "vISS" ] := hIniData['Total']['ValorISSQN']
    	::aISSTotal[ "vPIS" ] := hIniData['Total']['ValorPISISS']
    	::aISSTotal[ "vCOFINS" ] := hIniData['Total']['ValorCONFINSISS']
	CATCH
	END

	::aRetTrib := hash()
	TRY
    	::aRetTrib[ "vRetPIS" ] := hIniData['Total']['vRetPIS']
    	::aRetTrib[ "vRetCOFINS" ] := hIniData['Total']['vRetCOFINS']
    	::aRetTrib[ "vRetCSLL" ] := hIniData['Total']['vRetCSLL']
    	::aRetTrib[ "vBCIRRF" ] := hIniData['Total']['vBCIRRF']
    	::aRetTrib[ "vIRRF" ] := hIniData['Total']['vIRRF']
    	::aRetTrib[ "vBCRetPrev" ] := hIniData['Total']['vBCRetPrev']
    	::aRetTrib[ "vRetPrev" ] := hIniData['Total']['vRetPrev']
	CATCH
	END

	::aTransp := hash()
	TRY
    	::aTransp[ "modFrete" ] := hIniData['Transportador']['Freteporconta']
	CATCH
   	TRY
       	::aTransp[ "modFrete" ] := hIniData['Transportador']['FretePorConta']
      CATCH
       	::aTransp[ "modFrete" ] := '0'
      END
	END
	IF EMPTY(::aTransp[ "modFrete" ])
     	::aTransp[ "modFrete" ] := '0'
	ENDIF
	TRY
      IF LEN( hIniData['Transportador']['CnpjCpf'] ) <= 11
      	IF !EMPTY( hIniData['Transportador']['CnpjCpf'] )
          	::aTransp[ "CPF" ] := hIniData['Transportador']['CnpjCpf']
         ENDIF
      ELSE
       	::aTransp[ "CNPJ" ] := hIniData['Transportador']['CnpjCpf']
      ENDIF
   CATCH
   END
   TRY
    	::aTransp[ "xNome" ] := oFuncoes:parseEncode( hIniData['Transportador']['NomeRazao'] )
   CATCH
   END
   TRY
    	IF !EMPTY( hIniData['Transportador']['IE'] )
       	::aTransp[ "IE" ] := hIniData['Transportador']['IE']
      ENDIF
   CATCH
   END
   TRY
    	IF !EMPTY( hIniData['Transportador']['Endereco'] )
       	::aTransp[ "xEnder" ] := oFuncoes:parseEncode( hIniData['Transportador']['Endereco'] )
      ENDIF
   CATCH
   END
   TRY
      IF !EMPTY(oFuncoes:parseEncode( hIniData['Transportador']['Cidade'] ))
    	   ::aTransp[ "xMun" ] := oFuncoes:parseEncode( hIniData['Transportador']['Cidade'] )
      ENDIF
   CATCH
   END
   TRY
    	::aTransp[ "UF" ] := hIniData['Transportador']['UF']
   CATCH
   END

   // retTransp
	::aRetTransp := hash()
	TRY
    	::aRetTransp[ "vServ" ] := hIniData['Transportador']['ValorServico']
    	::aRetTransp[ "vBCRet" ] := hIniData['Transportador']['ValorBase']
    	::aRetTransp[ "pICMSRet" ] := hIniData['Transportador']['Aliquota']
    	::aRetTransp[ "vICMSRet" ] := hIniData['Transportador']['Valor']
    	::aRetTransp[ "CFOP" ] := hIniData['Transportador']['CFOP']
    	::aRetTransp[ "cMunFG" ] := hIniData['Transportador']['CidadeCod']
	CATCH
	END
	// veicTransp
	::aVeicTransp := hash()
	TRY
   	::aVeicTransp[ "placa" ] := hIniData['Transportador']['Placa']
    ::aVeicTransp[ "placa" ] := STRTRAN(::aVeicTransp[ "placa" ], "-", "" )
    ::aVeicTransp[ "placa" ] := STRTRAN(::aVeicTransp[ "placa" ], " ", "" )
   CATCH
   END
	TRY
   	::aVeicTransp[ "UF" ] := hIniData['Transportador']['ufplaca']
	CATCH
   	TRY
      	::aVeicTransp[ "UF" ] := hIniData['Transportador']['UFPlaca']
      CATCH
      END
	END
	TRY
   	::aVeicTransp[ "RNTC" ] := hIniData['Transportador']['RNTC']
	CATCH
	END

	TRY
   	::aVeicTransp[ "vagao" ] := hIniData['Transportador']['vagao']
	CATCH
	END
	TRY
   	::aVeicTransp[ "balsa" ] := hIniData['Transportador']['balsa']
	CATCH
	END

	//reboque
	::aReboque := hash()
	TRY
    	::aReboque[ "placa" ] := hIniData['Reboque001']['placa']
     ::aReboque[ "placa" ] := STRTRAN(::aReboque[ "placa" ], "-", "" )
     ::aReboque[ "placa" ] := STRTRAN(::aReboque[ "placa" ], " ", "" )
    	::aReboque[ "UF" ] := hIniData['Reboque001']['UF']
	CATCH
	END
	TRY
    	::aReboque[ "RNTC" ] := hIniData['Reboque001']['RNTC']
	CATCH
	END
	// dados transportados
	TRY
      IF VAL(hIniData['Volume001']['quantidade'])>0
   	   ::aTransp[ "qVol" ] := hIniData['Volume001']['quantidade']
      ELSE
         ::aTransp[ "qVol" ] := '0'
      ENDIF
	CATCH
      ::aTransp[ "qVol" ] := '0'
	END
	TRY
      IF !EMPTY(hIniData['Volume001']['Especie'])    // Mauricio Cruz - 30/09/2011
   	   ::aTransp[ "esp" ] := hIniData['Volume001']['Especie']
      ENDIF
	CATCH
	END
	TRY
	   IF !EMPTY( hIniData['Volume001']['Marca'] )
      	::aTransp[ "marca" ] := hIniData['Volume001']['Marca']
    ENDIF
	CATCH
	END
	TRY
    IF !EMPTY( hIniData['Volume001']['Numeracao'] )
       ::aTransp[ "nVol" ] := hIniData['Volume001']['Numeracao']
    ENDIF
	CATCH
	END
	TRY
	   IF VAL( hIniData['Volume001']['PesoLiquido'] ) > 0
      	::aTransp[ "pesoL" ] := ALLTRIM( STR( VAL( hIniData['Volume001']['PesoLiquido'] ) ,20 ,3 ) )
     ENDIF
	CATCH
     	::aTransp[ "pesoL" ] := '0.000'
	END
	TRY
	   IF VAL( hIniData['Volume001']['PesoBruto'] ) > 0
      	::aTransp[ "pesoB" ] := ALLTRIM( STR( VAL( hIniData['Volume001']['PesoBruto'] ) ,20 ,3 ) )
    ENDIF
	CATCH
     	::aTransp[ "pesoB" ] := '0.000'
	END

	TRY
   	::aTransp[ "nLacre" ] := hIniData['Lacre001001']['nLacre']
	CATCH
	END

	::aFatura := hash()
	TRY
    	::aFatura[ "nFat" ] := hIniData['Fatura']['Numero']
    	::aFatura[ "vOrig" ] := hIniData['Fatura']['ValorOriginal']
    	::aFatura[ "vDesc" ] := hIniData['Fatura']['ValorDesconto']
    	::aFatura[ "vLiq" ] := hIniData['Fatura']['ValorLiquido']
	CATCH
	END
	//Duplicatas
 	::aDuplicatas := hash()
   nICob := 0
   DO WHILE .T.
      nICob ++
    	TRY
       	::aDuplicatas[ "dup"+STRZERO(nICob,3)+"_nDup" ] := hIniData['Duplicata'+STRZERO(nICob,3)]['Numero']
    	CATCH
    	   nICob --
       	EXIT
    	END
    	::aDuplicatas[ "dup"+STRZERO(nICob,3)+"_dVenc" ] := oFuncoes:FormatDate(CTOD(hIniData['Duplicata'+STRZERO(nICob,3)]['DataVencimento']),"YYYY-MM-DD","-")
    	::aDuplicatas[ "dup"+STRZERO(nICob,3)+"_vDup" ] := oFuncoes:strTostrval( hIniData['Duplicata'+STRZERO(nICob,3)]['Valor'] )
   ENDDO

	::aInfAdic := hash()
   /*
	TRY
   	::aInfAdic[ "infAdFisco" ] := oFuncoes:parseEncode( hIniData['DadosAdicionais']['Fisco'] )
   CATCH
   END
	TRY
   	::aInfAdic[ "infCpl" ] := oFuncoes:parseEncode( hIniData['DadosAdicionais']['Complemento'] )
   CATCH
   END
   */

   // Maurício cruz - 27/10/2011
   IF !EMPTY(SYG_GetPrivateProfileString( 'DadosAdicionais', 'Fisco', , cIniFile ))
        //::aInfAdic[ "infAdFisco" ] := CLEAR_CHAR( oFuncoes:parseEncode( SYG_GetPrivateProfileString( 'DadosAdicionais', 'Fisco', , cIniFile ),.t. ) )
       TRY
         cOBSFISCO:=hIniData['DadosAdicionais']['Fisco']
       CATCH
         cOBSFISCO:=''
       END
       IF LEFT(cOBSFISCO,1) ='"'
       		 ::aInfAdic[ "infAdFisco" ] :=  CLEAR_CHAR('"' + oFuncoes:parseEncode(SYG_GetPrivateProfileString( 'DadosAdicionais', 'Fisco', , cIniFile ),.t.  ) +;
          if ( right( alltrim(hIniData['DadosAdicionais']['Fisco']) ,1)= '"' ,'"','' ) )
       ELSE
         ::aInfAdic[ "infAdFisco" ] := CLEAR_CHAR( oFuncoes:parseEncode( SYG_GetPrivateProfileString( 'DadosAdicionais', 'Fisco', , cIniFile ),.t. ) )
  	   ENDIF
   ENDIF

   IF !EMPTY(SYG_GetPrivateProfileString( 'DadosAdicionais', 'Complemento', , cIniFile ))
       //::aInfAdic[ "infCpl" ] := CLEAR_CHAR ( oFuncoes:parseEncode( SYG_GetPrivateProfileString( 'DadosAdicionais', 'Complemento', , cIniFile ),.t. ) )
      TRY
        cOBSADICIONAL:=hIniData['DadosAdicionais']['Complemento']
      CATCH
        cOBSADICIONAL:=''
      END
      IF LEFT(cOBSADICIONAL,1) ='"'
      		 ::aInfAdic[ "infCpl" ] :=  CLEAR_CHAR('"' + oFuncoes:parseEncode(SYG_GetPrivateProfileString( 'DadosAdicionais', 'Complemento', , cIniFile ),.t.  ) + ;
      		 if ( right( alltrim(hIniData['DadosAdicionais']['Complemento']) ,1)= '"' ,'"','' ) )
   	   ELSE
         ::aInfAdic[ "infCpl" ] := CLEAR_CHAR( oFuncoes:parseEncode( SYG_GetPrivateProfileString( 'DadosAdicionais', 'Complemento', , cIniFile ),.t. ) )
 	    ENDIF
   ENDIF

	//obsCont
 	::aObsCont := hash()
   nObs := 0
   DO WHILE .T.
      nObs ++
    	TRY
       	::aObsCont[ "obs"+STRZERO(nObs,3)+"_xCampo" ] := oFuncoes:parseEncode( hIniData['infAdic'+STRZERO(nObs,3)]['Campo'] )
    	CATCH
           EXIT
    	END
    	::aObsCont[ "obs"+STRZERO(nObs,3)+"_xTexto" ] := oFuncoes:parseEncode( hIniData['infAdic'+STRZERO(nObs,3)]['Texto'] )
   ENDDO
	//obsFisco
	::aObsFisco := hash()
   nObs := 0
   DO WHILE .T.
      nObs ++
    	TRY
       	::aObsFisco[ "obs"+STRZERO(nObs,3)+"_xCampo" ] := oFuncoes:parseEncode( hIniData['ObsFisco'+STRZERO(nObs,3)]['Campo'] )
    	CATCH
           EXIT
    	END
    	::aObsFisco[ "obs"+STRZERO(nObs,3)+"_xTexto" ] := oFuncoes:parseEncode( hIniData['ObsFisco'+STRZERO(nObs,3)]['Texto'] )
   ENDDO

   // processo referenciado
   ::aProcRef := hash()
   nObs := 0
   DO WHILE .T.
      nObs ++
    	TRY
       	::aObsFisco[ "pref"+STRZERO(nObs,3)+"_nProc" ] := hIniData['procRef'+STRZERO(nObs,3)]['nProc']
    	CATCH
        	EXIT
    	END
    	::aObsFisco[ "pref"+STRZERO(nObs,3)+"_indProc" ] := hIniData['procRef'+STRZERO(nObs,3)]['indProc']
   ENDDO


	::aExporta := hash()
	TRY
      ::aExporta[ "UFEmbarq" ] := hIniData['Exporta']['UFEmbarq']
      ::aExporta[ "xLocEmbarq" ] := hIniData['Exporta']['xLocEmbarq']
	CATCH
	END

	::aCompra := hash()
	TRY
    	::aCompra[ "xNEmp" ] := hIniData['Compra']['xNEmp']
    	::aCompra[ "xPed" ] := hIniData['Compra']['xPed']
    	::aCompra[ "xCont" ] := hIniData['Compra']['xCont']
	CATCH
	END

   ::REGRAS_NFE(@aMSGvld,cChaveNFe,nItem)
   IF LEN(aMSGvld)>0
      *IF !ERROS_ALERTAS_NFE(aMSGvld)
         aRetorno['OK'] := .F.
         aRetorno['MsgErro'] := ''
         RETURN(aRetorno)
      *ENDIF
   ENDIF

   ************************************************************************************************
   *                            CRIACAO DO ARQUIVO XML                                            *
   ************************************************************************************************






	::cXMLSaida := '<NFe xmlns="http://www.portalfiscal.inf.br/nfe">' + ;
	               '<infNFe versao="2.00" Id="NFe'+cChaveNFe+'">'
	::incluiTag('ide')
    	::incluiTag('cUF'     ,::aIde[ "cUF" ])
    	::incluiTag('cNF'     ,::aIde[ "cNF" ])
    	::incluiTag('natOp'   ,::aIde[ "natOp" ])
    	::incluiTag('indPag'  ,::aIde[ "indPag" ])
    	::incluiTag('mod'     ,::aIde[ "mod" ])
    	::incluiTag('serie'   ,::aIde[ "serie" ])
    	::incluiTag('nNF'     ,::aIde[ "nNF" ])
    	::incluiTag('dEmi'    ,::aIde[ "dEmi" ])
      IF !EMPTY(::aIde[ "dSaiEnt" ])
    	    ::incluiTag('dSaiEnt' ,::aIde[ "dSaiEnt" ])
      ENDIF
    	IF !EMPTY(::aIde[ "hSaiEnt" ])
       	::incluiTag('hSaiEnt' ,::aIde[ "hSaiEnt" ])
      ENDIF
    	::incluiTag('tpNF'    ,::aIde[ "tpNF" ])
    	::incluiTag('cMunFG'  ,::aIde[ "cMunFG" ])


      // NOTAS REFERENCIADAS   - Mauricio Cruz - 18/01/2012
      IF nItnRef>0
         ::incluiTag('NFref')
      ENDIF

      FOR mI:=1 TO nItnRef
         IF !EMPTY(::aRefNfe['refNFe'+STRZERO(mI,3)])
            ::incluiTag('refNFe'  ,::aRefNfe['refNFe'+STRZERO(mI,3)])
         ELSE
            TRY
               ::incluiTag('refNF',::aRefNfe['refNF' +STRZERO(mI,3)])
            CATCH
            END
            ::incluiTag('cUF'     ,::aRefNfe['cUF'   +STRZERO(mI,3)])
            ::incluiTag('AAMM'    ,::aRefNfe['AAMM'  +STRZERO(mI,3)])
            ::incluiTag('CNPJ'    ,::aRefNfe['CNPJ'  +STRZERO(mI,3)])
            ::incluiTag('mod'     ,::aRefNfe['mod'   +STRZERO(mI,3)])
            ::incluiTag('serie'   ,::aRefNfe['serie' +STRZERO(mI,3)])
            ::incluiTag('nNF'     ,::aRefNfe['nNF'   +STRZERO(mI,3)])
         ENDIF
      NEXT
      IF nItnRef>0
         ::incluiTag('/NFref')
      ENDIF

    	::incluiTag('tpImp'   ,::aIde[ "tpImp" ])
    	::incluiTag('tpEmis'  ,::aIde[ "tpEmis" ])
    	::incluiTag('cDV'     ,::aIde[ "cDV" ])
    	::incluiTag('tpAmb'   ,::aIde[ "tpAmb" ])
    	::incluiTag('finNFe'  ,::aIde[ "finNFe" ])
    	::incluiTag('procEmi' ,::aIde[ "procEmi" ])
    	::incluiTag('verProc' ,::aIde[ "verProc" ])
      IF VAL(::aIde[ "tpEmis" ])=3 .OR. VAL(::aIde[ "tpEmis" ])=5 .OR. VAL(::aIde[ "tpEmis" ])=6 .OR. VAL(::aIde[ "tpEmis" ])=7
         ::incluiTag('dhCont' ,::aIde[ "dhCont" ])
         ::incluiTag('xJust' ,::aIde[ "xJust" ])
      ENDIF
	::incluiTag('/ide')

	::incluiTag('emit')
    	::incluiTag('CNPJ'     ,::aEmit[ "CNPJ" ])
    	::incluiTag('xNome'    ,::aEmit[ "xNome" ])
      IF !EMPTY(::aEmit[ "xFant" ])
    	   ::incluiTag('xFant'    ,::aEmit[ "xFant" ])
      ENDIF
    	::incluiTag('enderEmit')
    	::incluiTag('xLgr'     ,::aEmit[ "xLgr" ])
    	::incluiTag('nro'      ,::aEmit[ "nro" ])
    	::incluiTag('xBairro'  ,::aEmit[ "xBairro" ])
    	::incluiTag('cMun'     ,::aEmit[ "cMun" ])
    	::incluiTag('xMun'     ,::aEmit[ "xMun" ])
    	::incluiTag('UF'       ,::aEmit[ "UF" ])
    	::incluiTag('CEP'      ,::aEmit[ "CEP" ])
    	::incluiTag('cPais'    ,::aEmit[ "cPais" ])
    	::incluiTag('xPais'    ,::aEmit[ "xPais" ])
      IF !EMPTY(::aEmit[ "fone" ])
    	   ::incluiTag('fone'     ,::aEmit[ "fone" ])
      ENDIF
    	::incluiTag('/enderEmit')
    	::incluiTag('IE'       ,::aEmit[ "IE" ])
    	IF !EMPTY(::aEmit[ "IEST" ])
       	::incluiTag('IEST'  ,::aEmit[ "IEST" ])
      ENDIF
    	IF !EMPTY(::aEmit[ "IM" ])
       	::incluiTag('IM'    ,::aEmit[ "IM" ])
       	::incluiTag('CNAE'  ,::aEmit[ "CNAE" ])
      ENDIF
    	::incluiTag('CRT'      ,::aEmit[ "CRT" ])
	::incluiTag('/emit')

	::incluiTag('dest')
	   TRY
       	::incluiTag('CNPJ'     ,::aDest[ "CNPJ" ])
      CATCH
       	::incluiTag('CPF'      ,::aDest[ "CPF" ])
      END
    	::incluiTag('xNome'    ,::aDest[ "xNome" ])
    	::incluiTag('enderDest')
    	::incluiTag('xLgr'     ,::aDest[ "xLgr" ])
    	::incluiTag('nro'      ,::aDest[ "nro" ])
    	::incluiTag('xBairro'  ,::aDest[ "xBairro" ])
    	::incluiTag('cMun'     ,::aDest[ "cMun" ])
    	::incluiTag('xMun'     ,::aDest[ "xMun" ])
    	::incluiTag('UF'       ,::aDest[ "UF" ])

      TRY   // Mauricio Cruz  04/10/2011 (Motivo de exportacao)
    	   ::incluiTag('CEP'      ,::aDest[ "CEP" ])
      CATCH
         IF ::aDest[ "UF" ] <> 'EX'
            aRetorno['OK'] := .F.
            aRetorno['MsgErro'] := 'CEP Destinatário não valido'
            RETURN(aRetorno)
         ENDIF
      END
    	::incluiTag('cPais'    ,::aDest[ "cPais" ])
    	::incluiTag('xPais'    ,::aDest[ "xPais" ])

      // Mauricio Cruz - 30/09/2011
    	//::incluiTag('fone'     ,::aDest[ "fone" ])
    	IF !EMPTY(::aDest[ "fone" ])
       	::incluiTag('fone'    ,::aDest[ "fone" ])
      ENDIF

    	::incluiTag('/enderDest')
    	::incluiTag('IE'       ,::aDest[ "IE" ])

    	IF !EMPTY(::aDest[ "ISUF" ])
       	::incluiTag('ISUF'  ,::aDest[ "ISUF" ])
      ENDIF
    	IF !EMPTY(::aDest[ "email" ])
       	::incluiTag('email'    ,::aDest[ "email" ])
      ENDIF

	::incluiTag('/dest')

   TRY
      IF !EMPTY(::aEntrega[ "CNPJ" ]) .OR. !EMPTY(::aEntrega[ "CPF" ])
         ::incluiTag('entrega')
      ENDIF

      TRY
         IF !EMPTY(::aEntrega[ "CNPJ" ])
            ::incluiTag('CNPJ',::aEntrega[ "CNPJ" ])
         ELSEIF !EMPTY(::aEntrega[ "CPF" ])
            ::incluiTag('CPF',::aEntrega[ "CPF" ])
         ENDIF
      CATCH
      END
      TRY
         IF !EMPTY(::aEntrega[ "xLgr" ])
            ::incluiTag('xLgr',::aEntrega[ "xLgr" ])
         ENDIF
      CATCH
      END
      TRY
         IF !EMPTY(::aEntrega[ "nro" ])
            ::incluiTag('nro',::aEntrega[ "nro" ])
         ENDIF
      CATCH
      END
      TRY
         IF !EMPTY(::aEntrega[ "xCpl" ])
            ::incluiTag('xCpl',::aEntrega[ "xCpl" ])
         ENDIF
      CATCH
      END
      TRY
         IF !EMPTY(::aEntrega[ "xBairro" ])
            ::incluiTag('xBairro',::aEntrega[ "xBairro" ])
         ENDIF
      CATCH
      END
      TRY
         IF !EMPTY(::aEntrega[ "cMun" ])
            ::incluiTag('cMun',::aEntrega[ "cMun" ])
         ENDIF
      CATCH
      END
      TRY
         IF !EMPTY(::aEntrega[ "xMun" ])
            ::incluiTag('xMun',::aEntrega[ "xMun" ])
         ENDIF
      CATCH
      END
      TRY
         IF !EMPTY(::aEntrega[ "UF" ])
            ::incluiTag('UF',::aEntrega[ "UF" ])
         ENDIF
      CATCH
      END
      IF !EMPTY(::aEntrega[ "CNPJ" ]) .OR. !EMPTY(::aEntrega[ "CPF" ])
         ::incluiTag('/entrega')
      ENDIF
   CATCH
   END

   nNItem := nItem
   FOR nItem = 1 TO nNItem
   	::incluiTag('det nItem="'+ALLTRIM(STR(nItem))+'"')
         ::incluiTag('prod')
         	::incluiTag('cProd'    ,::aItem[ "item"+STRZERO(nItem,3)+"_cProd" ])
            TRY
               IF oFuncoes:validaEan(::aItem[ "item"+STRZERO(nItem,3)+"_cEAN" ])[1] = .T.
                  ::incluiTag('cEAN'     ,::aItem[ "item"+STRZERO(nItem,3)+"_cEAN" ])   //<cEAN />
               ELSE
                  aRetorno['OK'] := .F.
                  aRetorno['MsgErro'] := 'Problema ao validar EAN ' + oFuncoes:validaEan(::aItem[ "item"+STRZERO(nItem,3)+"_cEAN" ])[2]
                  * RETURN(aRetorno)
               ENDIF
            CATCH
               ::incluiTag('cEAN'     ,'')   //<cEAN />
*               aRetorno['OK'] := .F.
*               aRetorno['MsgErro'] := 'Problema ao validar EAN'
*               RETURN(aRetorno)
            END
            IF aRetorno['OK'] = .F.
               RETURN(aRetorno)
            ENDIF

         	::incluiTag('xProd'    ,::aItem[ "item"+STRZERO(nItem,3)+"_xProd" ])
         	::incluiTag('NCM'      ,::aItem[ "item"+STRZERO(nItem,3)+"_NCM" ])
         	TRY
            	IF !EMPTY(::aItem[ "item"+STRZERO(nItem,3)+"_EXTIPI" ])
               	::incluiTag('EXTIPI',::aItem[ "item"+STRZERO(nItem,3)+"_EXTIPI" ])
               ENDIF
            CATCH
            END
         	::incluiTag('CFOP'     ,::aItem[ "item"+STRZERO(nItem,3)+"_CFOP" ])
         	::incluiTag('uCom'     ,::aItem[ "item"+STRZERO(nItem,3)+"_uCom" ])
         	::incluiTag('qCom'     ,::aItem[ "item"+STRZERO(nItem,3)+"_qCom" ])
         	::incluiTag('vUnCom'   ,::aItem[ "item"+STRZERO(nItem,3)+"_vUnCom" ])
         	::incluiTag('vProd'    ,::aItem[ "item"+STRZERO(nItem,3)+"_vProd" ])
            TRY
               IF oFuncoes:validaEan(::aItem[ "item"+STRZERO(nItem,3)+"_cEANTrib" ])[1] = .T.
         	      ::incluiTag('cEANTrib' ,::aItem[ "item"+STRZERO(nItem,3)+"_cEANTrib" ]) //<cEANTrib />
               ELSE
                  aRetorno['OK'] := .F.
                  aRetorno['MsgErro'] := 'Problema ao validar EANTrib ' + oFuncoes:validaEan(::aItem[ "item"+STRZERO(nItem,3)+"_cEANTrib" ])[2]
                  * RETURN(aRetorno)
               ENDIF
            CATCH
               ::incluiTag('cEANTrib'     ,'')   //<cEANTrib />
*               aRetorno['OK'] := .F.
*               aRetorno['MsgErro'] := 'Problema ao validar EANTrib'
*               RETURN(aRetorno)
            END
            IF aRetorno['OK'] = .F.
               RETURN(aRetorno)
            ENDIF

         	::incluiTag('uTrib'    ,::aItem[ "item"+STRZERO(nItem,3)+"_uTrib" ])
         	::incluiTag('qTrib'    ,::aItem[ "item"+STRZERO(nItem,3)+"_qTrib" ])

         	TRY
            	::incluiTag('nFCI'   ,::aItem[ "item"+STRZERO(nItem,3)+"_nFCI" ])
          CATCH
          END

         	::incluiTag('vUnTrib'  ,::aItem[ "item"+STRZERO(nItem,3)+"_vUnTrib" ])
         	TRY
            	IF !EMPTY(::aItem[ "item"+STRZERO(nItem,3)+"_vFrete" ]) .AND. VAL(::aItem[ "item"+STRZERO(nItem,3)+"_vFrete" ]) <> 0
               	::incluiTag('vFrete',::aItem[ "item"+STRZERO(nItem,3)+"_vFrete" ])
               ENDIF
            CATCH
            END
         	TRY
             	IF !EMPTY(::aItem[ "item"+STRZERO(nItem,3)+"_vSeg" ]) .AND. VAL(::aItem[ "item"+STRZERO(nItem,3)+"_vSeg" ]) <> 0
                	::incluiTag('vSeg'  ,::aItem[ "item"+STRZERO(nItem,3)+"_vSeg" ])
               ENDIF
            CATCH
            END
         	TRY
             	IF !EMPTY(::aItem[ "item"+STRZERO(nItem,3)+"_vDesc" ]) .AND. VAL(::aItem[ "item"+STRZERO(nItem,3)+"_vDesc" ]) <> 0
                	::incluiTag('vDesc' ,::aItem[ "item"+STRZERO(nItem,3)+"_vDesc" ])
               ENDIF
            CATCH
            END
         	TRY
             	IF !EMPTY(::aItem[ "item"+STRZERO(nItem,3)+"_vOutro" ]) .AND. VAL(::aItem[ "item"+STRZERO(nItem,3)+"_vOutro" ]) <> 0
                	::incluiTag('vOutro',::aItem[ "item"+STRZERO(nItem,3)+"_vOutro" ])
               ENDIF
            CATCH
            END
         	TRY
            	::incluiTag('indTot'   ,::aItem[ "item"+STRZERO(nItem,3)+"_indTot" ])
            CATCH
            END

            // DI - Mauricio Cruz - 04/10/2011
            IF nDI>0
               TRY
                  FOR mI:=1 TO nDi
                     ::incluiTag('DI')
                        ::incluiTag('nDI'          ,::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(mI,3)+"_nDI" ]         )
                        ::incluiTag('dDI'          ,::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(mI,3)+"_dDI" ]         )
                        ::incluiTag('xLocDesemb'   ,::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(mI,3)+"_xLocDesemb" ]  )
                        ::incluiTag('UFDesemb'     ,::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(mI,3)+"_UFDesemb" ]    )
                        ::incluiTag('dDesemb'      ,::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(mI,3)+"_dDesemb" ]     )
                        ::incluiTag('cExportador'  ,::aItemDI[ "item"+STRZERO(nItem,3)+STRZERO(mI,3)+"_cExportador" ] )
                        FOR mY:=1 TO nAdi
                           ::incluiTag('adi')
                              ::incluiTag('nAdicao'      ,::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_nAdicao" ]     )
                              ::incluiTag('nSeqAdic'     ,::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_nSeqAdic" ]    )
                              ::incluiTag('cFabricante'  ,::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_cFabricante" ] )
                              IF ALLTRIM(::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_vDescDI" ])#'0.00'
                                 ::incluiTag('vDescDI'      ,::aItemAdi[ "item"+STRZERO(nItem,3)+STRZERO(nDi,3)+STRZERO(nAdi,3)+"_vDescDI" ]     )
                              ENDIF
                           ::incluiTag('/adi')
                        NEXT
                     ::incluiTag('/DI')
                  NEXT
               CATCH
               END
            ENDIF

          TRY
            ::incluiTag('xPed'   ,::aItem[ "item"+STRZERO(nItem,3)+"_xPed" ])
          CATCH
          END
          TRY
            ::incluiTag('nItemPed'   ,::aItem[ "item"+STRZERO(nItem,3)+"_nItemPed" ])
          CATCH
          END

				TRY
					IF VAL(::aItemCOMB[ "item"+STRZERO(nItem,3)+"_cProdANP" ])>0
						::incluiTag('comb')
							::incluiTag('cProdANP' ,::aItemCOMB[ "item"+STRZERO(nItem,3)+"_cProdANP" ])
							::incluiTag('CODIF'    ,::aItemCOMB[ "item"+STRZERO(nItem,3)+"_CODIF" ])
							::incluiTag('qTemp'    ,::aItemCOMB[ "item"+STRZERO(nItem,3)+"_qTemp" ])
							::incluiTag('UFCons'   ,::aItemCOMB[ "item"+STRZERO(nItem,3)+"_UFCons" ])
						::incluiTag('/comb')
					ENDIF
				CATCH
				END

      	::incluiTag('/prod')

      	::incluiTag('imposto')

       IF ::lMostra_imp_danfe
          ::incluiTag('vTotTrib',::aItemICMS[ "item"+STRZERO(nItem,3)+"vTotTrib" ])
       ENDIF
         	::incluiTag('ICMS')

         	   IF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '00,10,20,30,40,41,50,51,60,70,90'
               	IF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '40,41,50'
                  	::incluiTag('ICMS40')
               	ELSE
                  	::incluiTag('ICMS'+::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ])
                  ENDIF
               	IF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '00'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CST'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ])
                   	::incluiTag('modBC'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBC" ])
                    	::incluiTag('vBC'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBC" ])
                    	::incluiTag('pICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMS" ])
                    	::incluiTag('vICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMS" ])
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '10'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CST'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ])
                   	::incluiTag('modBC'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBC" ])
                    	::incluiTag('vBC'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBC" ])
                    	::incluiTag('pICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMS" ])
                    	::incluiTag('vICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMS" ])
                   	::incluiTag('modBCST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBCST" ])
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ])>0
                   	   ::incluiTag('pMVAST'      ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ])
                     ENDIF
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ])>0
                   	   ::incluiTag('pRedBCST'    ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ])
                     ENDIF
                   	::incluiTag('vBCST'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCST" ])
                   	::incluiTag('pICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMSST" ])
                   	::incluiTag('vICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSST" ])
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '20'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CST'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ])
                   	::incluiTag('modBC'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBC" ])
                   	::incluiTag('pRedBC'      ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBC" ])
                    	::incluiTag('vBC'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBC" ])
                    	::incluiTag('pICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMS" ])
                    	::incluiTag('vICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMS" ])
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '30'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CST'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ])
                   	::incluiTag('modBCST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBCST" ])
                   	::incluiTag('pMVAST'      ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ])
                   	::incluiTag('pRedBCST'    ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ])
                   	::incluiTag('vBCST'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCST" ])
                   	::incluiTag('pICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMSST" ])
                   	::incluiTag('vICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSST" ])
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '40,41,50'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CST'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ])
                   	//::incluiTag('vICMS'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMS" ])
                     // havendo valor de icms, deve-se informar o mesmo e o motivo da desoneracao (N28)
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMS"]) >0    //Mauricio Cruz - 04/10/2011
                        ::incluiTag('vICMS'    ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMS" ])
                        TRY   // Mauricio Cruz - 03/10/2011
                           IF !EMPTY(::aItemICMS[ "item"+STRZERO(nItem,3)+"_motDesICMS" ])
                              ::incluiTag('motDesICMS'  ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_motDesICMS" ])
                           ELSE
                              ::incluiTag('motDesICMS'  ,'9')
                           ENDIF
                        CATCH
                           ::incluiTag('motDesICMS'  ,'9')
                        END
                     ENDIF
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '51'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CST'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ])
                   	::incluiTag('modBC'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBC" ])
                     TRY
                        IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBC" ])>0
                   	      ::incluiTag('pRedBC'      ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBC" ])
                        ENDIF
                     CATCH
                     END
                    	::incluiTag('vBC'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBC" ])
                    	::incluiTag('pICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMS" ])
                    	::incluiTag('vICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMS" ])
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '60'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CST'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ])
                     TRY
                   	   ::incluiTag('vBCSTRet'    ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCSTRet" ])
                   	   ::incluiTag('vICMSSTRet'  ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSSTRet" ])
                     CATCH
                     END
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '70'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CST'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ])
                   	::incluiTag('modBC'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBC" ])
                   	::incluiTag('pRedBC'      ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBC" ])
                   	::incluiTag('vBC'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBC" ])
                   	::incluiTag('pICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMS" ])
                   	::incluiTag('vICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMS" ])
                   	::incluiTag('modBCST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBCST" ])
                   	::incluiTag('pMVAST'      ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ])
                   	::incluiTag('pRedBCST'    ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ])
                   	::incluiTag('vBCST'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCST" ])
                   	::incluiTag('pICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMSST" ])
                   	::incluiTag('vICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSST" ])
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '90'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CST'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ])
                   	::incluiTag('modBC'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBC" ])
                     ::incluiTag('vBC'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBC" ])
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBC" ])>0
               	      ::incluiTag('pRedBC'   ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBC" ])
                     ENDIF
                   	::incluiTag('pICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMS" ])
                   	::incluiTag('vICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMS" ])
                   	::incluiTag('modBCST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBCST" ])
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ])>0
                        ::incluiTag('pMVAST'   ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ])
                     ENDIF
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ])>0
                        ::incluiTag('pRedBCST' ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ])
                     ENDIF
                	   ::incluiTag('vBCST'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCST" ])
                   	::incluiTag('pICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMSST" ])
                   	::incluiTag('vICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSST" ])
               	ENDIF
               	IF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '40,41,50'
                  	::incluiTag('/ICMS40')
               	ELSE
                  	::incluiTag('/ICMS'+::aItemICMS[ "item"+STRZERO(nItem,3)+"_CST" ])
                  ENDIF
               ELSE
               	IF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ] $ '102,103,300,400'
                  	::incluiTag('ICMSSN102')
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ] $ '202,203'
                  	::incluiTag('ICMSSN202')
               	ELSE
                  	::incluiTag('ICMSSN'+::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ])
                  ENDIF
               	IF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ] = '101'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CSOSN'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ])
                   	::incluiTag('pCredSN'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pCredSN" ])
                   	::incluiTag('vCredICMSSN' ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vCredICMSSN" ])
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ] $ '102,103,300,400'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CSOSN'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ])
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ] = '201'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CSOSN'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ])
                   	::incluiTag('modBCST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBCST" ])
                   	::incluiTag('pMVAST'      ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ])
                     if val(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ])>0
                	      ::incluiTag('pRedBCST'    ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ])
                     endif
                   	::incluiTag('vBCST'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCST" ])
                   	::incluiTag('pICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMSST" ])
                   	::incluiTag('vICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSST" ])
                   	::incluiTag('pCredSN'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pCredSN" ])
                   	::incluiTag('vCredICMSSN' ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vCredICMSSN" ])
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ] $ '202,203'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CSOSN'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ])
                   	::incluiTag('modBCST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBCST" ])
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ] ) >0
                   	   ::incluiTag('pMVAST'      ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ])
                     ENDIF
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ]) >0
                   	   ::incluiTag('pRedBCST'    ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ])
                     ENDIF
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCST" ])>0
                   	   ::incluiTag('vBCST'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCST" ])
                     ENDIF
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMSST" ])>0
                   	   ::incluiTag('pICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMSST" ])
                     ENDIF
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSST" ])>0
                   	   ::incluiTag('vICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSST" ])
                     ENDIF
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ] = '500'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CSOSN'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ])
                   	TRY
                      	::incluiTag('vBCSTRet'    ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCSTRet" ])
                      	::incluiTag('vICMSSTRet'  ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSSTRet" ])
                     CATCH
                      	::incluiTag('vBCSTRet'    ,'0.00')
                      	::incluiTag('vICMSSTRet'  ,'0.00')
                     END
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ] = '900'
                   	::incluiTag('orig'        ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_orig" ])
                   	::incluiTag('CSOSN'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ])
                   	::incluiTag('modBC'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBC" ])
                   	::incluiTag('vBC'         ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBC" ])
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBC" ])>0
                   	   ::incluiTag('pRedBC'      ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBC" ])
                     ENDIF
                   	::incluiTag('pICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMS" ])
                   	::incluiTag('vICMS'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMS" ])
                   	::incluiTag('modBCST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_modBCST" ])
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ])>0
                   	   ::incluiTag('pMVAST'      ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pMVAST" ])
                     ENDIF
                     IF VAL(::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ])>0
                   	   ::incluiTag('pRedBCST'    ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pRedBCST" ])
                     ENDIF
                   	::incluiTag('vBCST'       ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vBCST" ])
                   	::incluiTag('pICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pICMSST" ])
                   	::incluiTag('vICMSST'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vICMSST" ])
                   	::incluiTag('pCredSN'     ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_pCredSN" ])
                   	::incluiTag('vCredICMSSN' ,::aItemICMS[ "item"+STRZERO(nItem,3)+"_vCredICMSSN" ])
               	ENDIF
               	IF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ] $ '102,103,300,400'
                  	::incluiTag('/ICMSSN102')
               	ELSEIF ::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ] $ '202,203'
                  	::incluiTag('/ICMSSN202')
               	ELSE
                  	::incluiTag('/ICMSSN'+::aItemICMS[ "item"+STRZERO(nItem,3)+"_CSOSN" ])
                  ENDIF
               ENDIF
         	::incluiTag('/ICMS')


            TRY
              IF !EMPTY( ::aItemIPI[ "item"+STRZERO(nItem,3)+"_CST" ] )
               	::incluiTag('IPI')
               	   TRY
                    	::incluiTag('clEnq'        ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_clEnq" ])
                    CATCH
                    END
               	   TRY
                    	::incluiTag('CNPJProd'     ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_CNPJProd" ])
                    CATCH
                    END
               	   TRY
                    	::incluiTag('cSelo'        ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_cSelo" ])
                    CATCH
                    END
               	   TRY
                    	::incluiTag('qSelo'        ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_qSelo" ])
                    CATCH
                    END
               	   TRY
                    	::incluiTag('cEnq'         ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_cEnq" ])
                    CATCH
                    	::incluiTag('cEnq'         ,'999')
                    END

                    	IF ::aItemIPI[ "item"+STRZERO(nItem,3)+"_CST" ] $ '00,49,50'
                     	::incluiTag('IPITrib')
                        	::incluiTag('CST'    ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_CST" ])
                          	::incluiTag('vBC'    ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_vBC" ])
                          	::incluiTag('pIPI'   ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_pIPI" ])
                          	::incluiTag('vIPI'   ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_vIPI" ])
                     	::incluiTag('/IPITrib')
                    	ELSEIF ::aItemIPI[ "item"+STRZERO(nItem,3)+"_CST" ] $ '01,02,03,04,51,52,53,54,55'
                      	::incluiTag('IPINT')
                        	::incluiTag('CST'    ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_CST" ])
                      	::incluiTag('/IPINT')
                    	ELSEIF ::aItemIPI[ "item"+STRZERO(nItem,3)+"_CST" ] $ '99'
                     	::incluiTag('IPIOutr')
                        	::incluiTag('CST'    ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_CST" ])
                          	::incluiTag('vBC'    ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_vBC" ])
                          	::incluiTag('pIPI'   ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_pIPI" ])
                          	::incluiTag('vIPI'   ,::aItemIPI[ "item"+STRZERO(nItem,3)+"_vIPI" ])
                     	::incluiTag('/IPIOutr')
                    	ENDIF
               	::incluiTag('/IPI')
              ENDIF
            CATCH
            END


            // Mauricio Cruz - 04/10/2011
            TRY
               IF LEFT(::aItem[ "item"+STRZERO(nItem,3)+"_CFOP" ],1)='3'   // So precisa do II se for nota de importacao
                  ::incluiTag('II')
                     ::incluiTag('vBC'     ,::aItemII[ "item"+STRZERO(nItem,3)+"_vBC" ]      )
                     ::incluiTag('vDespAdu',::aItemII[ "item"+STRZERO(nItem,3)+"_vDespAdu" ] )
                     ::incluiTag('vII'     ,::aItemII[ "item"+STRZERO(nItem,3)+"_vII" ]      )
                     ::incluiTag('vIOF'    ,::aItemII[ "item"+STRZERO(nItem,3)+"_vIOF" ]     )
                  ::incluiTag('/II')
               ENDIF
            CATCH
            END

            // Mauricio Cruz - 30/09/2011
            IF EMPTY(::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ])
               ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ]:='01'
               ::aItemPIS[ "item"+STRZERO(nItem,3)+"_vBC" ]:='0.00'
               ::aItemPIS[ "item"+STRZERO(nItem,3)+"_pPIS" ]:='0.00'
               ::aItemPIS[ "item"+STRZERO(nItem,3)+"_vPIS" ]:='0.00'
            ENDIF



            // ATENCAO!!!  OS CODIGOS CST:  49,50,51,52,53,54,55,56,60,61,62,63,64,65,66,67,70,71,72,73,74,75,98 PARA PIS / COFINS
            // AINDA NAO FORAM IMPLEMENTADOS NO MANULA DA NF-E E DEVEM SER USADOS COMO 99 ATE QUE SEJA IMPLEMENTADO
            // FICAR DE OLHO PARA QUANDO ISSO SAIR!  (NT2010.001.PDF)  ->  JA FAZ DOIS ANOS ISSO! RECHECAR...
         	::incluiTag('PIS')
              	IF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '01,02'
               	::incluiTag('PISAliq')
               ELSEIF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '03'
               	::incluiTag('PISQtde')
               ELSEIF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '04,06,07,08,09'
               	::incluiTag('PISNT')
               ELSEIF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '99,49,50,51,52,53,54,55,56,60,61,62,63,64,65,66,67,70,71,72,73,74,75,98'
               	::incluiTag('PISOutr')
               ENDIF
                	::incluiTag('CST'    ,::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ])
                 	IF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '01,02'
                    	::incluiTag('vBC'        ,::aItemPIS[ "item"+STRZERO(nItem,3)+"_vBC" ])
                    	::incluiTag('pPIS'       ,::aItemPIS[ "item"+STRZERO(nItem,3)+"_pPIS" ])
                    	::incluiTag('vPIS'       ,::aItemPIS[ "item"+STRZERO(nItem,3)+"_vPIS" ])
                	ELSEIF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '03'
                    	::incluiTag('qBCProd'    ,::aItemPIS[ "item"+STRZERO(nItem,3)+"_qBCProd" ])
                    	::incluiTag('vAliqProd'  ,::aItemPIS[ "item"+STRZERO(nItem,3)+"_vAliqProd" ])
                    	::incluiTag('vPIS'       ,::aItemPIS[ "item"+STRZERO(nItem,3)+"_vPIS" ])
                	ELSEIF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '99,49,50,51,52,53,54,55,56,60,61,62,63,64,65,66,67,70,71,72,73,74,75,98'
                     TRY
                    	   ::incluiTag('vBC'        ,::aItemPIS[ "item"+STRZERO(nItem,3)+"_vBC" ])
                     CATCH
                        ::incluiTag('vBC'        ,'0.00')
                     END
                     TRY
                    	   ::incluiTag('pPIS'       ,::aItemPIS[ "item"+STRZERO(nItem,3)+"_pPIS" ])
                     CATCH
                        ::incluiTag('pPIS'       ,'0.00')
                     END

                     //Os campos vAliqProd e qBCProd só são gerados qdo o campo vAliqProd for maior que 0.
                    	TRY
                        IF VAL(::aItemPIS[ "item"+STRZERO(nItem,3)+"_vAliqProd" ])>0
                      	   ::incluiTag('qBCProd'    ,::aItemPIS[ "item"+STRZERO(nItem,3)+"_qBCProd" ])
                        ENDIF
                    	CATCH
                        //::incluiTag('qBCProd'    ,'0.00')
                    	END
                    	TRY
                        IF VAL(::aItemPIS[ "item"+STRZERO(nItem,3)+"_vAliqProd" ])>0
                      	   ::incluiTag('vAliqProd'  ,::aItemPIS[ "item"+STRZERO(nItem,3)+"_vAliqProd" ])
                        *ELSE
                        *  ::incluiTag('vAliqProd'  ,'0.00')
                        ENDIF
                    	CATCH
                        *::incluiTag('vAliqProd'  ,'0.00')
                    	END

                     TRY
                    	   ::incluiTag('vPIS'       ,::aItemPIS[ "item"+STRZERO(nItem,3)+"_vPIS" ])
                     CATCH
                        ::incluiTag('vPIS'       ,'0.00')
                     END
                	ENDIF
              	IF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '01,02'
               	::incluiTag('/PISAliq')
               ELSEIF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '03'
               	::incluiTag('/PISQtde')
               ELSEIF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '04,06,07,08,09'
               	::incluiTag('/PISNT')
               ELSEIF ::aItemPIS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '99,49,50,51,52,53,54,55,56,60,61,62,63,64,65,66,67,70,71,72,73,74,75,98'
               	::incluiTag('/PISOutr')
               ENDIF
         	::incluiTag('/PIS')

            // Mauricio Cruz - 30/09/2011
            IF EMPTY(::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ])
               ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST"]:='01'
               ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vBC" ]:='0.00'
               ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_pCOFINS" ]:='0.00'
               ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vCOFINS" ]:='0.00'
            ENDIF

         	::incluiTag('COFINS')
              	IF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '01,02'
               	::incluiTag('COFINSAliq')
               ELSEIF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '03'
               	::incluiTag('COFINSQtde')
               ELSEIF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '04,06,07,08,09'
               	::incluiTag('COFINSNT')
               ELSEIF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '99,49,50,51,52,53,54,55,56,60,61,62,63,64,65,66,67,70,71,72,73,74,75,98'
               	::incluiTag('COFINSOutr')
               ENDIF
                	::incluiTag('CST'    ,::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ])
                 	IF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '01,02'
                    	::incluiTag('vBC'        ,::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vBC" ])
                    	::incluiTag('pCOFINS'    ,::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_pCOFINS" ])
                    	::incluiTag('vCOFINS'    ,::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vCOFINS" ])
                	ELSEIF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '03'
                    	::incluiTag('qBCProd'    ,::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_qBCProd" ])
                    	::incluiTag('vAliqProd'  ,::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vAliqProd" ])
                    	::incluiTag('vCOFINS'    ,::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vCOFINS" ])
                	ELSEIF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '99,49,50,51,52,53,54,55,56,60,61,62,63,64,65,66,67,70,71,72,73,74,75,98'
                     TRY
                 	      ::incluiTag('vBC'        ,::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vBC" ])
                     CATCH
                        ::incluiTag('vBC'        ,'0.00')
                     END
                     TRY
                    	   ::incluiTag('pCOFINS'    ,::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_pCOFINS" ])
                     CATCH
                        ::incluiTag('pCOFINS'    ,'0.00')
                     END

                     //Os campos vAliqProd e qBCProd só são gerados qdo o campo vAliqProd for maior que 0.
                    	TRY
                        IF VAL(::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vAliqProd" ])>0
                      	   ::incluiTag('qBCProd'    ,::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_qBCProd" ])
                        ENDIF
                    	CATCH
                        //::incluiTag('qBCProd'    ,'0.00')
                    	END
                    	TRY
                        IF VAL(::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vAliqProd" ])>0
                     	     ::incluiTag('vAliqProd'  ,::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vAliqProd" ])
                        *ELSE
                        *   ::incluiTag('vAliqProd'  ,'0.00')
                        ENDIF
                    	CATCH
                        *::incluiTag('vAliqProd'  ,'0.00')
                    	END
                     TRY
                    	   ::incluiTag('vCOFINS'    ,::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_vCOFINS" ])
                     CATCH
                        ::incluiTag('vCOFINS'    ,'0.00')
                     END
                	ENDIF
              	IF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '01,02'
               	::incluiTag('/COFINSAliq')
               ELSEIF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '03'
               	::incluiTag('/COFINSQtde')
               ELSEIF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '04,06,07,08,09'
               	::incluiTag('/COFINSNT')
               ELSEIF ::aItemCOFINS[ "item"+STRZERO(nItem,3)+"_CST" ] $ '99,49,50,51,52,53,54,55,56,60,61,62,63,64,65,66,67,70,71,72,73,74,75,98'
               	::incluiTag('/COFINSOutr')
               ENDIF
         	::incluiTag('/COFINS')

      	::incluiTag('/imposto')
       	TRY
          	::incluiTag('indfAdProd'   ,::aItem[ "item"+STRZERO(nItem,3)+"_indfAdProd" ])
         CATCH
         END
   	::incluiTag('/det')
   NEXT

	::incluiTag('total')
    	::incluiTag('ICMSTot')
      	::incluiTag('vBC',::aICMSTotal[ "vBC" ])
      	::incluiTag('vICMS',::aICMSTotal[ "vICMS" ])
      	::incluiTag('vBCST',::aICMSTotal[ "vBCST" ])
      	::incluiTag('vST',::aICMSTotal[ "vST" ])
      	::incluiTag('vProd',::aICMSTotal[ "vProd" ])
      	::incluiTag('vFrete',::aICMSTotal[ "vFrete" ])
      	::incluiTag('vSeg',::aICMSTotal[ "vSeg" ])
      	::incluiTag('vDesc',::aICMSTotal[ "vDesc" ])
      	::incluiTag('vII',::aICMSTotal[ "vII" ])
      	::incluiTag('vIPI',::aICMSTotal[ "vIPI" ])
      	::incluiTag('vPIS',::aICMSTotal[ "vPIS" ])
      	::incluiTag('vCOFINS',::aICMSTotal[ "vCOFINS" ])
      	::incluiTag('vOutro',::aICMSTotal[ "vOutro" ])
      	::incluiTag('vNF',::aICMSTotal[ "vNF" ])
       IF ::lMostra_imp_danfe
          ::incluiTag('vTotTrib',::aICMSTotal[ "vTotTrib" ])
       ENDIF

    	::incluiTag('/ICMSTot')
	::incluiTag('/total')

	::incluiTag('transp')
   	::incluiTag('modFrete'  ,::aTransp[ "modFrete" ])
   	TRY
   	   IF !EMPTY( ::aTransp[ "xNome" ] )
         	::incluiTag('transporta')
          	   TRY
                 	::incluiTag('CNPJ'     ,::aTransp[ "CNPJ" ])
               CATCH
            	   TRY
                   	::incluiTag('CPF'      ,::aTransp[ "CPF" ])
                  CATCH
                  END
               END
            	::incluiTag('xNome'  ,::aTransp[ "xNome" ])
           	   TRY
               	::incluiTag('IE'     ,::aTransp[ "IE" ])
               CATCH
               END
           	   TRY
               	::incluiTag('xEnder' ,::aTransp[ "xEnder" ])
               CATCH
               END
           	   TRY
               	::incluiTag('xMun'   ,::aTransp[ "xMun" ])
               CATCH
               END
           	   TRY
               	::incluiTag('UF'     ,::aTransp[ "UF" ])
               CATCH
               END
          ::incluiTag('/transporta')
         ENDIF
      CATCH
      END

   	TRY
   	   IF !EMPTY( ::aVeicTransp[ "placa" ] )
            IF !oFuncoes:validaPlaca( ::aVeicTransp[ "placa" ] )
               aRetorno[ 'OK' ] := .F.
               aRetorno[ 'MsgErro' ] := 'Placa inválida ' + ::aVeicTransp[ "placa" ]
            ENDIF
            ::incluiTag('veicTransp')
               ::incluiTag('placa' ,::aVeicTransp[ "placa" ])
               ::incluiTag('UF'    ,::aVeicTransp[ "UF" ])
        	   TRY
            	::incluiTag('RNTC'   ,::aVeicTransp[ "RNTC" ])
            CATCH
            END
*::aVeicTransp[ "RNTC" ] := hIniData['Transportador']['RNTC']
         	::incluiTag('/veicTransp')
      ENDIF
      CATCH
      END

      TRY
         IF !EMPTY(::aReboque[ "placa" ])
            ::incluiTag('reboque')
               ::incluiTag('placa' ,::aReboque[ "placa" ])
               ::incluiTag('UF'    ,::aReboque[ "UF" ])
            ::incluiTag('/reboque')
         ENDIF
      CATCH
      END

      IF aRetorno[ 'OK' ] = .F.
         RETURN( aRetorno )
      ENDIF
   	//TRY
   	   IF VAL(::aTransp[ "qVol" ])>0 //.AND. (!EMPTY(::aTransp[ "esp" ]) .OR. VAL(::aTransp[ "pesoL" ])>0 .OR. VAL(::aTransp[ "pesoB" ])>0)
         	::incluiTag('vol')
   	      TRY
            	::incluiTag('qVol'   ,::aTransp[ "qVol" ])
            CATCH
            END
   	      TRY
            	::incluiTag('esp'   ,::aTransp[ "esp" ])
            CATCH
            END
   	      TRY
            	::incluiTag('marca'   ,::aTransp[ "marca" ])
            CATCH
            END
   	      TRY
            	::incluiTag('nVol'   ,::aTransp[ "nVol" ])
            CATCH
            END
   	      TRY
            	::incluiTag('pesoL'   ,::aTransp[ "pesoL" ])
            CATCH
            END
   	      TRY
            	::incluiTag('pesoB'   ,::aTransp[ "pesoB" ])
            CATCH
            END
         	::incluiTag('/vol')
         ENDIF
      //CATCH
      //END
	::incluiTag('/transp')

   TRY
      IF !EMPTY( ::aDuplicatas[ "dup001_nDup" ] )
      	::incluiTag('cobr')
      	nNICob := nICob
      	FOR nICob = 1 TO nNICob
         	::incluiTag('dup')
            	::incluiTag('nDup'   ,::aDuplicatas[ "dup"+STRZERO(nICob,3)+"_nDup" ])
            	::incluiTag('dVenc'  ,::aDuplicatas[ "dup"+STRZERO(nICob,3)+"_dVenc" ])
            	::incluiTag('vDup'   ,::aDuplicatas[ "dup"+STRZERO(nICob,3)+"_vDup" ])
         	::incluiTag('/dup')
      	NEXT
      	::incluiTag('/cobr')
      ENDIF
   CATCH
   END

   ::incluiTag('infAdic')

   IF VAL(::aIde[ "tpEmis" ])=3 .OR. VAL(::aIde[ "tpEmis" ])=5 .OR. VAL(::aIde[ "tpEmis" ])=6 .OR. VAL(::aIde[ "tpEmis" ])=7
      TRY
         ::aInfAdic[ "infAdFisco" ]+=' Entrada em Contigencia em '+::aIde[ "dhCont" ]+' Justificativa: '+::aIde[ "xJust" ]
      CATCH
         ::aInfAdic[ "infAdFisco" ]:='Entrada em Contigencia em '+::aIde[ "dhCont" ]+' Justificativa: '+::aIde[ "xJust" ]
      END
   ENDIF

   TRY    // Mauricio Cruz - 05/10/2011
      ::incluiTag('infAdFisco',::aInfAdic[ "infAdFisco" ])
   CATCH
   END
   TRY    // Mauricio Cruz - 30/09/2011
      ::incluiTag('infCpl',::aInfAdic[ "infCpl" ])
   CATCH
   END
   ::incluiTag('/infAdic')

   TRY
      IF !EMPTY(::aExporta[ 'UFEmbarq' ])
         ::incluiTag('exporta')
         ::incluiTag('UFEmbarq'   , ::aExporta[ "UFEmbarq" ] )
         ::incluiTag('xLocEmbarq' , ::aExporta[ "xLocEmbarq" ] )
         ::incluiTag('/exporta')
      ENDIF
   CATCH
   END

	::incluiTag('/infNFe')

	::incluiTag('/NFe')

   hb_MemoWrit( ::ohbNFe:pastaNFe + "\" + cChaveNFe + '-nfe.xml', ::cXMLSaida )
   IF ::lValida
        oAssina := hbNFeAssina()
        oAssina:ohbNFe := ::ohbNfe // Objeto hbNFe
        oAssina:cXMLFile := ::ohbNFe:pastaNFe+"\"+cChaveNFe+'-nfe.xml'
        oAssina:lMemFile := .F.
        aRetornoAss := oAssina:execute()
        oAssina := Nil

        IF aRetornoAss['OK'] == .F.
           aRetorno['OK'] := .F.
           aRetorno['MsgErro'] := aRetornoAss['MsgErro']
           RETURN(aRetorno)
        ELSE
           aRetorno['Assinou'] := .T.
        ENDIF
        oValida := hbNFeValida()
        oValida:ohbNFe := ::ohbNfe // Objeto hbNFe
        oValida:cXML := ::ohbNFe:pastaNFe+"\"+cChaveNFe+'-nfe.xml' // Arquivo XML ou ConteudoXML
        aRetornoVal := oValida:execute()
        oValida := Nil
        IF aRetornoVal['OK'] == .F.
           aRetorno['OK'] := .F.
           aRetorno['MsgErro'] := aRetornoVal['MsgErro']
           RETURN(aRetorno)
        ELSE
           aRetorno['Validou'] := .T.
        ENDIF
   ENDIF
   aRetorno['OK'] := .T.
   aRetorno['chNFe'] := cChaveNFe
   aRetorno['cXMLRet'] := ::ohbNFe:pastaNFe+"\"+cChaveNFe+'-nfe.xml'     // Mauricio Cruz - 30/09/2011

RETURN(aRetorno)

METHOD incluiTag(cTag,cValor) CLASS hbNFeIniToXML
   IF cValor = Nil
      ::cXMLSaida += '<'+cTag+'>'
   ELSEIF EMPTY(cValor)
      IF cTag == 'nro'
         ::cXMLSaida += '<'+cTag+'>'+cValor+'</'+cTag+'>'
      ELSE
         ::cXMLSaida += '<'+cTag+' />'
      ENDIF
   ELSE
      cValor:=CLEAR_CHAR(cValor)
      ::cXMLSaida += '<'+cTag+'>'+cValor+'</'+cTag+'>'
   ENDIF
RETURN Nil



STATIC FUNCTION CLEAR_CHAR(cTXT)
/*
   detona com caracteres indesejados
   Mauricio cruz - 23/11/2011
*/
LOCAL mI, cRET:=cTXT

IF VALTYPE(cRET)<>'C'
   RETURN(cRET)
ENDIF

IF DAY(CTOD(cRET))>0   // EM CASO DE DATAS
   RETURN(cRET)
ENDIF

cRET:=TIRAACENTO(cRET)

FOR mI:=1 TO 31
   IF CHR(mI)$cRET
      cRET:=StrTran( cRET, CHR(mI))
   ENDIF
NEXT
//cRET:=STRTRAN(cRET,'-')
cRET:=STRTRAN(cRET,'–')
IF CHR(145)$cRET // æ
   cRET:=StrTran( cRET, CHR(145))
ENDIF
IF CHR(146)$cRET  // Æ
   cRET:=StrTran( cRET, CHR(146))
ENDIF
IF CHR(155)$cRET  // ø
   cRET:=StrTran( cRET, CHR(155))
ENDIF
FOR mI:=156 TO 159  // £  Ø × ƒ
   IF CHR(mI)$cRET
      cRET:=StrTran( cRET, CHR(mI))
   ENDIF
NEXT
IF CHR(166)$cRET  //  ª
   cRET:=StrTran( cRET, CHR(166))
ENDIF
IF CHR(167)$cRET    //  º
   cRET:=StrTran( cRET, CHR(167))
ENDIF
FOR mI:=169 TO 254  // ® ¬ ½ ¼ ¡ « » .....
   IF CHR(mI)$cRET
      cRET:=StrTran( cRET, CHR(mI))
   ENDIF
NEXT

cRET:=ALLTRIM(cRET)
RETURN(cRET)




STATIC FUNCTION TiraAcento(cText)
/*
   remove os acentos
   Leonardo Machado
*/
  cText:= StrTran(cText,"Ã","A")
  cText:= StrTran(cText,"Â","A")
  cText:= StrTran(cText,"Á","A")
  cText:= StrTran(cText,"Ä","A")
  cText:= StrTran(cText,"À","A")
  cText:= StrTran(cText,"ã","a")
  cText:= StrTran(cText,"â","a")
  cText:= StrTran(cText,"á","a")
  cText:= StrTran(cText,"ä","a")
  cText:= StrTran(cText,"à","a")

  cText:= StrTran(cText,"É","E")
  cText:= StrTran(cText,"Ê","E")
  cText:= StrTran(cText,"Ë","E")
  cText:= StrTran(cText,"È","E")
  cText:= StrTran(cText,"é","e")
  cText:= StrTran(cText,"ê","e")
  cText:= StrTran(cText,"ë","e")
  cText:= StrTran(cText,"è","e")
  cText:= StrTran(cText,"Í","I")

  cText:= StrTran(cText,"Î","I")
  cText:= StrTran(cText,"Ï","I")
  cText:= StrTran(cText,"Ì","I")
  cText:= StrTran(cText,"í","i")
  cText:= StrTran(cText,"î","i")
  cText:= StrTran(cText,"ï","i")
  cText:= StrTran(cText,"ì","i")

  cText:= StrTran(cText,"Ó","O")
  cText:= StrTran(cText,"Õ","O")
  cText:= StrTran(cText,"Ô","O")
  cText:= StrTran(cText,"ó","O")
  cText:= StrTran(cText,"Ö","O")
  cText:= StrTran(cText,"Ò","O")
  cText:= StrTran(cText,"õ","o")
  cText:= StrTran(cText,"ô","o")
  cText:= StrTran(cText,"ó","o")
  cText:= StrTran(cText,"ö","o")
  cText:= StrTran(cText,"ò","o")
  cText := StrTran(cText,"º","")
  cText:= StrTran(cText,CHR(176),"")

  cText:= StrTran(cText,"Û","U")
  cText:= StrTran(cText,"Ú","U")
  cText:= StrTran(cText,"Ü","U")
  cText:= StrTran(cText,"Ù","U")
  cText:= StrTran(cText,"û","u")
  cText:= StrTran(cText,"ú","u")
  cText:= StrTran(cText,"ü","u")
  cText:= StrTran(cText,"ù","u")

  cText := StrTran(cText,"Ç","C")
  cText := StrTran(cText,"ç","c")
return(cText)







METHOD REGRAS_NFE(aMSGvld,cChaveNFe,nItem) CLASS hbNFeIniToXML
/*
   valida as regras de negocios da nota fiscal eletronica
   Mauricio Cruz - 02/05/2012
*/
LOCAL nItnRef, cCHV:='', mI, nVALbcl:=0, nVALicm:=0, nVALbst:=0, nVALstt:=0, nVALitn:=0, nVALfrt:=0, nVALseg:=0, nVALdes:=0, nVALipi:=0

aMSGvld:={}

// ******************* A - Dados da NF-e *************************
// GA03   | A03 | Campo Id inválido: – Chave de Acesso do campo Id difere da concatenação dos campos correspondentes | Obrig.  | 502 | Rej. | Rejeição: Erro na Chave de Acesso - Campo Id não corresponde à concatenação dos campos correspondentes
// ******************* B - Identificação da NF-e  *******************
// GB02   | B02 | Código da UF do Emitente difere da UF do Web Service                                               | Obrig.  | 226 | Rej. | Rejeição: Código da UF do Emitente diverge da UF autorizadora
// GB07   | B07 | Na autorização pela SEFAZ (ou SEFAZ VIRTUAL): – Série da NF-e difere da faixa de 0-889 A faixa
//                890-899 é reservada para a emissão de NF-e avulsa quando permitida pela SEFAZ.                     | Obrig.  | 266 | Rej. | Rejeição: Série utilizada fora da faixa permitida no Web Service (0-889)
IF VAL(::aIde[ "serie" ])>=890 .AND. VAL(::aIde[ "serie" ])<=899
   AADD(aMSGvld,{.T.,'Rejeição: Série utilizada fora da faixa permitida no Web Service (0-889). '+CHR(10)+CHR(13)+'DICA: Favor não utilizar as séries entre 890 e 899'})
ENDIF

// GB07.1 | B07 | Na autorização pelo SCAN - Sistema de Contingência Nacional: – Série da NF-e difere da faixa de
//                900-999                                                                                            | Obrig.  | 503 | Rej. | Rejeição: Série utilizada fora da faixa permitida no SCAN (900-999)
IF VAL(::aIde[ "tpEmis" ])=3 .AND. !(VAL(::aIde[ "serie" ])>=900 .AND. VAL(::aIde[ "serie" ])<=999)
   AADD(aMSGvld,{.T.,'Rejeição: Série utilizada fora da faixa permitida no SCAN (900-999). '+CHR(10)+CHR(13)+'DICA: Favor utilizar série entre 900 e 999 para modo SCAN.'})
ENDIF

// GB09   | B09 | Data de Emissão posterior à data de recebimento da NF-e na SEFAZ                                   | Obrig.  | 212 | Rej. | Rejeição: Data de emissão NF-e posterior a data de recebimento
IF CTOD(RIGHT(::aIde[ "dEmi" ],2)+'/'+SUBSTR(::aIde[ "dEmi" ],6,2)+'/'+LEFT(::aIde[ "dEmi" ],4)) > DATE()   // TESTA CONTRA A DATA DO COMPUTADOR
   AADD(aMSGvld,{.T.,'Rejeição: Data de emissão NF-e posterior a data de recebimento. '+CHR(10)+CHR(13)+'DICA: Favor ajustar a data de emissão da nota fiscal para uma data igual ou anterior a data atual.'})
ENDIF

// GB09.1 | B09 | Data de Emissão ocorrida há mais de 30 dias (ou outro limite definido pela SEFAZ)                  | Obrig.  | 228 | Rej. | Rejeição: Data de Emissão muito atrasada
IF DATE()-CTOD(RIGHT(::aIde[ "dEmi" ],2)+'/'+SUBSTR(::aIde[ "dEmi" ],6,2)+'/'+LEFT(::aIde[ "dEmi" ],4)) > 30
   AADD(aMSGvld,{.T.,'Rejeição: Data de Emissão muito atrasada. '+CHR(10)+CHR(13)+'DICA: Favor ajustar a data de emissão da nota fiscal para uma data não menor que trinta (30) dias a data atual.'})
ENDIF

// GB10   | B10 | Se informado Data de Entrada / Saída (dSaiEnt): – Data Entrada / Saída posterior a 30 dias
//                da Data de Autorização                                                                             | Facult. | 504 | Rej. | Rejeição: Data de Entrada/Saída posterior ao permitido
IF CTOD(RIGHT(::aIde[ "dSaiEnt" ],2)+'/'+SUBSTR(::aIde[ "dSaiEnt" ],6,2)+'/'+LEFT(::aIde[ "dSaiEnt" ],4))-DATE() > 30
   AADD(aMSGvld,{.F.,'Rejeição: Data de Entrada/Saída posterior ao permitido. '+CHR(10)+CHR(13)+'DICA: Favor ajustar a data de Entrada/Saída da nota fiscal para uma data não menor que trinta (30) dias a data atual.'})
ENDIF

// GB10.1 | B10 | Se informado Data de Entrada / Saída (dSaiEnt): – Data Entrada / Saída anterior a 30 dias
//                da Data de Autorização                                                                             | Facult. | 505 | Rej. | Rejeição: Data de Entrada/Saída anterior ao permitido
IF !EMPTY(::aIde[ "dSaiEnt" ])
   IF DATE()- CTOD(RIGHT(::aIde[ "dSaiEnt" ],2)+'/'+SUBSTR(::aIde[ "dSaiEnt" ],6,2)+'/'+LEFT(::aIde[ "dSaiEnt" ],4)) > 30
      AADD(aMSGvld,{.F.,'Rejeição: Data de Entrada/Saída anterior ao permitido. '+CHR(10)+CHR(13)+'DICA: Favor ajustar a data de Entrada/Saída da nota fiscal para uma data não maior que trinta (30) dias a data atual.'})
   ENDIF
ENDIF

// GB10.2 | B10 | Se informado Data de Entrada / Saída (dSaiEnt) para NF-e de Saída (tpNF=1):
//                –Data de Saída (dSaiEnt) menor que a Data de Emissão (dEmis)                                       | Facult. | 506 | Rej. | Rejeição: Data de Saída menor que a Data de Emissão
IF !EMPTY(::aIde[ "dSaiEnt" ])
   IF VAL(::aIde[ "tpNF" ])=1 .AND. CTOD(RIGHT(::aIde[ "dSaiEnt" ],2)+'/'+SUBSTR(::aIde[ "dSaiEnt" ],6,2)+'/'+LEFT(::aIde[ "dSaiEnt" ],4)) < CTOD(RIGHT(::aIde[ "dEmi" ],2)+'/'+SUBSTR(::aIde[ "dEmi" ],6,2)+'/'+LEFT(::aIde[ "dEmi" ],4))
      AADD(aMSGvld,{.F.,'Rejeição: Data de Saída menor que a Data de Emissão. '+CHR(10)+CHR(13)+'DICA: Favor ajustar a data de Entrada/Saída da nota fiscal para uma data igual ou posterior a data de emissão.'})
   ENDIF
ENDIF

// GB12   | B12 | Código do Município do Fato Gerador de ICMS com dígito verificador (DV) inválido (*1)              | Obrig.  | 270 | Rej. | Rejeição: Código Município do Fato Gerador: dígito inválido
// GB12.1 | B12 | Código do Município do Fato Gerador (2 primeiras posições) difere do Código da UF do emitente      | Obrig.  | 271 | Rej. | Rejeição: Código Município do Fato Gerador: difere da UF do emitente
IF LEFT(::aIde[ "cMunFG" ],2) <> LEFT(::aIde[ "cUF" ],2)
   AADD(aMSGvld,{.T.,'Rejeição: Código Município do Fato Gerador: difere da UF do emitente. '+CHR(10)+CHR(13)+'DICA: UF do Emitente da nota fiscal difere da UF para geração do ICMS. Favor verificar a Unidade Federativa do emissor da nota fiscal.'})
ENDIF

WHILE .T.
   nItnRef++
   TRY
      cCHV:=::aRefNfe['refNFe'+STRZERO(nItnRef,3)]
   CATCH
      nItnRef--
      EXIT
   END
   // GB13   | B13 | Se informada a TAG de NF-e Referenciada:
   //                -Dígito Verificador da Chave de Acesso inválido                                                    | Facult. | 547 | Rej. | Rejeição: Dígito Verificador da Chave de Acesso
   //                da NF-e Referenciada inválido
   IF !VERIFICA_DV_CHV_NFE(cCHV)
      AADD(aMSGvld,{.F.,'Rejeição: Dígito Verificador da Chave de Acesso. '+CHR(10)+CHR(13)+'DICA: O dígito verificador da nota fiscal referenciada, esta incorreto. Favor revisar.'})
   ENDIF

   TRY
      // GB17   | B17 | Se informada a TAG de NF Referenciada:– CNPJ com zeros, nulo ou DV inválido                        | Facult. | 548 | Rej. | Rejeição: CNPJ da NF referenciada inválido.
      IF VAL(::aRefNfe['CNPJ'+STRZERO(nItnRef,3)])=0
         AADD(aMSGvld,{.F.,'Rejeição: CNPJ da NF referenciada inválido. '+CHR(10)+CHR(13)+'DICA: O CNPJ da nota fiscal referenciada esta zerado ou não foi informado. Favor revisar.'})
      ENDIF
   CATCH
   END
ENDDO

// GB20d  | B20d| Se informada a TAG de NF Referenciada de produtor:– CNPJ com zeros, nulo ou DV inválido            | Facult. | 549 | Rej. | Rejeição: CNPJ da NF referenciada de produtor inválido.
// GB20e  | B20e| Se informada a TAG de NF Referenciada de produtor:– CPF com zeros, nulo ou DV inválido             | Facult. | 550 | Rej. | Rejeição: CPF da NF referenciada de produtor inválido.
// GB20f  | B20f| Se informada a TAG de NF Referenciada de produtor:– IE com zeros, nulo ou DV inválido para a UF.   | Facult. | 551 | Rej. | Rejeição: IE da NF referenciada de produtor inválido.
// GB20i  | B20i| Se informada a TAG de CT-e Referenciado:- Dígito Verificador da Chave de Acesso inválido           | Facult. | 552 | Rej. | Rejeição: Dígito Verificador da Chave de Acesso do CT-e Referenciado inválido
// GB22   | B22 | Se informada a TAG de tpEmis = 1:dhCont e xJust não devem ser informados                           | Obrig.  | 556 | Rej. | Rejeição: Justificativa de entrada em contingência não deve ser informada para tipo de emissão normal
IF VAL(::aIde[ "tpEmis" ])=1
   TRY
      IF !EMPTY(::aIde[ "xJust" ])
         AADD(aMSGvld,{.T.,'Rejeição: Justificativa de entrada em contingência não deve ser informada para tipo de emissão normal. '+CHR(10)+CHR(13)+'DICA: Favor entrar nas configurações da nota fiscal eletrônica e apagar as informações de justificativa do modo SCAN.'})
      ENDIF
   CATCH
   END
ENDIF

// GB22.1 | B22 | Se informada a TAG de tpEmis diferente de 1:dhCont e xJust devem ser informados                    | Obrig.  | 557 | Rej. | Rejeição: A Justificativa de entrada em contingência deve ser informada
IF VAL(::aIde[ "tpEmis" ])=3 .OR. VAL(::aIde[ "tpEmis" ])=5 .OR. VAL(::aIde[ "tpEmis" ])=6 .OR. VAL(::aIde[ "tpEmis" ])=7
   TRY
      IF EMPTY(::aIde[ "xJust" ]) .OR. EMPTY(::aIde[ "dhCont" ])
         AADD(aMSGvld,{.T.,'Rejeição: A Justificativa de entrada em contingência deve ser informada. '+CHR(10)+CHR(13)+'DICA: Favor entrar nas configurações da nota fiscal eletrônica e informar a justificativa do modo SCAN.'})
      ENDIF
   CATCH
   END
ENDIF

// GB23   | B23 | Chave de Acesso obtida pela concatenação dos campos correspondentes com dígito verificador
//                (DV) inválido                                                                                      | Obrig.  | 253 | Rej. | Rejeição: Digito Verificador da chave de acesso composta inválida
IF !VERIFICA_DV_CHV_NFE(cChaveNFe)
   AADD(aMSGvld,{.T.,'Rejeição: Digito Verificador da chave de acesso composta inválida.'})
ENDIF

// GB24   | B24 | Tipo do ambiente da NF-e difere do ambiente do Web Service                                         | Obrig.  | 252 | Rej. | Rejeição: Ambiente informado diverge do Ambiente de recebimento
// GB25   | B25 | Se NF-e complementar (finNFe=2): – Não informado NF referenciada (NF modelo 1 ou NF-e)             | Obrig.  | 254 | Rej. | Rejeição: NF-e complementar não possui NF referenciada
TRY
   IF VAL(::aIde[ "finNFe" ])=2 .AND. LEN(::aRefNfe)<=0
      AADD(aMSGvld,{.T.,'Rejeição: NF-e complementar não possui NF referenciada. '+CHR(10)+CHR(13)+'DICA: Favor informar as notas fiscais referenciadas no botão (Detalhar Complemento).'})
   ENDIF
CATCH
END

// GB25.1 | B25 | – NF referenciada com mais de uma ocorrência (NF modelo 1 ou NF-e)                                 | Obrig.  | 255 | Rej. | Rejeição: NF-e complementar possui mais de uma NF referenciada
IF VAL(::aIde[ "finNFe" ])=2
   WHILE .T.
      nItnRef++
      TRY
         cCHV:=::aRefNfe['refNFe'+STRZERO(nItnRef,3)]
      CATCH
         nItnRef--
         EXIT
      END
   ENDDO
   IF nItnRef>1
      AADD(aMSGvld,{.T.,'Rejeição: NF-e complementar possui mais de uma NF referenciada. '+CHR(10)+CHR(13)+'DICA: Favor informar apenas uma nota referenciada em (Detalhar Complemento).'})
   ENDIF
ENDIF

// GB25.2 | B25 | – CNPJ emitente da NF Referenciada difere do CNPJ emitente desta NF-e (NF modelo 1 ou NF-e)        | Obrig.  | 269 | Rej. | Rejeição: CNPJ Emitente da NF Complementar difere do CNPJ da NF Referenciada
IF VAL(::aIde[ "finNFe" ])=2
   WHILE .T.
      nItnRef++
      TRY
         cCHV:=::aRefNfe['CNPJ'+STRZERO(nItnRef,3)]
      CATCH
         EXIT
      END
   ENDDO
   IF ALLTRIM(cCHV) <> ALLTRIM(::aEmit[ "CNPJ" ])
      AADD(aMSGvld,{.T.,'Rejeição: CNPJ Emitente da NF Complementar difere do CNPJ da NF Referenciada. '+CHR(10)+CHR(13)+'DICA: Favor informar a nota referenciada cujo CNPJ seja igual ao CNPJ do emitente.'})
   ENDIF
ENDIF

// GB26   | B26 | Processo de Emissão difere de emissão pelo contribuinte (procEmi <> 0 e 3)                         | Obrig.  | 451 | Rej. | Rejeição: Processo de emissão informado inválido
TRY
   IF VAL(::aIde[ "procEmi" ])<>0 .AND. VAL(::aIde[ "procEmi" ])<>3
      AADD(aMSGvld,{.T.,'Rejeição: Processo de emissão informado inválido.'})
   ENDIF
CATCH
END

// GB28   | B28 | Data de entrada em contingência deve ser menor ou igual à data de emissão                          | Facult. | 558 | Rej. | Rejeição: Data de entrada em contingência posterior a data de emissão
IF VAL(::aIde[ "tpEmis" ])=3 .OR. VAL(::aIde[ "tpEmis" ])=5 .OR. VAL(::aIde[ "tpEmis" ])=6 .OR. VAL(::aIde[ "tpEmis" ])=7
   IF CTOD(SUBSTR(::aIde[ "dhCont"],9,2)+'/'+;
           SUBSTR(::aIde[ "dhCont"],6,2)+'/'+;
           LEFT(::aIde[ "dhCont"],4) ) > CTOD(RIGHT(::aIde[ "dEmi" ],2)+'/'+;
                                              SUBSTR(::aIde[ "dEmi" ],6,2)+'/'+;
                                              LEFT(::aIde[ "dEmi" ],4))
      AADD(aMSGvld,{.F.,'Rejeição: Data de entrada em contingência posterior a data de emissão. '+CHR(10)+CHR(13)+'DICA: Favor corrigir a data de entrada em contigencia/modo SCAN nos configurações da nota fiscal eletrônica.'})
   ENDIF
ENDIF

//
//
//*********************** C- Identificação do Emitente  *************************
//
//GC02   | C02 | Se informada a TAG de CNPJ do emitente: – CNPJ com zeros, nulo ou DV inválido                      | Obrig.  | 207 | Rej. | Rejeição: CNPJ do emitente inválido
IF VAL(::aEmit[ "CNPJ" ])=0 .OR. !HBNFE_CNPJ(::aEmit[ "CNPJ" ],.F.)
   AADD(aMSGvld,{.T.,'Rejeição: CNPJ do emitente inválido. '+CHR(10)+CHR(13)+'DICA: Favor revizar o CNPJ da empresa emitente.'})
ENDIF

//GC02.1 | C02 | CNPJ Base do Emitente difere do CNPJ Base da primeira NF-e do Lote recebido                        | Facult. | 560 | Rej. | Rejeição: CNPJ base do emitente difere do CNPJ base da primeira NF-e do lote recebido
//GC02a  | C02a| Se informada a TAG CPF do emitente: – CPF só pode ser informado no campo Emitente para NFe avulsa  | Obrig.  | 407 | Rej. | Rejeição: O CPF só pode ser informado no campo emitente para a NF-e avulsa
//GC02a.1| C02a| - CPF do Remetente de NF-e Avulsa com zeros, nulo ou DV inválido                                   | Obrig.  | 401 | Rej. | Rejeição: CPF do remetente inválido
//GC10   | C10 | Código do Município do Emitente com DV inválido (*1)                                               | Obrig.  | 272 | Rej. | Rejeição: Código Município do Emitente: dígito inválido
//GC10.1 | C10 | Código do Município do Emitente (2 primeiras posições) difere do Código da UF do emitente          | Obrig.  | 273 | Rej. | Rejeição: Código Município do Emitente: difere da UF do emitente
IF LEFT( ALLTRIM(::aEmit[ "cMun" ]),2 )<>CODIGO_UF(::aEmit[ "UF" ],2)
   AADD(aMSGvld,{.T.,'Rejeição: Código Município do Emitente: difere da UF do emitente. '+CHR(10)+CHR(13)+'DICA: Favor revisar a cidade e o estado do emitente.'})
ENDIF


//GC12   | C12 | Sigla da UF do Emitente difere da UF do Web Service                                                | Obrig.  | 247 | Rej. | Rejeição: Sigla da UF do Emitente diverge da UF autorizadora
//GC17   | C17 | IE Emitente com zeros ou nulo                                                                      | Obrig.  | 229 | Rej. | Rejeição: IE do emitente não informada
IF EMPTY(::aEmit[ "IE" ])
   AADD(aMSGvld,{.T.,'Rejeição: IE do emitente não informada. '+CHR(10)+CHR(13)+'DICA: Favor revisar a inscrição estadual do emitente.'})
ENDIF

//GC17.1 | C17 | IE Emitente inválida para a UF: erro no tamanho, na composição da IE, ou no dígito verificador (*2)| Obrig.  | 209 | Rej. | Rejeição: IE do emitente inválida
IF HBNFE_CONSISTEINSCRICAOESTADUAL(::aEmit[ "IE" ],::aEmit[ "UF" ]) <> 0
   AADD(aMSGvld,{.T.,'Rejeição: IE do emitente inválida. '+CHR(10)+CHR(13)+'DICA: Favor revisar a inscrição estadual do emitente.'})
ENDIF

//GC18   | C18 | Se informada operação de Faturamento Direto para veículos novos (tpOp, campo J02 = 2):
//               –UF do Local de Entrega (campo G09) não informada (A UF é necessária na validação da IE ST
//               nestas operações. Vide Convênio ICMS 51/00).                                                       | Obrig.  | 478 | Rej. | Rejeição: Local da entrega não informado para faturamento direto de veículos novos
//GC18.1 | C18 | Se informada a IE do Substituto Tributário:
//               -IEST inválida para a UF: erro no tamanho, na composição da IE, ou no dígito verificador (*2)
//               UF a ser utilizada na validação: – UF do Local de Entrega para operação de Faturamento
//               Direto de veículos novos (campo G09, caso tpOP, campo J02 = 2);
//               -UF do destinatário (UF, campo E12) nos demais casos.                                              | Obrig.  | 211 | Rej. | Rejeição: IE do substituto inválida
//
//*************** D - Identificação do Fisco Emitente (NF-e Avulsa) ******************
//
//GD01   | D01 | Informado o grupo “avulsa” pela empresa                                                            | Obrig.  | 403 | Rej. | Rejeição: O grupo de informações da NF-e avulsa é de uso exclusivo do Fisco E - Identificação do Destinatário
//
//*************** E - Identificação do Destinatário ********************
//
//GE02   | E02 | Se Operação com Exterior (UF Destinatário = “EX”) - não informada TAG CNPJ ou CNPJ <> nulo         | Obrig.  | 507 | Rej. | Rejeição: O CNPJ do destinatário/remetente não deve ser informado em operação com o exterior
TRY
   IF ::aDest[ "UF" ]='EX' .AND. VAL(::aDest[ "CPF" ])+VAL(::aDest[ "CNPJ" ])>0
      AADD(aMSGvld,{.T.,'Rejeição: O CNPJ do destinatário/remetente não deve ser informado em operação com o exterior. '+CHR(10)+CHR(13)+'DICA: Favor não informar ou informar zeros no CNPJ / CPF do Destinatário.'})
   ENDIF
CATCH
END

//GE02.1 | E02 | Se não é Operação com Exterior (UF destinatário <> “EX”):
//               -CNPJ destinatário é nulo e CPF destinatário é nulo                                                | Obrig.  | 508 | Rej. | Rejeição: O CNPJ com conteúdo nulo só é válido em operação com exterior.

IF ::aDest[ "UF" ]<>'EX'
   TRY
      IF VAL(::aDest[ "CNPJ" ])  =0
         AADD(aMSGvld,{.T.,'Rejeição: O CNPJ com conteúdo nulo só é válido em operação com exterior. '+CHR(10)+CHR(13)+'DICA: Favor não informar o CNPJ do Destinatário.'})
      ENDIF
   CATCH
      IF VAL(::aDest[ "CPF" ])  =0
         AADD(aMSGvld,{.T.,'Rejeição: O CPF com conteúdo nulo só é válido em operação com exterior. '+CHR(10)+CHR(13)+'DICA: Favor não informar o CPF do Destinatário.'})
      ENDIF
   END
ENDIF

TRY
   //GE02.2 | E02 | Se informada TAG CNPJ: - CNPJ com zeros ou dígito de controle inválido                             | Obrig.  | 208 | Rej. | Rejeição: CNPJ do destinatário inválido
   IF VAL(::aDest[ "CNPJ" ])>0 .AND. !HBNFE_CNPJ(::aDest[ "CNPJ" ],.F.)
      AADD(aMSGvld,{.T.,'Rejeição: CNPJ do destinatário inválido. '+CHR(10)+CHR(13)+'DICA: Favor revisar o CNPJ do Destinatário.'})
   ENDIF
CATCH
   //GE03   | E03 | Se informada a TAG CPF: - CPF com zeros ou dígito de controle inválido                             | Obrig.  | 237 | Rej. | Rejeição: CPF do destinatário inválido
   IF VAL(::aDest[ "CPF" ])>0 .AND. !HBNFE_CPF(::aDest[ "CPF" ],.F.)
      AADD(aMSGvld,{.T.,'Rejeição: CPF do destinatário inválido. '+CHR(10)+CHR(13)+'DICA: Favor revisar o CPF do Destinatário.'})
   ENDIF
END

//GE10   | E10 | Se não é Operação com Exterior (UF Destinatário <> “EX”):
//               - Código Município do destinatário com dígito verificador inválido                                 | Obrig.  | 274 | Rej. | Rejeição: Código Município do Destinatário: dígito inválido
//GE10.1 | E10 | - Código Município do destinatário (2 primeiras posições) difere do Código da UF do destinatário   | Obrig.  | 275 | Rej. | Rejeição: Código Município do Destinatário: difere da UF do Destinatário
IF ALLTRIM(UPPER(::aDest[ "UF" ]))<>'EX' .AND. LEFT( ALLTRIM(::aDest[ "cMun" ]),2 )<>CODIGO_UF(::aDest[ "UF" ],2)
   AADD(aMSGvld,{.T.,'Rejeição: Código Município do Destinatário: difere da UF do Destinatário. '+CHR(10)+CHR(13)+'DICA: Favor revisar a cidade e o estado do destinatário.'})
ENDIF

//GE10.2 | E10 | Se Operação com Exterior (UF Destinatário = “EX”):
//               -Código Município do destinatário difere de “9999999”                                              | Obrig.  | 509 | Rej. | Rejeição: Informado código de município diferente de “9999999” para operação com o exterior
IF ::aDest[ "UF" ]='EX' .AND. VAL(::aDest[ "cMun" ])<>9999999
   AADD(aMSGvld,{.T.,'Rejeição: Informado código de município diferente de “9999999” para operação com o exterior. '})  // NAO DEVE DE CAIR AQUI NUNCA
ENDIF

//GE14   | E14 | Se Operação com Exterior (UF Destinatário = “EX”):
//               - Código País do destinatário = 1058 (Brasil), ou não informado                                    | Facult. | 510 | Rej. | Rejeição: Operação com Exterior e Código País destinatário é 1058 (Brasil) ou não informado
TRY
   IF ::aDest[ "UF" ]='EX' .AND. (VAL(::aDest[ "cPais" ])=1058 .OR. VAL(::aDest[ "cPais" ])=0)
      AADD(aMSGvld,{.F.,'Rejeição: Operação com Exterior e Código País destinatário é 1058 (Brasil) ou não informado. '+CHR(10)+CHR(13)+'DICA: Favor informar o pais de exportação.'})
   ENDIF
CATCH
END

//GE14.1 | E14 | Se informado Código País do destinatário e não é uma Operação com Exterior
//               (UF Destinatário <> “EX”): - Código País do destinatário difere de 1058 (Brasil)                   | Facult. | 511 | Rej. | Rejeição: Não é de Operação com Exterior e Código País destinatário difere de 1058 (Brasil)
TRY
   IF ::aDest[ "UF" ]<>'EX' .AND. VAL(::aDest[ "cPais" ])<>1058
      AADD(aMSGvld,{.F.,'Rejeição: Não é de Operação com Exterior e Código País destinatário difere de 1058 (Brasil). '+CHR(10)+CHR(13)+'DICA: Favor informar o pais (Brasil).'})
   ENDIF
CATCH
END

//GE17   | E17 | Se Operação com Exterior (UF Destinatário = “EX”):- IE Destinatário difere de nulo ou “ISENTO”     | Obrig.  | 210 | Rej. | Rejeição: IE do destinatário inválida
IF ::aDest[ "UF" ]='EX'
   IF !EMPTY(::aDest[ "IE" ]) .AND. UPPER(ALLTRIM(::aDest[ "IE" ]))<>'ISENTO'
      AADD(aMSGvld,{.T.,'Rejeição: IE do destinatário inválida. '+CHR(10)+CHR(13)+'DICA: Se o Destinatario é ISENTO de ICMS pode-se informar (ISENTO) para a inscrição estadual do destinatário.'})
   ENDIF
ENDIF


//GE17.1 | E17 | IE Destinatário informada e difere de “ISENTO”: -
//               IE inválida para a UF: erro no tamanho, na composição da IE, ou no dígito verificador (*2)         | Obrig.  | 210 | Rej. | Rejeição: IE do destinatário inválida
IF ::aDest[ "UF" ]<>'EX'
   IF UPPER(ALLTRIM(::aDest[ "IE" ]))<>'ISENTO' .AND. HBNFE_CONSISTEINSCRICAOESTADUAL(::aDest[ "IE" ],::aDest[ "UF" ]) <> 0 .AND. VAL(::aIde[ "tpAmb" ])<>2
      AADD(aMSGvld,{.T.,'Rejeição: IE do destinatário inválida. '+CHR(10)+CHR(13)+'DICA: Favor revisar a inscrição estadual do destinatário.'})
   ENDIF
ENDIF

//GE18   | E18 | Inscr. SUFRAMA informada: - Inscrição com dígito verificador inválido                              | Obrig.  | 235 | Rej. | Rejeição: Inscrição SUFRAMA inválida
//GE18.1 | E18 | Inscr. SUFRAMA informada:- UF destinatário difere de AC-Acre, ou AM-Amazonas, ou RO-Rondônia, ou
//               RR-Roraima, ou AP-Amapá (só para municípios 1600303-Macapá e 1600600-Santana)                      | Obrig.  | 251 | Rej. | Rejeição: UF/Município destinatário não pertence a SUFRAMA
//
//******************** F - Local da Retirada *****************
//
//GF02   | F02 | Se informado Local de Retirada e CNPJ Retirada difere de nulo:- CNPJ com zeros ou dígito inválido  | Facult. | 512 | Rej. | Rejeição: CNPJ do Local de Retirada inválido
//GF02a  | F02a| Se informada a TAG CPF: - CPF com zeros ou dígito de controle inválido                             | Facult. | 540 | Rej. | Rejeição: CPF do Local de Retirada inválido
//GF07   | F07 | Se informado Local de Retirada e UF Retirada = “EX”:
//               -Código do Município do Local de Retirada difere de “9999999”                                      | Obrig.  | 513 | Rej. | Rejeição: Código Município do Local de Retirada deve ser 9999999 para UF retirada = “EX”.
//GF07.1 | F07 | Se informado Local de Retirada e UF Retirada <> “EX”:
//               -Código do Município do Local de Retirada com dígito verificador inválido                          | Obrig.  | 276 | Rej. | Rejeição: Código Município do Local de Retirada: dígito inválido
//GF07.2 | F07 | - Código Município do Local de Retirada (2 primeiras posições) difere do
//               Código da UF do Local de Retirada                                                                  | Obrig.  | 277 | Rej. | Rejeição: Código Município do Local de Retirada: difere da UF do Local de Retirada
//
//***********   G - Local da Entrega      *******************
//
TRY
   IF !EMPTY(::aEntrega[ "xLgr" ])
      IF !EMPTY(::aEntrega[ "CNPJ" ])
         //GG02   | G02 | Se informado o Local de Entrega e CNPJ Entrega difere de nulo: - CNPJ com zeros ou dígito inválido | Facult. | 514 | Rej. | Rejeição: CNPJ do Local de Entrega inválido
         IF VAL(::aEntrega[ "CNPJ" ])=0 .OR. !HBNFE_CNPJ(::aEntrega[ "CNPJ" ],.F.)
            AADD(aMSGvld,{.F.,'Rejeição: CNPJ do Local de Entrega inválido. '+CHR(10)+CHR(13)+'DICA: Favor revisar o cnpj do local de entrega.'})
         ENDIF
      ELSEIF VAL(::aEntrega[ "CPF" ])=0 .OR. !EMPTY(::aEntrega[ "CPF" ])
         //GG02a  | G02a| Se informada a TAG CPF: - CPF com zeros ou dígito de controle inválido                             | Facult. | 541 | Rej. | Rejeição: CPF do Local de Entrega inválido
         IF !HBNFE_CPF(::aEntrega[ "CPF" ],.F.)
            AADD(aMSGvld,{.F.,'Rejeição: CPF do Local de Entrega inválido. '+CHR(10)+CHR(13)+'DICA: Favor revisar o cpf do local de entrega.'})
         ENDIF
      ENDIF
   ENDIF
CATCH
END
//GG07   | G07 | Se informado Local de Entrega e UF Entrega = “EX”:
//               -Código do Município do Local de Entrega difere de “9999999”                                       | Obrig.  | 515 | Rej. | Rejeição: Código Município do Local de Entrega deve ser 9999999 para UF entrega = “EX”.
TRY
   IF !EMPTY(::aEntrega[ "xLgr" ]) .AND. ALLTRIM(UPPER(::aEntrega[ "UF" ]))='EX' .AND. VAL(::aEntrega[ "cMun" ])<>9999999
      AADD(aMSGvld,{.T.,'Rejeição: Código Município do Local de Entrega deve ser 9999999 para UF entrega = “EX”. '+CHR(10)+CHR(13)+'DICA: Favor a cidade do local de entrega.'})
   ENDIF
CATCH
END
//GG07.1 | G07 | Se informado Local de Entrega e UF Entrega <> “EX”:
//               -Código Município do Local de Entrega com dígito verificador inválido                              | Obrig.  | 278 | Rej. | Rejeição: Código Município do Local de Entrega: dígito inválido
//GG07.2 | G07 | - Código Município do Local de Entrega (2 primeiras posições) difere do
//                 Código da UF do Local de Entrega                                                                 | Obrig.  | 279 | Rej. | Rejeição: Código Município do Local de Entrega:
TRY
   IF !EMPTY(::aEntrega[ "xLgr" ]) .AND. ALLTRIM(UPPER(::aEntrega[ "UF" ]))<>'EX' .AND. LEFT( ALLTRIM(::aEntrega[ "cMun" ]),2 )<>CODIGO_UF(::aEntrega[ "UF" ],2)
      AADD(aMSGvld,{.T.,'Rejeição: Código Município do Local de Entrega Difere do Código da Unidade Federativa da Entrega. '+CHR(10)+CHR(13)+'DICA: Favor a cidade e o estado do local de entrega.'})
   ENDIF
CATCH
END


//************** H - Detalhamento Produtos e Serviços *******************
//************** I - Produtos e Serviços **********************************
FOR mI:=1 TO nItem

   IF EMPTY(::aItem[ "item"+STRZERO(mI,3)+"_xProd" ])
      AADD(aMSGvld,{.F.,'Rejeição: Descrição do Produto inválida. '+CHR(10)+CHR(13)+'DICA: Favor revisar a descrição do produto do item na sequência: '+ALLTRIM(STR(mI))+'.'  })
   ENDIF

   //GI08   | I08 | CFOP de Entrada (inicia por 1, 2, 3) para NF-e de Saída (tpNF=1)                                   | Facult. | 518 | Rej. | Rejeição: CFOP de entrada para NF-e de saída
   IF VAL(::aIde[ "tpNF" ])=1 .AND. (VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 )) = 1 .OR. VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 )) = 2 .OR. VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 )) = 3)
      AADD(aMSGvld,{.F.,'Rejeição: CFOP de entrada para NF-e de saída. '+CHR(10)+CHR(13)+'DICA: Favor revisar o CFOP do item na sequência: '+ALLTRIM(STR(mI))+'.'  })
   ENDIF

   //GI08.1 | I08 | CFOP de Saída (inicia por 5, 6, 7) para NF-e de Entrada (tpNF=0)                                   | Facult. | 519 | Rej. | Rejeição: CFOP de saída para NF-e de entrada
   IF VAL(::aIde[ "tpNF" ])=0 .AND. (VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 )) = 5 .OR. VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 )) = 6 .OR. VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 )) = 7)
      AADD(aMSGvld,{.F.,'Rejeição: CFOP de saída para NF-e de entrada. '+CHR(10)+CHR(13)+'DICA: Favor revisar o CFOP do item na sequência: '+ALLTRIM(STR(mI))+'.'  })
   ENDIF

   //GI08.2 | I08 | CFOP de Operação com Exterior (inicia por 3 ou 7) e UF destinatário <> “EX”                        | Facult. | 520 | Rej. | Rejeição: CFOP de Operação com Exterior e UF destinatário difere de “EX”
   IF ( VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 ))=3 .OR. VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 ))=7) .AND. ALLTRIM(UPPER(::aDest[ "UF" ]))<>'EX'
      AADD(aMSGvld,{.F.,'Rejeição: CFOP de Operação com Exterior e UF destinatário difere de “EX”. '+CHR(10)+CHR(13)+'DICA: Favor revisar o CFOP do item na sequência: '+ALLTRIM(STR(mI))+'.'  })
   ENDIF

   //GI08.3 | I08 | CFOP não é de Operação com Exterior (não inicia por 3 e 7) e UF destinatário = “EX”                | Facult. | 521 | Rej. | Rejeição: CFOP não é de Operação com Exterior e UF destinatário é “EX”
   IF ALLTRIM(UPPER(::aDest[ "UF" ]))<>'EX' .AND. ( VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 ))=3 .OR. VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 ))=7)
      AADD(aMSGvld,{.F.,'Rejeição: CFOP não é de Operação com Exterior e UF destinatário é “EX”. '+CHR(10)+CHR(13)+'DICA: Favor revisar o CFOP do item na sequência: '+ALLTRIM(STR(mI))+'.'  })
   ENDIF

   //GI08.4 | I08 | CFOP de Operação no Estado (inicia por 1 ou 5) e UF emitente difere da UF destinatário             | Facult. | 522 | Rej. | Rejeição: CFOP de Operação Estadual e UF emitente difere UF destinatário.
   IF ( VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 ))=1 .OR.;
        VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 ))=5) .AND.;
        ALLTRIM(UPPER(::aDest[ "UF" ]))<>ALLTRIM(UPPER(::aEmit[ "UF" ]))
      AADD(aMSGvld,{.F.,'Rejeição: CFOP de Operação Estadual e UF emitente difere UF destinatário. '+CHR(10)+CHR(13)+'DICA: Favor revisar o CFOP do item na sequência: '+ALLTRIM(STR(mI))+'.'  })
   ENDIF

   //GI08.5 | I08 | CFOP não é de Operação no Estado (não inicia por 1 e 5) e UF emitente = UF destinatário            | Facult. | 523 | Rej. | Rejeição: CFOP não é de Operação Estadual e UF emitente igual a UF destinatário.
   IF (VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1))=2 .OR.;
       VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1))=6) .AND.;
      ALLTRIM(UPPER(::aDest[ "UF" ]))=ALLTRIM(UPPER(::aEmit[ "UF" ]))
      AADD(aMSGvld,{.F.,'Rejeição: CFOP não é de Operação Estadual e UF emitente igual a UF destinatário. '+CHR(10)+CHR(13)+'DICA: Favor revisar o CFOP do item na sequência: '+ALLTRIM(STR(mI))+'.'  })
   ENDIF

   //GI08.6 | I08 | CFOP de Operação com Exterior (inicia por 3 ou 7) e não informada TAG NCM
   //               (id:I05) completo (8 posições)                                                                     | Facult. | 524 | Rej. | Rejeição: CFOP de Operação com Exterior e não informado NCM completa
   IF (VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 ))=3 .OR. VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 ))=7) .AND. VAL(::aItem[ "item"+STRZERO(mI,3)+"_NCM" ])=0
      AADD(aMSGvld,{.F.,'Rejeição: CFOP de Operação com Exterior e não informado NCM completa. '+CHR(10)+CHR(13)+'DICA: Favor revisar o NCM do item na sequência: '+ALLTRIM(STR(mI))+'.'  })
   ENDIF

   //GI08.7 | I08 | CFOP de Importação (inicia por 3) e não informado a tag DI                                         | Facult. | 525 | Rej. | Rejeição: CFOP de Importação e não informado dados da DI
   IF VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 ))=3 .AND. LEN(::aItemDI)=0
      AADD(aMSGvld,{.F.,'Rejeição: CFOP de Importação e não informado dados da DI. '+CHR(10)+CHR(13)+'DICA: Favor informar os dados da DI usando a aba (Declaração de Importação).'  })
   ENDIF

   //GI08.8 | I08 | CFOP de Exportação (inicia por 7) e não informado Local de Embarque (id:ZA01)                      | Facult. | 526 | Rej. | Rejeição: CFOP de Exportação e não informado Local de Embarque
   //***************** J - Item / Veículos Novos ****************
   //***************** K - Item / Medicamentos ***************
   //***************** L - Item / Armamentos ****************
   //***************** L1 - Item / Combustível ******************
   //***************** M - Item / Tributos do Produto e Serviço *************
   //**************** N - Item / Tributo: ICMS *******************
   //GN12   | N12 | CFOP de Exportação (inicia por 7): - Informado CST de ICMS diferente de 41                         | Facult. | 527 | Rej. | Rejeição: Operação de Exportação com informação de ICMS incompatível
   IF VAL(LEFT( ALLTRIM(::aItem[ "item"+STRZERO(mI,3)+"_CFOP" ]),1 ))=7 .AND. VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_CST" ])<>41
      AADD(aMSGvld,{.F.,'Rejeição: Operação de Exportação com informação de ICMS incompatível. '+CHR(10)+CHR(13)+'DICA: Favor revisar o CST do ICMS do item na sequência: '+ALLTRIM(STR(mI))+'.'  })
   ENDIF
   //GN17   | N17 | Se CST de ICMS = 00, 10, 20, 51, 70, 90: - Valor ICMS (id:N17) difere de Base de
   //           Cálculo (id:N15) * Alíquota (id:N16) (*3)                                                              | Facult. | 528 | Rej. | Rejeição: Valor do ICMS difere do produto BC e Alíquota
   //

   IF VAL(::aIde[ "finNFe" ])=1  // FINALIDADE NORMAL
      IF (VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_CST" ])=0  .OR.;
          VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_CST" ])=10 .OR.;
          VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_CST" ])=20 .OR.;
          VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_CST" ])=51 .OR.;
          VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_CST" ])=70 .OR.;
          VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_CST" ])=90 ) .AND.;
          ROUND(VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_vICMS" ]),2) <> ROUND(VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_vBC" ])*VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_pICMS" ])/100,2)
         AADD(aMSGvld,{.F.,'Rejeição: Valor do ICMS difere do produto BC e Alíquota. '+CHR(10)+CHR(13)+'DICA: Favor revisar o valor do ICMS para o item na sequência: '+ALLTRIM(STR(mI))+'.'  })
      ENDIF
   ENDIF
   //*************** O - Item / Tributo: IPI ****************

   //GO07   | O07 | Informada tributação do IPI (id:O07) sem informar a TAG NCM (id:I05) completo (8 posições)         | Facult. | 529 | Rej. | Rejeição: NCM de informação obrigatória para produto tributado pelo IPI
   TRY
      IF VAL(::aItemIPI[ "item"+STRZERO(mI,3)+"_pIPI" ])>0 .AND. VAL(::aItem[ "item"+STRZERO(mI,3)+"_NCM" ])=0
         AADD(aMSGvld,{.F.,'Rejeição: NCM de informação obrigatória para produto tributado pelo IPI. '+CHR(10)+CHR(13)+'DICA: Favor revisar o NCM para o item na sequência: '+ALLTRIM(STR(mI))+'.'  })
      ENDIF
   CATCH
   END

   //****************** P - Item / Tributo: II ******************
   //****************** Q - Item / Tributo: PIS *****************
   //****************** R - Item / Tributo: PIS ST **************
   //****************** S - Item / Tributo: COFINS *******************
   //******************* T - Item / Tributo: COFINS ST *****************
   //****************** U - Item / Tributo: ISSQN ***************
   //
   //GU01   | U01 | Informado grupo de tributação do ISSQN (id:U01) sem informar a Inscrição Municipal (id:C19)        | Facult. | 530 | Rej. | Rejeição: Operação com tributação de ISSQN sem informar a Inscrição Municipal
   //GU05   | U05 | Se informado Código Município do FG - ISSQN: – Código Município do FG - ISSQN com dígito inválido  | Obrig.  | 287 | Rej. | Rejeição: Código Município do FG - ISSQN: dígito inválido
   //
   //***************** V - Item / Informação Adicional  *****************

   IF VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_CST" ])<>51
      nVALbcl+=VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_vBC" ])
      nVALicm+=VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_vICMS" ])
   ENDIF
   nVALbst+=VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_vBCST" ])
   nVALstt+=ROUND(VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_vBC" ]) * VAL(::aItemICMS[ "item"+STRZERO(mI,3)+"_pICMSST" ]) /100,2)
   IF VAL(::aItem[ "item"+STRZERO(mI,3)+"_indTot" ])=1
      nVALitn+=VAL(::aItem[ "item"+STRZERO(mI,3)+"_vProd" ])
   ENDIF

   TRY
      IF !EMPTY(::aItem[ "item"+STRZERO(mI,3)+"_vFrete" ]) .AND. VAL(::aItem[ "item"+STRZERO(mI,3)+"_vFrete" ]) <> 0
         nVALfrt+=VAL(::aItem[ "item"+STRZERO(mI,3)+"_vFrete" ])
      ENDIF
   CATCH
   END
   TRY
      IF !EMPTY(::aItem[ "item"+STRZERO(mI,3)+"_vSeg" ]) .AND. VAL(::aItem[ "item"+STRZERO(mI,3)+"_vSeg" ]) <> 0
         nVALseg+=VAL(::aItem[ "item"+STRZERO(mI,3)+"_vSeg" ])
      ENDIF
   CATCH
   END
   TRY
      IF !EMPTY(::aItem[ "item"+STRZERO(mi,3)+"_vDesc" ]) .AND. VAL(::aItem[ "item"+STRZERO(mI,3)+"_vDesc" ]) <> 0
         nVALdes+=VAL(::aItem[ "item"+STRZERO(mI,3)+"_vDesc" ])
      ENDIF
   CATCH
   END
   TRY
      nVALipi+=VAL(::aItemIPI[ "item"+STRZERO(mI,3)+"_vIPI" ])
   CATCH
   END
NEXT

//***************** W - Total da NF-e *****************
//
//GW03   |     | Total da BC ICMS (id:W03) difere do somatório do valor dos itens (id:N15) (*3).
//               O Total não deve considerar o valor informado para o CST 51.                                       | Facult. | 531 | Rej. | Rejeição: Total da BC ICMS difere do somatório dos itens
IF ROUND(VAL(::aICMSTotal[ "vBC" ]),2)<>ROUND(nVALbcl,2)
   AADD(aMSGvld,{.F.,'Rejeição: Total da BC ICMS difere do somatório dos itens. '+CHR(10)+CHR(13)+'DICA: Favor verificar o total da nota fiscal e a somatoria das bases de calculos de todos os itens excluindo os CST 51.'  })
ENDIF

//GW04   |     | Total do ICMS (id:W04) difere do somatório do valor dos itens (id:N17) (*3).
//               O Total não deve considerar o valor informado para o CST 51.                                       | Facult. | 532 | Rej. | Rejeição: Total do ICMS difere do somatório dos itens
IF ROUND(VAL(::aICMSTotal[ "vICMS" ]),2)<>ROUND(nVALicm,2)
   AADD(aMSGvld,{.F.,'Rejeição: Total do ICMS difere do somatório dos itens. '+CHR(10)+CHR(13)+'DICA: Favor verificar o valor total de ICMS da nota fiscal e a somatoria dos valores de ICMS de todos os itens excluindo os CST 51.'  })
ENDIF

//GW05   |     | Total da BC ICMS-ST (id:W05) difere do somatório do valor dos itens (id:N21) (*3)                  | Facult. | 533 | Rej. | Rejeição: Total da BC ICMS-ST difere do somatório dos itens
IF ROUND(VAL(::aICMSTotal[ "vBCST" ]),2)<>ROUND(nVALbst,2)
   AADD(aMSGvld,{.F.,'Rejeição: Total da BC ICMS-ST difere do somatório dos itens. '+CHR(10)+CHR(13)+'DICA: Favor verificar o valor total de base de calculo do ICMS-ST da nota fiscal e a somatoria dos valores de base de calculo do ICMS-ST de todos os itens.'  })
ENDIF

//GW06   |     | Total do ICMS-ST (id:W06) difere do somatório do valor dos itens (id:N23) (*3)                     | Facult. | 534 | Rej. | Rejeição: Total do ICMS-ST difere do somatório dos itens
IF ROUND(VAL(::aICMSTotal[ "vST" ]),2)<>ROUND(nVALstt,2)
   AADD(aMSGvld,{.F.,'Rejeição: Total do ICMS-ST difere do somatório dos itens. '+CHR(10)+CHR(13)+'DICA: Favor verificar o valor total de ICMS-ST da nota fiscal e a somatoria dos valores de ICMS-ST de todos os itens.'  })
ENDIF

//GW07   |     | Total dos Produtos e Serviços (id:W07) difere do somatório do valor dos itens (id:I11).
//               Considerar somente os valores dos itens com a TAG indTot (id:I17b) = 1 (*3)                        | Facult. | 564 | Rej. | Rejeição: Total do Produto / Serviço difere do somatório dos itens
IF ROUND(VAL(::aICMSTotal[ "vProd" ]),2)<>ROUND(nVALitn,2)
   AADD(aMSGvld,{.F.,'Rejeição: Total do Produto / Serviço difere do somatório dos itens. '+CHR(10)+CHR(13)+'DICA: Favor verificar o valor total dos itens da nota fiscal e a somatoria dos valores total de todos os itens.'  })
ENDIF

//GW08   |     | Total do Frete (id:W08) difere do somatório do valor dos itens (id:I15) (*3)                       | Facult. | 535 | Rej. | Rejeição: Total do Frete difere do somatório dos itens
IF ROUND(VAL(::aICMSTotal[ "vFrete" ]),2)<>ROUND(nVALfrt,2)
   AADD(aMSGvld,{.F.,'Rejeição: Total do Frete difere do somatório dos itens. '+CHR(10)+CHR(13)+'DICA: Favor verificar o valor total do frete da nota fiscal e a somatoria dos valores total de frete de todos os itens.'  })
ENDIF

//GW09   |     | Total do Seguro (id:W09) difere do somatório do valor dos itens (id:I16) (*3)                      | Facult. | 536 | Rej. | Rejeição: Total do Seguro difere do somatório dos itens
IF ROUND(VAL(::aICMSTotal[ "vSeg" ]),2)<>ROUND(nVALseg,2)
   AADD(aMSGvld,{.F.,'Rejeição: Total do Seguro difere do somatório dos itens. '+CHR(10)+CHR(13)+'DICA: Favor verificar o valor total do seguro da nota fiscal e a somatoria dos valores total de seguro de todos os itens.'  })
ENDIF

//GW10   |     | Total do Desconto (id:W10) difere do somatório do valor dos itens (id:I17) (*3)                    | Facult. | 537 | Rej. | Rejeição: Total do Desconto difere do somatório dos itens
IF ROUND(VAL(::aICMSTotal[ "vDesc" ]),2)<>ROUND(nVALdes,2)
   AADD(aMSGvld,{.F.,'Rejeição: Total do Desconto difere do somatório dos itens. '+CHR(10)+CHR(13)+'DICA: Favor verificar o valor total do desconto da nota fiscal e a somatoria dos valores total de desconto de todos os itens.'  })
ENDIF

//GW12   |     | Total do IPI (id:W12) difere do somatório do valor dos itens (id:O14) (*3)                         | Facult. | 538 | Rej. | Rejeição: Total do IPI difere do somatório dos itens
IF ROUND(VAL(::aICMSTotal[ "vIPI" ]),2)<>ROUND(nVALipi,2)
   AADD(aMSGvld,{.F.,'Rejeição: Total do IPI difere do somatório dos itens. '+CHR(10)+CHR(13)+'DICA: Favor verificar o valor total de IPI da nota fiscal e a somatoria dos valores total de IPI de todos os itens.'  })
ENDIF

//******************* X - Transporte da NF-e ******************
//
//GX04   | X04 | Validar CNPJ do transportador.se informado. Obrig. 542 Rej. Rejeição: CNPJ do Transportador inválido
//GX05   | X05 | Validar CPF do transportador.se informado.                                                         | Obrig.  | 543 | Rej. | Rejeição: CPF do Transportador inválido
TRY
   IF !EMPTY( ::aTransp[ "xNome" ] )
      TRY
         IF !EMPTY(::aTransp[ "CNPJ" ]) .AND. !HBNFE_CNPJ(::aTransp[ "CNPJ" ],.F.)
            AADD(aMSGvld,{.T.,'Rejeição: CNPJ do Transportador inválido. '+CHR(10)+CHR(13)+'DICA: Favor verificar o CNPJ do transportador.'  })
         ENDIF
      CATCH
         TRY
            IF !EMPTY(::aTransp[ "CPF" ]) .AND. !HBNFE_CPF(::aTransp[ "CPF" ],.F.)
               AADD(aMSGvld,{.T.,'Rejeição: CPF do Transportador inválido. '+CHR(10)+CHR(13)+'DICA: Favor verificar o CPF do transportador.'  })
            ENDIF
         CATCH
         END
      END
   ENDIF
CATCH
END

//GX07   | X07 | Se informada a IE do Transportador: - UF do Transportador (id:X10) não informada                   | Obrig.  | 559 | Rej. | Rejeição: UF do Transportador não informada
TRY
   IF !EMPTY( ::aTransp[ "xNome" ] )
      TRY
         IF !EMPTY(::aTransp[ "IE" ]) .AND. EMPTY(::aTransp[ "UF" ])
            AADD(aMSGvld,{.T.,'Rejeição: UF do Transportador não informada. '+CHR(10)+CHR(13)+'DICA: Favor informar a unidade federativa do transportador.'  })
         ENDIF
      CATCH
      END
   ENDIF
CATCH
END

//GX07.1 | X07 | Validar IE do transportador.se informado. Utilizar a UF informada para escolha do algoritmo.       | Obrig.  | 544 | Rej. | Rejeição: IE do Transportador inválida
TRY
   IF !EMPTY( ::aTransp[ "xNome" ] )
      TRY
         IF !EMPTY(::aTransp[ "IE" ]) .AND. HBNFE_CONSISTEINSCRICAOESTADUAL(::aTransp[ "IE" ],::aTransp[ "UF" ]) <> 0
            AADD(aMSGvld,{.T.,'Rejeição: IE do Transportador inválida. '+CHR(10)+CHR(13)+'DICA: Favor verificar a inscrição estadual do transportador.'  })
         ENDIF
      CATCH
      END
   ENDIF
CATCH
END

//GX17   | X17 | Se informado Código Município do FG - Transporte (id:X17):
//               -Código do Município do FG - Transporte com dígito inválido                                        | Obrig.  | 288 | Rej. | Rejeição: Código Município do FG - Transporte: dígito inválido
//
//
//
//****************** Y - Dados da Cobrança *********************
//****************** Z - Informação Adicional da NF-e *****************
//****************** ZA - Comércio Exterior *********************
//****************** ZB - Informação de Compra *********************
//****************** ZC - Informações do Registro de Aquisição de Cana **************
//****************** ZD – Informação de Crédito do Simples Nacional ****************
//
//******************* Banco de Dados: Emitente  ***************************
//  PULA POR ENQUANTO...
//G1C02  | C02 | Acessar Cadastro Contribuinte p/ Emitente: – CNPJ emitente não cadastrado                          | Facult. | 245 | Rej. | Rejeição: CNPJ Emitente não cadastrado
//G1C02.1| C02 | – Emitente não autorizado                                                                          | Obrig.  | 203 | Rej. | Rejeição: Emissor não habilitado para emissão da NF-e
//G1C17  | C17 | – IE Emitente não cadastrada                                                                       | Facult. | 230 | Rej. | Rejeição: IE do emitente não cadastrada
//G1C17.1| C17 | – IE Emitente não vinculada ao CNPJ                                                                | Obrig.  | 231 | Rej. | Rejeição: IE do emitente não vinculada ao CNPJ
//G1C17.2| C17 | – Emitente em situação irregular perante o Fisco Obrig. 301 Den. Uso Denegado:
//               Irregularidade fiscal do emitente Banco de Dados: Chave da NF-e G1B08 B08
//               Acesso BD NFE (Chave: Ano, CNPJ Emitente, Modelo, Série, Nro):
//               –NF-e já cadastrada, com diferença na Chave de Acesso (campo de Código Numérico difere)            | Facult. | 539 | Rej. | Rejeição: Duplicidade de NF-e, com diferença na Chave de Acesso [99999999999999999999999999999999999999999]
//G1B08.1| B08 | – NF-e já cadastrada e não Cancelada/Denegada                                                      | Obrig.  | 204 | Rej. | Rejeição: Duplicidade de NF-e
//G1B08.2| B08 | - NF-e já cadastrada e está Cancelada                                                              | Obrig.  | 218 | Rej. | Rejeição: NF-e já esta cancelada na base de dados da SEFAZ
//G1B08.3| B08 | - NF-e já cadastrada e está Denegada                                                               | Obrig.  | 205 | Rej. | Rejeição: NF-e está denegada na base de dados da SEFAZ
//G1B08.4| B08 | Acesso BD de Inutilização (Chave: Ano, CNPJ, Modelo, Série, Nro):
//              -Numeração da NF-e está inutilizada                                                                 | Obrig.  | 206 | Rej. | Rejeição: NF-e já está inutilizada na Base de dados da SEFAZ Banco de Dados: NF-e Complementar
//G1B25  | B25 | Se NF-e complementar (finNFe=2) e informado NF-e referenciada (Campo: refNFe):
//               .Acessar BD NFE com a Chave de Acesso informada (Campo: refNFe);
//               - NF-e referenciada inexistente                                                                    | Facult. | 267 | Rej. | Rejeição: NF Complementar referencia uma NF-e inexistente
//G1B25.1| B25 | - NF-e referenciada acessada também é uma NF-e Complementar (finNFe=2)                             | Facult. | 268 | Rej. | Rejeição: NF Complementar referencia uma outra NF-e Complementar Banco de Dados: Destinatário
//G1E17  | E17 | Se Operação no Estado (UF emitente = UF destinatário) e informado IE Destinatário: .
//               Acessar Cadastro Contribuinte (Chave: IE / CNPJ destinatário)- CNPJ destinatário não cadastrado    | Facult. | 246 | Rej. | Rejeição: CNPJ Destinatário não cadastrado
//G1E17.1| E17 | - IE destinatário não cadastrada                                                                   | Facult. | 233 | Rej. | Rejeição: IE do destinatário não cadastrada
//G1E17.2| E17 | - IE destinatário não vinculada ao CNPJ                                                            | Facult. | 234 | Rej. | Rejeição: IE do destinatário não vinculada ao CNPJ
//G1E17.3| E17 | - Destinatário em situação irregular perante o Fisco                                               | Facult. | 302 | Den. | Uso Denegado: Irregularidade fiscal do destinatário

// (*1) Não validar o dígito de controle para os Códigos de Município que seguem: 2201919 - Bom Princípio do Piauí/PI; 2202251 - Canavieira /PI; 2201988 - Brejo do Piauí/PI; 2611533 – Quixaba/PE; 3117836 - Cônego Marinho/MG; 3152131 - Ponto Chique/MG; 4305871 - Coronel Barros/RS; 5203939 - Buriti de Goiás/GO; 5203962 – Buritinópolis/GO.
// (*2) O tamanho da IE deve ser normalizado, na aplicação da SEFAZ, com acréscimo de zeros não significativos, se necessário, antes da verificação do dígito de controle.
// (*3) Considerar uma tolerância de R$ 1,00 para mais ou para menos.

RETURN(.T.)




FUNCTION VERIFICA_DV_CHV_NFE(cCHV)
/*
   verifica o DV da chave de acesso.
   Mauricio Cruz - 02/05/2012
*/
LOCAL nDV:=VAL(RIGHT(ALLTRIM(cCHV),1)), mI, nSOM:=0, nPES:=2, nDIV, nRES, lRET:=.T.
LOCAL nDVG
cCHV:=ALLTRIM(cCHV)
IF EMPTY(cCHV)
   RETURN(.T.)
ENDIF

FOR mI:=LEN(cCHV)-1 TO 1 STEP -1
   nSOM+= VAL(SUBSTR(cCHV,mI,1)) * nPES
   nPES++
   IF nPES>9
      nPES:=2
   ENDIF
NEXT

nDIV:=INT(nSOM / 11)
nRES:=ABS((nDIV*11) - nSOM)
IF nRES=0 .OR. nRES=1
   nDVG:=0
ELSE
   nDVG:=ABS(nRES-11)
ENDIF

IF nDVG<>nDV
   lRET:=.F.
ENDIF


/*
4   |2   |1   |2   |0   |5   |0   |8   |9   |4   |6   |8   |8   |0   |0   |0   |0   |1   |0   |3   |5   |5   |0   |0   |1   |0   |0   |0   |0  |3   |9   |4   |2   |5   |1   |0   |0   |0   |3   |9   |4   |2   |5     1
4   |3   |2   |9   |8   |7   |6   |5   |4   |3   |2   |9   |8   |7   |6   |5   |4   |3   |2   |9   |8   |7   |6   |5   |4   |3   |2   |9   |8  |7   |6   |5   |4   |3   |2   |9   |8   |7   |6   |5   |4   |3   |2
--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |-- |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |--  |---
16  |6   |2   |18  |0   |35  |0   |40  |36  |12  |12  |72  |64  |0   |0   |0   |0   |3   |0   |27  |40  |35  |0   |0   |4   |0   |0   |0   |0  |21  |54  |20  |8   |15  |2   |0   |0   |0   |18  |45  |16  |6   |10   =  637


637/11 = 57
57 * 11 = 627

627-637 = 10
IF RESTO = 0 OU 1
   DV= 0
ELSE
  DV = 11 - 10 = 1
ENIDF


//42|1205|08946880000103|55|001|0000394251|00039425|1
//uf emis  cnpj          md ser  numnf      sequen  dv
*/



RETURN(lRET)
