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

                    ***USE AS YOU WISH , AT YOUR OWN RISK ***

------------------------------------------------------------------------------------------- */



#include  'protheus.ch'
#include  'zLib.ch'

/* ============================================================================

CLASSE         ZSTREAM
Autor          J�lio Wittwer
Data           01/2019
Descri��o      O Objeto Stream permite gravar sequencias de dados e de objetos 
               em uma string bin�ria, que pode ser armazenada e carregada 

============================================================================ */

CLASS ZSTREAM FROM LONGNAMECLASS

   DATA aStream          // Array com os elementos do Stream
   DATA nPos             // Elemento atual do Stream 
   DATA nSize            // Tamanho atual do Stream ( elementos ) 
   
   METHOD NEW()          // Concstrutor 
   METHOD LOADSTR()      // Carrega um stream da binary String gerada pelo ::SaveStr()
   METHOD SAVESTR()      // Salva o Stream em uma Binary String 
   METHOD CLEAR()        // Limpa o Stream 
   METHOD READ()         // L� a informa��o da posi��o atual do Stream e posiciona na pr�xima
   METHOD WRITE()        // Acrescenta uma vari�vel no Stream
   METHOD EOF()          // Verifica se o stream est� no final 

ENDCLASS

// ----------------------------------------
// Construtor, apenas inicializa varia�veis 
METHOD NEW() CLASS ZSTREAM 
::aStream := {}
::nPos := 1
::nSize := 0 
Return SELF

// ----------------------------------------
// Recebe cBuffer com o Binary Stream gerado pelo Save()
// L� o Buffer e popula o Stream.
// Se o tream � valido -- foi gerado pela SaveStr, carrega 
METHOD LOADSTR(cBuffer) CLASS ZSTREAM 
If left(cBuffer,11) == "#_ZSTREAM_#"
	cBuffer := Substr(cBuffer,12)
	BinStr2Var( cBuffer, ::aStream ) 
	::nPos := 1
	::nSize := len(::aStream)
	Return .T. 
Endif
Return .F. 

// ----------------------------------------
// Recebe cBuffer por referencia 
// Salva o stream nele como Binary String
// Coloca um prefixo na BinaryString gerada
METHOD SAVESTR(cBuffer) CLASS ZSTREAM 
Var2BinStr( ::aStream , cBuffer )
cBuffer := Stuff(cBuffer , 1 , 0 , "#_ZSTREAM_#")
Return .T. 

// ----------------------------------------
// Limpa e reinicializa o Stream 

METHOD CLEAR() CLASS ZSTREAM 
::aStream := {}
::nPos := 1
::nSize := 0
Return

// ----------------------------------------
// Leitura por refer�ncia do stream , na ordem de grava��o 

METHOD READ(xValue) CLASS ZSTREAM 

// Recupero o elemento atual 
BinStr2Var( ::aStream[nPos][2] , xValue  )

// Posiciona na pr�xima posi��o para leitura 
::nPos++

Return 

// ----------------------------------------
// Escreve um valor no Stream. 
// Pode at� ser um objeto 

METHOD WRITE(xValue) CLASS ZSTREAM 
Local cBuffer := ''
Local cType := Valtype(xValue)
If cType $ 'CNDLMAU'
	// Acrescenta o valor no Array para Stream 
	// Coloca o tipo junto 
	Var2BinStr(xValue,cBuffer)
	aadd(::aStream,{cType,cBuffer})
	::nSize := len(::aStream)
	::nPos := ::nSize + 1 
	cBuffer := ''
Else
	UserException("ZSTREAM:Write() -- Unsupported Type "+cType)
Endif
Return 

// ----------------------------------------
// Verifica se o stream acabou ou est� no final 

METHOD EOF() CLASS ZSTREAM 
Return ::nPos > ::nSize



