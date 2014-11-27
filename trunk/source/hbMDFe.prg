#include "common.ch"
#include "hbclass.ch"
#include "hbnfe.ch"
#include "HBXML.ch"

class hbMDFe
   DATA oFuncoes INIT hbNFeFuncoes()
   DATA cXML
   DATA ohbNFe
   DATA tpEmit
   DATA mod
   DATA serie
   DATA nMDF
   DATA cMDF
   DATA cDV
   DATA modal
   DATA dhEmi
   DATA tpEmis
   DATA UFIni
   DATA UFFim
   DATA CNPJ
   DATA cCHAVE
   DATA aMUNcarregamento
   DATA aUFpercurso

   DATA emit_IE
   DATA emit_xNome
   DATA emit_xFant
   DATA emit_xLgr
   DATA emit_nro
   DATA emit_xCpl
   DATA emit_xBairro
   DATA emit_cMun
   DATA emit_xMun
   DATA emit_CEP
   DATA emit_UF
   DATA emit_fone
   DATA emit_email

   DATA modRod_RNTRC
   DATA modRod_CIOT
   DATA modRod_cInt
   DATA modRod_placa
   DATA modRod_tara
   DATA modRod_RNTRC_prop
   DATA modRod_condutor
   DATA modRod_reboque
   DATA modRod_pedagio
   DATA modRod_capKG
   DATA modRod_capM3

   DATA munDes_municipio

   DATA qCTe INIT 0 HIDDEN
   DATA qCT  INIT 0 HIDDEN
   DATA qNFe INIT 0 HIDDEN
   DATA qNF  INIT 0 HIDDEN
   DATA vCarga
   DATA cUnid
   DATA qCarga
   DATA aLACRE
   DATA infAdFisco
   DATA infCpl

   DATA versaoDados

   DATA mdfRecibo

   DATA nProt
   DATA xJust
   DATA URIId

   DATA cUFencerra
   DATA cMUNencerra

   DATA cDANDFE
   DATA cLANG

   DATA lDesign

   Method LinkWebService( cServ )
   Method XMLide()
   Method XMLemit()
   Method XMLmodalRodoviario()
   Method XMLDocumentos()
   Method XMLtot()
   Method Assina_XML()
   Method Valida_XML(cXML)
   Method ComunicaWebService(cXML,cSoap,cService)
   Method RecepcaoMDFe()
   Method RetRecepcaoMDFe()
   Method ConsultaMDF()
   Method StatusServico()
   Method MDFeEvento()
   Method MDFeCancela()
   Method MDFeEncerra()
   Method MDFeImprimeFastReport()

EndCLass


Method LinkWebService( cServ ) Class hbMDFe
/*
   Links dos webservices do MDFe
   Mauricio Cruz - 22/05/2013
*/
LOCAL aWEB:={}
LOCAL nSCAN
LOCAL cRET:=''
//          Serviço              Verc  Produção                                                                    Homologação
AADD(aWEB,{'MDFeRecepcao'      ,'1.0','https://mdfe.sefaz.rs.gov.br/ws/MDFerecepcao/MDFeRecepcao.asmx'            ,'https://mdfe-hml.sefaz.rs.gov.br/ws/MDFerecepcao/MDFeRecepcao.asmx'            })
AADD(aWEB,{'MDFeRetRecepcao'   ,'1.0','https://mdfe.sefaz.rs.gov.br/ws/MDFeRetRecepcao/MDFeRetRecepcao.asmx'      ,'https://mdfe-hml.sefaz.rs.gov.br/ws/MDFeRetRecepcao/MDFeRetRecepcao.asmx'      })
AADD(aWEB,{'MDFeRecepcaoEvento','1.0','https://mdfe.sefaz.rs.gov.br/ws/MDFeRecepcaoEvento/MDFeRecepcaoEvento.asmx','https://mdfe-hml.sefaz.rs.gov.br/ws/MDFeRecepcaoEvento/MDFeRecepcaoEvento.asmx'})
AADD(aWEB,{'MDFeConsulta'      ,'1.0','https://mdfe.sefaz.rs.gov.br/ws/MDFeConsulta/MDFeConsulta.asmx'            ,'https://mdfe-hml.sefaz.rs.gov.br/ws/MDFeConsulta/MDFeConsulta.asmx'            })
AADD(aWEB,{'MDFeStatusServico' ,'1.0','https://mdfe.sefaz.rs.gov.br/ws/MDFeStatusServico/MDFeStatusServico.asmx'  ,'https://mdfe-hml.sefaz.rs.gov.br/ws/MDFeStatusServico/MDFeStatusServico.asmx'  })

nSCAN:=ASCAN(aWEB,{|x| x[1]=cServ})
IF nSCAN>0
   cRET:=aWEB[nSCAN,IF(::ohbNFe:tpAmb='1',3,4)]
ENDIF
return(cRET)


Method XMLide() Class hbMDFe
/*
   cria o grupo IDE do xml
   Mauricio Cruz - 21/05/2031
*/
LOCAL aRETORNO:=HASH()
LOCAL mI // :=0
LOCAL cXML:=''

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::ohbNFe=NIL
   aRETORNO['MSG']:='Favor informar as propriedades da hbNFe'
ENDIF
IF ::tpEmit=NIL .OR. ::tpEmit<=0
   aRETORNO['MSG']:='Favor informar tipo de emitente'
ENDIF
IF ::mod=NIL .OR. EMPTY(::mod)
   ::mod:='58'
ENDIF
IF ::serie=NIL .OR. EMPTY(::serie)
   ::serie:='0'
ENDIF
IF ::nMDF=NIL .OR. ::nMDF<=0
   aRETORNO['MSG']:='Favor informar o número do manifesto'
ENDIF
IF ::dhEmi=NIL .OR. DAY(::dhEmi)<=0
   aRETORNO['MSG']:='Favor informar a data de emissão'
ENDIF
IF ::CNPJ=NIL .OR. EMPTY(::CNPJ)
   aRETORNO['MSG']:='Favor informar o cnpj do emitente'
ENDIF
IF ::modal=NIL .OR. ::modal<=0
   aRETORNO['MSG']:='Favor informar a modalidade de transporte'
ENDIF
IF ::UFIni=NIL .OR. EMPTY(::UFIni)
   aRETORNO['MSG']:='Favor informar a UF de inicio de transporte'
ENDIF
IF ::UFFim=NIL .OR. EMPTY(::UFFim)
   aRETORNO['MSG']:='Favor informar a UF de final de transporte'
ENDIF
IF ::aMUNcarregamento=NIL .OR. LEN(::aMUNcarregamento)<=0
   aRETORNO['MSG']:='Favor informar os municípios de carregamentos'
ENDIF
IF ::tpEmis=NIL .OR. EMPTY(::tpEmis)
   aRETORNO['MSG']:='Favor informar o tipo de emitente'
ENDIF

/*
IF ::aUFpercurso=NIL .OR. LEN(::aUFpercurso)<=0
   aRETORNO['MSG']:='Favor informar as UFs de percurso'
ENDIF
*/

IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

cXML:='<enviMDFe versao="1.00" xmlns="http://www.portalfiscal.inf.br/mdfe"><idLote>'+ALLTRIM(STR(::nMDF))+'</idLote><MDFe xmlns="http://www.portalfiscal.inf.br/mdfe">'

::cMDF:=STRZERO(::nMDF,8)

::cCHAVE:=::ohbNFe:empresa_UF+;
          ::oFuncoes:FormatDate(::dhEmi,"YYMM","")+;
          PADL(::CNPJ,14,'0')+;
          PADL(::mod,2,'0')+;
          PADL(::serie,3,'0')+;
          STRZERO(::nMDF,9)+;
          ::tpEmis+;
          ::cMDF

::cDV := ::oFuncoes:modulo11( ::cCHAVE, 2, 9 )

::cCHAVE+=::cDV

cXML+='<infMDFe versao="1.00" Id="MDFe'+::cCHAVE+'">'

cXML+='<ide>'
cXML+=   '<cUF>'+::ohbNFe:empresa_UF+'</cUF>'
cXML+=   '<tpAmb>'+::ohbNFe:tpAmb+'</tpAmb>'
cXML+=   '<tpEmit>'+ALLTRIM(STR(::tpEmit))+'</tpEmit>'
cXML+=   '<mod>'+::mod+'</mod>'
cXML+=   '<serie>'+::serie+'</serie>'
cXML+=   '<nMDF>'+ALLTRIM(STR(::nMDF))+'</nMDF>'
cXML+=   '<cMDF>'+::cMDF+'</cMDF>'
cXML+=   '<cDV>'+::cDV+'</cDV>'
cXML+=   '<modal>'+ALLTRIM(STR(::modal))+'</modal>'
cXML+=   '<dhEmi>'+::oFuncoes:FormatDate(::dhEmi,'YYYY-MM-DD','-')+'T'+LEFT(TIME(),8)+'</dhEmi>'
cXML+=   '<tpEmis>'+::tpEmis+'</tpEmis>'
cXML+=   '<procEmi>0</procEmi>'
cXML+=   '<verProc>'+::ohbNFe:versaoSistema+'</verProc>'
cXML+=   '<UFIni>'+::UFIni+'</UFIni>'
cXML+=   '<UFFim>'+::UFFim+'</UFFim>'
FOR mI:=1 TO LEN(::aMUNcarregamento)
   cXML+='<infMunCarrega>'
   cXML+=   '<cMunCarrega>'+ALLTRIM(STR(::aMUNcarregamento[mI,1]))+'</cMunCarrega>'
   cXML+=   '<xMunCarrega>'+ALLTRIM(::aMUNcarregamento[mI,2])+'</xMunCarrega>'
   cXML+='</infMunCarrega>'
NEXT
FOR mI:=1 TO LEN(::aUFpercurso)
   cXML+='<infPercurso>'
   cXML+=   '<UFPer>'+::aUFpercurso[mI,1]+'</UFPer>'
   cXML+='</infPercurso>'
NEXT
cXML+='</ide>'

aRETORNO['XML']:=::ohbNFe:pastaEnvRes+'\MDFe_'+::cCHAVE+'.xml'
IF FILE(aRETORNO['XML'])
   FERASE(aRETORNO['XML'])
ENDIF
IF MEMOWRIT(aRETORNO['XML'],cXML,.F.)
   aRETORNO['STATUS']:=.T.
   aRETORNO['MSG']:='Grupo IDE criado com sucesso.'
ELSE
   aRETORNO['MSG']:='Não foi possível gravar o arquivo XML para Grupo IDE'
ENDIF

Return(aRETORNO)



Method XMLemit() Class hbMDFe
/*
   cria o grupo emit do XML da MDF
   Mauricio Cruz - 21/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:=''

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::cXML=NIL .OR. !FILE(::cXML)
   aRETORNO['MSG']:='Arquivo XML não informado ou inexistente.'
ENDIF
IF ::CNPJ=NIL .OR. EMPTY(::CNPJ)
   aRETORNO['MSG']:='Favor informar o cnpj do emitente'
ENDIF
IF ::emit_IE=NIL .OR. EMPTY(::emit_IE)
   aRETORNO['MSG']:='Favor informar a inscrição estadual do emitente'
ENDIF
IF ::emit_xNome=NIL .OR. EMPTY(::emit_xNome)
   aRETORNO['MSG']:='Favor informar o nome do emitente'
ENDIF
IF ::emit_xLgr=NIL .OR. EMPTY(::emit_xLgr)
   aRETORNO['MSG']:='Favor informar o endereço do emitente'
ENDIF
IF ::emit_nro=NIL .OR. EMPTY(::emit_nro)
   aRETORNO['MSG']:='Favor informar o número do endereço do emitente'
ENDIF
IF ::emit_xBairro=NIL .OR. EMPTY(::emit_xBairro)
   aRETORNO['MSG']:='Favor informar o bairro do emitente'
ENDIF
IF ::emit_cMun=NIL .OR. EMPTY(::emit_cMun)
   aRETORNO['MSG']:='Favor informar o código do município do emitente'
ENDIF
IF ::emit_xMun=NIL .OR. EMPTY(::emit_xMun)
   aRETORNO['MSG']:='Favor informar o município do emitente'
ENDIF
IF ::emit_CEP=NIL .OR. EMPTY(::emit_CEP)
   aRETORNO['MSG']:='Favor informar o CEP do emitente'
ENDIF
IF ::emit_UF=NIL .OR. EMPTY(::emit_UF)
   aRETORNO['MSG']:='Favor informar a UF do emitente'
ENDIF


IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

cXML:=MEMOREAD(::cXML)
FERASE(::cXML)


cXML+='<emit>'
cXML+=   '<CNPJ>'+PADL(::CNPJ,14,'0')+'</CNPJ>'
cXML+=   '<IE>'+ALLTRIM(::emit_IE)+'</IE>'
cXML+=   '<xNome>'+ALLTRIM(::oFuncoes:RemoveAcentuacao(::emit_xNome))+'</xNome>'
TRY
   IF !EMPTY(::emit_xFant)
      cXML+='<xFant>'+ALLTRIM(::oFuncoes:RemoveAcentuacao(::emit_xFant))+'</xFant>'
   ENDIF
CATCH
END
cXML+=   '<enderEmit>'
cXML+=      '<xLgr>'+ALLTRIM(::oFuncoes:RemoveAcentuacao(::emit_xLgr))+'</xLgr>'
cXML+=      '<nro>'+ALLTRIM(::emit_nro)+'</nro>'
TRY
   IF !EMPTY(::emit_xCpl)
      cXML+='<xCpl>'+ALLTRIM(::oFuncoes:RemoveAcentuacao(::emit_xCpl))+'</xCpl>'
   ENDIF
CATCH
END
cXML+=      '<xBairro>'+ALLTRIM(::oFuncoes:RemoveAcentuacao(::emit_xBairro))+'</xBairro>'
cXML+=      '<cMun>'+ALLTRIM(::emit_cMun)+'</cMun>'
cXML+=      '<xMun>'+ALLTRIM(::oFuncoes:RemoveAcentuacao(::emit_xMun))+'</xMun>'
TRY
   IF !EMPTY(::emit_CEP)
      cXML+='<CEP>'+ALLTRIM(::emit_CEP)+'</CEP>'
   ENDIF
CATCH
END
cXML+=      '<UF>'+ALLTRIM(::emit_UF)+'</UF>'
TRY
   IF !EMPTY(::emit_fone)
      cXML+='<fone>'+ALLTRIM(::emit_fone)+'</fone>'
   ENDIF
CATCH
END
TRY
   IF !EMPTY(::emit_email)
      cXML+='<email>'+ALLTRIM(::oFuncoes:RemoveAcentuacao(::emit_email))+'</email>'
   ENDIF
CATCH
END
cXML+=   '</enderEmit>'
cXML+='</emit>'

aRETORNO['XML']:=::cXML

IF MEMOWRIT(::cXML,cXML,.F.)
   aRETORNO['STATUS']:=.T.
   aRETORNO['MSG']:='Grupo EMIT criado com sucesso.'
ELSE
   aRETORNO['MSG']:='Não foi possível gravar o arquivo XML para o Grupo EMIT'
ENDIF

Return(aRETORNO)




Method XMLmodalRodoviario() Class hbMDFe
/*
   Modal Rodoviario
   Mauricio Cruz - 22/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:='', cXMLmod:=''
LOCAL mI:=0

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::cXML=NIL .OR. !FILE(::cXML)
   aRETORNO['MSG']:='Arquivo XML não informado ou inexistente.'
ENDIF
IF ::modRod_placa=NIL .OR. EMPTY(::modRod_placa)
   aRETORNO['MSG']:='Favor informar a placa do veículo principal.'
ENDIF
IF ::modRod_tara=NIL .OR. ::modRod_tara<0
   aRETORNO['MSG']:='Favor informar a tara do veículo principal.'
ENDIF
IF ::modRod_condutor=NIL .OR. LEN(::modRod_condutor)<=0
   aRETORNO['MSG']:='Favor informar o(s) condutor(es).'
ENDIF
IF LEN(::modRod_condutor)>10
   aRETORNO['MSG']:='Informado mais de 10 condutores.'
ENDIF
IF ::modRod_reboque<>NIL .AND. LEN(::modRod_reboque)>3
   aRETORNO['MSG']:='Informado mais de 3 veículos reboque.'
ENDIF

IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

cXML:=MEMOREAD(::cXML)
FERASE(::cXML)

cXML+='<infModal versaoModal="1.00">'

//cXMLmod+='<rodo  xmlns="http://www.portalfiscal.inf.br/mdfe">'
TRY
   IF !EMPTY(::modRod_RNTRC)
      cXMLmod+='<RNTRC>'+ALLTRIM(STR(::modRod_RNTRC))+'</RNTRC>'
   ENDIF
CATCH
END
TRY
   IF !EMPTY(::modRod_CIOT)
      cXMLmod+='<CIOT>'+ALLTRIM(STR(::modRod_CIOT))+'</CIOT>'
   ENDIF
CATCH
END
//cXMLmod+=      '<veicPrincipal>'   QQQ
cXMLmod+=      '<veicTracao>'
TRY
   IF !EMPTY(::modRod_cInt)
      cXMLmod+=   '<cInt>'+ALLTRIM(::modRod_cInt)+'</cInt>'
   ENDIF
CATCH
END
cXMLmod+=         '<placa>'+ALLTRIM(::modRod_placa)+'</placa>'
cXMLmod+=         '<tara>'+ALLTRIM(STRTRAN(STR(::modRod_tara),'.'))+'</tara>'
TRY
   IF ::modRod_capKG>0
      cXMLmod+=   '<capKG>'+ALLTRIM(STRTRAN(STR(::modRod_capKG),'.'))+'</capKG>'
   ENDIF
CATCH
END
TRY
   IF ::modRod_capM3>0
      cXMLmod+=   '<capM3>'+ALLTRIM(STRTRAN(STR(::modRod_capM3),'.'))+'</capM3>'
   ENDIF
CATCH
END
cXMLmod+=         '<prop>'
cXMLmod+=            '<RNTRC>'+ALLTRIM(::modRod_RNTRC_prop)+'</RNTRC>'
cXMLmod+=         '</prop>'
FOR mI:=1 TO LEN(::modRod_condutor)
   cXMLmod+=      '<condutor>'
   cXMLmod+=         '<xNome>'+ALLTRIM(::oFuncoes:RemoveAcentuacao(::modRod_condutor[mI,1]))+'</xNome>'
   cXMLmod+=         '<CPF>'+ALLTRIM(::modRod_condutor[mI,2])+'</CPF>'
   cXMLmod+=      '</condutor>'
NEXT
//cXMLmod+=      '</veicPrincipal>' QQQ
cXMLmod+=      '</veicTracao>'
TRY
   FOR mI:=1 TO LEN(::modRod_reboque)
      cXMLmod+='<veicReboque>'
      IF !EMPTY(::modRod_reboque[mI,1])
         cXMLmod+='<cInt>'+ALLTRIM(::modRod_reboque[mI,1])+'</cInt>'
      ENDIF
      cXMLmod+=   '<placa>'+ALLTRIM(::modRod_reboque[mI,2])+'</placa>'
      cXMLmod+=   '<tara>'+ALLTRIM(STRTRAN(STR(::modRod_reboque[mI,3]),'.'))+'</tara>'
      IF ::modRod_reboque[mI,4]>0
         cXMLmod+='<capKG>'+ALLTRIM(STRTRAN(STR(::modRod_reboque[mI,4]),'.'))+'</capKG>'
      ENDIF
      IF ::modRod_reboque[mI,5]>0
         cXMLmod+='<capM3>'+ALLTRIM(STRTRAN(STR(::modRod_reboque[mI,5]),'.'))+'</capM3>'
      ENDIF
      IF !EMPTY(::modRod_reboque[mI,6])
         cXMLmod+='<prop>'
         cXMLmod+=   '<RNTRC>'+ALLTRIM(::modRod_reboque[mI,6])+'</RNTRC>'
         cXMLmod+='</prop>'
      ENDIF
      cXMLmod+='</veicReboque>'
   NEXT
CATCH
END
TRY
   FOR mI:=1 TO LEN(::modRod_pedagio)
      IF EMPTY(::modRod_pedagio[mI,1]) .OR. EMPTY(::modRod_pedagio[mI,3])
         ::modRod_pedagio:={}
      ENDIF
   NEXT
   IF LEN(::modRod_pedagio)>0
      cXMLmod+=   '<valePed>'
      FOR mI:=1 TO LEN(::modRod_pedagio)
         cXMLmod+=   '<disp>'
         cXMLmod+=      '<CNPJForn>'+ALLTRIM(::modRod_pedagio[mI,1])+'</CNPJForn>'
         IF !EMPTY(::modRod_pedagio[mI,2])
            cXMLmod+=   '<CNPJPg>'+ALLTRIM(::modRod_pedagio[mI,2])+'</CNPJPg>'
         ENDIF
         cXMLmod+=      '<nCompra>'+ALLTRIM(::modRod_pedagio[mI,3])+'</nCompra>'
         cXMLmod+=   '</disp>'
      NEXT
      cXMLmod+=   '</valePed>'
   ENDIF
CATCH
END
cXMLmod+='</rodo>'
// QQQ

aRETORNO:=::Valida_XML('<rodo xmlns="http://www.portalfiscal.inf.br/mdfe">'+cXMLmod)
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF


cXML+='<rodo>'+cXMLmod
cXML+='</infModal>'

aRETORNO['XML']:=::cXML

IF MEMOWRIT(::cXML,cXML,.F.)
   aRETORNO['STATUS']:=.T.
   aRETORNO['MSG']:='Grupo Modal Ferroviário criado com sucesso.'
ELSE
   aRETORNO['MSG']:='Não foi possível gravar o arquivo XML para o Grupo Modal Ferroviário'
ENDIF

Return(aRETORNO)


Method XMLDocumentos() Class hbMDFe
/*
   Documentos vinculados
   Mauricio Cruz - 22/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:=''
LOCAL mI:=0, cI:=0

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''
aRETORNO['MSG']:=''

IF ::cXML=NIL .OR. !FILE(::cXML)
   aRETORNO['MSG']:='Arquivo XML não informado ou inexistente.'
ENDIF

IF ::munDes_municipio=NIL .OR. LEN(::munDes_municipio)<=0
   aRETORNO['MSG']:='Favor informar os municípios de descarregamento.'
ENDIF

IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

cXML:=MEMOREAD(::cXML)
FERASE(::cXML)

/*  Municipio de descarregamento (munDes_municipio): array multidimencional:

       1          2            3          4          5      6
{cMunDescarga,xMunDescarga,{<infCTe>},{<infNFe>},<infCT>,<infNF> } 1 2  3     4    5    6   7         8
                                |         |          |      |->{CNPJ,UF,nNF,serie,dEmi,vNF,PIN,{<infUnidTransp>}}  1         2                3                4
                                |         |          |                                                  |->{tpUnidTransp,idUnidTransp,{<lacUnidTransp>}, {<infUnidCarga> }} 1        2                3
                                |         |          |                                                                                        |->nLacre        |-->{tpUnidCarga,idUnidCarga,{<lacUnidCarga>}}
                                |         |          |                                                                                                                                              |->nLacre
                                |         |          |
                                |         |          |    1    2     3      4    5            6
                                |         |          |->{nCT,serie,subser,dEmi,vCarga,{<infUnidTransp>} } 1         2               3                 4
                                |         |                                                   |->{tpUnidTransp,idUnidTransp,{<lacUnidTransp>}, {<infUnidCarga> } } 1       2              3
                                |         |                                                                                         |->nLacre        |-->{tpUnidCarga,idUnidCarga,{<lacUnidCarga>}}
                                |         |                                                                                                                                              |->nLacre
                                |         |
                                |         |      1       2             3
                                |         |->{chNFe,SegCodBarra,{<infUnidTransp>} }
                                |                                      |->{tpUnidTransp,idUnidTransp,{<lacUnidTransp>}, {<infUnidCarga> } }
                                |                                                                             |->nLacre        |-->{tpUnidCarga,idUnidCarga,{<lacUnidCarga>}}
                                |                                                                                                                                     |->nLacre
                                |
                                |     1        2               3
                                |->{chCTe,SegCodBarra,{<infUnidTransp>} }
                                                               |->{tpUnidTransp,idUnidTransp,{<lacUnidTransp>}, {<infUnidCarga> } }
                                                                                                      |->nLacre        |-->{tpUnidCarga,idUnidCarga,{<lacUnidCarga>}}
                                                                                                                                                           |->nLacre
*/


cXML+='<infDoc>'
FOR mI:=1 TO LEN(::munDes_municipio)
   cXML+='<infMunDescarga>'
   cXML+=   '<cMunDescarga>'+ALLTRIM(STR(::munDes_municipio[mI,1]))+'</cMunDescarga>'
   cXML+=   '<xMunDescarga>'+ALLTRIM(::munDes_municipio[mI,2])+'</xMunDescarga>'
   // CTe
   FOR cI:=1 TO LEN(::munDes_municipio[mI,3])
      cXML+='<infCTe>'
      cXML+=   '<chCTe>'+ALLTRIM(::munDes_municipio[mI,3,cI,1])+'</chCTe>'
      IF !EMPTY(::munDes_municipio[mI,3,cI,2])
         cXML+='<SegCodBarra>'+ALLTRIM(::munDes_municipio[mI,3,cI,2])+'</SegCodBarra>'
      ENDIF
      TRY
         IF LEN(::munDes_municipio[mI,3,cI,3])>0
            cXML+='<infUnidTransp>'
            FOR ccI:=1 TO LEN(::munDes_municipio[mI,3,cI,3])
               cXML+='<tpUnidTransp>'+::munDes_municipio[mI,3,cI,3,ccI,1]+'</tpUnidTransp>'
               cXML+='<idUnidTransp>'+::munDes_municipio[mI,3,cI,3,ccI,2]+'</idUnidTransp>'
               TRY
                  cXML+='<lacUnidTransp>'
                  FOR cccI:=1 TO LEN(::munDes_municipio[mI,3,cI,3,ccI,3])
                     cXML+='<nLacre>'+::munDes_municipio[mI,3,cI,3,ccI,3,cccI,1]+'</nLacre>'
                  NEXT
                  cXML+='</lacUnidTransp>'
               CATCH
               END
               TRY
                  cXML+='<infUnidCarga>'
                  FOR cccI:=1 TO LEN(::munDes_municipio[mI,3,cI,3,ccI,4])
                     cXML+='<tpUnidCarga>'+::munDes_municipio[mI,3,cI,3,ccI,4,cccI,1]+'</tpUnidCarga>'
                     cXML+='<idUnidCarga>'+::munDes_municipio[mI,3,cI,3,ccI,4,cccI,2]+'</idUnidCarga>'
                     TRY
                        cXML+='<lacUnidCarga>'
                        FOR ccccI:=1 TO LEN(::munDes_municipio[mI,3,cI,3,ccI,4,cccI,3])
                           cXML+='<nLacre>'+::munDes_municipio[mI,3,cI,3,ccI,4,cccI,3,cccI,1]+'</nLacre>'
                        NEXT
                        cXML+='</lacUnidCarga>'
                     CATCH
                     END
                  NEXT
                  TRY
                     cXML+='<qtdRat>'+::munDes_municipio[mI,3,cI,3,ccI,4,cccI,4]+'</qtdRat>'
                  CATCH
                  END
                  cXML+='</infUnidCarga>'
               CATCH
               END
               TRY
                  cXML+='<qtdRat>'+::munDes_municipio[mI,3,cI,3,ccI,5]+'</qtdRat>'
               CATCH
               END
            NEXT
            cXML+='</infUnidTransp>'
         ENDIF
      CATCH
      END
      cXML+='</infCTe>'
      ::qCTe++
   NEXT
   //CT
   FOR cI:=1 TO LEN(::munDes_municipio[mI,5])
      cXML+='<infCT>'
      cXML+=   '<nCT>'+ALLTRIM(STR(::munDes_municipio[mI,5,cI,1]))+'</nCT>'
      cXML+=   '<serie>'+ALLTRIM(::munDes_municipio[mI,5,cI,2])+'</serie>'
      IF !EMPTY(::munDes_municipio[mI,5,cI,3])
         cXML+='<subser>'+ALLTRIM(::munDes_municipio[mI,5,cI,3])+'</subser>'
      ENDIF
      cXML+=   '<dEmi>'+ALLTRIM( ::oFuncoes:FormatDate(::munDes_municipio[mI,5,cI,4],'YYYY-MM-DD','-'))+'</dEmi>'
      cXML+=   '<vCarga>'+ALLTRIM(STR(::munDes_municipio[mI,5,cI,5]))+'</vCarga>'
      TRY
         IF LEN(::munDes_municipio[mI,5,cI,6])>0
            cXML+='<infUnidTransp>'
            FOR ccI:=1 TO LEN(::munDes_municipio[mI,5,cI,6])
               cXML+='<tpUnidTransp>'+::munDes_municipio[mI,5,cI,6,ccI,1]+'</tpUnidTransp>'
               cXML+='<idUnidTransp>'+::munDes_municipio[mI,5,cI,6,ccI,2]+'</idUnidTransp>'
               TRY
                  cXML+='<lacUnidTransp>'
                  FOR cccI:=1 TO LEN(::munDes_municipio[mI,5,cI,6,ccI,3])
                     cXML+='<nLacre>'+::munDes_municipio[mI,5,cI,6,ccI,3,cccI,1]+'</nLacre>'
                  NEXT
                  cXML+='</lacUnidTransp>'
               CATCH
               END
               TRY
                  cXML+='<infUnidCarga>'
                  FOR cccI:=1 TO LEN(::munDes_municipio[mI,5,cI,6,ccI,4])
                     cXML+='<tpUnidCarga>'+::munDes_municipio[mI,5,cI,6,ccI,4,cccI,1]+'</tpUnidCarga>'
                     cXML+='<idUnidCarga>'+::munDes_municipio[mI,5,cI,6,ccI,4,cccI,2]+'</idUnidCarga>'
                     TRY
                        cXML+='<lacUnidCarga>'
                        FOR ccccI:=1 TO LEN(::munDes_municipio[mI,5,cI,6,ccI,4,cccI,3])
                           cXML+='<nLacre>'+::munDes_municipio[mI,5,cI,6,ccI,4,cccI,3,cccI,1]+'</nLacre>'
                        NEXT
                        cXML+='</lacUnidCarga>'
                     CATCH
                     END
                  NEXT
                  TRY
                     cXML+='<qtdRat>'+::munDes_municipio[mI,5,cI,6,ccI,4,cccI,4]+'</qtdRat>'
                  CATCH
                  END
                  cXML+='</infUnidCarga>'
               CATCH
               END
               TRY
                  cXML+='<qtdRat>'+::munDes_municipio[mI,5,cI,6,ccI,5]+'</qtdRat>'
               CATCH
               END
            NEXT
            cXML+='</infUnidTransp>'
         ENDIF
      CATCH
      END
      cXML+='</infCT>'
      ::qCT++
   NEXT
   //NFe
   FOR cI:=1 TO LEN(::munDes_municipio[mI,4])
      cXML+='<infNFe>'
      cXML+=   '<chNFe>'+ALLTRIM(::munDes_municipio[mI,4,cI,1])+'</chNFe>'
      IF !EMPTY(::munDes_municipio[mI,4,cI,2])
         cXML+='<SegCodBarra>'+ALLTRIM(::munDes_municipio[mI,4,cI,2])+'</SegCodBarra>'
      ENDIF
      TRY
         IF LEN(::munDes_municipio[mI,4,cI,3])>0
            cXML+='<infUnidTransp>'
            FOR ccI:=1 TO LEN(::munDes_municipio[mI,4,cI,3])
               cXML+='<tpUnidTransp>'+::munDes_municipio[mI,4,cI,3,ccI,1]+'</tpUnidTransp>'
               cXML+='<idUnidTransp>'+::munDes_municipio[mI,4,cI,3,ccI,2]+'</idUnidTransp>'
               TRY
                  cXML+='<lacUnidTransp>'
                  FOR cccI:=1 TO LEN(::munDes_municipio[mI,4,cI,3,ccI,3])
                     cXML+='<nLacre>'+::munDes_municipio[mI,4,cI,3,ccI,3,cccI,1]+'</nLacre>'
                  NEXT
                  cXML+='</lacUnidTransp>'
               CATCH
               END
               TRY
                  cXML+='<infUnidCarga>'
                  FOR cccI:=1 TO LEN(::munDes_municipio[mI,4,cI,3,ccI,4])
                     cXML+='<tpUnidCarga>'+::munDes_municipio[mI,4,cI,3,ccI,4,cccI,1]+'</tpUnidCarga>'
                     cXML+='<idUnidCarga>'+::munDes_municipio[mI,4,cI,3,ccI,4,cccI,2]+'</idUnidCarga>'
                     TRY
                        cXML+='<lacUnidCarga>'
                        FOR ccccI:=1 TO LEN(::munDes_municipio[mI,4,cI,3,ccI,4,cccI,3])
                           cXML+='<nLacre>'+::munDes_municipio[mI,4,cI,3,ccI,4,cccI,3,cccI,1]+'</nLacre>'
                        NEXT
                        cXML+='</lacUnidCarga>'
                     CATCH
                     END
                  NEXT
                  TRY
                     cXML+='<qtdRat>'+::munDes_municipio[mI,4,cI,3,ccI,4,cccI,4]+'</qtdRat>'
                  CATCH
                  END
                  cXML+='</infUnidCarga>'
               CATCH
               END
               TRY
                  cXML+='<qtdRat>'+::munDes_municipio[mI,4,cI,3,ccI,5]+'</qtdRat>'
               CATCH
               END
            NEXT
            cXML+='</infUnidTransp>'
         ENDIF
      CATCH
      END
      cXML+='</infNFe>'
      ::qNFe++
   NEXT
   //NF
   FOR cI:=1 TO LEN(::munDes_municipio[mI,6])
      cXML+='<infNF>'
      cXML+=   '<CNPJ>'+ALLTRIM(::munDes_municipio[mI,6,cI,1])+'</CNPJ>'
      cXML+=   '<UF>'+ALLTRIM(::munDes_municipio[mI,6,cI,2])+'</UF>'
      cXML+=   '<nNF>'+ALLTRIM(STR(::munDes_municipio[mI,6,cI,3]))+'</nNF>'
      cXML+=   '<serie>'+ALLTRIM(::munDes_municipio[mI,6,cI,4])+'</serie>'
      cXML+=   '<dEmi>'+ALLTRIM(::oFuncoes:FormatDate(::munDes_municipio[mI,6,cI,5],'YYYY-MM-DD','-'))+'</dEmi>'
      cXML+=   '<vNF>'+ALLTRIM(STR(::munDes_municipio[mI,6,cI,6]))+'</vNF>'
      IF ::munDes_municipio[mI,6,cI,7]>0
         cXML+='<PIN>'+ALLTRIM(STR(::munDes_municipio[mI,6,cI,7]))+'</PIN>'
      ENDIF
      TRY
         IF LEN(::munDes_municipio[mI,6,cI,8])>0
            cXML+='<infUnidTransp>'
            FOR ccI:=1 TO LEN(::munDes_municipio[mI,6,cI,8])
               cXML+='<tpUnidTransp>'+::munDes_municipio[mI,6,cI,8,ccI,1]+'</tpUnidTransp>'
               cXML+='<idUnidTransp>'+::munDes_municipio[mI,6,cI,8,ccI,2]+'</idUnidTransp>'
               TRY
                  cXML+='<lacUnidTransp>'
                  FOR cccI:=1 TO LEN(::munDes_municipio[mI,6,cI,8,ccI,3])
                     cXML+='<nLacre>'+::munDes_municipio[mI,6,cI,8,ccI,3,cccI,1]+'</nLacre>'
                  NEXT
                  cXML+='</lacUnidTransp>'
               CATCH
               END
               TRY
                  cXML+='<infUnidCarga>'
                  FOR cccI:=1 TO LEN(::munDes_municipio[mI,6,cI,8,ccI,4])
                     cXML+='<tpUnidCarga>'+::munDes_municipio[mI,6,cI,8,ccI,4,cccI,1]+'</tpUnidCarga>'
                     cXML+='<idUnidCarga>'+::munDes_municipio[mI,6,cI,8,ccI,4,cccI,2]+'</idUnidCarga>'
                     TRY
                        cXML+='<lacUnidCarga>'
                        FOR ccccI:=1 TO LEN(::munDes_municipio[mI,6,cI,8,ccI,4,cccI,3])
                           cXML+='<nLacre>'+::munDes_municipio[mI,6,cI,8,ccI,4,cccI,3,cccI,1]+'</nLacre>'
                        NEXT
                        cXML+='</lacUnidCarga>'
                     CATCH
                     END
                  NEXT
                  TRY
                     cXML+='<qtdRat>'+::munDes_municipio[mI,6,cI,8,ccI,4,cccI,4]+'</qtdRat>'
                  CATCH
                  END
                  cXML+='</infUnidCarga>'
               CATCH
               END
               TRY
                  cXML+='<qtdRat>'+::munDes_municipio[mI,6,cI,8,ccI,5]+'</qtdRat>'
               CATCH
               END
            NEXT
            cXML+='</infUnidTransp>'
         ENDIF
      CATCH
      END
      cXML+='</infNF>'
      ::qNF++
   NEXT
   cXML+='</infMunDescarga>'
NEXT
cXML+='</infDoc>'

aRETORNO['XML']:=::cXML

IF MEMOWRIT(::cXML,cXML,.F.)
   aRETORNO['STATUS']:=.T.
   aRETORNO['MSG']:='Grupo de Documentos criado com sucesso.'
ELSE
   aRETORNO['MSG']:='Não foi possível gravar o arquivo XML para o Grupo de Documentos'
ENDIF

Return(aRETORNO)


Method XMLtot() Class hbMDFe
/*
   Totalizadores
   Mauricio Cruz - 22/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:=''
LOCAL mI:=0

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::cXML=NIL .OR. !FILE(::cXML)
   aRETORNO['MSG']:='Arquivo XML não informado ou inexistente.'
ENDIF
IF ::vCarga=NIL .OR. ::vCarga<=0
   aRETORNO['MSG']:='Favor informar o valor da carga.'
ENDIF
IF ::cUnid=NIL .OR. EMPTY(::cUnid)
   aRETORNO['MSG']:='Favor informar a unidade de peso.'
ENDIF
IF ::qCarga=NIL .OR. ::qCarga<=0
   aRETORNO['MSG']:='Favor informar o peso da carga.'
ENDIF

IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

cXML:=MEMOREAD(::cXML)
FERASE(::cXML)

cXML+='<tot>'
IF ::qCTe>0
   cXML+='<qCTe>'+ALLTRIM(STRTRAN(STR(::qCTe),'.'))+'</qCTe>'
ENDIF
IF ::qCT>0
   cXML+='<qCT>'+ALLTRIM(STRTRAN(STR(::qCT),'.'))+'</qCT>'
ENDIF
IF ::qNFe>0
   cXML+='<qNFe>'+ALLTRIM(STRTRAN(STR(::qNFe),'.'))+'</qNFe>'
ENDIF
IF ::qNF>0
   cXML+='<qNF>'+ALLTRIM(STRTRAN(STR(::qNF),'.'))+'</qNF>'
ENDIF
cXML+=   '<vCarga>'+ALLTRIM(STR(::vCarga))+'</vCarga>'
cXML+=   '<cUnid>'+ALLTRIM(::cUnid)+'</cUnid>'
cXML+=   '<qCarga>'+ALLTRIM(STR(::qCarga),'.')+'</qCarga>'
cXML+='</tot>'

FOR mI:=1 TO LEN(::aLACRE)
   IF !EMPTY(::aLACRE[mI])
      cXML+='<lacres>'
      cXML+=   '<nLacre>'+ALLTRIM(::aLACRE[mI])+'</nLacre>'
      cXML+='</lacres>'
   ENDIF
NEXT

IF (::infAdFisco<>NIL .AND. !EMPTY(::infAdFisco)) .OR. (::infCpl<>NIL .AND. !EMPTY(::infCpl))
   cXML+='<infAdic>'
   TRY
      IF !EMPTY(::infAdFisco)
         cXML+='<infAdFisco>'+ALLTRIM(::oFuncoes:RemoveAcentuacao(::infAdFisco))+'</infAdFisco>'
      ENDIF
   CATCH
   END
   TRY
      IF !EMPTY(::infCpl)
         cXML+='<infCpl>'+ALLTRIM(::oFuncoes:RemoveAcentuacao(::infCpl))+'</infCpl>'
      ENDIF
   CATCH
   END
   cXML+='</infAdic>'
ENDIF

cXML+='</infMDFe>'

aRETORNO['XML']:=::cXML

IF MEMOWRIT(::cXML,cXML,.F.)
   aRETORNO['STATUS']:=.T.
   aRETORNO['MSG']:='Grupo de totais criado com sucesso.'
ELSE
   aRETORNO['MSG']:='Não foi possível gravar o arquivo XML para o Grupo de totais'
ENDIF

Return(aRETORNO)



Method Assina_XML() Class hbMDFe
/*
   Finaliza a estrutura do arquivo XML e assina o XML
   Mauricio Cruz - 22/05/2013
*/
LOCAL oDOMDoc, oXmldsig, oCert, oStoreMem, dsigKey, signedKey
LOCAL aRETORNO:=HASH()
LOCAL cXML:='', cXMLSig:=''
LOCAL PosIni:=0, PosFim:=0, nP:=0, nResult:=0

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::cXML=NIL .OR. !FILE(::cXML)
   aRETORNO['MSG']:='Arquivo XML não informado ou inexistente.'
   RETURN(aRETORNO)
ENDIF

cXML:=MEMOREAD(::cXML)
FERASE(::cXML)

IF 'enviMDFe' $ cXML
   cXML+='<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">'
   cXML+=   '<SignedInfo>'
   cXML+=      '<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>'
   cXML+=      '<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />'
   cXML+=      '<Reference URI="#MDFe'+::cCHAVE+'">'
   cXML+=         '<Transforms>'
   cXML+=            '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>'
   cXML+=            '<Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315"/>'
   cXML+=         '</Transforms>'
   cXML+=         '<DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>'
   cXML+=         '<DigestValue></DigestValue>'
   cXML+=      '</Reference>'
   cXML+=   '</SignedInfo>'
   cXML+=   '<SignatureValue></SignatureValue>'
   cXML+=   '<KeyInfo>'
   cXML+=      '<X509Data>'
   cXML+=         '<X509Certificate></X509Certificate>'
   cXML+=      '</X509Data>'
   cXML+=   '</KeyInfo>'
   cXML+='</Signature>'
   cXML+='</MDFe>'
   cXML+='</enviMDFe>'
ELSE
   cXML+='<Signature xmlns="http://www.w3.org/2000/09/xmldsig#">'
   cXML+=   '<SignedInfo>'
   cXML+=      '<CanonicalizationMethod Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />'
   cXML+=      '<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />'
   cXML+=      '<Reference URI="#ID'+::URIId+'">'
   cXML+=         '<Transforms>'
   cXML+=            '<Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />'
   cXML+=            '<Transform Algorithm="http://www.w3.org/TR/2001/REC-xml-c14n-20010315" />'
   cXML+=         '</Transforms>'
   cXML+=         '<DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />'
   cXML+=         '<DigestValue></DigestValue>'
   cXML+=      '</Reference>'
   cXML+=   '</SignedInfo>'
   cXML+=   '<SignatureValue></SignatureValue>'
   cXML+=   '<KeyInfo>'
   cXML+=      '<X509Data>'
   cXML+=         '<X509Certificate></X509Certificate>'
   cXML+=      '</X509Data>'
   cXML+=   '</KeyInfo>'
   cXML+='</Signature>'
   cXML+='</eventoMDFe>'
ENDIF

// Inicializa o objeto do DOMDocument
TRY
   #ifdef __XHARBOUR__
      oDOMDoc := xhb_CreateObject(_MSXML2_DOMDocument)
   #else
      oDOMDoc := win_oleCreateObject(_MSXML2_DOMDocument)
   #endif
CATCH
   aRETORNO['MSG']:='Nao foi possível carregar '+ _MSXML2_DOMDocument
   RETURN(aRETORNO)
END
oDOMDoc:async = .F.
oDOMDoc:resolveExternals := .F.
oDOMDoc:validateOnParse  = .T.
oDOMDoc:preserveWhiteSpace = .T.


// inicializa o objeto do MXDigitalSignature
TRY
   #ifdef __XHARBOUR__
      oXmldsig := xhb_CreateObject( _MSXML2_MXDigitalSignature )
   #else
      oXmldsig := win_oleCreateObject( _MSXML2_MXDigitalSignature )
   #endif
CATCH
   aRETORNO['MSG']:='Nao foi possível carregar ' + _MSXML2_MXDigitalSignature
   RETURN(aRETORNO)
END

// carrega o arquivo XML para o DOM
oDOMDoc:LoadXML(cXML)
IF oDOMDoc:parseError:errorCode<>0
   aRETORNO['MSG']:=' Assinar: Não foi possível carregar o documento pois ele não corresponde ao seu Schema'+HB_OsNewLine()+;
                    ' Linha: '              + STR(oDOMDoc:parseError:line)+HB_OsNewLine()+;
                    ' Caractere na linha: ' + STR(oDOMDoc:parseError:linepos)+HB_OsNewLine()+;
                    ' Causa do erro: '      + oDOMDoc:parseError:reason+HB_OsNewLine()+;
                    ' code: '               + STR(oDOMDoc:parseError:errorCode)
   RETURN(aRETORNO)
ENDIF

// Localiza as assinaturas no XML
oDOMDoc:setProperty('SelectionNamespaces',"xmlns:ds='http://www.w3.org/2000/09/xmldsig#'")
oXmldsig:signature := oDOMDoc:selectSingleNode('.//ds:Signature')
IF (oXmldsig:signature = nil)
   aRETORNO['MSG'] := 'É preciso carregar o template antes de assinar.'
   RETURN(aRETORNO)
ENDIF

// carrega o objeto do certificado digital
oCert:=::ohbNFe:pegaObjetoCertificado(::ohbNFe:cSerialCert)
IF oCert == Nil
   aRETORNO['MSG']  := 'Certificado não encontrado, Favor revisar a instalação do Certificado'
   RETURN(aRETORNO)
ENDIF

// cria o objeto de Store da capicom
#ifdef __XHARBOUR__
   oStoreMem := xhb_CreateObject('CAPICOM.Store')
#else
   oStoreMem := win_oleCreateObject('CAPICOM.Store')
#endif

// Aloca o certificado na memoria
TRY
   oStoreMem:open(_CAPICOM_MEMORY_STORE,'Memoria',_CAPICOM_STORE_OPEN_MAXIMUM_ALLOWED)
CATCH oError
   aRETORNO['MSG']:='Falha ao alocar o certificado na memoria '+HB_OsNewLine()+ ;
                    'Error: '     + Transform(oError:GenCode, nil)   + ';' +HB_OsNewLine()+ ;
                    'SubC: '      + Transform(oError:SubCode, nil)   + ';' +HB_OsNewLine()+ ;
                    'OSCode: '    + Transform(oError:OsCode,  nil)   + ';' +HB_OsNewLine()+ ;
                    'SubSystem: ' + Transform(oError:SubSystem, nil) + ';' +HB_OsNewLine()+ ;
                    'Mensangem: ' + oError:Description
   RETURN(aRETORNO)
END

// Aloca o certificado na Capicom
TRY
   oStoreMem:Add(oCert)
CATCH oError
   aRETORNO['MSG']:='Falha ao aloca o certificado na memoria da Capicom '+HB_OsNewLine()+;
                    'Error: '     + Transform(oError:GenCode, nil)   + ';' +HB_OsNewLine()+;
                    'SubC: '      + Transform(oError:SubCode, nil)   + ';' +HB_OsNewLine()+;
                    'OSCode: '    + Transform(oError:OsCode,  nil)   + ';' +HB_OsNewLine()+;
                    'SubSystem: ' + Transform(oError:SubSystem, nil) + ';' +HB_OsNewLine()+;
                    'Mensangem: ' + oError:Description
   RETURN(aRETORNO)
END
oXmldsig:store:=oStoreMem

// Cria chave CSP
TRY
   dsigKey:=oXmldsig:createKeyFromCSP(oCert:PrivateKey:ProviderType, oCert:PrivateKey:ProviderName, oCert:PrivateKey:ContainerName, 0)
CATCH
   aRETORNO['MSG']:='Erro ao criar a chave do CSP, talvez o certificado não esteja instalado corretamente.'
   RETURN(aRETORNO)
END
IF (dsigKey = nil)
   aRETORNO['MSG']:='Erro ao criar a chave do CSP.'
   RETURN(aRETORNO)
ENDIF

// Assina a chave do CSP
TRY
   signedKey:=oXmldsig:sign(dsigKey, 2)
CATCH
   aRETORNO['MSG']:='Erro ao assinar a chave do CSP, talvez o certificado não esteja instalado corretamente.'
   RETURN(aRETORNO)
END
IF signedKey=NIL
   aRETORNO['MSG']:='Assinatura Falhou.'
   RETURN(aRetorno)
ENDIF

// Trata o formato da estrutura do XML
cXMLSig := STRTRAN(STRTRAN(oDOMDoc:xml,CHR(10)),CHR(13))
PosIni := AT('<SignatureValue>',cXMLSig)+len('<SignatureValue>')
cXMLSig := SUBS(cXMLSig,1,PosIni-1)+STRTRAN( SUBS(cXMLSig,PosIni,len(cXMLSig)), ' ', '' )
PosIni := AT('<X509Certificate>',cXMLSig)-1
nP = AT('<X509Certificate>',cXMLSig)
nResult := 0
DO WHILE nP<>0
   nResult := nP
   nP = AT('<X509Certificate>',cXMLSig,nP+1)
ENDDO
PosFim := nResult
cXMLSig := SUBS(cXMLSig,1,PosIni)+SUBS(cXMLSig,PosFim,len(cXMLSig))

// valida o schema da assinatura
aRETORNO:=::Valida_XML('<Signature '+::oFuncoes:pegaTag(cXMLSig,'Signature')+'</Signature>')
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF

// valida com o schema da MDFe
aRETORNO:=::Valida_XML(cXMLSig)
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF

// grava o arquivo no disco
aRETORNO['XML']:=::cXML
IF MEMOWRIT(::cXML,cXMLSig,.F.)
   aRETORNO['STATUS']:=.T.
   aRETORNO['MSG']:='XML assinado e validado com sucesso em '+::cXML
ELSE
   aRETORNO['MSG']:='Não foi possível gravar o arquivo XML com a assinatura.'
   RETURN(aRETORNO)
ENDIF

RETURN(aRETORNO)

Method Valida_XML(cXML) Class hbMDFe
/*
   Valida o arquivo XML
   Mauricio Cruz - 27/05/2013
*/
LOCAL oDOMDoc, oSchema, ParseError
LOCAL aRETORNO:=HASH()
LOCAL cSchemaFilename:=''

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

TRY
   oDOMDoc := xhb_CreateObject( _MSXML2_DOMDocument )
CATCH
   aRETORNO['MSG']:='Não foi possível carregar o MSXML para validação do XML.'
   RETURN(aRETORNO)
END

TRY
   oDOMDoc:async = .F.
   oDOMDoc:resolveExternals := .F.
   oDOMDoc:validateOnParse  = .T.
   oDOMDoc:LoadXML(cXML)
CATCH
   aRETORNO['MSG']:='Não foi possível carregar o arquivo XML para a validação.'
   RETURN(aRETORNO)
END
IF oDOMDoc:parseError:errorCode <> 0 // XML não carregado
   aRETORNO['MSG']:='Não foi possível carregar o documento pois ele não corresponde ao seu Schema'+HB_OsNewLine()+;
                    'Linha: '+STR(oDOMDoc:parseError:line)                                        +HB_OsNewLine()+;
                    'Caractere na linha: '+STR(oDOMDoc:parseError:linepos)                        +HB_OsNewLine()+;
                    'Causa do erro: '+oDOMDoc:parseError:reason                                   +HB_OsNewLine()+;
                    'Code: '+STR(oDOMDoc:parseError:errorCode)
  RETURN(aRETORNO)
ENDIF

TRY
   oSchema := xhb_CreateObject( _MSXML2_XMLSchemaCache )
CATCH
   aRETORNO['MSG']:='Não foi possível carregar o MSXML para o schema do XML.'
   RETURN(aRETORNO)
END

IF '</enviMDFe>' $ cXML .AND. '</Signature>' $ cXML   // envio da mdf
   cSchemaFilename := ::ohbNFe:cPastaSchemas+'\MDFe\enviMDFe_v1.00.xsd'
ELSEIF '</rodo>' $ cXML  // Modal Rodoviario
   cSchemaFilename := ::ohbNFe:cPastaSchemas+'\MDFe\mdfeModalRodoviario_v1.00.xsd'
ELSEIF '</Signature>' $ cXML .AND. !'</enviMDFe>' $ cXML .AND. !'</eventoMDFe>' $ cXML // assinatura
   cSchemaFilename := ::ohbNFe:cPastaSchemas+'\MDFe\xmldsig-core-schema_v1.01.xsd'
ELSEIF '</eventoMDFe>' $ cXML  // eventos
   cSchemaFilename := ::ohbNFe:cPastaSchemas+'\MDFe\eventoMDFe_v1.00.xsd'
ELSEIF '</evCancMDFe>' $ cXML  .AND. !'</eventoMDFe>' $ cXML // cancelamento
   cSchemaFilename := ::ohbNFe:cPastaSchemas+'\MDFe\evCancMDFe_v1.00.xsd'
ELSEIF '</evEncMDFe>' $ cXML  .AND. !'</eventoMDFe>' $ cXML // encerramento
   cSchemaFilename := ::ohbNFe:cPastaSchemas+'\MDFe\evEncMDFe_v1.00.xsd'
ENDIF

IF !FILE(cSchemaFilename)
  aRETORNO['MSG']:='Arquivo do schema não encontrado '+cSchemaFilename
  RETURN(aRETORNO)
ENDIF

TRY
  IF '</Signature>' $ cXML .AND. !'</enviMDFe>' $ cXML .AND. !'</rodo>' $ cXML .AND. !'</eventoMDFe>' $ cXML
      oSchema:add( 'http://www.w3.org/2000/09/xmldsig#', cSchemaFilename )
   ELSE
      oSchema:add( 'http://www.portalfiscal.inf.br/mdfe', cSchemaFilename )
   ENDIF
CATCH oError
   aRETORNO['MSG']:='Falha '+HB_OsNewLine()+ ;
                    'Error: '+Transform(oError:GenCode, nil)       + ';' +HB_OsNewLine()+;
                    'SubC: '+Transform(oError:SubCode, nil)        + ';' +HB_OsNewLine()+;
                    'OSCode: '+Transform(oError:OsCode,  nil)      + ';' +HB_OsNewLine()+;
                    'SubSystem: '+Transform(oError:SubSystem, nil) + ';' +HB_OsNewLine()+;
                    'Mensangem: '+oError:Description
  RETURN(aRETORNO)
END

oDOMDoc:Schemas := oSchema
ParseError := oDOMDoc:validate
IF ParseError:errorCode <> 0
   aRetorno['nResult']  := ParseError:errorCode
   aRETORNO['MSG']  := ParseError:reason
   RETURN(aRetorno)
ENDIF
oDOMDoc := nil
ParseError := nil
oSchema := nil
aRETORNO['STATUS']:=.T.

RETURN(aRETORNO)



Method ComunicaWebService(cXML,cSoap,cService) Class hbMDFe
/*
   Faz a comunicação com o webservice
   Mauricio Cruz - 23/05/2013
*/
LOCAL oServerWS
LOCAL aRETORNO:=HASH()
LOCAL cCERT:='', cUrlWS:=''

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF cXML=NIL .OR. EMPTY(cXML)
   aRETORNO['MSG']:='Favor informar o arquivo de XML.'
   RETURN(aRETORNO)
ENDIF


TRY
   cCERT := ::ohbNFe:pegaCNCertificado(::ohbNFe:cSerialCert)
CATCH
END
IF EMPTY(cCERT)
   aRETORNO['MSG']:='Não foi possível carregar as informações do certificado.'
   RETURN(aRETORNO)
ENDIF

cUrlWS:=::LinkWebService(cService)
IF EMPTY(cUrlWS) .AND. 'https' $ cService
   cUrlWS:=cService
ENDIF
IF EMPTY(cUrlWS)
   aRETORNO['MSG']:='Webservice não localizado'
   RETURN(aRETORNO)
ENDIF

TRY
   oServerWS:=xhb_CreateObject( _MSXML2_ServerXMLHTTP )
   oServerWS:setOption( 3, 'CURRENT_USER\MY\'+cCERT )
   oServerWS:open('POST', cUrlWS, .F.)
   oServerWS:setRequestHeader('SOAPAction', cSoap )
   oServerWS:setRequestHeader('Content-Type','application/soap+xml; charset=utf-8')
CATCH
   aRETORNO['MSG']:='Não foi possível inicializar a conexão do webservice'
   RETURN(aRETORNO)
END

IF oServerWS=NIL
   aRETORNO['MSG']:='Não foi possível inicializar o objeto de conexão do webservice'
   RETURN(aRETORNO)
ENDIF

TRY
   oDOMDoc:=xhb_CreateObject(_MSXML2_DOMDocument)
   oDOMDoc:async = .F.
   oDOMDoc:validateOnParse  = .T.
   oDOMDoc:resolveExternals := .F.
   oDOMDoc:preserveWhiteSpace = .T.
   oDOMDoc:LoadXML(cXML)
CATCH
   aRETORNO['MSG']:='Não foi possível carregar o documento XML'
   RETURN(aRETORNO)
END
IF oDOMDoc:parseError:errorCode <> 0
   aRETORNO['MSG']:='Não foi possível carregar o documento pois ele não corresponde ao seu Schema'+HB_OsNewLine()+;
                    ' Linha: '+STR(oDOMDoc:parseError:line)                                       +HB_OsNewLine()+;
                    ' Caractere na linha: '+STR(oDOMDoc:parseError:linepos)                       +HB_OsNewLine()+;
                    ' Causa do erro: '+oDOMDoc:parseError:reason                                  +HB_OsNewLine()+;
                    ' Code: '+STR(oDOMDoc:parseError:errorCode)
  RETURN(aRETORNO)
ENDIF

TRY
  oServerWS:send(oDOMDoc:xml)
CATCH e
   aRETORNO['MSG']:='Falha: Não foi possível conectar-se ao servidor do SEFAZ, Servidor inativou ou inoperante.'+HB_OsNewLine()+;
                    'Error: '+Transform(e:GenCode,nil)                                                      +';'+HB_OsNewLine()+;
                    'SubC: '+Transform(e:SubCode,nil)                                                       +';'+HB_OsNewLine()+;
                    'OSCode: '+Transform(e:OsCode,nil)                                                      +';'+HB_OsNewLine()+;
                    'SubSystem: '+Transform(e:SubSystem,nil)                                                +';'+HB_OsNewLine()+;
                    'Mensangem: '+e:Description
  RETURN(aRETORNO)
END
DO WHILE oServerWS:readyState <> 4
  millisec(500)
ENDDO
aRETORNO['MSG']:='Comunicação com o webservice finalizada com sucesso.'
aRETORNO['STATUS']:=.T.
aRETORNO['XML']:=::oFuncoes:RemoveAcentuacao(oServerWS:responseText)

RETURN(aRETORNO)


Method RecepcaoMDFe() Class hbMDFe
/*
   Recepção da MDFe
   Mauricio Cruz - 22/05/2013
*/
LOCAL oServerWS, oDOMDoc, e
LOCAL aRETORNO:=HASH()
LOCAL cXML:='', cCERT:='', cUrlWS:='', cXMLResp:=''

aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''
aRETORNO['cStat']:=''

IF ::cXML=NIL .OR. !FILE(::cXML)
   aRETORNO['MSG']:='Arquivo XML não informado ou inexistente.'
   RETURN(aRETORNO)
ENDIF

IF ::versaoDados = Nil
   ::versaoDados := ::ohbNFe:versaoDados
ENDIF

cXML+='<?xml version="1.0" encoding="UTF-8"?>'
cXML+='<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
cXML+=   '<soap12:Header>'
cXML+=      '<mdfeCabecMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRecepcao">'
cXML+=         '<cUF>'+ALLTRIM(::ohbNFe:empresa_UF)+'</cUF>'
cXML+=         '<versaoDados>'+ALLTRIM(::versaoDados)+'</versaoDados>'
cXML+=      '</mdfeCabecMsg>'
cXML+=   '</soap12:Header>'
cXML+=   '<soap12:Body>'
cXML+=      '<mdfeDadosMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRecepcao">'
cXML+=         MEMOREAD(::cXML)
cXML+=      '</mdfeDadosMsg>'
cXML+=   '</soap12:Body>'
cXML+='</soap12:Envelope>'

aRETORNO:=::ComunicaWebService(cXML,'http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRecepcao','MDFeRecepcao')
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF
cXMLResp:=aRETORNO['XML']
aRETORNO['STATUS']:=.F.

aRETORNO['tpAmb']    := ::oFuncoes:pegaTag(cXMLResp,'tpAmb')
aRETORNO['cUF']      := ::oFuncoes:pegaTag(cXMLResp,'cUF')
aRETORNO['verAplic'] := ::oFuncoes:pegaTag(cXMLResp,'verAplic')
aRETORNO['cStat']    := ::oFuncoes:pegaTag(cXMLResp,'cStat')
aRETORNO['xMotivo']  := ::oFuncoes:pegaTag(cXMLResp,'xMotivo')

IF VAL(aRETORNO['cStat'])>=200
   aRETORNO['nRec'] := STRTRAN(STRTRAN(STRTRAN(STRTRAN(SUBSTR(aRETORNO['xMotivo'],AT('[',aRETORNO['xMotivo'])+1,AT(']',aRETORNO['xMotivo'])),'nRec'),':'),']'),'.')
   aRETORNO['MSG']:=aRETORNO['xMotivo']
   RETURN(aRETORNO)
ENDIF

cXMLResp := ::oFuncoes:pegaTag(cXMLResp,'infRec')

aRETORNO['nRec']     := ::oFuncoes:pegaTag(cXMLResp,'nRec')
aRETORNO['dhRecbto'] := ::oFuncoes:DesFormatDate(::oFuncoes:pegaTag(cXMLResp,'dhRecbto'))
aRETORNO['hrRecbto'] := RIGHT(::oFuncoes:pegaTag(cXMLResp,'dhRecbto'),8)
aRETORNO['tMed']     := ::oFuncoes:pegaTag(cXMLResp,'tMed')
aRETORNO['MSG']      := aRETORNO['xMotivo']
aRETORNO['STATUS']:=.T.


RETURN(aRETORNO)


Method RetRecepcaoMDFe() Class hbMDFe
/*
   consulta o retorno da recepcao do MDF
   Mauricio Cruz - 23/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:='', cXMLResp:=''
aRETORNO['STATUS']:=.F.
aRETORNO['MSG']:=''

IF ::mdfRecibo=NIL .OR. EMPTY(::mdfRecibo)
   aRETORNO['MSG']:='Favor informar o recibo a ser consultado'
   RETURN(aRETORNO)
ENDIF
IF ::cXML=NIL .OR. EMPTY(::cXML)
   aRETORNO['MSG']:='Favor informar o XML assinado.'
   RETURN(aRETORNO)
ENDIF


IF ::versaoDados = Nil
   ::versaoDados := ::ohbNFe:versaoDados
ENDIF

cXML+='<?xml version="1.0" encoding="utf-8"?>'
cXML+='<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
cXML+=   '<soap12:Header>'
cXML+=      '<mdfeCabecMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRetRecepcao">'
cXML+=         '<cUF>'+ALLTRIM(::ohbNFe:empresa_UF)+'</cUF>'
cXML+=         '<versaoDados>'+ALLTRIM(::versaoDados)+'</versaoDados>'
cXML+=      '</mdfeCabecMsg>'
cXML+=   '</soap12:Header>'
cXML+=   '<soap12:Body>'
cXML+=      '<mdfeDadosMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRetRecepcao">'
cXML+=         '<consReciMDFe xmlns="http://www.portalfiscal.inf.br/mdfe" versao="'+ALLTRIM(::versaoDados)+'">'
cXML+=            '<tpAmb>'+::ohbNFe:tpAmb+'</tpAmb>'
cXML+=            '<nRec>'+ALLTRIM(::mdfRecibo)+'</nRec>'
cXML+=         '</consReciMDFe>'
cXML+=      '</mdfeDadosMsg>'
cXML+=   '</soap12:Body>'
cXML+='</soap12:Envelope>'

aRETORNO:=::ComunicaWebService(cXML,'http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRetRecepcao','MDFeRetRecepcao')
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF
cXMLResp:=aRETORNO['XML']
aRETORNO['STATUS']:=.F.

cXMLResp := ::oFuncoes:pegaTag(cXMLResp,'retConsReciMDFe')

aRETORNO['tpAmb']    := ::oFuncoes:pegaTag(cXMLResp,'tpAmb')
aRETORNO['verAplic'] := ::oFuncoes:pegaTag(cXMLResp,'verAplic')
aRETORNO['nRec']     := ::oFuncoes:pegaTag(cXMLResp,'nRec')
aRETORNO['cStat']    := ::oFuncoes:pegaTag(cXMLResp,'cStat')
aRETORNO['xMotivo']  := ::oFuncoes:pegaTag(cXMLResp,'xMotivo')
aRETORNO['cUF']      := ::oFuncoes:pegaTag(cXMLResp,'cUF')
IF VAL(aRETORNO['cStat'])<>104
   aRETORNO['MSG']:=aRETORNO['xMotivo']
   RETURN(aRETORNO)
ENDIF

cXMLResp := ::oFuncoes:pegaTag(cXMLResp,'infProt')
aRETORNO['tpAmb']    := ::oFuncoes:pegaTag(cXMLResp,'tpAmb')
aRETORNO['verAplic'] := ::oFuncoes:pegaTag(cXMLResp,'verAplic')
aRETORNO['chMDFe']   := ::oFuncoes:pegaTag(cXMLResp,'chMDFe')
aRETORNO['dhRecbto'] := ::oFuncoes:DesFormatDate(::oFuncoes:pegaTag(cXMLResp,'dhRecbto'))
aRETORNO['hrRecbto'] := RIGHT(::oFuncoes:pegaTag(cXMLResp,'dhRecbto'),8)
aRETORNO['nProt']    := ::oFuncoes:pegaTag(cXMLResp,'nProt')
aRETORNO['digVal']   := ::oFuncoes:pegaTag(cXMLResp,'digVal')
aRETORNO['cStat']    := ::oFuncoes:pegaTag(cXMLResp,'cStat')
aRETORNO['xMotivo']  := ::oFuncoes:pegaTag(cXMLResp,'xMotivo')
aRETORNO['infProt']  := '<infProt '+cXMLResp+'</infProt>'
aRETORNO['XML']      := '<mdfProc versao="1.00" xmlns="http://www.portalfiscal.inf.br/mdfe">'+::cXML+aRETORNO['infProt']+'</mdfProc>'

IF VAL(aRETORNO['cStat'])=204
   aRETORNO['nRec'] := STRTRAN(STRTRAN(STRTRAN(STRTRAN(SUBSTR(aRETORNO['xMotivo'],AT('[',aRETORNO['xMotivo'])+1,AT(']',aRETORNO['xMotivo'])),'nRec'),':'),']'),'.')
ENDIF

IF VAL(aRETORNO['cStat'])<>100
   aRETORNO['MSG']:=aRETORNO['xMotivo']
   RETURN(aRETORNO)
ENDIF

aRETORNO['STATUS']:=.T.

RETURN(aRETORNO)

Method ConsultaMDF() Class hbMDFe
/*
   consulta o protocologo da MDFe
   Mauricio Cruz - 28/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:='', cXMLResp:='', cXMLinfProt:='', cXMLeventoMDFe:='', cXMLevCancMDFe:='', cXMLretEventoMDFe:=''

aRETORNO['MSG']:=''
aRETORNO['STATUS']:=.F.

IF ::cCHAVE=NIL .OR. EMPTY(::cCHAVE)
   aRETORNO['MSG']:='Favor informar a chave da MDF-e a ser consultado'
   RETURN(aRETORNO)
ENDIF

IF ::versaoDados = Nil
   ::versaoDados := ::ohbNFe:versaoDados
ENDIF

cXML+='<?xml version="1.0" encoding="utf-8"?>'
cXML+='<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
cXML+=   '<soap12:Header>'
cXML+=      '<mdfeCabecMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsulta">'
cXML+=         '<cUF>'+ALLTRIM(::ohbNFe:empresa_UF)+'</cUF>'
cXML+=         '<versaoDados>'+ALLTRIM(::versaoDados)+'</versaoDados>'
cXML+=      '</mdfeCabecMsg>'
cXML+=   '</soap12:Header>'
cXML+=   '<soap12:Body>'
cXML+=      '<mdfeDadosMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsulta">'
cXML+=       '<consSitMDFe xmlns="http://www.portalfiscal.inf.br/mdfe" versao="'+ALLTRIM(::versaoDados)+'">'
cXML+=          '<tpAmb>'+::ohbNFe:tpAmb+'</tpAmb>'
cXML+=          '<xServ>CONSULTAR</xServ>'
cXML+=          '<chMDFe>'+ALLTRIM(::cCHAVE)+'</chMDFe>'
cXML+=       '</consSitMDFe>'
cXML+=      '</mdfeDadosMsg>'
cXML+=   '</soap12:Body>'
cXML+='</soap12:Envelope>'

aRETORNO:=::ComunicaWebService(cXML,'http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeConsulta/mdfeConsultaMDF','MDFeConsulta')
IF !aRETORNO['STATUS']
   aRETORNO['xMotivo']:=aRETORNO['MSG']
   RETURN(aRETORNO)
ENDIF
cXMLResp:=aRETORNO['XML']

cXMLResp:=::oFuncoes:pegaTag(cXMLResp,'retConsSitMDFe')

// Situação da MDFe
aRETORNO['cStat'] := ::oFuncoes:pegaTag(cXMLResp,'cStat')
aRETORNO['xMotivo'] := ::oFuncoes:pegaTag(cXMLResp,'xMotivo')

IF VAL(aRETORNO['cStat'])>=200
   aRETORNO['MSG']:=aRETORNO['xMotivo']
   RETURN(aRETORNO)
ENDIF

// Protocologo da MDFe
cXMLinfProt:=::oFuncoes:pegaTag(cXMLResp,'infProt')
aRETORNO['infProt_tpAmb']    := ::oFuncoes:pegaTag(cXMLinfProt,'tpAmb')
aRETORNO['infProt_verAplic'] := ::oFuncoes:pegaTag(cXMLinfProt,'verAplic')
aRETORNO['infProt_chMDFe']   := ::oFuncoes:pegaTag(cXMLinfProt,'chMDFe')
aRETORNO['infProt_dhRecbto'] := ::oFuncoes:DesFormatDate(::oFuncoes:pegaTag(cXMLinfProt,'dhRecbto'))
aRETORNO['infProt_hrRecbto'] := RIGHT(::oFuncoes:pegaTag(cXMLinfProt,'dhRecbto'),8)
aRETORNO['infProt_nProt']    := ::oFuncoes:pegaTag(cXMLinfProt,'nProt')
aRETORNO['infProt_digVal']   := ::oFuncoes:pegaTag(cXMLinfProt,'digVal')
aRETORNO['infProt_cStat']    := ::oFuncoes:pegaTag(cXMLinfProt,'cStat')
aRETORNO['infProt_xMotivo']  := ::oFuncoes:pegaTag(cXMLinfProt,'xMotivo')

// evento da MDFe
cXMLeventoMDFe:=::oFuncoes:pegaTag(cXMLResp,'eventoMDFe')
cXMLeventoMDFe:=::oFuncoes:pegaTag(cXMLeventoMDFe,'infEvento')
aRETORNO['eventoMDFe_cOrgao']     := ::oFuncoes:pegaTag(cXMLeventoMDFe,'cOrgao')
aRETORNO['eventoMDFe_tpAmb']      := ::oFuncoes:pegaTag(cXMLeventoMDFe,'tpAmb')
aRETORNO['eventoMDFe_CNPJ']       := ::oFuncoes:pegaTag(cXMLeventoMDFe,'CNPJ')
aRETORNO['eventoMDFe_chMDFe']     := ::oFuncoes:pegaTag(cXMLeventoMDFe,'chMDFe')
aRETORNO['eventoMDFe_dhEvento']   := ::oFuncoes:DesFormatDate(::oFuncoes:pegaTag(cXMLeventoMDFe,'dhEvento'))
aRETORNO['eventoMDFe_hrEvento']   := RIGHT(::oFuncoes:pegaTag(cXMLeventoMDFe,'dhEvento'),8)
aRETORNO['eventoMDFe_tpEvento']   := ::oFuncoes:pegaTag(cXMLeventoMDFe,'tpEvento')
aRETORNO['eventoMDFe_nSeqEvento'] := ::oFuncoes:pegaTag(cXMLeventoMDFe,'nSeqEvento')

// pedido de evendo de cancelamento da MDFe
cXMLevCancMDFe:=::oFuncoes:pegaTag(cXMLeventoMDFe,'evCancMDFe')
aRETORNO['evCancMDFe_descEvento'] := ::oFuncoes:pegaTag(cXMLevCancMDFe,'descEvento')
aRETORNO['evCancMDFe_nProt']      := ::oFuncoes:pegaTag(cXMLevCancMDFe,'nProt')
aRETORNO['evCancMDFe_xJust']      := ::oFuncoes:pegaTag(cXMLevCancMDFe,'xJust')

// protocologo de cancelamento da MDFe
cXMLretEventoMDFe:=::oFuncoes:pegaTag(cXMLResp,'retEventoMDFe')
cXMLretEventoMDFe:=::oFuncoes:pegaTag(cXMLretEventoMDFe,'infEvento')
aRETORNO['retEventoMDFe_tpAmb']       := ::oFuncoes:pegaTag(cXMLretEventoMDFe,'tpAmb')
aRETORNO['retEventoMDFe_verAplic']    := ::oFuncoes:pegaTag(cXMLretEventoMDFe,'verAplic')
aRETORNO['retEventoMDFe_cOrgao']      := ::oFuncoes:pegaTag(cXMLretEventoMDFe,'cOrgao')
aRETORNO['retEventoMDFe_cStat']       := ::oFuncoes:pegaTag(cXMLretEventoMDFe,'cStat')
aRETORNO['retEventoMDFe_xMotivo']     := ::oFuncoes:pegaTag(cXMLretEventoMDFe,'xMotivo')
aRETORNO['retEventoMDFe_chMDFe']      := ::oFuncoes:pegaTag(cXMLretEventoMDFe,'chMDFe')
aRETORNO['retEventoMDFe_tpEvento']    := ::oFuncoes:pegaTag(cXMLretEventoMDFe,'tpEvento')
aRETORNO['retEventoMDFe_xEvento']     := ::oFuncoes:pegaTag(cXMLretEventoMDFe,'xEvento')
aRETORNO['retEventoMDFe_nSeqEvento']  := ::oFuncoes:pegaTag(cXMLretEventoMDFe,'nSeqEvento')
aRETORNO['retEventoMDFe_dhRegEvento'] := ::oFuncoes:DesFormatDate(::oFuncoes:pegaTag(cXMLretEventoMDFe,'dhRegEvento'))
aRETORNO['retEventoMDFe_hrRegEvento'] := RIGHT(::oFuncoes:pegaTag(cXMLretEventoMDFe,'dhRegEvento'),8)
aRETORNO['retEventoMDFe_nProt']       := ::oFuncoes:pegaTag(cXMLretEventoMDFe,'nProt')

aRETORNO['procEventoMDFe'] := '<procEventoMDFe '+::oFuncoes:pegaTag(cXMLResp,'procEventoMDFe')+'</procEventoMDFe>'

aRETORNO['STATUS']   :=.T.


RETURN(aRETORNO)



Method StatusServico() Class hbMDFe
/*
   consulta o status do serviço da MDFe
   Mauricio Cruz - 28/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:='', cXMLResp:=''

aRETORNO['STATUS']:=.F.

IF ::versaoDados = Nil
   ::versaoDados := ::ohbNFe:versaoDados
ENDIF

cXML+='<?xml version="1.0" encoding="utf-8"?>'
cXML+='<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
cXML+=  '<soap12:Header>'
cXML+=    '<mdfeCabecMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeStatusServico">'
cXML+=      '<cUF>'+ALLTRIM(::ohbNFe:empresa_UF)+'</cUF>'
cXML+=      '<versaoDados>'+ALLTRIM(::versaoDados)+'</versaoDados>'
cXML+=    '</mdfeCabecMsg>'
cXML+=  '</soap12:Header>'
cXML+=  '<soap12:Body>'
cXML+=    '<mdfeDadosMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeStatusServico">'
cXML+=       '<consStatServMDFe xmlns="http://www.portalfiscal.inf.br/mdfe" versao="'+ALLTRIM(::versaoDados)+'">'
cXML+=          '<tpAmb>'+::ohbNFe:tpAmb+'</tpAmb>'
cXML+=          '<xServ>STATUS</xServ>'
cXML+=       '</consStatServMDFe>'
cXML+=    '</mdfeDadosMsg>'
cXML+=  '</soap12:Body>'
cXML+='</soap12:Envelope>'

aRETORNO:=::ComunicaWebService(cXML,'http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeStatusServico/mdfeStatusServicoMDF','MDFeStatusServico')
IF !aRETORNO['STATUS']
   aRETORNO['xMotivo']:=aRETORNO['MSG']
   RETURN(aRETORNO)
ENDIF
cXMLResp:=aRETORNO['XML']
cXMLResp := ::oFuncoes:pegaTag(cXMLResp,'retConsStatServMDFe')

aRETORNO['tpAmb']    := ::oFuncoes:pegaTag(cXMLResp,'tpAmb')
aRETORNO['verAplic'] := ::oFuncoes:pegaTag(cXMLResp,'verAplic')
aRETORNO['cStat']    := ::oFuncoes:pegaTag(cXMLResp,'cStat')
aRETORNO['xMotivo']  := ::oFuncoes:pegaTag(cXMLResp,'xMotivo')
aRETORNO['cUF']      := ::oFuncoes:pegaTag(cXMLResp,'cUF')
aRETORNO['dhRecbto'] := ::oFuncoes:DesFormatDate(::oFuncoes:pegaTag(cXMLResp,'dhRecbto'))
aRETORNO['hrRecbto'] := RIGHT(::oFuncoes:pegaTag(cXMLResp,'dhRecbto'),8)
aRETORNO['tMed']     := ::oFuncoes:pegaTag(cXMLResp,'tMed')
aRETORNO['MSG']      := aRETORNO['xMotivo']
aRETORNO['STATUS']:=.T.

RETURN(aRETORNO)


Method MDFeEvento(cXMLeve) Class hbMDFe
/*
   Registro de evento da MDFe
   Mauricio Cruz - 28/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:=''
LOCAL tpEvento:=''

aRETORNO['MSG']:=''
aRETORNO['STATUS']:=.F.

IF cXMLeve=NIL .OR. EMPTY(cXMLeve)
   aRETORNO['MSG']:='Favor informar o XML do evento'
ENDIF
IF ::cCHAVE=NIL .OR. EMPTY(::cCHAVE)
   aRETORNO['MSG']:='Favor informar a chave da MDF-e'
ENDIF
IF ::CNPJ=NIL .OR. EMPTY(::CNPJ)
   aRETORNO['MSG']:='Favor informar o CNPJ'
ENDIF

IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

IF ::versaoDados = Nil
   ::versaoDados := ::ohbNFe:versaoDados
ENDIF

IF '</evCancMDFe>' $ cXMLeve
   tpEvento:='110111'
   ::cXML:=::ohbNFe:pastaEnvRes+'\CANC_MDFe_'+ALLTRIM(::cCHAVE)+'.xml'
ELSEIF '</evEncMDFe>' $ cXMLeve
   tpEvento:='110112'
   ::cXML:=::ohbNFe:pastaEnvRes+'\ENCE_MDFe_'+ALLTRIM(::cCHAVE)+'.xml'
ENDIF

::URIId:=ALLTRIM(tpEvento)+ALLTRIM(::cCHAVE)+'01'

cXML+='<eventoMDFe xmlns="http://www.portalfiscal.inf.br/mdfe" versao="1.00">'
cXML+='<infEvento Id="ID'+::URIId+'">'
cXML+=   '<cOrgao>'+ALLTRIM(::ohbNFe:empresa_UF)+'</cOrgao>'
cXML+=   '<tpAmb>'+::ohbNFe:tpAmb+'</tpAmb>'
cXML+=   '<CNPJ>'+ALLTRIM(::CNPJ)+'</CNPJ>'
cXML+=   '<chMDFe>'+ALLTRIM(::cCHAVE)+'</chMDFe>'
cXML+=   '<dhEvento>'+::oFuncoes:FormatDate(DATE(),'YYYY-MM-DD','-')+'T'+LEFT(TIME(),8)+'</dhEvento>'
cXML+=   '<tpEvento>'+ALLTRIM(tpEvento)+'</tpEvento>'
cXML+=   '<nSeqEvento>1</nSeqEvento>'
cXML+=   '<detEvento versaoEvento="1.00">'
cXML+=      cXMLeve
cXML+=   '</detEvento>'
cXML+='</infEvento>'

IF FILE(::cXML)
   FERASE(::cXML)
ENDIF
IF !MEMOWRIT(::cXML,cXML,.F.)
   aRETORNO['MSG']:='Não foi possível gravar o arquivo XML de cancelamento assinado.'
   RETURN(aRETORNO)
ENDIF

aRETORNO:=::Assina_XML()
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF

aRETORNO['STATUS']:=.F.
IF !FILE(::cXML)
   aRETORNO['MSG']:='Não foi possível localizar o arquivo de XML de cancelamento assinada.'
   RETURN(aRETORNO)
ENDIF

cXMLeve:=MEMOREAD(::cXML)

cXML:='<?xml version="1.0" encoding="utf-8"?>'
cXML+='<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">'
cXML+=   '<soap12:Header>'
cXML+=      '<mdfeCabecMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRecepcaoEvento">'
cXML+=         '<cUF>'+ALLTRIM(::ohbNFe:empresa_UF)+'</cUF>'
cXML+=         '<versaoDados>'+ALLTRIM(::versaoDados)+'</versaoDados>'
cXML+=      '</mdfeCabecMsg>'
cXML+=   '</soap12:Header>'
cXML+=   '<soap12:Body>'
cXML+=      '<mdfeDadosMsg xmlns="http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRecepcaoEvento">'
cXML+=         cXMLeve
cXML+=      '</mdfeDadosMsg>'
cXML+=   '</soap12:Body>'
cXML+='</soap12:Envelope>'

aRETORNO:=::ComunicaWebService(cXML,'http://www.portalfiscal.inf.br/mdfe/wsdl/MDFeRecepcaoEvento/mdfeRecepcaoEvento','MDFeRecepcaoEvento')
IF !aRETORNO['STATUS']
   aRETORNO['xMotivo']:=aRETORNO['MSG']
   RETURN(aRETORNO)
ENDIF

cXMLResp:=aRETORNO['XML']

aRETORNO['XML'] := '<procEventoMDFe versao="1.00" xmlns="http://www.portalfiscal.inf.br/mdfe">'+;
                   cXMLeve+;
                   '<retEventoMDFe '+::oFuncoes:pegaTag(cXMLResp,'retEventoMDFe')+'</retEventoMDFe>'+;
                   '</procEventoMDFe>'

cXMLResp:=::oFuncoes:pegaTag(cXMLResp,'infEvento')
aRETORNO['tpAmb']       := ::oFuncoes:pegaTag(cXMLResp,'tpAmb')
aRETORNO['verAplic']    := ::oFuncoes:pegaTag(cXMLResp,'verAplic')
aRETORNO['cOrgao']      := ::oFuncoes:pegaTag(cXMLResp,'cOrgao')
aRETORNO['cStat']       := ::oFuncoes:pegaTag(cXMLResp,'cStat')
aRETORNO['xMotivo']     := ::oFuncoes:pegaTag(cXMLResp,'xMotivo')
aRETORNO['chMDFe']      := ::oFuncoes:pegaTag(cXMLResp,'chMDFe')
aRETORNO['tpEvento']    := ::oFuncoes:pegaTag(cXMLResp,'tpEvento')
aRETORNO['xEvento']     := ::oFuncoes:pegaTag(cXMLResp,'xEvento')
aRETORNO['nSeqEvento']  := ::oFuncoes:pegaTag(cXMLResp,'nSeqEvento')
aRETORNO['dhRegEvento'] := ::oFuncoes:DesFormatDate(::oFuncoes:pegaTag(cXMLResp,'dhRegEvento'))
aRETORNO['hrRegEvento'] := RIGHT(::oFuncoes:pegaTag(cXMLResp,'dhRegEvento'),8)
aRETORNO['nProt']       := ::oFuncoes:pegaTag(cXMLResp,'nProt')
aRETORNO['STATUS']      := .T.

RETURN(aRETORNO)

Method MDFeCancela() Class hbMDFe
/*
   Cancelamento de MDFe
   Mauricio Cruz - 28/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:='', cXMLResp:=''

aRETORNO['MSG']:=''
aRETORNO['STATUS']:=.F.

IF ::nProt=NIL .OR. EMPTY(::nProt)
   aRETORNO['MSG']:='Favor informar o protocologo para o cancelamento.'
ENDIF
IF ::xJust=NIL .OR. EMPTY(::xJust)
   aRETORNO['MSG']:='Favor informar a justificativa para o cancelamento.'
ENDIF
IF LEN(::xJust)<15
   aRETORNO['MSG']:='Favor informar uma justificativa maior do que 15 caracteres.'
ENDIF

IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

cXML+='<evCancMDFe xmlns="http://www.portalfiscal.inf.br/mdfe">'
cXML+=   '<descEvento>Cancelamento</descEvento>'
cXML+=   '<nProt>'+ALLTRIM(::nProt)+'</nProt>'
cXML+=   '<xJust>'+ALLTRIM(::xJust)+'</xJust>'
cXML+='</evCancMDFe>'

aRETORNO:=::Valida_XML(cXML)
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF
aRETORNO['STATUS']:=.F.

aRETORNO:=::MDFeEvento(cXML)

IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF

// Tratamento de duplicidade de evento
IF VAL(aRETORNO['cStat'])=631
   aRETORNO:=::ConsultaMDF()
   IF !aRETORNO['STATUS']
      RETURN(aRETORNO)
   ENDIF
   aRETORNO['XML']:=aRETORNO['procEventoMDFe']

   cXMLResp:=::oFuncoes:pegaTag(aRETORNO['XML'],'retEventoMDFe')
   cXMLResp:=::oFuncoes:pegaTag(cXMLResp,'infEvento')

   aRETORNO['tpAmb']       := ::oFuncoes:pegaTag(cXMLResp,'tpAmb')
   aRETORNO['verAplic']    := ::oFuncoes:pegaTag(cXMLResp,'verAplic')
   aRETORNO['cOrgao']      := ::oFuncoes:pegaTag(cXMLResp,'cOrgao')
   aRETORNO['cStat']       := '135'
   aRETORNO['xMotivo']     := ::oFuncoes:pegaTag(cXMLResp,'xMotivo')
   aRETORNO['chMDFe']      := ::oFuncoes:pegaTag(cXMLResp,'chMDFe')
   aRETORNO['tpEvento']    := ::oFuncoes:pegaTag(cXMLResp,'tpEvento')
   aRETORNO['xEvento']     := ::oFuncoes:pegaTag(cXMLResp,'xEvento')
   aRETORNO['nSeqEvento']  := ::oFuncoes:pegaTag(cXMLResp,'nSeqEvento')
   aRETORNO['dhRegEvento'] := ::oFuncoes:DesFormatDate(::oFuncoes:pegaTag(cXMLResp,'dhRegEvento'))
   aRETORNO['hrRegEvento'] := RIGHT(::oFuncoes:pegaTag(cXMLResp,'dhRegEvento'),8)
   aRETORNO['nProt']       := ::oFuncoes:pegaTag(cXMLResp,'nProt')
ENDIF
aRETORNO['MSG']:=aRETORNO['xMotivo']
aRETORNO['STATUS']:=.T.

IF VAL(aRETORNO['cStat'])<>135
   aRETORNO['STATUS']:=.F.
ENDIF

RETURN(aRETORNO)


Method MDFeEncerra() Class hbMDFe
/*
   Encerramento de MDFe
   Mauricio Cruz - 29/05/2013
*/
LOCAL aRETORNO:=HASH()
LOCAL cXML:=''

aRETORNO['MSG']:=''
aRETORNO['STATUS']:=.F.

IF ::nProt=NIL .OR. EMPTY(::nProt)
   aRETORNO['MSG']:='Favor informar o protocologo para o encerramento.'
ENDIF
IF ::cUFencerra=NIL .OR. EMPTY(::cUFencerra)
   aRETORNO['MSG']:='Favor informar o código da UF de encerramento da MDF-e.'
ENDIF
IF ::cMUNencerra=NIL .OR. EMPTY(::cMUNencerra)
   aRETORNO['MSG']:='Favor informar o código do município de encerramento da MDF-e.'
ENDIF

IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

cXML+='<evEncMDFe xmlns="http://www.portalfiscal.inf.br/mdfe">'
cXML+=   '<descEvento>Encerramento</descEvento>'
cXML+=   '<nProt>'+ALLTRIM(::nProt)+'</nProt>'
cXML+=   '<dtEnc>'+::oFuncoes:FormatDate(DATE(),'YYYY-MM-DD','-')+'</dtEnc>'
cXML+=   '<cUF>'+ALLTRIM(::cUFencerra)+'</cUF>'
cXML+=   '<cMun>'+ALLTRIM(::cMUNencerra)+'</cMun>'
cXML+='</evEncMDFe>'

aRETORNO:=::Valida_XML(cXML)
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF
aRETORNO['STATUS']:=.F.

aRETORNO:=::MDFeEvento(cXML)
IF !aRETORNO['STATUS']
   RETURN(aRETORNO)
ENDIF
aRETORNO['STATUS']:=.F.

aRETORNO:=::MDFeEvento(cXML)
IF !aRETORNO['STATUS']
   aRETORNO['STATUS']:=.F.
ENDIF

// Tratamento de duplicidade de evento
IF VAL(aRETORNO['cStat'])=631
   aRETORNO:=::ConsultaMDF()
   IF !aRETORNO['STATUS']
      RETURN(aRETORNO)
   ENDIF
   aRETORNO['XML']:=aRETORNO['procEventoMDFe']

   cXMLResp:=::oFuncoes:pegaTag(aRETORNO['XML'],'retEventoMDFe')
   cXMLResp:=::oFuncoes:pegaTag(cXMLResp,'infEvento')

   aRETORNO['tpAmb']       := ::oFuncoes:pegaTag(cXMLResp,'tpAmb')
   aRETORNO['verAplic']    := ::oFuncoes:pegaTag(cXMLResp,'verAplic')
   aRETORNO['cOrgao']      := ::oFuncoes:pegaTag(cXMLResp,'cOrgao')
   aRETORNO['cStat']       := '132'
   aRETORNO['xMotivo']     := ::oFuncoes:pegaTag(cXMLResp,'xMotivo')
   aRETORNO['chMDFe']      := ::oFuncoes:pegaTag(cXMLResp,'chMDFe')
   aRETORNO['tpEvento']    := ::oFuncoes:pegaTag(cXMLResp,'tpEvento')
   aRETORNO['xEvento']     := ::oFuncoes:pegaTag(cXMLResp,'xEvento')
   aRETORNO['nSeqEvento']  := ::oFuncoes:pegaTag(cXMLResp,'nSeqEvento')
   aRETORNO['dhRegEvento'] := ::oFuncoes:DesFormatDate(::oFuncoes:pegaTag(cXMLResp,'dhRegEvento'))
   aRETORNO['hrRegEvento'] := RIGHT(::oFuncoes:pegaTag(cXMLResp,'dhRegEvento'),8)
   aRETORNO['nProt']       := ::oFuncoes:pegaTag(cXMLResp,'nProt')
ENDIF
aRETORNO['MSG']:=aRETORNO['xMotivo']
IF VAL(aRETORNO['cStat'])<>132
   aRETORNO['STATUS']:=.F.
ENDIF

RETURN(aRETORNO)



Method MDFeImprimeFastReport() Class hbMDFe
/*
   Impressão da MDFe pelo FastReport
   Mauricio Cruz - 29/05/2013
*/
LOCAL oFrPrn
LOCAL aRETORNO:=HASH()
LOCAL aXML:={}, aREL:={}
LOCAL mI:=0
LOCAL cPLA:='', cRNT:='', cCPF:='', cNOM:=''

aRETORNO['MSG']:=''
aRETORNO['STATUS']:=.F.

IF ::cDANDFE=NIL .OR. !FILE(::cDANDFE)
   aRETORNO['MSG']:='Favor informar o arquivo da impressão do DANDFE'
ENDIF
IF ::cLANG=NIL .OR. !FILE(::cLANG)
   aRETORNO['MSG']:='Favor informar o arquivo da linguagem do FastReport'
ENDIF
IF ::cXML=NIL .OR. !FILE(::cXML)
   aRETORNO['MSG']:='Favor informar o arquivo xml da DANDFE'
ENDIF
IF !EMPTY(aRETORNO['MSG'])
   RETURN(aRETORNO)
ENDIF

AADD(aREL,{'ide.mod',''})
AADD(aREL,{'ide.serie',''})
AADD(aREL,{'ide.nMDF',''})
AADD(aREL,{'ide.dhEmi',''})
AADD(aREL,{'ide.UFIni',''})
AADD(aREL,{'ide.tpAmb',''})

AADD(aREL,{'emit.xNome',''})
AADD(aREL,{'emit.CNPJ',''})
AADD(aREL,{'emit.IE',''})

AADD(aREL,{'rodo.RNTRC',''})
AADD(aREL,{'rodo.CIOT',''})

AADD(aREL,{'enderEmit.xLgr',''})
AADD(aREL,{'enderEmit.nro',''})
AADD(aREL,{'enderEmit.xCpl',''})
AADD(aREL,{'enderEmit.xBairro',''})
AADD(aREL,{'enderEmit.cMun',''})
AADD(aREL,{'enderEmit.xMun',''})
AADD(aREL,{'enderEmit.CEP',''})
AADD(aREL,{'enderEmit.UF',''})
AADD(aREL,{'enderEmit.fone',''})
AADD(aREL,{'enderEmit.email',''})

AADD(aREL,{'infProt.chMDFe',''})
AADD(aREL,{'infProt.nProt',''})
AADD(aREL,{'infProt.dhRecbto',''})

AADD(aREL,{'tot.qCTe',''})
AADD(aREL,{'tot.qCT',''})
AADD(aREL,{'tot.qNFe',''})
AADD(aREL,{'tot.qNF',''})
AADD(aREL,{'tot.qCarga',''})

AADD(aREL,{'disp.CNPJForn',''})
AADD(aREL,{'disp.CNPJPg',''})
AADD(aREL,{'disp.nCompra',''})

AADD(aREL,{'infAdic.infAdFisco',''})
AADD(aREL,{'infAdic.infCpl',''})

oFrPrn := frReportManager():new()
oFrPrn:LoadFromFile(::cDANDFE)
oFrPrn:LoadLangRes(::cLANG)

aXML:=::oFuncoes:XMLnaArray(::cXML)
FOR mI:=1 TO LEN(aXML)
   nSCAN:=ASCAN(aREL,{|x| x[1]=ALLTRIM(aXML[mI,4])+'.'+ALLTRIM(aXML[mI,1])  })
   IF nSCAN>0
      aREL[nSCAN,2]:=aXML[mI,2]
   ENDIF
   IF (aXML[mI,4]='veicTracao' .OR. aXML[mI,4]='veicReboque') .AND. aXML[mI,1]='placa'
      cPLA+=TRANSFORM(aXML[mI,2],'@R XXX-9999')+HB_OsNewLine()
   ENDIF
   IF aXML[mI,4]='prop' .AND. aXML[mI,1]='RNTRC'
      cRNT+=aXML[mI,2]+HB_OsNewLine()
   ENDIF
   IF aXML[mI,4]='condutor' .AND. aXML[mI,1]='xNome'
      cNOM+=aXML[mI,2]+HB_OsNewLine()
   ENDIF
   IF aXML[mI,4]='condutor' .AND. aXML[mI,1]='CPF'
      cCPF+=TRANSFORM(aXML[mI,2],'@R 999.999.999-99')+HB_OsNewLine()
   ENDIF
NEXT
FOR mI:=1 TO LEN(aREL)
   oFrPrn:AddVariable(LEFT(aREL[mI,1],AT('.',aREL[mI,1])-1), STRTRAN(aREL[mI,1],'.','_'),"'"+aREL[mI,2]+"'" )
NEXT
oFrPrn:AddVariable('VEICULO','PLACA',cPLA )
oFrPrn:AddVariable('VEICULO','RNTRC',cRNT )
oFrPrn:AddVariable('MOTORISTA','NOME',cNOM )
oFrPrn:AddVariable('MOTORISTA','CPF',cCPF )

oFrPrn:SetProperty("MailExport", "ShowDialog", .f.)
oFrPrn:SetEventHandler("MailExport", "OnSendMail", {|| ShowMsg('Atenção !!!, Por essa opção apenas é enviado o DAMDFE em formato PDF'),MySendMail(oFrPrn)})
oFrPrn:SetIcon(1001)
oFrPrn:SetTitle( 'DAMDEFE' )

IF ::lDesign
   oFrPrn:DesignReport()
ELSE
   //oFrPrn:PrepareReport()
   oFrPrn:PreviewOptions:SetZoomMode(2)
   oFrPrn:ShowReport()
ENDIF
oFrPrn:DestroyFR()
oFrPrn:=NIL

aRETORNO['STATUS']:=.T.

RETURN(aRETORNO)















/*
aXML:=::oFuncoes:XMLnaArray(::cXML)
ASORT(aXML,,,{|x,y|  x[4] < y[4] })
FOR mI:=1 TO LEN(aXML)
   IF !EMPTY(aXML[mI,2])
      oFrPrn:AddVariable(aXML[mI,4],aXML[mI,1],aXML[mI,2])
   ENDIF
NEXT
*/
