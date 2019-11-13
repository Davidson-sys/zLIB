/* -------------------------------------------------------------------------------------------

Copyright 2015-2019 J�lio Wittwer ( siga0984@gmail.com | http://siga0984.wordpress.com/ )

� permitido, gratuitamente, a qualquer pessoa que obtenha uma c�pia deste software 
e dos arquivos de documenta��o associados (o "Software"), para negociar o Software 
sem restri��es, incluindo, sem limita��o, os direitos de uso, c�pia, modifica��o, fus�o,
publica��o, distribui��o, sublicenciamento e/ou venda de c�pias do Software, 
SEM RESTRI��ES OU LIMITA��ES. 

O SOFTWARE � FORNECIDO "TAL COMO EST�", SEM GARANTIA DE QUALQUER TIPO, EXPRESSA OU IMPL�CITA,
INCLUINDO MAS N�O SE LIMITANDO A GARANTIAS DE COMERCIALIZA��O, ADEQUA��O A UMA FINALIDADE
ESPEC�FICA E N�O INFRAC��O. EM NENHUM CASO OS AUTORES OU TITULARES DE DIREITOS AUTORAIS
SER�O RESPONS�VEIS POR QUALQUER REIVINDICA��O, DANOS OU OUTRA RESPONSABILIDADE, SEJA 
EM A��O DE CONTRATO OU QUALQUER OUTRA FORMA, PROVENIENTE, FORA OU RELACIONADO AO SOFTWARE. 

                    *** USE A VONTADE, POR SUA CONTA E RISCO ***

Permission is hereby granted, free of charge, to any person obtaining a copy of this software
and associated documentation files (the "Software"), to deal in the Software without 
restriction, including without limitation the rights to use, copy, modify, merge, publish, 
distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom 
the Software is furnished to do so, WITHOUT RESTRICTIONS OR LIMITATIONS. 

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT 
OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE. 

                    *** USE AS YOU WISH , AT YOUR OWN RISK ***

------------------------------------------------------------------------------------------- */




#include 'protheus.ch'
#include 'zlib.ch' 

/* ======================================================

				Factory de Defini��es 

	criado e armazenado como um objeto do ZENV()

====================================================== */

CLASS ZDEFFACTORY FROM LONGNAMECLASS

  DATA oLogger         // Objeto de log 
  DATA aObjects
  DATA aRPODefs
  DATA bDefFactory       // encapsulamento de cria��o de defini��es 

  METHOD NEW()
  METHOD GetaDefs()
  METHOD GetNewDef()
  METHOD Done()

ENDCLASS 


// ------------------------------------------------------
//

METHOD NEW(bDefBlock) CLASS ZDEFFACTORY

::oLogger := ZLOGGER():New("ZDEFFACTORY")
::oLogger:Write("NEW","Create Definition Factory")

// Popula array de strings com as classes compiladas no RPO 
// que herdam a classe ZTABLEDEF

::aRpoDefs := ChdClsArr("ZTABLEDEF")

// Array de controle de instancias 
::aObjects := {}

If bDefBlock != NIL
	::bDefFactory  := bDefBlock
Endif


Return self

// ------------------------------------------------------
// Retorna array com os nomes das classes 

METHOD GetaDefs() CLASS ZDEFFACTORY

::oLogger:Write("GETADEFS","Retrieve Definition Class List")

Return ::aRpoDefs


// ------------------------------------------------------
// Retorna um objeto com a instancia montada da classe

METHOD GetNewDef(cDefName,p1,p2,p3,p4,p5)  CLASS ZDEFFACTORY
Local oRet
Local bBlock
Local cBlock

::oLogger:Write("GetNewDef","Create Definition ["+cDefName+"]")

If ::bDefFactory != NIL

	// SE eu tenho um construtor alternativo chama ele 
	oRet := Eval(::bDefFactory,cDefName,p1,p2,p3,p4,p5)
	
Else

	// Monta codeblock para criar instancia dinamicamente 
	cBlock := "{|p1,p2,p3,p4,p5| "+cDefName+"():New(p1,p2,p3,p4,p5) }"
	bBlock := &(cBlock)
	oRet := Eval(bBlock,p1,p2,p3,p4,p5)

	// Limpa codeblock para quebrar referencias 
	bBlock := NIL

Endif

// Guarda a referencia deste objeto 
aadd(::aObjects,oRet)

Return oRet

// ------------------------------------------------------

METHOD Done() CLASS ZDEFFACTORY
Local nI, oObj
::oLogger:Write("Done")

For nI := 1 to len(::aObjects)
	oObj := ::aObjects[nI]
	If oObj != NIL 
		oObj:Done()
		 FreeObj(oObj)
	Endif
Next
aSize(::aObjects,0)

Return .T. 


// ===================================================================

User function clstst()
Local nI

// Retorna array de strings contendo o nome dos fontes que tem classe
// ax := GETCLSARRAY('*') 

// REtorna array de strings contendo as classes 
// compiladas no RPO  que herdam a classe ZTABLEDEF
// -- No caso, todos os componentes -- 
ay := ChdClsArr( "ZTABLEDEF" )

For nI := 1 to len(ay)
	conout(ay[nI])
Next

return

