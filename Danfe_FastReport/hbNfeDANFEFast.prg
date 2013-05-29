/*
 * Projeto: hbNFe - Open Source
 * Arquivo: hbNfeDanfeFast.prg
 * Descrição: Módulo para impressão do DANFE em FastReport
 * Autor: Wilson Alves - CASTELO Porto Software - www.casteloporto.com.br
 * Ajustes: Leonardo Machado - 20/12/2012
 * Data: 06-09-2011
 */

#include "common.ch"
#include "hbclass.ch"
#include "HBXML.ch"

#define eMascFone  "@R (99) 9999-9999"

#ifndef __XHARBOUR__
   #include "hbcompat.ch"
#endif

#define CRLF chr(13)+chr(10)

STATIC FastReport

//-----------------------------------
CLASS hbNfeDANFEFast
//-----------------------------------
   DATA ID

   DATA ArquivoFR3
   DATA ArquivoXML
   DATA ArquivoPDF

   DATA Modo       AS NUMERIC INIT 0 // 0-Gera relatório  / 2 - Design'
   DATA Impressora INIT ''
   DATA Copias     AS NUMERIC INIT 1 // Numero de copias a ser impressa

   DATA PreVisualizar AS LOGICAL INIT .T.

   DATA aVariaveis INIT {}

   DATA FromParam AS LOGICAL

   DATA produto,faturas,med
   DATA aTempDB
   
   DATA nLogoStyle   // Mauricio Cruz - 29/09/2011    1-esquerda, 2-direita, 3-expandido
   DATA ImprimirHora // Mauricio Cruz - 05/10/2011    0-nao imprime data e hora da impressao, 1-imprime 
   DATA cLogoMarca   // Mauricio Cruz - 25/10/2011    caminho da logo marca
   
	  DATA cCancelada   // juliana - 22/11/2012           nota cancelada
	  DATA cDenegada    // juliana - 22/11/2012           nota denegada

   DATA cSHOWlogo INIT 'S'
   
   METHOD Executa()
   METHOD ExecutaFast()
   METHOD CriaTabelasTemporarias()
   METHOD FechaTemporarias()

   METHOD CarregaItems()
   METHOD AdicionaVariavel( cName, oPublic, uValue , NoQuote )


   METHOD AdicionaProduto()

   METHOD AdicionaImpostos()
   METHOD AdicionaICMS()
   METHOD AdicionaIPI()

   METHOD PutValue( cName ,cData )

   METHOD AdicionaISSQN( oIPI )

   METHOD AdicionaFaturas( oCob )
   METHOD InsereMed( oChild )

   METHOD SavePDF( cFile )
ENDCLASS

//----------------------------------------
METHOD Executa( Fast )
//----------------------------------------
   Local objInf
   Local Nfe
   Local x
   Local aEstru   := {}
   Local cChave
   Local uDataTime,uData,uTime
   LOCAL nRET:=0  // Mauricio Cruz - 29/09/2011
   LOCAL aRetorno:=HASH()  // Mauricio Cruz - 25/10/2011
   LOCAL cOBSfisc:='', cOBSfisc_COMPL:=''
   LOCAL nSCAN:=0
   
   IF .NOT. FILE( ::arquivoXML )
      aRetorno['OK']:=.F.
      aRetorno['MsgErro']:='Não existe o arquivo: '+::arquivoXML
      RETURN(aRetorno)
   ENDIF
   
   objInf := XmlToObj( ::arquivoXML ,'nfeProc' )
   
   IF hb_isObject( objInf )
      Nfe      := objInf:Nfe
   ELSE
      Nfe      := XmlToObj( ::arquivoXML,'NFe' )
   ENDIF

   IF VALTYPE(Nfe)<>'O'
      Nfe      := XmlToObj( ::arquivoXML,'NFe' )
   ENDIF

   IF Nfe == Nil //.OR. Nfe:GetPos('infNfe')==0    Mauricio Cruz - 29/09/2011
      aRetorno['OK']:=.F.
      aRetorno['MsgErro']:="Não parece ser um XML de Nota Fiscal Eletronica"
      Return(aRetorno)
   ENDIF

   // Mauricio Cruz - 29/09/2011
   nRET:=0
   TRY
      nRET:=Nfe:GetPos('infNfe')
   CATCH
      aRetorno['OK']:=.F.
      aRetorno['MsgErro']:="Erro ao ler o arquivo XML."
      nRET=-1
   END
   IF nRET<0
      Return(aRetorno)
   ENDIF
   IF nRET=0
      aRetorno['OK']:=.F.
      aRetorno['MsgErro']:="Não parece ser um XML de Nota Fiscal Eletronica"
      Return(aRetorno)
   ENDIF

   ::aVariaveis:={}
   
   fastReport := frReportManager():new()

   FastReport:SetEventHandler("Report", "OnUserFunction", {|FName, FParams| frCallUserFunction( FName  , FParams   ) } )
   FastReport:AddFunction( "FUNCTION MaskCNPJCPF( uFone: String):String","CPS","Retorna conteúdo em formato CNPJ ou CPF")
   FastReport:AddFunction( "FUNCTION ZMaskCNPJCPF( uFone: String):String","CPS","Retorna conteúdo em formato CNPJ ou CPF")
   FastReport:AddFunction( "FUNCTION MaskCEP( uFone: String):String","CPS","Retorna conteúdo em formato CEP")
   FastReport:AddFunction( "FUNCTION Transform(uValue : Variant, cMask:Variant ): Variant", "CPS", "Função Transform")
   FastReport:AddFunction( "FUNCTION StrZero(uValue: Variant, uLen: Integer):String", "CPS", "Funcao strzero da xiRébis" )
   FastReport:AddFunction( "FUNCTION MaskCNPJ( uFone: String):String","CPS","Retorna conteúdo em formato CNPJ")
   FastReport:AddFunction( "FUNCTION MaskCPF( uFone: String):String","CPS","Retorna conteúdo em formato CPF")
   FastReport:AddFunction( "FUNCTION MaskFone( uFone: String):String","CPS","Retorna conteúdo em formato como telefone")
   FastReport:AddFunction( "FUNCTION Empty(uValue: Variant = EmptyVar):Boolean", "CPS", "Funcao verificar se está vazio")

/*
   IF hb_isNil( fastReport )
      if hb_isnil( fast )

         FastReport:=frReportManager():Init()
         FastReport:SetEventHandler("Report", "OnUserFunction", {|FName, FParams| frCallUserFunction( FName  , FParams   ) } )

         FastReport:AddFunction( "FUNCTION MaskCNPJCPF( uFone: String):String","CPS","Retorna conteúdo em formato CNPJ ou CPF")
         FastReport:AddFunction( "FUNCTION ZMaskCNPJCPF( uFone: String):String","CPS","Retorna conteúdo em formato CNPJ ou CPF")
         FastReport:AddFunction( "FUNCTION MaskCEP( uFone: String):String","CPS","Retorna conteúdo em formato CEP")
         FastReport:AddFunction( "FUNCTION Transform(uValue : Variant, cMask:Variant ): Variant", "CPS", "Função Transform")
         FastReport:AddFunction( "FUNCTION StrZero(uValue: Variant, uLen: Integer):String", "CPS", "Funcao strzero da xiRébis" )
         FastReport:AddFunction( "FUNCTION MaskCNPJ( uFone: String):String","CPS","Retorna conteúdo em formato CNPJ")
         FastReport:AddFunction( "FUNCTION MaskCPF( uFone: String):String","CPS","Retorna conteúdo em formato CPF")
         FastReport:AddFunction( "FUNCTION MaskFone( uFone: String):String","CPS","Retorna conteúdo em formato como telefone")
         FastReport:AddFunction( "FUNCTION Empty(uValue: Variant = EmptyVar):Boolean", "CPS", "Funcao verificar se está vazio")

      else
         FastReport:=Fast
      endif

   ELSE
      FastReport:Clear()
      FastReport:ClearDataSets()
   ENDIF
*/

   ::CriaTabelasTemporarias()

   
   IF .NOT. FILE( ::arquivoFR3  )  // SE NÃO ENCONTRAR O FR3 CRIA AUTOMATICAMENTE se modo design

      IF ::Modo == 2
         FastReport:SaveToFile( ::arquivoFR3  )
      ELSE
         aRetorno['OK']:=.F.
         aRetorno['MsgErro']:='ERRO: ARQUIVO FR3 não localizado'
         Return(aRetorno)
      ENDIF

   ENDIF
   FastReport:LoadFromFile( ::ArquivoFR3 )

   Nfe:InfNFE:IDE:DEmi := aaaammdd2Date( Nfe:InfNFE:IDE:DEmi  )
   Nfe:InfNFE:IDE:dSaiEnt := aaaammdd2Date( Nfe:InfNFE:IDE:dSaiEnt  )   // Mauricio Cruz - 04/10/2011

   IF valtype(Nfe:InfNFE:IDE:NNF  )=='C'
      Nfe:InfNFE:IDE:NNF  := VAL( Nfe:InfNFE:IDE:NNF   )
   ENDIF

   Nfe:InfNFE:IDE:NNF  := TransForm(StrZero( Nfe:InfNFE:IDE:NNF , 9 ),"@R 999.999.999" )

   IF valtype(Nfe:InfNFE:IDE:Serie )=='C'
      Nfe:InfNFE:IDE:Serie:=VAL(Nfe:InfNFE:IDE:Serie )
   ENDIF

   Nfe:InfNFE:IDE:Serie := StrZero(Nfe:InfNFE:IDE:Serie, 3 )
   
   
   

   ::AdicionaVariavel( 'IDE'    , Nfe:InfNFE:Ide)
   //::AdicionaVariavel( 'IDE'    , 'FromParam'  , quoteSTr( if( ::FromParam,'Sim','Não') ) )

   Nfe:infNFE:Emit:Check('IEST')

   ::AdicionaVariavel( 'Emit'        , Nfe:InfNFE:Emit )

   Nfe:InfNFE:Emit:Check('EnderEmit',,.T.)

   Nfe:InfNFE:Emit:EnderEmit:Check('xLgr')
   Nfe:InfNFE:Emit:EnderEmit:Check('nro')
   Nfe:InfNFE:Emit:EnderEmit:Check('xCpl')
   Nfe:InfNFE:Emit:EnderEmit:Check('xBairro')
   Nfe:InfNFE:Emit:EnderEmit:Check('cMun')
   Nfe:InfNFE:Emit:EnderEmit:Check('xMun')
   Nfe:InfNFE:Emit:EnderEmit:Check('UF')
   Nfe:InfNFE:Emit:EnderEmit:Check('CEP')
   Nfe:InfNFE:Emit:EnderEmit:Check('cPais')
   Nfe:InfNFE:Emit:EnderEmit:Check('fone')
   Nfe:InfNFE:Emit:EnderEmit:Check('IE')
   Nfe:InfNFE:Emit:EnderEmit:Check('IEST')
   Nfe:InfNFE:Emit:EnderEmit:Check('IM')
   Nfe:InfNFE:Emit:EnderEmit:Check('CNAE')

   ::AdicionaVariavel( 'enderEmit' , Nfe:InfNFE:Emit:enderEmit )
   ::AdicionaVariavel( 'Dest'      , Nfe:InfNFE:Dest )
   
   IF !EMPTY(Nfe:InfNFE:Dest:CPF)
      ::AdicionaVariavel( 'IDE', 'TipoPes_Dest'  , 'F' )
   ELSEIF !EMPTY(Nfe:InfNFE:Dest:CNPJ)
      ::AdicionaVariavel( 'IDE', 'TipoPes_Dest'  , 'J' )
   ELSE
      ::AdicionaVariavel( 'IDE', 'TipoPes_Dest'  , ' ' )
   ENDIF

   Nfe:InfNFE:Dest:Check('enderDest',,.T.)
   Nfe:InfNFE:Dest:enderDest:Check('xLgr')
   Nfe:InfNFE:Dest:enderDest:Check('nro')
   Nfe:InfNFE:Dest:enderDest:Check('xCpl')
   Nfe:InfNFE:Dest:enderDest:Check('xBairro')
   Nfe:InfNFE:Dest:enderDest:Check('cMun')
   Nfe:InfNFE:Dest:enderDest:Check('xMun')
   Nfe:InfNFE:Dest:enderDest:Check('UF')
   Nfe:InfNFE:Dest:enderDest:Check('CEP')
   Nfe:InfNFE:Dest:enderDest:Check('cPais')
   Nfe:InfNFE:Dest:enderDest:Check('fone')
   Nfe:InfNFE:Dest:enderDest:Check('IE')
   Nfe:InfNFE:Dest:enderDest:Check('ISUF')
   
   ::AdicionaVariavel( 'enderDest' , Nfe:InfNFE:Dest:enderDest )
   ::AdicionaVariavel( 'Total'     , Nfe:InfNFE:Total:icmsTot )
   
   Nfe:InfNFE:Check('entrega',,.T.)
   Nfe:InfNFE:entrega:Check('CNPJ')
   Nfe:InfNFE:entrega:Check('CPF')
   Nfe:InfNFE:entrega:Check('xLgr')
   Nfe:InfNFE:entrega:Check('nro')
   Nfe:InfNFE:entrega:Check('xCpl')
   Nfe:InfNFE:entrega:Check('xBairro')
   Nfe:InfNFE:entrega:Check('cMun')
   Nfe:InfNFE:entrega:Check('xMun')
   Nfe:InfNFE:entrega:Check('UF')
   
   ::AdicionaVariavel( 'endEntrega' , Nfe:InfNFE:entrega )
   
   Nfe:InfNfe:Check('Transp' , ,.T.)


   Nfe:InfNFE:Transp:Check('Transporta', ,.T.)

   IF !EMPTY(Nfe:InfNFE:Transp:Transporta:CPF)
      ::AdicionaVariavel( 'IDE', 'TipoPes_Transp'  , 'F' )
   ELSEIF !EMPTY(Nfe:InfNFE:Transp:Transporta:CNPJ)
      ::AdicionaVariavel( 'IDE', 'TipoPes_Transp'  , 'J' )
   ELSE
      ::AdicionaVariavel( 'IDE', 'TipoPes_Transp'  , ' ' )
   ENDIF

   Nfe:InfNFE:Transp:Transporta:Check('CNPJ')
   Nfe:InfNFE:Transp:Transporta:Check('CPF')
   Nfe:InfNFE:Transp:Transporta:Check('xNOme')
   Nfe:InfNFE:Transp:Transporta:Check('IE')
   Nfe:InfNFE:Transp:Transporta:Check('xEnder')
   Nfe:InfNFE:Transp:Transporta:Check('xMun')
   Nfe:InfNFE:Transp:Transporta:Check('UF')


   Nfe:InfNFE:Transp:Check('Reboque',,.T.)
   Nfe:InfNFE:Transp:Reboque:Check('placa')
   Nfe:InfNFE:Transp:Reboque:Check('UF')
   Nfe:InfNFE:Transp:Reboque:Check('RNTC')

   **************************************

   Nfe:InfNFE:Transp:Check('veicTransp',,.T.)
   Nfe:InfNFE:Transp:veicTransp:Check('placa')
   Nfe:InfNFE:Transp:veicTransp:Check('UF')
   Nfe:InfNFE:Transp:veicTransp:Check('RNTC')


   ************************************************

   Nfe:InfNFE:Transp:Check('vol',,.T.)
   Nfe:InfNFE:Transp:vol:Check('qVol')
   Nfe:InfNFE:Transp:vol:Check('esp')
   Nfe:InfNFE:Transp:vol:Check('marca')
   Nfe:InfNFE:Transp:vol:Check('nvol')
   Nfe:InfNFE:Transp:vol:Check('pesoL')

   IF !Empty( Nfe:InfNFE:Transp:vol:pesoL )
      Nfe:InfNFE:Transp:vol:pesoL:=StrTran(Nfe:InfNFE:Transp:vol:pesoL , "." , "," )
   ENDIF

   Nfe:InfNFE:Transp:vol:Check( 'pesoB' )

   IF !Empty( Nfe:InfNFE:Transp:vol:pesoB )
      Nfe:InfNFE:Transp:vol:pesoB:=StrTran( Nfe:InfNFE:Transp:vol:pesoB , "." , ","  )
   ENDIF

   ::AdicionaVariavel( 'Transp', Nfe:InfNFE:Transp)
   ::AdicionaVariavel( 'Transp', Nfe:InfNFE:Transp:Transporta)
   ::AdicionaVariavel( 'TranspVolume', Nfe:InfNFE:Transp:vol)
   ::AdicionaVariavel( 'TranspReboque', Nfe:InfNFE:Transp:Reboque)
   ::AdicionaVariavel( 'TranspVeiculo', Nfe:InfNFE:Transp:veicTransp)

   Nfe:InfNFE:Check('infAdic',,.T.)
   Nfe:InfNFE:infAdic:Check('infAdFisco')
   Nfe:InfNFE:infAdic:Check('infCPL')

   Nfe:InfNFE:infAdic:Check('obsCont',,.T.)
   Nfe:InfNFE:infAdic:obsCont:Check('xCampo')
   Nfe:InfNFE:infAdic:obsCont:Check('xtexto')

   Nfe:InfNFE:infAdic:Check('obsFisco',,.T.)
   Nfe:InfNFE:infAdic:obsFisco:Check('xCampo')
   Nfe:InfNFE:infAdic:obsFisco:Check('xtexto')

   ::AdicionaVariavel( 'infAdic'         , Nfe:InfNFE:infAdic )
   ::AdicionaVariavel( 'infAdicObsCont'  , Nfe:InfNFE:infAdic:obsCont)
   ::AdicionaVariavel( 'infAdicObsFisco' , Nfe:InfNFE:infAdic:obsFisco)
   

   // VERIFICA SE EH PRECISO CONTINUAR COM A OBSERVACAO NO CORPO DA NOTA FISCAL
   nSCAN:=ASCAN(::aVariaveis,{|x|  x[1]='infAdic' .and. x[2]='infAdic_INFADFISCO' })
   IF nSCAN>0
      IF VALTYPE(::aVariaveis[nSCAN,3])='C' .AND. LEN(::aVariaveis[nSCAN,3])>0
         cOBSfisc:=::aVariaveis[nSCAN,3]
      ENDIF
   ENDIF
   nSCAN:=ASCAN(::aVariaveis,{|x|  x[1]='infAdic' .and. x[2]='infAdic_INFCPL' })
   IF nSCAN>0
      IF VALTYPE(::aVariaveis[nSCAN,3])='C' .AND. LEN(::aVariaveis[nSCAN,3])>0
         cOBSfisc+=::aVariaveis[nSCAN,3]
      ENDIF
   ENDIF
   
   cOBSfisc:=ALLTRIM(cOBSfisc)
   IF LEN(cOBSfisc)>1180
      cOBSfisc_COMPL:=SUBSTR(cOBSfisc,1181,LEN(cOBSfisc))
      cOBSfisc:=LEFT(cOBSfisc,1180)
     
      nSCAN:=ASCAN(::aVariaveis,{|x|  x[1]='infAdic' .and. x[2]='infAdic_INFADFISCO' })
      IF nSCAN>0
         ::aVariaveis[nSCAN,3]:=cOBSfisc
      ENDIF

      nSCAN:=ASCAN(::aVariaveis,{|x|  x[1]='infAdic' .and. x[2]='infAdic_INFCPL' })
      IF nSCAN>0
         ::aVariaveis[nSCAN,3]:=""
      ENDIF
      cOBSfisc_COMPL:=CLEAR_CHAR(cOBSfisc_COMPL)
      ::AdicionaVariavel( 'IDE', 'CONT_OBS'  , ALLTRIM(cOBSfisc_COMPL) )
/*
      nSCAN:=ASCAN(::aVariaveis,{|x|  x[1]='IDE' .and. x[2]='CONT_OBS' })
      IF nSCAN>0

         ::aVariaveis[nSCAN,3]:=CLEAR_CHAR(::aVariaveis[nSCAN,3])

         ::aVariaveis[nSCAN,3]:=Stuff(::aVariaveis[nSCAN,3],len(::aVariaveis[nSCAN,3]),1,'')

      ENDIF
*/
   ENDIF
   

   Nfe:InfNFE:Total:Check('ISSQNTOT',, .T. )

   Nfe:InfNFE:Total:ISSQNTOT:Check( 'vServ'  )
   Nfe:InfNFE:Total:ISSQNTOT:Check( 'vBC'    )
   Nfe:InfNFE:Total:ISSQNTOT:Check( 'vISS'   )
   Nfe:InfNFE:Total:ISSQNTOT:Check( 'Vpis'   )
   Nfe:InfNFE:Total:ISSQNTOT:Check( 'VCofins')

   ::AdicionaVariavel( 'ISSQN'     , Nfe:InfNFE:Total:ISSQNTOT )
   
   IF hb_isObject( objInf ) .AND.;            //objInf:GetPos( 'retConsReciNFe' ) > 0 .AND. ;    retConsReciNFe??  não localizei esta TAG no XML de nf-e  Mauricio Cruz - 04/10/2011
      ObjInf:GetPos('protNfe') > 0 .AND. ;
      ObjInf:protNfe:GetPos('infProt') > 0

      ObjInf:protNfe:InfProt:Check('dhRecbto')
      ObjInf:protNfe:InfProt:Check('nProt')
      ObjInf:protNfe:InfProt:Check('cStat')
      ObjInf:protNfe:InfProt:Check('xMotivo' )

      IF !EMPTY( objInf:protNfe:infProt:dhRecbto )

         uDataTime := ObjInf:protNfe:InfProt:dhRecbto
         uData     := AAAAMMDD2DATE( uDataTime )
         uTime     := Right( uDataTime , 8 )

         ObjInf:protNfe:InfProt:dhRecbto := DToc(uData) + ' ' + uTime

      ENDIF

      ::AdicionaVariavel( 'infProt'     , ObjInf:protNfe:infProt )
   ELSE
      ::AdicionaVariavel( 'infProt'     , '' )
   ENDIF


   IF !Empty( ::Impressora )
      FastReport:PrintOptions:SetPrinter( ::Impressora )
   ENDIF

   ::CarregaItems(cOBSfisc_COMPL)

   ::AdicionaVariavel( 'IDE', 'ChaveNFE'  , quoteStr( Subs(::ID , 4 )) )
   ::AdicionaVariavel( 'IDE', 'ChaveMask' , quoteStr( Trans( Subs( ::ID , 4 ) , "@R 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999 9999") ) )
   
   ::AdicionaVariavel( 'IDE','nLogoStyle'  , ::nLogoStyle )    // Mauricio Cruz - 29/09/2011
   ::AdicionaVariavel( 'IDE','ImprimirHora', ::ImprimirHora )  // Mauricio Cruz - 05/10/2011
   ::AdicionaVariavel( 'IDE','cLogoMarca',   ::cLogoMarca )    // Mauricio Cruz - 25/10/2011
   ::AdicionaVariavel( 'IDE','cSHOWlogo',    ::cSHOWlogo )     // Mauricio Cruz - 14/12/2011
  	::AdicionaVariavel( 'IDE','cCancelada',   ::cCancelada )     // juliana - 22/11/2012
  	::AdicionaVariavel( 'IDE','cDenegada',    ::cDenegada )      // juliana - 22/11/2012

   
   // Mauricio Cruz - 06/10/2011
   Try
      Nfe:InfNFE:Check('cobr',, .T. )
      Nfe:InfNFE:cobr:Check( 'dup' )
      Nfe:InfNFE:cobr:dup:Check( 'nDup' )
      ::AdicionaVariavel( 'cobr','dup', Nfe:InfNFE:cobr:dup:nDup )
   Catch
      ::AdicionaVariavel( 'cobr','dup', '' )
   End
   
   AEval( ::aVariaveis, {|i| FastReport:AddVariable( i[1], i[2], quoteStr( i[3] )) } )

   FastReport:SetTitle( 'DANFE ' + ::ID + ' Emitente ' + Nfe:infNFE:Emit:xNome  )

   ::ExecutaFast()
   ::FechaTemporarias()

   aRetorno['OK']:=.T.
   
RETURN(aRetorno)

//-----------------------------------------------------
METHOD ExecutaFast()
//-----------------------------------------------------

   IF .NOT. EMPTY( ::ArquivoPDF )

       ::SavePDF( ::arquivoPDF )

   ELSEIF ::Modo == 0
      IF !EMPTY(::Impressora) .AND. !::PreVisualizar
         FastReport:PrintOptions:SetShowDialog(.F.)
         FastReport:PrintOptions:SetPrinter(::Impressora)
         IF ::Copias > 1
            FastReport:PrintOptions:SetCopies(::Copias)
         ENDIF
         FastReport:PrepareReport()
         FastReport:Print( .T. )
      ELSE

         FastReport:PrepareReport()
         IF ::PreVisualizar
            FastReport:ShowReport()
         ELSE
            FastReport:Print( Empty( ::Impressora ) )
         ENDIF
      ENDIF
   ELSEIF ::Modo == 2
      FastReport:LoadLangRes( 'brazil.xml')
      FastReport:DesignReport()
   ENDIF

   FastReport:DestroyFR()


Return NIl

//-----------------------------------------------------
METHOD FechaTemporarias()
//-----------------------------------------------------

   AEval( ::aTempDB,{|i| (i[1])->(dbCloseArea()) , FErase(i[2]) } )
   ASize(::aTempDB,0 )

Return Nil

//------------------------------
METHOD CarregaItems(cOBSfisc_COMPL)
//------------------------------
   Local oRoot,oChild
   Local x
   Local aRetorno:=HASH()  // Mauricio Cruz - 25/10/2011

   With Object TXMLDocument():New( MeMoRead( ::ArquivoXML ) )

      IF (:nStatus==HBXML_STATUS_OK)

         oRoot:=:FindFirst('infNFe')

         ::id:= oRoot:aAttributes["Id"]

         oRoot:=oRoot:oChild

         IF oRoot==Nil
            aRetorno['OK']:=.F.
            aRetorno['MsgErro']:='Items não localizados'
         ELSE

            DO While oRoot!=Nil

               IF oRoot:cName=='det'

                  oChild:=oRoot:oChild

                  DO While oChild!=Nil

                     IF oChild:cName=='prod'
                        ::AdicionaProduto( oChild )
                     ELSEIF oChild:cName=='imposto'
                        ::AdicionaImpostos( oChild )
                     ENDIF

                     oChild:=oChild:oNEXT

                  Enddo

               ELSEIF oRoot:cName=='cobr'
                  ::AdicionaFaturas( oRoot )
               ENDIF

               oRoot:=oRoot:oNEXT

            Enddo
         ENDIF

      ENDIF

   End Object

   IF !EMPTY(cOBSfisc_COMPL)
      (::produto)->( dbAppend() )
      (::produto)->Codigo := (::produto)->( Recno() )
      (::produto)->CPROD := 'CONTI'
      //(::produto)->OBSCONT := cOBSfisc_COMPL
      (::produto)->NCM   := 'CONTINUA'

      //SELECT(::produto)
      //MY_BROWSE(NIL,'TESTE',.T.)
      
   ENDIF
   
   
Return Nil

*********************************************************************************
STATIC FUNCTION xmlToObj( xml , cTag)
*********************************************************************************
Local Obj,oRoot
Local uMEM:=MeMoRead(xml)
Local aRetorno:=HASH()  // Mauricio Cruz - 25/10/2011

   With Object TXMLDocument():New( uMem )

      IF (:nStatus==HBXML_STATUS_OK)

         oRoot:=:FindFirstRegex( cTag )

         IF oRoot==Nil

            oRoot:=:oRoot:oChild

            IF oRoot==NIL
               aRetorno['OK']:=.F.
               aRetorno['MsgErro']:='XML inválido'
            ELSE
               IF oRoot:cName=='xml'
                  oRoot:=oRoot:oNEXT
               ENDIF
            ENDIF
         ENDIF

         IF hb_isobject(oRoot)
            obj := XMLLeFilhos( oRoot:oChild , TPublic():New( .T. ) )
         ENDIF

      ELSE
         aRetorno['OK']:=.F.
         aRetorno['MsgErro']:='XML inválido'
      ENDIF

   End Object

Return Obj

*********************************************
STATIC Function XMLLeFilhos( oChild , oObj )
*********************************************
Local nPos
Local objNew
Local uValue

Do While oChild!=NIL

   IF oChild:nType==0 .AND. hb_isobject(oChild:oChild)

      objNew:=  TPublic():New(.T.)

      oObj:SetArray( oChild:cName , objNew )

      XMLLeFilhos(  oChild:oChild , objNew )

   ELSE

      uValue:=oChild:cData

      IF isDigit( uValue ) .and. UPPER(Left(oChild:cName,1))='V'
         uValue:=Val( uValue )
      ENDIF

      oObj:ADD( oChild:cName , uValue )

   ENDIF

   oChild:=oChild:oNEXT
Enddo

Return oObj

*********************************
METHOD AdicionaVariavel( cName, oPublic, uValue , NoQuote )
*********************************
Local oField
Local uBuffer


IF hb_ISobject(oPublic)

   FOR EACH oField IN oPublic:aFields

      IF !(Valtype( oField[2] )=="O")

         uBuffer:=oField[2]

         noQuote :=if(noquote==nil,.F.,noquote)

         IF valtype(uBuffer)=='C' .AND. !noQuote
            uBuffer:=quoteSTR( oField[2] )
         ENDIF
         
         IF valtype(uBuffer)=='C'
            uBuffer:=CLEAR_CHAR(uBuffer)
         ENDIF

         AADD( ::AVariaveis ,  {cName, cName+'_'+oField[1], uBuffer } )

      ENDIF

   NEXT

ELSE
   IF valtype(uValue)=='C'
      uValue:=CLEAR_CHAR(uValue)
   ENDIF

   AADD( ::AVariaveis ,  {cName, oPublic , uValue, NoQuote } )
ENDIF

Return Nil


//--------------------------------------------------------------
METHOD AdicionaProduto( oProduto )
//--------------------------------------------------------------
Local oChild

(::produto)->( dbAppend() )

(::produto)->Codigo := (::produto)->( Recno() )

oChild:=oProduto:oChild

Do While oChild!=Nil

   IF !hb_isobject(oChild:oChild)
      ::PutValue( oChild:cName , oChild:cData )
   ELSE

      IF Upper(oChild:cName)=='MED'
         ::InsereMed( oChild:oChild )
      ENDIF

   ENDIF

   oChild:=oChild:oNEXT
Enddo

Return Nil

//--------------------------------------------------------------
METHOD InsereMed( oChild )
//--------------------------------------------------------------

(::Med)->( dbAppend() )
(::Med)->CODIGO := (::produto)->CODIGO

Do While oChild!=Nil
   IF !hb_isobject( oChild:oChild )
      ::PutValue( oChild:cName, oChild:cData , , ::med)
   ENDIF
   oChild:=oChild:oNEXT
Enddo

Return Nil

//--------------------------------------------------------------
METHOD AdicionaICMS( oICMS )
//--------------------------------------------------------------
Local oChild:=oICMS:oChild

Do While oChild!=Nil

   IF !hb_isobject( oChild:oChild )
      ::PutValue( oChild:cName, oChild:cData )
   ENDIF

   oChild:=oChild:oNEXT
Enddo

Return Nil

****************************************************************
METHOD PutValue( cName ,cData, cTag, cAlias )
****************************************************************
Local nPos
Local uValue,cType
Local e
Local aRetorno:=HASH()  // Mauricio Cruz - 25/10/2011

   cTag := IF(cTag=NIL, '',cTag)
   cAlias :=IF(cAlias==nil, ::produto, cAlias)



   nPos:=(cAlias)->(FieldPos(cTag+cName))

   IF nPos>0

      uValue:=cData

      cType:=(cAlias)->(FieldType( nPos ))

      IF cType=='N'
         uValue:=Val(uValue)
      ELSEIF cType=='D'
         uValue:=AAAAMMDD2DATE( uValue )
      ENDIF

      try
         (cAlias)->(FieldPut( nPos, uValue ))
      catch e
         aRetorno['OK']:=.F.
         aRetorno['MsgErro']:=oERRO:description
      end

   ENDIF

Return Nil

******************************************************
METHOD AdicionaImpostos( oImpostos )
******************************************************
Local oChild:=oImpostos:oChild
Local cName

While oChild!=Nil

   cName:=Upper(oChild:cName)

   IF cName=='ICMS'
      ::AdicionaICMS( oChild:oChild )
   ELSEIF cName=='IPI'
      ::AdicionaIPI( oChild )
   ELSEIF cNAME=='ISSQN'
      ::AdicionaISSQN( oChild )
   ENDIF

   oChild:=oChild:oNEXT
enddo

Return Nil

****************************************************************
METHOD AdicionaIPI( oIPI )
****************************************************************
Local oChild:=oIPI:oChild
Local oTrib

While oChild!=Nil

   IF oChild:oChild==Nil

   ELSEIF Upper(oChild:cName)=='IPITRIB'

      oTrib:=oChild:oChild

      While oTrib!=Nil
         ::PutValue( oTrib:cName,oTrib:cData, 'IPI')
         oTrib:=oTrib:oNEXT
      enddo

   ENDIF

   oChild:=oChild:oNEXT
enddo

Return Nil

****************************************************************
METHOD AdicionaISSQN( oIPI )
****************************************************************
Local oChild:=oIPI:oChild
Local oTrib

While oChild!=Nil

   IF oChild:oChild==Nil
      ::PutValue( oChild:cName,oChild:cData, 'ISS')
   ENDIF

   oChild:=oChild:oNEXT
enddo

Return Nil

****************************************************************
METHOD AdicionaFaturas( oCob )
****************************************************************
   Local oChild := oCob:oChild
   Local oFat
   Local x

   DO While oChild!=Nil

      IF oChild:cName=='dup' .OR. oChild:cName=='fat'

         oFat := oChild:oChild

         (::faturas)->(DBAppend())

         While oFat!=Nil
            ::PutValue( oFat:cName,oFat:cData ,, ::faturas)
            oFat:=oFat:oNEXT
         enddo

      ENDIF

      oChild:=ochild:oNEXT

   Enddo

Return Nil

///////////////////////////////////////////////////////////////
STATIC FUNCTION AAAAMMDD2DATE( cStr )
///////////////////////////////////////////////////////////////

   cStr:=Left(cStr,10)

Return Ctod( Right(cStr,2)+'/' + Subs(cStr,6,2) + '/'+Left( cStr , 4 ) )


//---------------------------------------------------------------------------------
STATIC FUNCTION QuoteStr( uValue )
//---------------------------------------------------------------------------------

IF uValue==Nil

   uValue:=''

ELSEIF valtype( uValue )=='N'

   uValue:=StrTran( Alltrim(Str(uValue)),'.',',' )

ELSEIF Valtype(uValue)=="D"

   uValue:=Dtoc(uValue)

ENDIF

IF Left(uValue,1)="'" .AND. Right(Alltrim(uValue),1)=="'"
   Return uValue
ENDIF

Return "'"+uValue+"'"


STATIC FUNCTION AdicionaDataSet(FastReport, cAlias , frAlias )
   Local cFields:=''
   Local x

   FOR x := 1 to (cAlias)->(FCount())
       cFields+=(cAlias)->(FieldName(x)) + ";"
   NEXT

   FastReport:SetUserDataSet( frAlias, cFields,;
                              {|| (cAlias)->(dbGoTop()) },;
                              {|| (cAlias)->(dbSkip(1)) },;
                              {|| (cAlias)->(dbSkip(-1)) },;
                              {|| (cAlias)->(EOF()) } ,;
                              {|cField|  (cAlias)->(FieldGet((cAlias)->(FieldPos( cField)))) } )

Return NIL

//////////////////////////////////////
FUNCTION MaskCNPJCPF( uCNPJ )
//////////////////////////////////////


Return IF( Len(Alltrim( uCNPJ) )==11 , MaskCPF( uCNPJ ), MaskCNPJ( uCNPJ ) )

//////////////////////////////////////
FUNCTION ZMaskCNPJCPF( uCNPJ )
//////////////////////////////////////

Return IF( Len(Alltrim( uCNPJ) )==11 , MaskCPF( uCNPJ ), MaskCNPJ( uCNPJ ) )


//////////////////////////////////////
FUNCTION MaskCNPJ( uCNPJ )
//////////////////////////////////////
Local nLen

uCNPJ := Alltrim(uCNPJ)
nLen  := Len(uCNPJ )

IF nLen==14
   uCNPJ:=TransForm(uCNPJ,"@R 99.999.999/9999-99")
ELSEIF nLen==15
   uCNPJ:=TransForm(uCNPJ,"@R 999.999.999/9999-99")
ENDIF

Return uCNPJ

//////////////////////////////////////
FUNCTION MaskCPF( uCNPJ )
//////////////////////////////////////
Local nLen

uCNPJ := Alltrim(uCNPJ)
nLen  := Len(uCNPJ )

IF nLen==11
   uCNPJ:=TransForm(uCNPJ,"@R 999.999.999-99")
ENDIF

Return uCNPJ

//////////////////////////////////////
FUNCTION MaskCEP( uValue )
//////////////////////////////////////
Local nLen

uValue := Alltrim( uValue )
nLen   := Len( uValue )

IF nLen==7
   uValue:=' '+uVAlue
ENDIF

IF ( nLen==8 )
   uValue:=TransForm(uVAlue,"@R 99.999-999")
ENDIF

Return uValue


//////////////////////////////////////
FUNCTION MaskFone( uFone )
//////////////////////////////////////
Local nLen

IF Empty(uFone)
   Return ''
ENDIF

IF VAltype(uFone)=='N'
   uFone:=Alltrim(Str(uFone,19,0) )
ENDIF

uFone := Alltrim(uFone)
nLen  := Len(uFone)

IF nLen==8 .OR. nLen==7

   IF nLen==7
      uFone:=' '+uFone
   ENDIF
   Return Transform(uFone,eMascFone)
ELSEIF nLen==11
   Return Transform(uFone,"@R (99) 99999-9999")
ELSEIF nLen==10 .AND. Left(uFone,1)#0
   Return Transform(uFone,eMascFone)
ELSEIF nLen==10
   Return Transform(uFone,eMascFone)
ENDIF

Return uFone

//------------------------------------------------------------
METHOD CriaTabelasTemporarias()
//------------------------------------------------------------
   Local aEstru:={}
   // Add caminho para pasta temporaria do usuario no windows para evitar de 2 pessoas emitindo NF-e não veja as DANF trocadas   Mauricio Cruz - 04/10/2011
   Local cTempFAT := GETENV('temp') + dtos(date())+strtran(time(),":")+'F.dbf'   // Mauricio Cruz - 04/10/2011
   Local cTempMED := GETENV('temp') + dtos(date())+strtran(time(),":")+'M.dbf'   // Mauricio Cruz - 04/10/2011
   Local cTemp    := GETENV('temp') + dtos(date())+strtran(time(),":")+'.dbf'    // Mauricio Cruz - 04/10/2011
   Local uFile

   ::produto     := 'prd' + StrZero( hb_random(100 ),3 )
   ::med         := 'med' + StrZero( hb_random(100 ),3 )
   ::faturas     := 'fat' + StrZero( hb_random(100 ),3 )

   AADD(aEstru,{'codigo','N',5,0})
   AADD(aEstru,{'cProd','C',60,0})
   AADD(aEstru,{'cEAN','C',14,0})
   AADD(aEstru,{'EXTIPI','C',3,0})

   AADD(aEstru,{'xProd','C',150,0})
   AADD(aEstru,{'NCM','C',8,0})
   AADD(aEstru,{'genero','C',2,0})
   AADD(aEstru,{'CFOP','C',4,0})

   AADD(aEstru,{'uCom','C',50,0})
   AADD(aEstru,{'qCom','N',19,3})
   AADD(aEstru,{'vunCom','N',16,4})
   AADD(aEstru,{'vProd','N',19,2})
   AADD(aEstru,{'cEANTrib','C',16,0})

   AADD(aEstru,{'uTrib','C',6,0})
   AADD(aEstru,{'qTrib','N',19,5})
   AADD(aEstru,{'vunTrib','N',16,4})
   AADD(aEstru,{'vFrete','N',15,2})
   AADD(aEstru,{'vSeg','N',15,2})
   AADD(aEstru,{'vDesc','N',15,2})

   AADD(aEstru,{'CST','C',2,0})
   AADD(aEstru,{'orig','C',2,0})
   AADD(aEstru,{'vBC','N',15,2})
   AADD(aEstru,{'pICMS','N',5,2})
   AADD(aEstru,{'vICMS','N',15,2})

   AADD(aEstru,{'CSTST','C',2,0})
   AADD(aEstru,{'vBCCST','C',2,0})
   AADD(aEstru,{'pICMSST','N',5,2})
   AADD(aEstru,{'vICMSST','N',15,2})

   AADD(aEstru,{'IPIpIPI'  , 'N' ,5  , 2 } )
   AADD(aEstru,{'IPIvIPI' , 'N' ,15 , 4 } )

   AADD(aEstru,{'ISSVBC'  , 'N' ,15  , 2 } )
   AADD(aEstru,{'ISSVALIQ'  , 'N' ,15  , 2 } )
   AADD(aEstru,{'ISSVISSQN'  , 'N' ,15  , 2 } )
   AADD(aEstru,{'ISCMUNCFG'  , 'N' ,7  , 0 } )
   //AADD(aEstru,{'OBSCONT'  , 'M' ,10  , 0 } )

   dbCreate(cTemp , aEstru  , 'DBFCDX' )


   *** Cria Tabela de Faturas
   ASize( aEstru , 0  )
   AADD(aEstru,{'nDup'  , 'C' ,60  , 0 } )
   AADD(aEstru,{'dVenc'  , 'D' ,8, 0 } )
   AADD(aEstru,{'VDup'  , 'N' ,15, 2 } )

   DbCreate(cTempFat , aEstru  , 'DBFCDX' )

   ASize( aEstru , 0  )

   AADD(aEstru,{'codigo','N',5,0})

   AADD(aEstru,{'nLote'  , 'C' ,20  , 0 } )
   AADD(aEstru,{'qLote'  , 'N' ,11  , 3 } )
   AADD(aEstru,{'dFat'   , 'D' , 8, 0 } )
   AADD(aEstru,{'dVenc'  , 'D' , 8, 0 } )
   AADD(aEstru,{'VPmc'   , 'N' ,15, 2 } )

   dbCreate(cTempMED , aEstru  , 'DBFCDX' )

   IF HB_ISNil( ::aTempdB )
      ::aTempDB:={}
   ELSE
      ASize(::aTempDB,0)
   ENDIF

   AADD( ::aTempDB, {::faturas , cTempFat  , 'faturas' } )
   AADD( ::aTempDB, {::produto , cTemp     , 'produto' } )
   AADD( ::aTempDB, {::med     , cTempMED  , 'med' } )

   FOR EACH uFile IN ::aTempDB
      Use (uFile[2]) New Alias (uFile[1])  VIA 'DBFCDX' EXCLUSIVE
   NEXT

   AEVAL( ::aTempDB, {| iDB | AdicionaDataSet( FastReport , iDB[1] ,iDB[3] )  } ) // Adiciona as datasets

Return NIL

*************************************
METHOD SavePDF(cFile )
*************************************
   With Object FastReport
     :PrepareReport()
     :SetProperty("PDFExport", "ShowDialog", .F.)
     :SetProperty("PDFExport", "FileName", cFile )
     :SetProperty("PDFExport", "Compressed", .F. )
     :DoExport('PDFExport')
     :SetProperty("PDFExport", "ShowDialog", .T.)
   End Object

Return Nil

//------------------------------------------------------------------------------*
FUNCTION frCalluserFunction( FName, FParams )
//------------------------------------------------------------------------------*
Local nPont:=hb_FuncPtr( Upper( FName ) )
Local Ret

If HB_ISPOINTER( nPont )
   Ret:=hb_ExecFromArray( nPont, FParams )
Endif

Return Ret






STATIC FUNCTION CLEAR_CHAR(cTXT)
/*
   detona com caracteres indesejados
   Mauricio cruz - 23/11/2011
*/
LOCAL mI, cRET:=cTXT

IF VALTYPE(cRET)<>'C'
   RETURN(cRET)
ENDIF

*IF DAY(CTOD(cRET))>0   // EM CASO DE DATAS
*   RETURN(cRET)
*ENDIF

FOR mI:=1 TO 31
   IF CHR(mI)$cRET
      cRET:=StrTran( cRET, CHR(mI))
   ENDIF
NEXT

FOR mI:=1 TO LEN(cRET) // LENDO LETRA A LETRA
*   IF SUBSTR(cRET,mi,1)="'" .OR.;
*      SUBSTR(cRET,mi,1)='"' .OR.;
*      SUBSTR(cRET,mi,1)="´" .OR.;
*      SUBSTR(cRET,mi,1)='-'
*      cRET:=Stuff( cRET, mi, 1, " " )
*   ENDIF

   cRET:=StrTran( cRET, "'" )
   //cRET:=StrTran( cRET, '"' )
   cRET:=StrTran( cRET, "´" )
   cRET:=StrTran( cRET, "-" )
NEXT

//cRET:=STRTRAN(cRET,'–')
//cRET:=STRTRAN(cRET,"'")
cRET:=TIRAACENTO(cRET)

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
