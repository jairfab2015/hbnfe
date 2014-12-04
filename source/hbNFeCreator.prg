****************************************************************************************************
* Funcoes e Classes Relativas a NFE (Geração de XML por Classe interna)                            *
* Usado como Base o Projeto Open ACBR e Sites sobre XML, Certificados e Afins                      *
* Qualquer modificação deve ser reportada para Fernando Athayde para manter a sincronia do projeto *
* Fernando Athayde 28/08/2011 fernando_athayde@yahoo.com.br                                        *
****************************************************************************************************

#include "hbclass.ch"
#include "hbnfe.ch"

CREATE CLASS hbNFeCreator
   DATA ohbNFe
   DATA oFuncoes
   DATA lValida       INIT .F.
   DATA cChave        AS STRING
   DATA Ide                      EXPORTED
   DATA Emi                      EXPORTED
   DATA Dest                     EXPORTED
   DATA Retirada                 EXPORTED
   DATA Entrega                  EXPORTED
   DATA Item                     EXPORTED
   DATA Totais                   EXPORTED
	DATA Transp                   EXPORTED
	DATA Cobr                     EXPORTED
	DATA InfAdic                  EXPORTED
	DATA ObsCont                  EXPORTED
	DATA ObsFisco                 EXPORTED
	DATA ProcRef                  EXPORTED
   DATA Exporta                  EXPORTED
	DATA Compra                   EXPORTED

   DATA nDuplicatas
   DATA nObsCont
   DATA nObsFisco
   DATA cXMLSaida

   METHOD New()                  CONSTRUCTOR
   METHOD AddItem()
   METHOD getCurItem()

   METHOD geraXML()
   METHOD incluiTagGrupo( cTag ) // , cValor
   METHOD incluiTag(cTag,cValor,lExigida)
   METHOD valToStr(cnCampo, nDec)
ENDCLASS

METHOD New() CLASS hbNFeCreator
   ::oFuncoes := hbNFeFuncoes()
   ::Ide  := hbNFeCreatorIdentificacao():New(::ohbNFe)
   ::Emi  := hbNFeCreatorEmitente():New()
   ::Dest := hbNFeCreatorDestinatario():New()
   ::Item := hash()
   ::Totais := hbNFeCreatorTotais():New()
   ::Transp := hbNFeCreatorTransp():New()
   ::Cobr   := hbNFeCreatorCobranca():New()
   ::InfAdic := hbNFeCreatorInfAdic():New()
   ::ObsCont := hbNFeCreatorObsCont():New()
   ::ProcRef := hbNFeCreatorProcRef():New()
   ::Exporta := hbNFeCreatorExporta():New()
   ::Compra := hbNFeCreatorCompra():New()
RETURN Self

METHOD AddItem() CLASS hbNFeCreator
   ::nItens ++
   ::Item[::nItens] := hbNFeCreatorItem():New()
RETURN Nil

METHOD getCurItem() CLASS hbNFeCreator
RETURN ::nItens

*
* CLASSE DA IDENTIFICACAO
*
CREATE CLASS hbNFeCreatorIdentificacao
   DATA cUF
   DATA cNF
   DATA natOp
   DATA indPag
   DATA mod
   DATA serie
   DATA nNF
   DATA dEmi
   DATA dSaiEnt
   DATA hSaiEnt
   DATA tpNF
   DATA cMunFG
   DATA NFref                 EXPORTED
   DATA tpImp
   DATA tpEmis
   DATA cDV
   DATA tpAmb
   DATA finNFe
   DATA procEmi
   DATA verProc
   DATA dhCont
   DATA xJust

   METHOD New(ohbNFe) CONSTRUCTOR
ENDCLASS

METHOD New(ohbNFe) CLASS hbNFeCreatorIdentificacao
   ::cUF          := ohbNFe:empresa_UF
   ::cNF          := Nil
   ::natOp        := Nil
   ::indPag       := Nil
   ::mod          := Nil
   ::serie        := Nil
   ::nNF          := Nil
   ::dEmi         := CTOD('')
   ::dSaiEnt      := CTOD('')
   ::hSaiEnt      := Nil
   ::tpNF         := Nil
   ::cMunFG       := ohbNFe:empresa_cMun
   ::NFref        := hbNFeCreatorInfref():New()
   ::tpImp        := ohbNFe:empresa_tpImp
   ::tpEmis       := ohbNFe:tpEmis
   ::cDV          := Nil
   ::tpAmb        := ohbNFe:tpAmb
   ::finNFe       := Nil
   ::procEmi      := 0
   ::verProc      := "1.0.0"
   ::dhCont       := Nil
   ::xJust        := Nil
RETURN SELF

*
* CLASSE DA NF Ref.
*
CREATE CLASS hbNFeCreatorInfref
   DATA refNFe
   DATA refNF         EXPORTED
   DATA refNFP        EXPORTED
   DATA refECF        EXPORTED

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorInfref
   ::refNFe       := Nil
   ::refNF        := hbNFeCreatorInfrefNF():New()
   ::refNFP       := hbNFeCreatorInfrefNFP():New()
   ::refECF       := hbNFeCreatorInfrefECF():New()
RETURN SELF

*
* CLASSE DA NF Ref. refNF
*
CREATE CLASS hbNFeCreatorInfrefNF
   DATA cUF
   DATA AAMM
   DATA CNPJ
   DATA mod
   DATA serie
   DATA nNF

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorInfrefNF
   ::cUF   := Nil
   ::AAMM  := Nil
   ::CNPJ  := Nil
   ::mod   := Nil
   ::serie := Nil
   ::nNF   := Nil
RETURN SELF

*
* CLASSE DA NF Ref. refNFP
*
CREATE CLASS hbNFeCreatorInfrefNFP
   DATA cUF
   DATA AAMM
   DATA CNPJ
   DATA CPF
   DATA IE
   DATA mod
   DATA serie
   DATA nNF
   DATA refCTe

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorInfrefNFP
   ::cUF    := Nil
   ::AAMM   := Nil
   ::CNPJ   := Nil
   ::CPF    := Nil
   ::IE     := Nil
   ::mod    := Nil
   ::serie  := Nil
   ::nNF    := Nil
   ::refCTe := Nil
RETURN SELF

*
* CLASSE DA NF Ref. refECF
*
CREATE CLASS hbNFeCreatorInfrefECF
   DATA mod
   DATA nECF
   DATA nCOO

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorInfrefECF
   ::mod    := Nil
   ::nECF   := Nil
   ::nCOO   := Nil
RETURN SELF


*
* CLASSE DO EMISSOR
*
CREATE CLASS hbNFeCreatorEmitente
   DATA CNPJ
   DATA CPF
   DATA xNome
   DATA xFant
   DATA xLgr
   DATA nro
   DATA xCpl
   DATA xBairro
   DATA cMun
   DATA xMun
   DATA UF
   DATA CEP
   DATA cPais
   DATA xPais
   DATA fone
   DATA IE
   DATA IEST
   DATA IM
   DATA CNAE
   DATA CRT

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorEmitente
   ::CNPJ        := Nil
   ::CPF         := Nil
   ::xNome       := Nil
   ::xFant       := Nil
   ::xLgr        := Nil
   ::nro         := Nil
   ::xBairro     := Nil
   ::cMun        := Nil
   ::xMun        := Nil
   ::UF          := Nil
   ::CEP         := Nil
   ::cPais       := Nil
   ::xPais       := Nil
   ::fone        := Nil
   ::IE          := Nil
   ::IEST        := Nil
   ::IM          := Nil
   ::CNAE        := Nil
   ::CRT         := Nil
RETURN SELF

*
* CLASSE DO DESTINATARIO
*
CREATE CLASS hbNFeCreatorDestinatario
   DATA CNPJ
   DATA CPF
   DATA xNome
   DATA xFant
   DATA xLgr
   DATA nro
   DATA xCpl
   DATA xBairro
   DATA cMun
   DATA xMun
   DATA UF
   DATA CEP
   DATA cPais
   DATA xPais
   DATA fone
   DATA IE
   DATA ISUF
   DATA email

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorDestinatario
   ::CNPJ        := Nil
   ::CPF         := Nil
   ::xNome       := Nil
   ::xFant       := Nil
   ::xLgr        := Nil
   ::nro         := Nil
   ::xCpl        := Nil
   ::xBairro     := Nil
   ::cMun        := Nil
   ::xMun        := Nil
   ::UF          := Nil
   ::CEP         := Nil
   ::cPais       := Nil
   ::xPais       := Nil
   ::fone        := Nil
   ::IE          := Nil
   ::ISUF        := Nil
   ::email       := Nil
RETURN SELF

*
* CLASSE DA RETIRADA
*
CREATE CLASS hbNFeCreatorRetirada
   DATA CNPJ
   DATA CPF
   DATA xNome
   DATA xLgr
   DATA nro
   DATA xCpl
   DATA xBairro
   DATA cMun
   DATA xMun
   DATA UF

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorRetirada
   ::CNPJ        := Nil
   ::CPF         := Nil
   ::xNome       := Nil
   ::xLgr        := Nil
   ::nro         := Nil
   ::xCpl        := Nil
   ::xBairro     := Nil
   ::cMun        := Nil
   ::xMun        := Nil
   ::UF          := Nil
RETURN SELF

*
* CLASSE DA ENTREGA
*
CREATE CLASS hbNFeCreatorEntrega
   DATA CNPJ
   DATA CPF
   DATA xNome
   DATA xLgr
   DATA nro
   DATA xCpl
   DATA xBairro
   DATA cMun
   DATA xMun
   DATA UF

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorEntrega
   ::CNPJ        := Nil
   ::CPF         := Nil
   ::xNome       := Nil
   ::xLgr        := Nil
   ::nro         := Nil
   ::xCpl        := Nil
   ::xBairro     := Nil
   ::cMun        := Nil
   ::xMun        := Nil
   ::UF          := Nil
RETURN SELF

*
* CLASSE DO ITEM
*
CREATE CLASS hbNFeCreatorItem
   DATA cProd
   DATA cEAN
   DATA xProd
   DATA NCM
   DATA EXTIPI
   DATA CFOP
   DATA uCom
   DATA qCom
   DATA vUnCom
   DATA vProd
   DATA cEANTrib
   DATA uTrib
   DATA qTrib
   DATA nFCI
   DATA vUnTrib
   DATA vFrete
   DATA vSeg
   DATA vDesc
   DATA vOutro
   DATA indTot
   DATA infAdProd

   DATA ItemICMS
   DATA ItemIPI
   DATA ItemII
   DATA ItemPIS
   DATA ItemPISST
   DATA ItemCOFINS
   DATA ItemCOFINSST

   DATA nItensDI
   DATA ItemDI             EXPORTED

   METHOD New() CONSTRUCTOR
   METHOD AddDI()
   METHOD getCurDI()
ENDCLASS

METHOD New() CLASS hbNFeCreatorItem
   ::cProd     := Nil
   ::cEAN      := Nil
   ::xProd     := Nil
   ::NCM       := Nil
   ::EXTIPI    := Nil
   ::CFOP      := Nil
   ::uCom      := Nil
   ::qCom      := Nil
   ::vUnCom    := Nil
   ::vProd     := Nil
   ::cEANTrib  := Nil
   ::uTrib     := Nil
   ::qTrib     := Nil
   ::nFCI      := NIL
   ::vUnTrib   := Nil
   ::vFrete    := Nil
   ::vSeg      := Nil
   ::vDesc     := Nil
   ::vOutro    := Nil
   ::indTot    := Nil
   ::infAdProd := Nil

   ::ItemICMS     := hbNFeCreatorItemICMS():New()
   ::ItemIPI      := hbNFeCreatorItemIPI():New()
   ::ItemII       := hbNFeCreatorItemII():New()
   ::ItemPIS      := hbNFeCreatorItemPIS():New()
   ::ItemPISST    := hbNFeCreatorItemPISST():New()
   ::ItemCOFINS   := hbNFeCreatorItemCOFINS():New()
   ::ItemCOFINSST := hbNFeCreatorItemCOFINSST():New()
   ::ItemDI       := hash()

   ::nItensDI := 0
RETURN SELF

METHOD AddDI() CLASS hbNFeCreatorItem
   ::nItensDI ++
   ::ItemDI[::nItensDI] := hbNFeCreatorItemDI():New()
RETURN Nil

METHOD getCurDI() CLASS hbNFeCreatorItem
RETURN ::nItensDI

*
* CLASSE DO ITEM ICMS
*
CREATE CLASS hbNFeCreatorItemICMS
   DATA orig
   DATA CST
   DATA CSOSN
   DATA modBC
   DATA pRedBC
   DATA vBC
   DATA pICMS
   DATA vICMS
   DATA modBCST
   DATA pMVAST
   DATA pRedBCST
   DATA vBCST
   DATA pICMSST
   DATA vICMSST
   DATA cUFST
   DATA pBCOp
   DATA vBCSTRet
   DATA vICMSSTRet
   DATA motDesICMS
   DATA pCredSN
   DATA vCredICMSSN
   DATA vBCSTDest
   DATA vICMSSTDest

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorItemICMS
   ::orig        := Nil
   ::CST         := Nil
   ::CSOSN       := Nil
   ::modBC       := Nil
   ::pRedBC      := Nil
   ::vBC         := Nil
   ::pICMS       := Nil
   ::vICMS       := Nil
   ::modBCST     := Nil
   ::pMVAST      := Nil
   ::pRedBCST    := Nil
   ::vBCST       := Nil
   ::pICMSST     := Nil
   ::vICMSST     := Nil
   ::cUFST       := Nil
   ::pBCOp       := Nil
   ::vBCSTRet    := Nil
   ::vICMSSTRet  := Nil
   ::motDesICMS  := Nil
   ::pCredSN     := Nil
   ::vCredICMSSN := Nil
   ::vBCSTDest   := Nil
   ::vICMSSTDest := Nil
RETURN Self

*
* CLASSE DO ITEM IPI
*
CREATE CLASS hbNFeCreatorItemIPI
   DATA clEnq
   DATA CNPJProd
   DATA cSelo
   DATA qSelo
   DATA cEnq
   DATA CST
   DATA vBC
   DATA pIPI
   DATA qUnid
   DATA nUnid
   DATA vIPI

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorItemIPI
   ::clEnq    := Nil
   ::CNPJProd := Nil
   ::cSelo    := Nil
   ::qSelo    := Nil
   ::cEnq     := Nil
   ::CST      := Nil
   ::vBC      := Nil
   ::pIPI     := Nil
   ::qUnid    := Nil
   ::nUnid    := Nil
   ::vIPI     := Nil
RETURN Self
*
* CLASSE DO ITEM II
*
CREATE CLASS hbNFeCreatorItemII
   DATA vBC
   DATA vDespAdu
   DATA vII
   DATA vIOF

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorItemII
   ::vBC      := Nil
   ::vDespAdu := Nil
   ::vII      := Nil
   ::vIOF     := Nil
RETURN Self

*
* CLASSE DO ITEM PIS
*
CREATE CLASS hbNFeCreatorItemPIS
   DATA CST
   DATA vBC
   DATA pPIS
   DATA vPIS
   DATA vBCProd
   DATA nAliqProd

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorItemPIS
   ::CST       := Nil
   ::vBC       := Nil
   ::pPIS      := Nil
   ::vPIS      := Nil
   ::vBCProd   := Nil
   ::nAliqProd := Nil
RETURN Self

*
* CLASSE DO ITEM PISST
*
CREATE CLASS hbNFeCreatorItemPISST
   DATA vBC
   DATA pPIS
   DATA vBCProd
   DATA vAliqProd
   DATA vPIS

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorItemPISST
   ::vBC       := Nil
   ::pPIS      := Nil
   ::vBCProd   := Nil
   ::vAliqProd := Nil
   ::vPIS      := Nil
RETURN Self

*
* CLASSE DO ITEM COFINS
*
CREATE CLASS hbNFeCreatorItemCOFINS
   DATA CST
   DATA vBC
   DATA pCOFINS
   DATA vCOFINS
   DATA vBCProd
   DATA nAliqProd

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorItemCOFINS
   ::CST       := Nil
   ::vBC       := Nil
   ::pCOFINS   := Nil
   ::vCOFINS   := Nil
   ::vBCProd   := Nil
   ::nAliqProd := Nil
RETURN Self

*
* CLASSE DO ITEM COFINSST
*
CREATE CLASS hbNFeCreatorItemCOFINSST
   DATA vBC
   DATA pCOFINS
   DATA vBCProd
   DATA vAliqProd
   DATA vCOFINS

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorItemCOFINSST
   ::vBC       := Nil
   ::pCOFINS   := Nil
   ::vBCProd   := Nil
   ::vAliqProd := Nil
   ::vCOFINS   := Nil
RETURN Self

*
* CLASSE DO ITEM DI
*
CREATE CLASS hbNFeCreatorItemDI
   DATA nDI
   DATA dDI
   DATA xLocDesemb
   DATA UFDesemb
   DATA dDesemb
   DATA cExportador

   DATA ItemADI
   DATA nItensADI

   METHOD New() CONSTRUCTOR
   METHOD AddADI()
   METHOD getCurADI()
ENDCLASS

METHOD AddADI() CLASS hbNFeCreatorItemDI
   ::nItensADI ++
   ::ItemADI[::nItensADI] := hbNFeCreatorItemADI():New()
RETURN Nil

METHOD getCurADI() CLASS hbNFeCreatorItemDI
RETURN ::nItensADI

METHOD New() Class hbNFeCreatorItemDI
   ::nDI         := Nil
   ::dDI         := CTOD('')
   ::xLocDesemb  := Nil
   ::UFDesemb    := Nil
   ::dDesemb     := CTOD('')
   ::cExportador := Nil

   ::ItemADI     := hash()

   ::nItensADI := 0
RETURN SELF

*
* CLASSE DO ITEM ADICAO
*
CREATE CLASS hbNFeCreatorItemADI
   DATA nAdicao
   DATA nSeqAdic
   DATA cFabricante
   DATA vDescDI
   DATA xPed
   DATA nItemPed

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() Class hbNFeCreatorItemADI
   ::nAdicao     := Nil
   ::nSeqAdic    := Nil
   ::cFabricante := Nil
   ::vDescDI     := Nil
   ::xPed        := Nil
   ::nItemPed    := Nil
RETURN SELF

*
* CLASSE DOS TOTAIS
*
CREATE CLASS hbNFeCreatorTotais
   DATA ICMS             EXPORTED
   DATA retTrib          EXPORTED

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorTotais
   ::ICMS    := hbNFeCreatorTotaisICMS():New()
   ::retTrib := hbNFeCreatorTotaisRetTrib():New()
RETURN Self

*
* CLASSE DOS TOTAIS ICMS
*
CREATE CLASS hbNFeCreatorTotaisICMS
   DATA vBC
   DATA vICMS
   DATA vBCST
   DATA vST
   DATA vProd
   DATA vFrete
   DATA vSeg
   DATA vDesc
   DATA vII
   DATA vIPI
   DATA vPIS
   DATA vCOFINS
   DATA vOutro
   DATA vNF

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorTotaisICMS
   ::vBC     := Nil
   ::vICMS   := Nil
   ::vBCST   := Nil
   ::vST     := Nil
   ::vProd   := Nil
   ::vFrete  := Nil
   ::vSeg    := Nil
   ::vDesc   := Nil
   ::vII     := Nil
   ::vIPI    := Nil
   ::vPIS    := Nil
   ::vCOFINS := Nil
   ::vOutro  := Nil
   ::vNF     := Nil
RETURN Self

*
* CLASSE DOS TOTAIS RETENCOES
*
CREATE CLASS hbNFeCreatorTotaisRetTrib
   DATA vRetPIS
   DATA vRetCOFINS
   DATA vRetCSLL
   DATA vBCIRRF
   DATA vIRRF
   DATA vBCRetPrev
   DATA vRetPrev

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorTotaisRetTrib
   ::vRetPIS    := Nil
   ::vRetCOFINS := Nil
   ::vRetCSLL   := Nil
   ::vBCIRRF    := Nil
   ::vIRRF      := Nil
   ::vBCRetPrev := Nil
   ::vRetPrev   := Nil
RETURN Self

*
* CLASSE DO TRANSPORTE
*
CREATE CLASS hbNFeCreatorTransp
   DATA modFrete
   DATA transporta         EXPORTED
   DATA retTransp          EXPORTED
   DATA veictransp         EXPORTED
   DATA vol                EXPORTED
   DATA lacres             EXPORTED

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorTransp
   ::modFrete := '2'
   ::transporta := hbNFeCreatorTranspTransporta():New()
   ::retTransp  := hbNFeCreatorTranspRetTransp():New()
   ::veictransp := hbNFeCreatorTranspVeic():New()
   ::vol        := hbNFeCreatorTranspVol():New()
RETURN Self

*
* CLASSE DO TRANSPORTE (TRANPORTADOR)
*
CREATE CLASS hbNFeCreatorTranspTransporta
   DATA CNPJ
   DATA CPF
   DATA xNome
   DATA IE
   DATA xEnder
   DATA xMun
   DATA UF

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorTranspTransporta
   ::CNPJ   := Nil
   ::CPF    := Nil
   ::xNome  := Nil
   ::IE     := Nil
   ::xEnder := Nil
   ::xMun   := Nil
   ::UF     := Nil
RETURN Self

*
* CLASSE DO TRANSPORTE (RETENCAO)
*
CREATE CLASS hbNFeCreatorTranspRetTransp
   DATA vServ
   DATA vBCRet
   DATA pICMSRet
   DATA vICMSRet
   DATA CFOP
   DATA cMunFG

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorTranspRetTransp
   ::vServ    := Nil
   ::vBCRet   := Nil
   ::pICMSRet := Nil
   ::vICMSRet := Nil
   ::CFOP     := Nil
   ::cMunFG   := Nil
RETURN Self

*
* CLASSE DO TRANSPORTE (VEICULO)
*
CREATE CLASS hbNFeCreatorTranspVeic
   DATA placa
   DATA UF
   DATA RNTC

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorTranspVeic
   ::placa := Nil
   ::UF    := Nil
   ::RNTC  := Nil
RETURN Self

*
* CLASSE DO TRANSPORTE (VOLUMES)
*
CREATE CLASS hbNFeCreatorTranspVol
   DATA qVol
   DATA esp
   DATA marca
   DATA nVol
   DATA pesoL
   DATA pesoB

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorTranspVol
   ::qVol  := Nil
   ::esp   := Nil
   ::marca := Nil
   ::nVol  := Nil
   ::pesoL := Nil
   ::pesoB := Nil
RETURN Self

*
* CLASSE DA COBRANCA
*
CREATE CLASS hbNFeCreatorCobranca
   DATA fat         EXPORTED

   DATA nItensDup
   DATA ItemDup

   METHOD New() CONSTRUCTOR
   METHOD AddDup()
   METHOD getCurDup()
ENDCLASS

METHOD New() CLASS hbNFeCreatorCobranca
   ::fat       := hbNFeCreatorCobrancaFatura():New()
   ::ItemDup   := hash()
   ::nItensDup := 0
RETURN Self

METHOD AddDup() CLASS hbNFeCreatorCobranca
   ::nItensDup ++
   ::ItemDup[::nItensDup] := hbNFeCreatorCobrancaDup():New()
RETURN Nil

METHOD getCurDup() CLASS hbNFeCreatorCobranca
RETURN ::nItensDup

*
* CLASSE DA COBRANCA (FATURA)
*
CREATE CLASS hbNFeCreatorCobrancaFatura
   DATA nFat
   DATA vOrig
   DATA vDesc
   DATA vLiq

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorCobrancaFatura
   ::nFat  := Nil
   ::vOrig := Nil
   ::vDesc := Nil
   ::vLiq  := Nil
RETURN Self

*
* CLASSE DA COBRANCA (DUP)
*
CREATE CLASS hbNFeCreatorCobrancaDup
   DATA nDup
   DATA dVenc
   DATA vDup

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorCobrancaDup
   ::nDup  := Nil
   ::dVenc := CTOD('')
   ::vDup  := Nil
RETURN Self

*
* CLASSE DA INFADIC
*
CREATE CLASS hbNFeCreatorInfAdic
   DATA infAdFisco
   DATA infCpl

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorInfAdic
   ::infAdFisco := Nil
   ::infCpl     := Nil
RETURN Self

*
* CLASSE DA OBSCONT
*
CREATE CLASS hbNFeCreatorObsCont
   DATA nItensObs
   DATA ItemObs

   METHOD New() CONSTRUCTOR
   METHOD AddObs()
   METHOD getCurObs()
ENDCLASS

METHOD New() CLASS hbNFeCreatorObsCont
   ::ItemObs   := hash()
   ::nItensObs := 0
RETURN Self

METHOD AddObs() CLASS hbNFeCreatorObsCont
   ::nItensObs ++
   ::ItemObs[::nItensObs] := hbNFeCreatorObsContItens():New()
RETURN Nil

METHOD getCurObs() CLASS hbNFeCreatorObsCont
RETURN ::nItensObs

CREATE CLASS hbNFeCreatorObsContItens
   DATA xCampo
   DATA xTexto

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorObsContItens
   ::xCampo := Nil
   ::xTexto := Nil
RETURN Self

*
* CLASSE DA PROCREF
*
CREATE CLASS hbNFeCreatorProcRef
   DATA nProc
   DATA indProc

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorProcRef
   ::nProc   := Nil
   ::indProc := Nil
RETURN Self

*
* CLASSE DA EXPORTA
*
CREATE CLASS hbNFeCreatorExporta
   DATA UFEmbarq
   DATA xLocEmbarq

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorExporta
   ::UFEmbarq   := Nil
   ::xLocEmbarq := Nil
RETURN Self

*
* CLASSE DA COMPRA
*
CREATE CLASS hbNFeCreatorCompra
   DATA xNEmp
   DATA xPed
   DATA xCont

   METHOD New() CONSTRUCTOR
ENDCLASS

METHOD New() CLASS hbNFeCreatorCompra
   ::xNEmp := Nil
   ::xPed  := Nil
   ::xCont := Nil
RETURN Self

METHOD geraXML() CLASS hbNFeCreator
LOCAL aRetorno := hash(), oAssina, aRetornoAss, oValida, aRetornoVal, nItem, nItemDup, nItemDI, nItemADI, cDV
   aRetorno[ 'OK' ] := .F.
    WITH OBJECT Self
       // TRATAMENTO DE DADOS
       IF :Emi:CNPJ <> Nil
          :Emi:CNPJ := ::oFuncoes:eliminaString(:Emi:CNPJ, ".-/ ()")
       ELSE
          :Emi:CPF := ::oFuncoes:eliminaString(:Emi:CPF, ".-/ ()")
       ENDIF
       :Emi:CEP := ::oFuncoes:eliminaString(:Emi:CEP, ".-/ ()")
       :Emi:fone := ::oFuncoes:eliminaString(:Emi:fone, ".-/ ()")
       IF :Emi:IE <> Nil
          :Emi:IE := ::oFuncoes:eliminaString(:Emi:IE, ".-/ ()")
       ENDIF

       IF :Dest:CNPJ <> Nil
          :Dest:CNPJ := ::oFuncoes:eliminaString(:Dest:CNPJ, ".-/ ()")
       ELSE
          :Dest:CPF := ::oFuncoes:eliminaString(:Dest:CPF, ".-/ ()")
       ENDIF
       :Dest:CEP := ::oFuncoes:eliminaString(:Dest:CEP, ".-/ ()")
       IF :Dest:fone <> Nil
          :Dest:fone := ::oFuncoes:eliminaString(:Dest:fone, ".-/ ()")
       ENDIF
       IF :Dest:IE <> Nil
          :Dest:IE := ::oFuncoes:eliminaString(:Dest:IE, ".-/ ()")
       ENDIF

       IF :Transp:transporta:CNPJ <> Nil
          :Transp:transporta:CNPJ := ::oFuncoes:eliminaString(:Transp:transporta:CNPJ, ".-/ ()")
       ELSE
          IF :Transp:transporta:CPF <> Nil
             :Transp:transporta:CPF := ::oFuncoes:eliminaString(:Transp:transporta:CPF, ".-/ ()")
          ENDIF
       ENDIF
       IF :Transp:veictransp:placa <> Nil
          :Transp:veictransp:placa := ::oFuncoes:eliminaString(:Transp:veictransp:placa, ".-/ ()")
       ENDIF
       //
       IF EMPTY( ::cChave )
          ::cChave := ::ohbNFe:empresa_UF + ;
                        ::oFuncoes:FormatDate(:Ide:dEmi,"YYMM","") + ;
                        PADL(ALLTRIM(:Emi:CNPJ),14,'0') + ;
                        STRZERO( VAL(::valToStr( :Ide:mod )), 2) + ;
                        STRZERO( VAL(::valToStr( :Ide:serie )), 3) + ;
                        STRZERO( :Ide:nNF , 9) + ;
                        ::ohbNFe:tpEmis + ;
                        STRZERO( :Ide:nNF , 8)
          cDV := ::oFuncoes:modulo11( ::cChave, 2, 9 )
          ::cChave += cDV
       ENDIF
    	::cXMLSaida := '<NFe xmlns="http://www.portalfiscal.inf.br/nfe">' + ;
    	               '<infNFe versao="2.00" Id="NFe'+::cChave+'">'
    	::incluiTagGrupo('ide')
       WITH OBJECT :Ide
        	::incluiTag('cUF'     ,::valToStr( :cUF ) )
        	::incluiTag('cNF'     ,STRZERO( :cNF ,8 ) )
        	::incluiTag('natOp'   ,:natOp )
        	::incluiTag('indPag'  ,::valToStr( :indPag ) )
        	::incluiTag('mod'     ,::valToStr( :mod ) )
        	::incluiTag('serie'   ,ALLTRIM( ::valToStr( :serie ) ) )
        	::incluiTag('nNF'     ,::valToStr( :nNF ) )
        	::incluiTag('dEmi'    ,::oFuncoes:FormatDate( :dEmi,"YYYY-MM-DD","-") )
        	::incluiTag('dSaiEnt' ,::oFuncoes:FormatDate( :dSaiEnt,"YYYY-MM-DD","-") )
        	IF !EMPTY( :hSaiEnt )
           	::incluiTag('hSaiEnt' ,:hSaiEnt )
         ENDIF
        	::incluiTag('tpNF'    ,::valToStr( :tpNF ) )
        	::incluiTag('cMunFG'  ,::valToStr( :cMunFG ) )

         IF :NFref:refNFe <> Nil
           	::incluiTagGrupo('NFref')
              	::incluiTag('refNFe'  ,:NFref:refNFe )
           	   IF :NFref:refNF:cUF <> Nil
                  WITH OBJECT :NFref:refNF
                   	::incluiTagGrupo('refNF')
                       	::incluiTag('cUF'   ,::valToStr( :cUF ) )
                       	IF :AAMM = Nil
                       	   aRetorno[ 'MsgErro' ] := 'Tag AAMM da refNF invalida'
                       	   RETURN(aRetorno)
                       	ENDIF
                       	::incluiTag('AAMM'  ,:AAMM )
                       	::incluiTag('CNPJ'  ,:CNPJ )
                       	::incluiTag('mod'   ,::valToStr( :mod ) )
                       	::incluiTag('serie' ,ALLTRIM( ::valToStr( :serie ) ) )
                       	::incluiTag('nNF'   ,::valToStr( :nNF ) )
                    	::incluiTagGrupo('/refNF')
                  END WITH
              	ENDIF
           	::incluiTagGrupo('/NFref')
          ENDIF

        	::incluiTag('tpImp'   ,::valToStr( :tpImp ) )
        	::incluiTag('tpEmis'  ,::valToStr( :tpEmis ) )
        	::incluiTag('cDV'     ,::valToStr( SUBS(::cChave,44,1) ) )
        	::incluiTag('tpAmb'   ,::valToStr( :tpAmb ) )
        	::incluiTag('finNFe'  ,::valToStr( :finNFe ) )
        	::incluiTag('procEmi' ,::valToStr( :procEmi ), .T. )
        	::incluiTag('verProc' ,:verProc )
       END WITH
    	::incluiTagGrupo('/ide')

    	::incluiTagGrupo('emit')
       WITH OBJECT :Emi
          IF :CNPJ <> Nil
          	::incluiTag('CNPJ'     ,:CNPJ)
          ELSE
             IF :CPF <> Nil
             	::incluiTag('CPF'     ,:CPF)
             ELSE
                aRetorno[ 'MsgErro' ] := 'Emitente sem CNPJ e CPF.'
                RETURN(aRetorno)
             ENDIF
          ENDIF
        	::incluiTag('xNome'    ,:xNome)
        	IF !EMPTY( ALLTRIM( :xFant ) )
           	::incluiTag('xFant'    ,:xFant)
         ENDIF
        	::incluiTagGrupo('enderEmit')
          	::incluiTag('xLgr'     ,:xLgr)
          	::incluiTag('nro'      ,:nro)
          	IF :xCpl <> Nil
              	IF !EMPTY( ALLTRIM( :xCpl ) )
                 	::incluiTag('xCpl'     ,:xCpl)
                ENDIF
             ENDIF
          	::incluiTag('xBairro'  ,:xBairro)
          	::incluiTag('cMun'     ,::valToStr( :cMun ) )
          	::incluiTag('xMun'     ,:xMun)
          	::incluiTag('UF'       ,:UF)
          	IF !EMPTY( ALLTRIM( :CEP ) )
             	::incluiTag('CEP'      ,:CEP )
             ENDIF
          	IF :cPais <> Nil
              	::incluiTag('cPais'    ,:cPais)
              	::incluiTag('xPais'    ,:xPais)
             ELSE
              	::incluiTag('cPais'    ,'1058')
              	::incluiTag('xPais'    ,'BRASIL')
             ENDIF
             IF :fone <> Nil
                IF !EMPTY( :fone )
                   ::incluiTag('fone'     ,:fone)
                ENDIF
             ENDIF
        	::incluiTagGrupo('/enderEmit')
          IF :IE <> Nil
           	::incluiTag('IE'       ,:IE)
          ENDIF
          IF :IEST <> Nil
           	::incluiTag('IEST'  ,:IEST)
          ENDIF
          IF :IM <> Nil
           	::incluiTag('IM'    ,:IM)
           	::incluiTag('CNAE'  ,::valToStr( :CNAE ) ) //somente quando IM for informado
          ENDIF
        	::incluiTag('CRT'      ,::valToStr( :CRT ) )
       END WITH
    	::incluiTagGrupo('/emit')

    	::incluiTagGrupo('dest')
       WITH OBJECT :Dest
          IF :CNPJ <> Nil
          	::incluiTag('CNPJ'     ,:CNPJ)
          ELSE
             IF :CPF <> Nil
             	::incluiTag('CPF'     ,:CPF)
             ELSE
                aRetorno[ 'MsgErro' ] := 'Emitente sem CNPJ e CPF.'
                RETURN(aRetorno)
             ENDIF
          ENDIF
        	::incluiTag('xNome'    ,:xNome)
        	::incluiTagGrupo('enderDest')
          	::incluiTag('xLgr'     ,:xLgr)
          	::incluiTag('nro'      ,:nro)
          	IF !EMPTY( :xCpl )
             	::incluiTag('xCpl'     ,:xCpl)
             ENDIF
          	::incluiTag('xBairro'  ,:xBairro)
          	IF LEN( ::valToStr( :cMun ) ) > 7
                aRetorno[ 'MsgErro' ] := 'Código do municipio inválido.'
                RETURN(aRetorno)
          	ENDIF
          	::incluiTag('cMun'     ,::valToStr( :cMun ) )
          	::incluiTag('xMun'     ,:xMun )
          	::incluiTag('UF'       ,:UF )
          	IF !EMPTY( ALLTRIM( :CEP ) )
             	::incluiTag('CEP'      ,:CEP )
             ENDIF
          	IF :cPais <> Nil
              	::incluiTag('cPais'    ,::valToStr( :cPais) )
              	::incluiTag('xPais'    ,:xPais)
             ELSE
              	::incluiTag('cPais'    ,'1058')
              	::incluiTag('xPais'    ,'BRASIL')
             ENDIF
             IF :fone <> Nil
                IF !EMPTY( :fone )
                   ::incluiTag('fone'     ,:fone)
                ENDIF
             ENDIF
        	::incluiTagGrupo('/enderDest')
          IF :IE <> Nil
           	::incluiTag('IE'       ,:IE)
          ENDIF
          IF :ISUF <> Nil
           	::incluiTag('ISUF'  ,:ISUF)
          ENDIF
          IF :email <> Nil
             IF !EMPTY( ALLTRIM( :email ) )
              	::incluiTag('email'    ,:email)
             ENDIF
          ENDIF
       END WITH
    	::incluiTagGrupo('/dest')

       FOR nItem = 1 TO :nItens
          WITH OBJECT :Item[nItem]
            IF :cProd <= 0
               LOOP
            ENDIF
           	::incluiTagGrupo('det nItem="'+ALLTRIM(STR(nItem))+'"')
                 ::incluiTagGrupo('prod')
                 	::incluiTag('cProd'    ,::valToStr( :cProd ) )

                  TRY
                     IF ::oFuncoes:validaEan(:cEAN)[1] = .T.
                        ::incluiTag('cEAN'     ,:cEAN)   //<cEAN />
                     ELSE
                        aRetorno['OK'] := .F.
                        aRetorno['MsgErro'] := 'Problema ao validar EAN ' + ::oFuncoes:validaEan(:cEAN)[2]
                     ENDIF
                  CATCH
                     aRetorno['OK'] := .F.
                     aRetorno['MsgErro'] := 'Problema ao validar EAN'
                  END
                  IF aRetorno['OK'] = .F.
                     RETURN(aRetorno)
                  ENDIF

                 	::incluiTag('xProd'    ,:xProd )
                 	::incluiTag('NCM'      ,:NCM )
                 	IF :EXTIPI <> Nil
                      	::incluiTag('EXTIPI',:EXTIPI )
                   ENDIF
                 	::incluiTag('CFOP'     ,:CFOP)
                 	::incluiTag('uCom'     ,:uCom)
                 	::incluiTag('qCom'     ,::valToStr( :qCom ) )  // até 4 casas
                 	::incluiTag('vUnCom'   ,::valToStr( :vUnCom ) ) // até 10 casas
                 	::incluiTag('vProd'    ,::valToStr( :vProd, 2 ) )
                 	IF :cEANTrib <> Nil
                     TRY
                        IF ::oFuncoes:validaEan(:cEANTrib)[1] = .T.
                           ::incluiTag('cEANTrib'     ,:cEANTrib)   //<cEANTrib />
                        ELSE
                           aRetorno['OK'] := .F.
                           aRetorno['MsgErro'] := 'Problema ao validar EANTrib ' + ::oFuncoes:validaEan(:cEANTrib)[2]
                        ENDIF
                     CATCH
                        aRetorno['OK'] := .F.
                        aRetorno['MsgErro'] := 'Problema ao validar EANTrib'
                     END
                     IF aRetorno['OK'] = .F.
                        RETURN(aRetorno)
                     ENDIF
                  ELSE
                    	::incluiTag('cEANTrib' ,'' ) //<cEANTrib />
                  ENDIF
                 	IF :cEANTrib <> Nil
                    	::incluiTag('uTrib'    ,:uTrib )
                   ELSE
                    	::incluiTag('uTrib'    ,:uCom )
                   ENDIF
                 	 IF :cEANTrib <> Nil
                    	::incluiTag('qTrib'    ,::valToStr( :qTrib ) )
                   ELSE
                    	::incluiTag('qTrib'    ,'0.00' )
                   ENDIF
                   IF !EMPTY(:nFCI)
                      ::incluiTag('nFCI'    , :nFCI )
                   ENDIF
                 	 IF :cEANTrib <> Nil
                    	::incluiTag('vUnTrib'  ,::valToStr( :vUnTrib ) )
                   ELSE
                    	::incluiTag('vUnTrib'  ,'0.00' )
                   ENDIF
                   IF :vFrete <> Nil
                     	::incluiTag('vFrete'   ,::valToStr( :vFrete ) )
                   ENDIF
                   IF :vSeg <> Nil
                     	::incluiTag('vSeg'     ,::valToStr( :vSeg ) )
                   ENDIF
                   IF :vDesc <> Nil
                     	::incluiTag('vDesc'    ,::valToStr( :vDesc ) )
                   ENDIF
                   IF :vOutro <> Nil
                     	::incluiTag('vOutro'   ,::valToStr( :vOutro ) )
                   ENDIF
                   IF :indTot <> Nil
                    	::incluiTag('indTot'   ,::valToStr( :indTot ) )
                   ELSE
                    	::incluiTag('indTot'   ,'1' )
                   ENDIF
                   FOR nItemDI = 1 TO :nItensDI
                    	::incluiTagGrupo('DI' )
                      WITH OBJECT :ItemDI[nItemDI]
                        IF :nDI = Nil .OR. :dDI = Nil .OR. :xLocDesemb = Nil .OR. :UFDesemb = Nil .OR. :cExportador = Nil
                           aRetorno[ 'MgErro' ] := 'Campo incorreto ou não informado na Tag DI'
                           RETURN( aRetorno )
                        ENDIF
                       	::incluiTag('nDI'         ,:nDI )
                       	::incluiTag('dDI'         ,::oFuncoes:FormatDate( :dDI,"YYYY-MM-DD","-") )
                       	::incluiTag('xLocDesemb'  ,:xLocDesemb )
                       	::incluiTag('UFDesemb'    ,:UFDesemb )
                       	::incluiTag('dDesemb'         ,::oFuncoes:FormatDate( :dDesemb,"YYYY-MM-DD","-") )
                       	::incluiTag('cExportador' ,:cExportador )
                          FOR nItemADI = 1 TO :nItensADI
                          	::incluiTagGrupo('adi' )
                             WITH OBJECT :ItemADI[nItemADI]
                             	::incluiTag('nAdicao'     ,::valToStr( :nAdicao ) )
                             	::incluiTag('nSeqAdic'    ,::valToStr( nItemADI ) )
                             	::incluiTag('cFabricante' ,:cFabricante )
                             	::incluiTag('vDescDI'     ,::valToStr( :vDescDI, 2 ), HBNFE_NAOEXIGIDA )
                             	IF :xPed <> Nil
                                	::incluiTag('xPed'        ,:xPed )
                              ENDIF
                             	IF :nItemPed <> Nil
                                	::incluiTag('nItemPed'    ,::valToStr( :nItemPed ) )
                              ENDIF
                             END WITH
                          	::incluiTagGrupo('/adi' )
                          NEXT
                       END WITH
                    	::incluiTagGrupo('/DI' )
                    NEXT
              	::incluiTagGrupo('/prod')

          	::incluiTagGrupo('imposto')
             	::incluiTagGrupo('ICMS')
                WITH OBJECT :ItemICMS
                   IF :CST <> Nil // CST
                   	IF :CST $ '40,41,50'
                      	::incluiTagGrupo('ICMS40')
                   	ELSE
                      	::incluiTagGrupo('ICMS'+:CST)
                     ENDIF
                      	::incluiTag('orig' ,:orig)
                     	::incluiTag('CST'  ,:CST)
                   	IF :CST $ '00'
                       	::incluiTag('modBC'       ,::valToStr( :modBC ) )
                        	::incluiTag('vBC'         ,::valToStr( :vBC ) )
                        	::incluiTag('pICMS'       ,::valToStr( :pICMS ) )
                        	::incluiTag('vICMS'       ,::valToStr( :vICMS ) )
                   	ELSEIF :CST $ '10'
                       	::incluiTag('modBC'       ,::valToStr( :modBC ) )
                        	::incluiTag('vBC'         ,::valToStr( :vBC ) )
                        	::incluiTag('pICMS'       ,::valToStr( :pICMS ) )
                        	::incluiTag('vICMS'       ,::valToStr( :vICMS ) )
                       	::incluiTag('modBCST'     ,::valToStr( :modBCST ) )
                       	IF :pMVAST <> Nil
                          	::incluiTag('pMVAST'   ,::valToStr( :pMVAST ) )
                         ENDIF
                       	IF :pRedBCST <> Nil
                          	::incluiTag('pRedBCST' ,::valToStr( :pRedBCST ) )
                         ENDIF
                       	::incluiTag('vBCST'       ,::valToStr( :vBCST ) )
                       	::incluiTag('pICMSST'     ,::valToStr( :pICMSST ) )
                       	::incluiTag('vICMSST'     ,::valToStr( :vICMSST ) )
                   	ELSEIF :CST $ '20'
                       	::incluiTag('modBC'       ,::valToStr( :modBC ) )
                       	::incluiTag('pRedBC'      ,::valToStr( :pRedBC ) )
                        	::incluiTag('vBC'         ,::valToStr( :vBC ) )
                        	::incluiTag('pICMS'       ,::valToStr( :pICMS ) )
                        	::incluiTag('vICMS'       ,::valToStr( :vICMS ) )
                   	ELSEIF :CST $ '30'
                       	::incluiTag('modBCST'     ,::valToStr( :modBCST ) )
                       	IF :pMVAST <> Nil
                          	::incluiTag('pMVAST'   ,::valToStr( :pMVAST ) )
                         ENDIF
                       	IF :pRedBCST <> Nil
                          	::incluiTag('pRedBCST' ,::valToStr( :pRedBCST ) )
                         ENDIF
                       	::incluiTag('vBCST'       ,::valToStr( :vBCST ) )
                       	::incluiTag('pICMSST'     ,::valToStr( :pICMSST ) )
                       	::incluiTag('vICMSST'     ,::valToStr( :vICMSST ) )
                   	ELSEIF :CST $ '40,41,50'
                   	   IF :vICMS <> Nil
                           	::incluiTag('vICMS'    ,::valToStr( :vICMS ) )
                         ENDIF
                         IF :motDesICMS <> Nil
                          	::incluiTag('motDesICMS' ,::valToStr( :motDesICMS ) )
                         ENDIF
                   	ELSEIF :CST $ '51'
                       	IF :modBC <> Nil
                          	::incluiTag('modBC'    ,::valToStr( :modBC ) )
                         ENDIF
                       	IF :pRedBC <> Nil
                         	::incluiTag('pRedBC'   ,::valToStr( :pRedBC ) )
                         ENDIF
                       	IF :vBC <> Nil
                          	::incluiTag('vBC'      ,::valToStr( :vBC ) )
                         ENDIF
                       	IF :pICMS <> Nil
                         	::incluiTag('pICMS'    ,::valToStr( :pICMS ) )
                         ENDIF
                       	IF :vICMS <> Nil
                         	::incluiTag('vICMS'    ,::valToStr( :vICMS ) )
                         ENDIF
                   	ELSEIF :CST $ '60'
                       	::incluiTag('vBCSTRet'    ,::valToStr( :vBCSTRet, 2 ) )
                       	::incluiTag('vICMSSTRet'  ,::valToStr( :vICMSSTRet, 2 ) )
                   	ELSEIF :CST $ '70'
                       	::incluiTag('modBC'       ,::valToStr( :modBC ) )
                       	::incluiTag('pRedBC'      ,::valToStr( :pRedBC ) )
                        	::incluiTag('vBC'         ,::valToStr( :vBC, 2 ) )
                        	::incluiTag('pICMS'       ,::valToStr( :pICMS, 2 ) )
                        	::incluiTag('vICMS'       ,::valToStr( :vICMS, 2 ) )
                       	::incluiTag('modBCST'     ,::valToStr( :modBCST ) )
                       	IF :pMVAST <> Nil
                          	::incluiTag('pMVAST'   ,::valToStr( :pMVAST ) )
                         ENDIF
                       	IF :pRedBCST <> Nil
                          	::incluiTag('pRedBCST' ,::valToStr( :pRedBCST ) )
                         ENDIF
                       	::incluiTag('vBCST'       ,::valToStr( :vBCST, 2 ) )
                       	::incluiTag('pICMSST'     ,::valToStr( :pICMSST, 2 ) )
                       	::incluiTag('vICMSST'     ,::valToStr( :vICMSST, 2 ) )
                   	ELSEIF :CST $ '90'
                       	::incluiTag('modBC'       ,::valToStr( :modBC ) )
                       	IF :pRedBC <> Nil
                          	::incluiTag('pRedBC'   ,::valToStr( :pRedBC ) )
                         ENDIF
                        	::incluiTag('vBC'         ,::valToStr( :vBC, 2 ) )
                        	::incluiTag('pICMS'       ,::valToStr( :pICMS, 2 ) )
                        	::incluiTag('vICMS'       ,::valToStr( :vICMS, 2 ) )
                       	::incluiTag('modBCST'     ,::valToStr( :modBCST ) )
                       	IF :pMVAST <> Nil
                          	::incluiTag('pMVAST'   ,::valToStr( :pMVAST ) )
                         ENDIF
                       	IF :pRedBCST <> Nil
                          	::incluiTag('pRedBCST' ,::valToStr( :pRedBCST ) )
                         ENDIF
                       	::incluiTag('vBCST'       ,::valToStr( :vBCST, 2 ) )
                       	::incluiTag('pICMSST'     ,::valToStr( :pICMSST, 2 ) )
                       	::incluiTag('vICMSST'     ,::valToStr( :vICMSST, 2 ) )
                   	ENDIF
                   	IF :CST $ '40,41,50'
                      	::incluiTagGrupo('/ICMS40')
                   	ELSE
                      	::incluiTagGrupo('/ICMS'+:CST)
                      ENDIF
                   ELSE // CSOSN
                   	IF :CSOSN $ '102,103,300,400'
                      	::incluiTagGrupo('ICMSSN102')
                   	ELSEIF :CSOSN $ '202,203'
                      	::incluiTagGrupo('ICMSSN202')
                   	ELSE
                      	::incluiTagGrupo('ICMSSN'+:CSOSN)
                      ENDIF
                     	::incluiTag('orig'  ,:orig)
                     	::incluiTag('CSOSN' ,:CSOSN)
                   	IF :CSOSN = '101'
                   	   IF :pCredSN <> Nil
                          	::incluiTag('pCredSN'     ,::valToStr( :pCredSN, 2 ) )
                        ELSE
                           aRetorno[ 'MsgErro' ] := 'Campo pCredSN deve ser preenchido para CSOSN 101'
                           RETURN(aRetorno)
                        ENDIF
                   	   IF :vCredICMSSN <> Nil
                          	::incluiTag('vCredICMSSN' ,::valToStr( :vCredICMSSN, 2 ) )
                        ELSE
                           aRetorno[ 'MsgErro' ] := 'Campo vCredICMSSN deve ser preenchido para CSOSN 101'
                           RETURN(aRetorno)
                        ENDIF
                   	ELSEIF :CSOSN $ '102,103,300,400'
                   	ELSEIF :CSOSN = '201'
                       	::incluiTag('modBCST'     ,::valToStr( :modBCST ) )
                       	IF :pMVAST <> Nil
                          	::incluiTag('pMVAST'   ,::valToStr( :pMVAST ) )
                         ENDIF
                       	IF :pRedBCST <> Nil
                          	::incluiTag('pRedBCST' ,::valToStr( :pRedBCST ) )
                         ENDIF
                       	::incluiTag('vBCST'       ,::valToStr( :vBCST, 2 ) )
                       	::incluiTag('pICMSST'     ,::valToStr( :pICMSST, 2 ) )
                       	::incluiTag('vICMSST'     ,::valToStr( :vICMSST, 2 ) )
                       	::incluiTag('pCredSN'     ,::valToStr( :pCredSN, 2 ) )
                       	::incluiTag('vCredICMSSN' ,::valToStr( :vCredICMSSN, 2 ) )
                   	ELSEIF :CSOSN $ '202,203'
                       	::incluiTag('modBCST'     ,::valToStr( :modBCST ) )
                       	IF :pMVAST <> Nil
                          	::incluiTag('pMVAST'   ,::valToStr( :pMVAST ) )
                         ENDIF
                       	IF :pRedBCST <> Nil
                          	::incluiTag('pRedBCST' ,::valToStr( :pRedBCST ) )
                         ENDIF
                       	::incluiTag('vBCST'       ,::valToStr( :vBCST, 2 ) )
                       	::incluiTag('pICMSST'     ,::valToStr( :pICMSST, 2 ) )
                       	::incluiTag('vICMSST'     ,::valToStr( :vICMSST, 2 ) )
                   	ELSEIF :CSOSN = '500'
                       	::incluiTag('vBCSTRet'    ,::valToStr( :vBCSTRet, 2 ) )
                       	::incluiTag('vICMSSTRet'  ,::valToStr( :vICMSSTRet, 2 ) )
                   	ELSEIF :CSOSN = '900'
                       	::incluiTag('modBC'       ,::valToStr( :modBC ) )
                       	IF :pRedBC <> Nil
                          	::incluiTag('pRedBC'   ,::valToStr( :pRedBC ) )
                         ENDIF
                        	::incluiTag('vBC'         ,::valToStr( :vBC, 2 ) )
                        	::incluiTag('pICMS'       ,::valToStr( :pICMS, 2 ) )
                        	::incluiTag('vICMS'       ,::valToStr( :vICMS, 2 ) )
                       	::incluiTag('modBCST'     ,::valToStr( :modBCST ) )
                       	IF :pMVAST <> Nil
                          	::incluiTag('pMVAST'   ,::valToStr( :pMVAST ) )
                         ENDIF
                       	IF :pRedBCST <> Nil
                          	::incluiTag('pRedBCST' ,::valToStr( :pRedBCST ) )
                         ENDIF
                       	::incluiTag('vBCST'       ,::valToStr( :vBCST, 2 ) )
                       	::incluiTag('pICMSST'     ,::valToStr( :pICMSST, 2 ) )
                       	::incluiTag('vICMSST'     ,::valToStr( :vICMSST, 2 ) )
                       	::incluiTag('pCredSN'     ,::valToStr( :pCredSN, 2 ) )
                       	::incluiTag('vCredICMSSN' ,::valToStr( :vCredICMSSN, 2 ) )
                   	ENDIF
                   	IF :CSOSN $ '102,103,300,400'
                      	::incluiTagGrupo('/ICMSSN102')
                   	ELSEIF :CSOSN $ '202,203'
                      	::incluiTagGrupo('/ICMSSN202')
                   	ELSE
                      	::incluiTagGrupo('/ICMSSN'+:CSOSN)
                      ENDIF
                   ENDIF
                END WITH
             	::incluiTagGrupo('/ICMS')


                IF :ItemIPI:CST <> Nil
                  	::incluiTagGrupo('IPI')
                   WITH OBJECT :ItemIPI
                      IF :clEnq <> Nil
                        	::incluiTag('clEnq'        ,:clEnq )
                      ENDIF
                      IF :CNPJProd <> Nil
                        	::incluiTag('CNPJProd'     ,:CNPJProd )
*                      ELSE
*                        	::incluiTag('CNPJProd'     ,'00000000000000' )
                      ENDIF
                      IF :cSelo <> Nil
                        	::incluiTag('cSelo'        ,:cSelo )
                      ENDIF
                      IF :qSelo <> Nil
                        	::incluiTag('qSelo'        ,::valToStr( :qSelo ) )
                      ENDIF
                      IF :cEnq <> Nil
                        	::incluiTag('cEnq'         ,:cEnq )
                      ELSE
                        	::incluiTag('cEnq'         ,'999' )
                      ENDIF
                    	 IF :CST $ '00,49,50,99'
                         ::incluiTagGrupo('IPITrib')
                          	::incluiTag('CST'    ,:CST)
                           ::incluiTag('vBC'        ,::valToStr( :vBC, 2 ) )
                           ::incluiTag('pIPI'       ,::valToStr( :pIPI, 2) )
                           ::incluiTag('vIPI'       ,::valToStr( :vIPI, 2 ) )
                         ::incluiTagGrupo('/IPITrib')
                  	 ELSEIF :CST $ '01,02,03,04,51,52,53,54,55'
                         ::incluiTagGrupo('IPINT')
                          	::incluiTag('CST'    ,:CST)
                         ::incluiTagGrupo('/IPINT')
                      ENDIF
                  	END WITH
                  	::incluiTagGrupo('/IPI')
                ENDIF

                IF :ItemII:vII <> Nil
                 	::incluiTagGrupo('II')
                   WITH OBJECT :ItemII
                     	::incluiTag('vBC'       ,::valToStr( :vBC ) )
                     	::incluiTag('vDespAdu'  ,::valToStr( :vDespAdu ) )
                     	::incluiTag('vII'       ,::valToStr( :vII ) )
                     	::incluiTag('vIOF'      ,::valToStr( :vIOF ) )
                   END WITH
                	::incluiTagGrupo('/II')
                ENDIF

               	::incluiTagGrupo('PIS')
                WITH OBJECT :ItemPIS
                  	IF :CST $ '01,02'
                   	::incluiTagGrupo('PISAliq')
                   ELSEIF :CST $ '03'
                   	::incluiTagGrupo('PISQtde')
                   ELSEIF :CST $ '04,06,07,08,09'
                   	::incluiTagGrupo('PISNT')
                   ELSEIF :CST $ '99'
                   	::incluiTagGrupo('PISOutr')
                   ENDIF
                    	::incluiTag('CST' ,:CST)
                     IF :CST $ '01,02'
                        ::incluiTag('vBC'          ,::valToStr( :vBC ) )
                        ::incluiTag('pPIS'         ,::valToStr( :pPIS ) )
                        ::incluiTag('vPIS'         ,::valToStr( :vPIS ) )
                    	ELSEIF :CST $ '03'
                        ::incluiTag('qBCProd'      ,::valToStr( :qBCProd ) )
                        ::incluiTag('vAliqProd'    ,::valToStr( :vAliqProd ) )
                        ::incluiTag('vPIS'         ,::valToStr( :vPIS ) )
                    	ELSEIF :CST $ '04,05,06,07,08,09'
                    	ELSEIF ::CST $ '99'
                    	   IF :vBC <> Nil
                           :incluiTag('vBC'          ,::valToStr( :vBC ) )
                          	::incluiTag('pPIS'         ,::valToStr( :pPIS ) )
                        ELSE
                          	::incluiTag('qBCProd'   ,::valToStr( :qBCProd ) )
                          	::incluiTag('vAliqProd' ,::valToStr( :vAliqProd ) )
                        ENDIF
                        ::incluiTag('vPIS'         ,::valToStr( :vPIS ) )
                     ENDIF
                 	 IF :CST $ '01,02'
                   	::incluiTagGrupo('/PISAliq')
                   ELSEIF :CST $ '03'
                   	::incluiTagGrupo('/PISQtde')
                   ELSEIF :CST $ '04,06,07,08,09'
                   	::incluiTagGrupo('/PISNT')
                   ELSEIF :CST $ '99'
                   	::incluiTagGrupo('/PISOutr')
                   ENDIF
                END WITH
             	::incluiTagGrupo('/PIS')

                IF :ItemPISST:vPIS <> Nil
                 	::incluiTagGrupo('PISST')
                   WITH OBJECT :ItemPISST
                      IF :vBC <> Nil
                        	::incluiTag('vBC'       ,::valToStr( :vBC ) )
                        	::incluiTag('pPIS'      ,::valToStr( :pPIS ) )
                      ELSE
                        	::incluiTag('qBCProd'   ,::valToStr( :qBCProd ) )
                       	::incluiTag('vAliqProd' ,::valToStr( :vAliqProd ) )
                      ENDIF
                     	::incluiTag('vPIS'         ,::valToStr( :vPIS ) )
                   END WITH
                	::incluiTagGrupo('/PISST')
                ENDIF

               	::incluiTagGrupo('COFINS')
                WITH OBJECT :ItemCOFINS
                  	IF :CST $ '01,02'
                   	::incluiTagGrupo('COFINSAliq')
                   ELSEIF :CST $ '03'
                   	::incluiTagGrupo('COFINSQtde')
                   ELSEIF :CST $ '04,06,07,08,09'
                   	::incluiTagGrupo('COFINSNT')
                   ELSEIF :CST $ '99'
                   	::incluiTagGrupo('COFINSOutr')
                   ENDIF
                    	::incluiTag('CST' ,:CST)
                     	IF :CST $ '01,02'
                        	::incluiTag('vBC'          ,::valToStr( :vBC ) )
                        	::incluiTag('pCOFINS'      ,::valToStr( :pCOFINS ) )
                        	::incluiTag('vCOFINS'      ,::valToStr( :vCOFINS ) )
                    	ELSEIF :CST $ '03'
                        	::incluiTag('qBCProd'      ,::valToStr( :qBCProd ) )
                        	::incluiTag('vAliqProd'    ,::valToStr( :vAliqProd ) )
                        	::incluiTag('vCOFINS'      ,::valToStr( :vCOFINS ) )
                    	ELSEIF :CST $ '04,05,06,07,08,09'
                    	ELSEIF ::CST $ '99'
                    	   IF :vBC <> Nil
                           	::incluiTag('vBC'       ,::valToStr( :vBC ) )
                          	::incluiTag('pCOFINS'   ,::valToStr( :pCOFINS ) )
                         ELSE
                          	::incluiTag('qBCProd'   ,::valToStr( :qBCProd ) )
                          	::incluiTag('vAliqProd' ,::valToStr( :vAliqProd ) )
                         ENDIF
                        	::incluiTag('vCOFINS'      ,::valToStr( :vCOFINS ) )
                    	ENDIF
                  	IF :CST $ '01,02'
                   	::incluiTagGrupo('/COFINSAliq')
                   ELSEIF :CST $ '03'
                   	::incluiTagGrupo('/COFINSQtde')
                   ELSEIF :CST $ '04,06,07,08,09'
                   	::incluiTagGrupo('/COFINSNT')
                   ELSEIF :CST $ '99'
                   	::incluiTagGrupo('/COFINSOutr')
                   ENDIF
                END WITH
             	::incluiTagGrupo('/COFINS')

                IF :ItemCOFINSST:vCOFINS <> Nil
                 	::incluiTagGrupo('COFINSST')
                   WITH OBJECT :ItemCOFINSST
                      IF :vBC <> Nil
                        	::incluiTag('vBC'       ,::valToStr( :vBC ) )
                        	::incluiTag('pCOFINS'      ,::valToStr( :pCOFINS ) )
                      ELSE
                        	::incluiTag('qBCProd'   ,::valToStr( :qBCProd ) )
                       	::incluiTag('vAliqProd' ,::valToStr( :vAliqProd ) )
                      ENDIF
                     	::incluiTag('vCOFINS'         ,::valToStr( :vCOFINS ) )
                   END WITH
                	::incluiTagGrupo('/COFINSST')
                ENDIF

          	::incluiTagGrupo('/imposto')
            IF :infAdProd <> Nil
              	::incluiTag('infAdProd'   ,:infAdProd )
           	ENDIF
       	::incluiTagGrupo('/det')
          END WITH
       NEXT
    	::incluiTagGrupo('total')
       WITH OBJECT :Totais:ICMS
        	::incluiTagGrupo('ICMSTot')
          	::incluiTag('vBC'     ,::valToStr( :vBC, 2 ) )
          	::incluiTag('vICMS'   ,::valToStr( :vICMS, 2 ) )
          	::incluiTag('vBCST'   ,::valToStr( :vBCST, 2 ) )
          	::incluiTag('vST'     ,::valToStr( :vST, 2 ) )
          	::incluiTag('vProd'   ,::valToStr( :vProd, 2 ) )
          	::incluiTag('vFrete'  ,::valToStr( :vFrete, 2 ) )
          	::incluiTag('vSeg'    ,::valToStr( :vSeg, 2 ) )
          	::incluiTag('vDesc'   ,::valToStr( :vDesc, 2 ) )
          	::incluiTag('vII'     ,::valToStr( :vII, 2 ) )
          	::incluiTag('vIPI'    ,::valToStr( :vIPI, 2 ) )
          	::incluiTag('vPIS'    ,::valToStr( :vPIS, 2 ) )
          	::incluiTag('vCOFINS' ,::valToStr( :vCOFINS, 2 ) )
          	::incluiTag('vOutro'  ,::valToStr( :vOutro, 2 ) )
          	::incluiTag('vNF'     ,::valToStr( :vNF, 2 ) )
        	::incluiTagGrupo('/ICMSTot')
       END WITH
       WITH OBJECT :Totais:retTrib
     	   IF :vRetPIS <> Nil .OR. :vRetCOFINS <> Nil .OR. :vRetCSLL <> Nil .OR. :vBCIRRF <> Nil .OR. :vIRRF <> Nil .OR. :vBCRetPrev <> Nil .OR. :vRetPrev <> Nil
        	::incluiTagGrupo('retTrib')
        	   IF :vRetPIS <> Nil
             	::incluiTag('vRetPIS'     ,::valToStr( :vRetPIS, 2 ) )
             ENDIF
        	   IF :vRetCOFINS <> Nil
             	::incluiTag('vRetCOFINS'  ,::valToStr( :vRetCOFINS, 2 ) )
             ENDIF
        	   IF :vRetCSLL <> Nil
             	::incluiTag('vRetCSLL'    ,::valToStr( :vRetCSLL, 2 ) )
             ENDIF
        	   IF :vBCIRRF <> Nil
             	::incluiTag('vBCIRRF'     ,::valToStr( :vBCIRRF, 2 ) )
             ENDIF
        	   IF :vIRRF <> Nil
             	::incluiTag('vIRRF'       ,::valToStr( :vIRRF, 2 ) )
             ENDIF
        	   IF :vBCRetPrev <> Nil
             	::incluiTag('vBCRetPrev'  ,::valToStr( :vBCRetPrev, 2 ) )
             ENDIF
        	   IF :vRetPrev <> Nil
             	::incluiTag('vRetPrev'    ,::valToStr( :vRetPrev, 2 ) )
             ENDIF
        	::incluiTagGrupo('/retTrib')
        	ENDIF
       END WITH
    	::incluiTagGrupo('/total')

    	::incluiTagGrupo('transp')
       WITH OBJECT :transp
       	::incluiTag('modFrete'  ,::valToStr( :modFrete ) )
          WITH OBJECT :transporta
             IF :xNome <> Nil
             	::incluiTagGrupo('transporta')
          	      IF :CNPJ <> Nil
                     	::incluiTag('CNPJ'     ,:CNPJ )
          	      ELSE
                     	::incluiTag('CPF'      ,:CPF )
                   ENDIF
                	::incluiTag('xNome'  ,:xNome )
          	      IF :IE <> Nil
                   	::incluiTag('IE'     ,:IE )
                   ENDIF
          	      IF :xEnder <> Nil
                    	::incluiTag('xEnder' ,:xEnder )
                   ENDIF
          	      IF :xMun <> Nil
                   	::incluiTag('xMun'   ,:xMun )
                   ENDIF
          	      IF :UF <> Nil
                   	::incluiTag('UF'     ,:UF )
                   ENDIF
             	::incluiTagGrupo('/transporta')
             ENDIF
          END WITH
          WITH OBJECT :veicTransp
             IF :placa <> Nil
               	::incluiTagGrupo('veicTransp')
                IF !::oFuncoes:validaPlaca( :placa )
                   aRetorno[ 'OK' ] := .F.
                   aRetorno[ 'MsgErro' ] := 'Placa inválida ' + :placa
                   RETURN( aRetorno )
                ENDIF

               	::incluiTag('placa' ,:placa )
               	::incluiTag('UF'    ,:UF )
               	IF :RNTC <> Nil
               	::incluiTag('RNTC'    ,:RNTC )
               	ENDIF
               	::incluiTagGrupo('/veicTransp')
             ENDIF
          END WITH
          WITH OBJECT :vol
       	   IF :qVol <> Nil .OR. :esp <> Nil .OR. :pesoL <> Nil .OR. :pesoB <> Nil
             	::incluiTagGrupo('vol')
       	      IF :qVol <> Nil
                	::incluiTag('qVol'   ,::valToStr( :qVol ) )
                ENDIF
       	      IF :esp <> Nil
                	::incluiTag('esp'   ,:esp )
                ENDIF
       	      IF :marca <> Nil
                	::incluiTag('marca'   ,:marca )
                ENDIF
       	      IF :nVol <> Nil
                	::incluiTag('nVol'   ,:nVol )
                ENDIF
       	      IF :pesoL <> Nil
                	::incluiTag('pesoL'   ,::valToStr( :pesoL ) )
                ENDIF
       	      IF :pesoB <> Nil
                	::incluiTag('pesoB'   ,::valToStr( :pesoB ) )
                ENDIF
             	::incluiTagGrupo('/vol')
             ENDIF
          END WITH
      END WITH
    	::incluiTagGrupo('/transp')

       IF :cobr:nItensDup > 0
         	::incluiTagGrupo('cobr')
          FOR nItemDup = 1 TO :cobr:nItensDup
            	::incluiTagGrupo('dup')
             WITH OBJECT :cobr:ItemDup[nItemDup]
              	::incluiTag('nDup'   ,:nDup )
              	::incluiTag('dVenc'  ,::oFuncoes:FormatDate( :dVenc,"YYYY-MM-DD","-") )
              	::incluiTag('vDup'   ,::valToStr( :vDup ) )
             END WITH
            	::incluiTagGrupo('/dup')
          NEXT
         	::incluiTagGrupo('/cobr')
       ENDIF

       IF :InfAdic:infCpl <> Nil .OR. :ObsCont:nItensObs > 0
       	::incluiTagGrupo('infAdic')
       	IF :InfAdic:infCpl <> Nil
       	   ::incluiTag('infCpl',:InfAdic:infCpl )
         ENDIF
         IF :ObsCont:nItensObs > 0
            FOR nItem = 1 TO :ObsCont:nItensObs
               WITH OBJECT :ObsCont:ItemObs[nItem]
                  IF :xCampo = Nil .OR. EMPTY(:xCampo)
                     aRetorno[ 'MsgErro' ] := 'Adicionada uma ObsCont sem a tag xCampo'
                     RETURN(aRetorno)
                  ENDIF
               	::incluiTagGrupo('obsCont xCampo="'+:xCampo+'"')
               	   ::incluiTag('xTexto',:xTexto )
               	::incluiTagGrupo('/obsCont')
               END WITH
            NEXT
          ENDIF
      	::incluiTagGrupo('/infAdic')
       ENDIF

    	::incluiTagGrupo('/infNFe')

    	::incluiTagGrupo('/NFe')
    END WITH

   aRetorno[ 'OK' ] := .T.

   hb_MemoWrit( ::ohbNFe:pastaNFe + "\" + ::cChave + '-nfe.xml', ::cXMLSaida )
   IF ::lValida
        oAssina := hbNFeAssina()
        oAssina:ohbNFe := ::ohbNfe // Objeto hbNFe
        oAssina:cXMLFile := ::ohbNFe:pastaNFe+"\"+::cChave+'-nfe.xml'
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
        oValida:cXML := ::ohbNFe:pastaNFe+"\"+::cChave+'-nfe.xml' // Arquivo XML ou ConteudoXML
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
RETURN(aRetorno)

METHOD incluiTagGrupo(cTag) CLASS hbNFeCreator
   ::cXMLSaida += '<'+cTag+'>'
RETURN Nil

METHOD incluiTag(cTag,cValor,lExigida) CLASS hbNFeCreator
   IF lExigida == Nil
      lExigida := .T.
   ENDIF
   IF cValor = Nil
      IF lExigida = .T.
         ::cXMLSaida += '<'+cTag+' />'
      ENDIF
   ELSEIF EMPTY(cValor)
      IF lExigida = .T.
         IF cTag == 'nro'
            ::cXMLSaida += '<'+cTag+'>'+cValor+'</'+cTag+'>'
         ELSE
            ::cXMLSaida += '<'+cTag+' />'
         ENDIF
      ENDIF
   ELSE
      cValor := ::oFuncoes:parseEncode( cValor )  // TRATA CARACTERES ESPECIAIS
      ::cXMLSaida += '<'+cTag+'>'+cValor+'</'+cTag+'>'
   ENDIF
RETURN Nil

METHOD valToStr(cnCampo, nDec) CLASS hbNFeCreator
LOCAL cRetorno
   IF VALTYPE(cnCampo) = 'N'
      IF nDec <> Nil
         cRetorno := ALLTRIM( STR( cnCampo, 20, nDec ) )
      ELSE
         cRetorno := ALLTRIM( STR( cnCampo ) )
      ENDIF
   ELSE
*      IF cnCampo = Nil .AND. nDec <> Nil
*         cRetorno := ALLTRIM( STR( 0.00, 20, nDec ) )
*      ELSE
         cRetorno := cnCampo
*      ENDIF
   ENDIF
RETURN(cRetorno)
