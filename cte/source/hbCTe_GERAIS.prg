/*
   Classe de metodos gerais de integração da CT-e com  xHarbour
   Mauricio Cruz - 15/07/2013
   - cruz@sygecom.com.br
   - www.sygecom.com.br
*/
#include "common.ch"
#include "hbclass.ch"
#Include "hwgui.ch"
#include "HBXML.ch"
#include "hbCTe.ch"

Class oCTe_GERAIS

   // Metodos Rotinas gerais
   Method rgRetorna_uf(xBUS,nPOS)
   Method rgRetorna_municipio(xBUS,nPOS)
   Method rgLimpaString(cStr)
   Method rgRetorna_paises(xBUS,nPOS)
   Method rgRelatorioGeral(oOBJ,cSOP,cFIL)
   
   // SUBSTITUIR POR ROTINA DE AVISO DE ALERTA (MENSAGEM,TITULO)
   Method uiAviso( cMsg, cTit ) INLINE SHOWMSG(cMsg,cTit)   
   
   // SUBSTITUIR POR ROTINA DE PERGUNTA DE SIM OU NAO (MENSAGEM) RETORNA .T.=SIM, .F.=NAO
   Method uiSN( cMsg ) INLINE SN(cMsg)  
   
   // SUBSTITUIR POR ROTINA QUE RETORNE A DESCRICAO DO CFOP  (CODIGO CFOP)
   Method rgDesccfop(nCfop) INLINE DESCCFOP(nCfop) 
   
   // SUBSTITUIR POR ROTINA QUE RETORNE UMA ARRAY COM {CODIGO,CIDADE}
   Method rgTodas_Cidades() INLINE TODAS_CIDADES()  

   // SUBSTITUIR POR ROTINA Q RETORNE UMA ARRAY COM {CODIGO,PAIS}
   Method rgTodos_Paises() INLINE LISTA_PAIS()  

   // SUBSTITUIR POR ROTINA QUE GERE A NUMERCAO SEQUENCIAL DA CT-E (CHAVE DE BUSCA,.T.=GRAVA A SEQUENCIA .F.=SIMULA,ZERA A SEQUENCIA)
   Method rgSequencia(cKey,lGrava,lZera_Seq) INLINE SEQUENCIA(cKey,lGrava,lZera_Seq)   
   
   // SUBSTITUIR POR ROTINA QUE GERE A NUMERCAO SEQUENCIAL DA CT-E E CONEXAO SEPARADA SQL (CHAVE DE BUSCA,.T.=GRAVA A SEQUENCIA .F.=SIMULA,ZERA A SEQUENCIA)
   Method rgSequencia_Sql(cKey,lGrava,lZera_Seq) INLINE SEQUENCIA_SQL(cKey,lGrava,lZera_Seq)   

   // SUBSTITUIR POR ROTINA QUE CARREGA UMA ARRAY COM AS CIDADES DA UF SELECIONADA (UF,OBJETO COMBOBOX A SER CARREGADO COM AS CIDADES,ARRAY A SER CARREGADA) RETORNA ARRAY COM AS CIDADES
   Method rgRecarrega_combo_uf(cUF,oOBJ,aCID) INLINE RECARREGA_COMBO_UF(cUF,oOBJ,@aCID) 
   
   // SUBSTITUIR POR ROTINA QUE RETORNE O NOME DO CLIENTE  (CODIGO CLIENTE)
   Method rgDesccli(nCli) INLINE DESCCLI(nCli) 
   
   // SUBSTITUIR POR ROTINA QUE RETORNE O NOME DO TRANSPORTADOR  (CODIGO TRANSPOTADOR)
   Method rgDescTrp(nCod) INLINE DESCTRP(nCOD)

   // SUBSTITUIR POR ROTINA QUE RETORNE O CODIGO IBGE DO MUNICIPIO (UF,CIDADE)
   Method rgPega_Cod_Cidade(cEst,cCid) INLINE PEGA_COD_CIDADE(cEst,cCid) 

   // SUBSTITUIR POR ROTINA DE CONECTA E EXECUTA UMA QUERY NO BANCO DE DADOS E RETORNE NA ARRAY (COMANDO SQL,CAMINHO PARA GERACAO DO ARQUIVO DBF,ALIAS DBF,VETOR A SER RETORNADO COM O RESULTADO DO SQL,.T.=EXIBIR ERROS SQL,.T.=EXIBE O RETORNO)
   Method rgExecuta_Sql(cSql,cPthDBF,cAlias,aVet,lErr,lQry) INLINE EXECUTA_SQL(cSql,cPthDBF,cAlias,@aVet,lErr,lQry)  
   
   // SUBSTITUIR POR ROTINA QUE RETORNE QUALQUER TIPO DE DADO EM STRING ENTRE ASPAS SIMPLES PARA O COMANDO SQL (DADO A SER TRANSFORMADO,.T.=TIPO DATE PARA TRANSFORMAR EM NULL)
   Method rgConcat_sql(cSql,lDATA) INLINE CONCAT_SQL(cSql,lDATA)

   // SUBSTITUIR POR ROTINA DE INICIO DE TRANSACAO DE BANCO DE DADOS: BEGIN
   Method rgBeginTransaction() INLINE SYG_BEGINTRANSACTION()   
   
   // SUBSTITUIR POR ROTINA DE FINALIZACAO DE TRANSACAO DE BANCO DE DADOS: COMMIT
   Method rgEndTransaction() INLINE SYG_ENDTRANSACTION()  

   // SUBSTITUIR POR ROTINA DE CANCELAMENTO DE TRANSACAO DE BANCO DE DADOS: ROLLBACK
   Method rgRollBackTransaction() INLINE SYG_ROLLBACKTRANSACTION() 

   // SUBSTITUIR POR ROTINA DE ENVIO DE EMAIL(OBJETO PARA O FASTREPORT)
   Method rgMySendMail(oOBJ) INLINE MYSENDMAIL(oOBJ)  

   // SUBSTITUIR POR ROTINA QUE FACA UMA BUSCA INCREMENTAL NA ARRAY (COLUNA DA ARRAY,STRING DA BUSCA,OBJETO DA BROWSE,ARRAY PARA AGRUPAMENTO,AGRUPAMENTO APROXIMADO)
   Method rgBuscaNaArray(nORD,cBUS,oBrw,aGRP,aPROX) INLINE  BUSCA_NA_ARRAY(nORD,cBUS,oBrw,aGRP,aPROX)

   // SUBSTITUR POR ROTINA QUE MARQUE TODA UAM POSICAO DA ARRAY COM .T. OU .F. (OBJETO DA BROWE,COLUNA,VALOR A SER MARCADO)
   Method rgMarcaDesmarcaTudo(oBrw,nPOS,lVAL) INLINE MARCA_DESMARCA_TUDO(oBrw,nPOS,lVAL)  
   
   // SUBSTITUIR POR TELA DE BUSCA DE PRAZO DE PAGAMENTO
   Method rgPegaPrazo(cBUS,oCOD,oDES) INLINE PESQPRAZO2(cBUS,oCOD,oDES)
   
   // SUBSTITUIR POR ROTINA QUE GERE CONTAS A RECEBER DA CTE
   Method rgGeraCtaRec(nCTE_ID) INLINE GERA_CTA_REC_CTE(nCTE_ID)

   // SUBSTITUIR POR ROTINA QUE RETORNE .T. SE JA TIVER ALGUMA PARCELA DO CONTAS A RECER DO CTE RECEBIDA
   Method rgCteJaEstaRecebida(nCTE_ID) INLINE VERIFICA_CTE_RECEBIDA(nCTE_ID)
   
   // SUBSTITUIR POR ROTINA QUE DELETA O CONTAS A RECEBER DA CTE
   Method rgDeletaCtaRec(nCTE_ID) INLINE DELETA_CTA_REC_CTE(nCTE_ID)

   // SUBSTITUIR POR ROTINA QUE IMPRIMA A CT DE PAPEL
   Method rgImprimeCTPapel(nCTE_ID,cTIPimp,cPTHpdf) INLINE IMPRIMECTPAPEL(nCTE_ID,cTIPimp,cPTHpdf)
   
   // SUBSTITUIR POR ROTINA DE BUSCA DE PLACAS
   Method rgPegaPlaca(cPLA,lMULT,oPLA,oTRP,oMOT,lBUSCA) INLINE PEGA_PLACA(cPLA,lMULT,oPLA,oTRP,oMOT,lBUSCA)
   
   // SUBSTITUIR POR ROTINA DE PREPARO DE CHAMADA DO FASTREPORT
   Method rgChamaFastReport(cSOP,aALI,cREL,aARR,cARQpdf,aVARIAVEIS,lPERGUNTA_PRINT,lModoEdicao, nBOLETO, cENTSAI) INLINE CHAMA_FASTREP(cSOP,aALI,cREL,aARR,cARQpdf,aVARIAVEIS,lPERGUNTA_PRINT,lModoEdicao, nBOLETO, cENTSAI)
   
   // SUBSTITUIR POR ROTINA DE SELECAO DE ARQUIVO EM DISCL
   Method rgPegaArquivo(cTip,oOBJ) INLINE PEGA_ARQUIVO({cTIP},{cTIP},oOBJ)
   
   // SUBSTITUIR POR ROTINA QUE ABRA UM ARQUIVO EM DISCO
   Method rgAbreArquivo(cARQ) INLINE ABRE_ARQUIVO( cARQ )

EndClass



Method rgRetorna_uf(xBUS,nPOS) Class oCTe_GERAIS
/*
   Retorna a UF ou o codigo da UF
   Mauricio Cruz - 17/07/2013
*/
LOCAL xRET
LOCAL nSCAN:=0
LOCAL aUF:={}

IF nPOS=NIL
   nPOS:=1
ENDIF
AADD( aUF, { 11, 'RO'  } )
AADD( aUF, { 12, 'AC'  } )
AADD( aUF, { 13, 'AM'  } )
AADD( aUF, { 14, 'RR'  } )
AADD( aUF, { 15, 'PA'  } )
AADD( aUF, { 16, 'AP'  } )
AADD( aUF, { 17, 'TO'  } )
AADD( aUF, { 21, 'MA'  } )
AADD( aUF, { 22, 'PI'  } )
AADD( aUF, { 23, 'CE'  } )
AADD( aUF, { 24, 'RN'  } )
AADD( aUF, { 25, 'PB'  } )
AADD( aUF, { 26, 'PE'  } )
AADD( aUF, { 27, 'AL'  } )
AADD( aUF, { 28, 'SE'  } )
AADD( aUF, { 29, 'BA'  } )
AADD( aUF, { 31, 'MG'  } )
AADD( aUF, { 32, 'ES'  } )
AADD( aUF, { 33, 'RJ'  } )
AADD( aUF, { 35, 'SP'  } )
AADD( aUF, { 41, 'PR'  } )
AADD( aUF, { 42, 'SC'  } )
AADD( aUF, { 43, 'RS'  } )
AADD( aUF, { 50, 'MS'  } )
AADD( aUF, { 51, 'MT'  } )
AADD( aUF, { 52, 'GO'  } )
AADD( aUF, { 53, 'DF'  } )
AADD( aUF, { 54, 'EX'  } )
nSCAN:=ASCAN( aUF, {|x|x[nPOS]=xBUS} )
IF nSCAN>0
  xRET:=aUF[nSCAN,IF(nPOS=1,2,1)]
ENDIF
Return(xRET)


Method rgRetorna_municipio(xBUS,nPOS,nCODuf) Class oCTe_GERAIS
/*
   retorna o codigo ou nome do municipio
   Mauricio cruz - 17/07/2013
*/
LOCAL xRET
LOCAL aCIDADE:=::rgTodas_Cidades()
LOCAL nSCAN:=0

IF nCODuf<>NIL .AND. nCODuf>0 .AND. nPOS=2
   nSCAN:=ASCAN( aCIDADE, {|x|x[2]=xBUS  .AND. VAL(LEFT(ALLTRIM(STR(x[1])),2))=nCODuf } )
ELSE
   nSCAN:=ASCAN( aCIDADE, {|x|x[nPOS]=xBUS} )
ENDIF

IF nSCAN>0
  xRET:=aCIDADE[nSCAN,IF(nPOS=1,2,1)]
ENDIF
return(xRET)


Method rgLimpaString(cStr) Class oCTe_GERAIS
/*
   Limpa a string dos acentos e caracteres que nao sao permitidos nos XML
   Mauricio Cruz - 19/07/2013
*/
LOCAL mI:=0

IF VALTYPE(cStr)<>'C'
   RETURN(cStr)
ENDIF
IF DAY(CTOD(cStr))>0   // EM CASO DE DATAS
   RETURN(cStr)
ENDIF

cStr:=StrTran(cStr,"Ã","A")
cStr:=StrTran(cStr,"Â","A")
cStr:=StrTran(cStr,"Á","A")
cStr:=StrTran(cStr,"Ä","A")
cStr:=StrTran(cStr,"À","A")
cStr:=StrTran(cStr,"ã","a")
cStr:=StrTran(cStr,"â","a")
cStr:=StrTran(cStr,"á","a")
cStr:=StrTran(cStr,"ä","a")
cStr:=StrTran(cStr,"à","a")
cStr:=StrTran(cStr,"É","E")
cStr:=StrTran(cStr,"Ê","E")
cStr:=StrTran(cStr,"Ë","E")
cStr:=StrTran(cStr,"È","E")
cStr:=StrTran(cStr,"é","e")
cStr:=StrTran(cStr,"ê","e")
cStr:=StrTran(cStr,"ë","e")
cStr:=StrTran(cStr,"è","e")
cStr:=StrTran(cStr,"Í","I")
cStr:=StrTran(cStr,"Î","I")
cStr:=StrTran(cStr,"Ï","I")
cStr:=StrTran(cStr,"Ì","I")
cStr:=StrTran(cStr,"í","i")
cStr:=StrTran(cStr,"î","i")
cStr:=StrTran(cStr,"ï","i")
cStr:=StrTran(cStr,"ì","i")
cStr:=StrTran(cStr,"Ó","O")
cStr:=StrTran(cStr,"Õ","O")
cStr:=StrTran(cStr,"Ô","O")
cStr:=StrTran(cStr,"ó","O")
cStr:=StrTran(cStr,"Ö","O")
cStr:=StrTran(cStr,"Ò","O")
cStr:=StrTran(cStr,"õ","o")
cStr:=StrTran(cStr,"ô","o")
cStr:=StrTran(cStr,"ó","o")
cStr:=StrTran(cStr,"ö","o")
cStr:=StrTran(cStr,"ò","o")
cStr:=StrTran(cStr,"º","")
cStr:=StrTran(cStr,CHR(176),"")
cStr:=StrTran(cStr,"Û","U")
cStr:=StrTran(cStr,"Ú","U")
cStr:=StrTran(cStr,"Ü","U")
cStr:=StrTran(cStr,"Ù","U")
cStr:=StrTran(cStr,"û","u")
cStr:=StrTran(cStr,"ú","u")
cStr:=StrTran(cStr,"ü","u")
cStr:=StrTran(cStr,"ù","u")
cStr:=StrTran(cStr,"Ç","C")
cStr:=StrTran(cStr,"ç","c")
cStr:=StrTran(cStr,"&")

FOR mI:=1 TO 31
   IF CHR(mI)$cStr
      cStr:=StrTran( cStr, CHR(mI))
   ENDIF
NEXT

cStr:=STRTRAN(cStr,'–')
IF CHR(135)$cStr // ‡
   cStr:=StrTran( cStr, CHR(135))
ENDIF
IF CHR(145)$cStr // æ
   cStr:=StrTran( cStr, CHR(145))
ENDIF
IF CHR(146)$cStr  // Æ
   cStr:=StrTran( cStr, CHR(146))
ENDIF
IF CHR(155)$cStr  // ø
   cStr:=StrTran( cStr, CHR(155))
ENDIF
FOR mI:=156 TO 159  // £  Ø × ƒ 
   IF CHR(mI)$cStr
      cStr:=StrTran( cStr, CHR(mI))
   ENDIF
NEXT
IF CHR(166)$cStr  //  ª
   cStr:=StrTran( cStr, CHR(166))
ENDIF
IF CHR(167)$cStr    //  º
   cStr:=StrTran( cStr, CHR(167))
ENDIF
FOR mI:=169 TO 254  // ® ¬ ½ ¼ ¡ « » .....
   IF CHR(mI)$cStr
      cStr:=StrTran( cStr, CHR(mI))
   ENDIF
NEXT

RETURN(cStr)


Method rgRetorna_paises(xBUS,nPOS) Class oCTe_GERAIS
/*
   retorna o codigo ou nome do pais
   Mauricio cruz - 19/07/2013
*/
LOCAL xRET
LOCAL aPAIS:=::rgTodos_Paises()
LOCAL nSCAN:=0
nSCAN:=ASCAN( aPAIS, {|x|x[nPOS]=xBUS} )
IF nSCAN>0
  xRET:=aPAIS[nSCAN,IF(nPOS=1,2,1)]
ENDIF
return(xRET)


Method rgRelatorioGeral(oOBJ,cSOP,cFIL) Class oCTe_GERAIS
/*
   Impressao em fastreport do relatorio geral dos cte
   Mauricio Cruz - 22/08/2013
*/
LOCAL mI:=0
LOCAL aSQL:={}

WITH OBJECT oOBJ
   ::rgExecuta_Sql('select a.cte_numerodacte, '+;                                            // 01
                   '       a.cte_serie, '+;                                                  // 02
                   '       a.cte_modelo, '+;                                                 // 03
                   '       a.cte_dataemissao, '+;                                            // 04
                   '       a.cte_dataautorizacao, '+;                                        // 05
                   "       case when trim(a.cte_prot_canc)<>'' then 'CANCELADA' "+;          
                   "            when trim(a.cte_prot_inut)<>'' then 'INUTILIZADA' "+;        
                   "            when trim(a.cte_protocolo)<>'' then 'AUTORIZADA' "+;         
                   "            else 'NÃO TRANSMITIDA' "+;                                   
                   '       end::text, '+;                                                    // 06
                   '       a.remetente_id, '+;                                               // 07
                   "       coalesce(b.cliente,'')::text, "+;                                 // 08
                   '       a.destinatario_id, '+;                                            // 09
                   '       a.cte_descricaopredominante, '+;                                  // 10
                   '       case '+;                                                          
                   "          when a.cte_tiposervico=0 then 'Normal' "+;                     
                   "          when a.cte_tiposervico=1 then 'Subcontratação' "+;             
                   "          when a.cte_tiposervico=2 then 'Redespacho' "+;                 
                   "          when a.cte_tiposervico=3 then 'Redespacho Intermediário' "+;  
                   '       end::text, '+;                                                    // 11
                   '       case '+;                                                          
                   "          when a.cte_tomadorservico=0 then 'Remetente' "+;               
                   "          when a.cte_tomadorservico=1 then 'Expedidor' "+;               
                   "          when a.cte_tomadorservico=2 then 'Recebedor' "+;               
                   "          when a.cte_tomadorservico=3 then 'Destinatário' "+;            
                   '       end::text, '+;                                                    // 12
                   '       a.cte_volumes, '+;                                                // 13
                   '       a.cte_pesobruto, '+;                                              // 14
                   '       a.cte_valortotalmercad, '+;                                       // 15
                   '       a.cfop_id, '+;                                                    // 16
                   '       a.cte_placa, '+;                                                  // 17
                   '       a.cte_rntrc, '+;                                                  // 18
                   '       case '+;
                   "          when a.cte_imposto=00 then '00-ICMS Normal' "+;
                   "          when a.cte_imposto=20 then '20-Redução de BC' "+;
                   "          when a.cte_imposto=40 then '40-ICMS Isenção' "+;
                   "          when a.cte_imposto=45 then '45-Isento, não tributado ou diferido' "+;
                   "          when a.cte_imposto=51 then '51-ICMS diferido' "+;
                   "          when a.cte_imposto=60 then '60-Cobrado por substituição tributária' "+;
                   "          when a.cte_imposto=90 then '90-Outros' "+;
                   '       end::text as base_calculo, '+;                                     // 19
                   '       a.cte_icmsbasecalc as base_calculo, '+;                           // 20
                   '       a.cte_icmsaliq as aliq_icms, '+;                                  // 21
                   '       a.cte_icmsvalor as valor_icms, '+;                                // 22
                   '       a.cte_icmsreducaobc as reducao_bc, '+;                            // 23
                   '       a.cte_vbcstret as val_bc_st_ret, '+;                              // 24
                   '       a.cte_vicmsstret as val_icms_st_ret, '+;                          // 25
                   '       a.cte_picmsstret as aliq_icms_bc_st_ret, '+;                      // 26
                   '       a.cte_vcred as val_cre_op, '+;                                    // 27
                   '       a.cte_predbcoutrauf as aliq_red_bc_out_uf, '+;                    // 28
                   '       a.cte_vbcoutrauf as val_bc_icms_out_uf, '+;                       // 29
                   '       a.cte_picmsoutrauf as aliq_icms_out_uf, '+;                       // 30
                   '       a.cte_vicmsoutrauf as val_icms_dev_out_uf, '+;                    // 31
                   '       a.cte_id, '+;                                                     // 32
                   '       f.prest_id_cte_cad_servico, '+;                                   // 33
                   '       h.servico, '+;                                                    // 34
                   '       f.prest_quant, '+;                                                // 35
                   '       f.prest_valor, '+;                                                // 36
                   '       f.prest_valor*f.prest_quant, '+;                                  // 37 
                   '       g.docs_tipo, '+;                                                  // 38
                   '       g.docs_ndoc, '+;                                                  // 39
                   '       g.docs_demi, '+;                                                  // 40
                   '       g.docs_vbc, '+;                                                   // 41
                   '       g.docs_vicms, '+;                                                 // 42
                   '       g.docs_vbcst, '+;                                                 // 43
                   '       g.docs_vst, '+;                                                   // 44
                   '       g.docs_vprod, '+;                                                 // 45
                   '       g.docs_vnf, '+;                                                   // 46
                   '       g.docs_ncfop, '+;                                                 // 47
                   '       g.docs_npeso, '+;                                                 // 48
                   '       g.docs_chavenfe, '+;                                              // 49
                   '       g.docs_id_cte, '+;                                                // 50
                   '       a.cte_valfrete '+;                                                // 51
                   '  from sagi_cte a '+;
                   '  left join cag_cli b on b.codcli=a.remetente_id '+;
                   '  left join cag_cli c on c.codcli=a.destinatario_id '+;
                   '  left join sagi_cte_prestacao_servico f on f.prest_id_cte=a.cte_id '+;
                   '  left join sagi_cte_docs g on g.docs_id_cte=a.cte_id '+;
                   '  left join tipserv h on h.codserv=f.prest_id_cte_cad_servico '+;
                   ' where a.'+IF(:oPER:GETTEXT()='Emissão','cte_dataemissao','cte_dataautorizacao')+'>='+::rgConcat_sql(:oINI:GETVALUE())+;
                   '   and a.'+IF(:oPER:GETTEXT()='Emissão','cte_dataemissao','cte_dataautorizacao')+'<='+::rgConcat_sql(:oFIM:GETVALUE())+;
                   '   and '+IF(:oSIT:GETTEXT()<>'TODAS'," case when trim(a.cte_prot_canc)<>'' then 'CANCELADA' "+;
                                                         "      when trim(a.cte_prot_inut)<>'' then 'INUTILIZADA' "+;
                                                         "      when trim(a.cte_protocolo)<>'' then 'AUTORIZADA' "+;
                                                         "      else 'NÃO TRANSMITIDA' "+;
                                                         ' end::text='+::rgConcat_sql(:oSIT:GETTEXT()),'true')+;
                   '   and a.cte_serie='+::rgConcat_sql(:oSER:GETTEXT())+;
                   '   and a.cte_modelo='+::rgConcat_sql(:oMOD:GETTEXT())+;
                   '   and ('+IF(:oREM:GETVALUE(),"b.cliente like '%"+ALLTRIM(:oNOM:VARGET())+"%'",'true')+;
                   '    or ' +IF(:oDES:GETVALUE(),"c.cliente like '%"+ALLTRIM(:oNOM:VARGET())+"%'",'true')+')'+;
                   '   and '+IF(!EMPTY(:oPROD:VARGET()),"a.cte_descricaopredominante like '%"+ALLTRIM(:oPROD:VARGET())+"%'" ,'true')+;
                   '   and '+IF(:oCFOP:VARGET()>0,'a.cfop_id='+::rgConcat_sql(:oCFOP:VARGET()),'true')+;
                   '   and '+IF(!EMPTY(:oPLA:VARGET()),"a.cte_placa like '%"+ALLTRIM(:oPLA:VARGET())+"%'",'true')+;
                   '   and '+IF(:oRNTRC:VARGET()>0,"a.cte_rntrc like '%"+ALLTRIM(STR(:oRNTRC:VARGET()))+"%'"  ,'true')+;
                   '   and a.empresa='+::rgConcat_sql(cFIL)+;
                   ' order by '+ALLTRIM(STR(:oORD:GETVALUE()))+', 1, g.docs_id_cte',,,@aSQL)
				   
   
   ::rgChamaFastReport(cSOP,NIL,PEGA_ARQUIVO_SAGI(125),{aSQL},NIL,{:oITNpre:GETVALUE(),:oIMP:GETVALUE()})
   //Marco Barcelos - Caso: 2855
   //::rgChamaFastReport(cSOP,NIL,'relatorios\sagi_rel_cte2.fr3',{aSQL},NIL,{:oITNpre:GETVALUE(),:oIMP:GETVALUE()})

END

RETURN(.T.)

