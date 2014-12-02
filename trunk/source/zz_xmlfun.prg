/*
   O objetivo desta fun��o � montar o "node" do XML com menos fonte.
   Ao inv�s de "<cliente>" + cliente->Codigo + "</cliente>"
   S� usar  XmlTag( "cliente", cliente->Codigo )
   Fica um fonte menor e mais leg�vel
   E quando o conte�do for vazio, o node vira "<cliente />"
*/
FUNCTION XmlTag( cTag, xValue )
   LOCAL cXml

   IF Empty( xValue )
      cXml := "<" + cTag + " />"
   ELSE
      cXml := "<" + cTag + ">" + xValue + "</" + cTag + ">"
   ENDIF
   RETURN cXml
