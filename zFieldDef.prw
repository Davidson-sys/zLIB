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



#include 'protheus.ch'
#include 'zlib.ch' 

/* ======================================================

Classe de abstra��o de defini��o extendida de campos  da Tabela 

Replica as informa��es da estrutura, mas armazena informa��es
adicionais para a montagem de qualquer interface. Label, Descri��o, 
Picture (mascara) de entrada de dados.

Por hora os eventos s�o colocados apenas na defini��o do arquivo 

====================================================== */

CLASS ZFIELDDEF FROM LONGNAMECLASS

   DATA cField                         // Nome do campo 
   DATA cType                          // Tipo AdvPL do campo 
   DATA nSize                          // Tamanho do campo 
   DATA nDec                           // Numero de decimais 
   DATA cLabel                         // Label ou descri��o curta do campo 
   DATA cDescr                         // Descri��o longa do campo 
   DATA cPicture                       // Mascara de dados do campo 
   DATA lRequired                      // Campo de preenchimento Required�rio -- nao pode estar vazio 
   DATA lEnabled                       // Indica se o campo habilitado 
   DATA lVisible                       // Indica se o campo est� visivel 
   DATA lReadOnly                      // Indica se o campo somente pode ser lido -- mas nao editado \
   DATA lVirtual                       // Indica se o campo � virtual 
   DATA nMultiLine                     // Numero de linhas default para edi��o de campo memo ( multiline ) 
   DATA cLookTab                       // Tabela da chave estrangeira do campo  
   DATA cLookKey                       // Campo Chave da Chave estrangeira
   DATA cLookFld                       // Campo ou expressao relacionada a tabela estrangeira 
   DATA xDefault

   METHOD New()                        // Construtor 
   METHOD SetLabel()                   // Informa label e descri��o do campo 

   METHOD SetLookUp()                  // Informa tabela , chave e campo a recuperar 
   METHOD GetLookTable()               // Tabela da chave estrangeira 
   METHOD GetLookKey()                 // Chave da Chave Estrangeira 
   METHOD GetLookField()               // Campo ou Expressao da Tabela Estrangeira 

   METHOD SetPicture()                 // Coloca m�scara no campo
   METHOD GetField()                   // Recupera o nome do campo 
   METHOD GetLabel()                   // Recupera o label informado 
   METHOD GetDescr()                   // Recupera a descri��o longa do campo 
   METHOD GetPicture()                 // Recupera m�scara no campo
   METHOD GetType()                    // Recupera o Tipo AdvPL do campo 
   METHOD GetSize()                    // Recupera o tamanho do campo 
   METHOD GetDec()                     // Recupera o numero de casas decimais do campo 
   METHOD DefaultValue()               // Recupera o valor do cammpo "Vazio" de acordo com o tipo 
   METHOD SetDefault()                 // Seta um valor default para o campo para todas as operacoes
   METHOD SetEnabled()                 // Seta se o campo est� habilitado 
   METHOD SetVisible()                 // Seta se o campo est� visivel 
   METHOD SetReadOnly()                // Seta se o campo � somente leitura ( nao editavel ) 
   METHOD SetVirtual()                 // Seta se o campo � virtual 
   METHOD SetRequired()                // Seta se o campo � de preenchimento Required�rio 
   METHOD IsEnabled()                  // Consulta se o campo est� habilitado 
   METHOD IsVisible()                  // Consulta se o campo est� visivel 
   METHOD IsReadOnly()                 // Consulta se o campo somente pode ser lido ( n�o edit�vel ) 
   METHOD IsRequired()                 // Retorna se o campo � de preencimento Requiredorio 
   METHOD IsVirtual()                  // Retorna se o campo � virtual 
   METHOD SetMultiLine()               // Seta numero de linhas para visualiza��o MultiLine( Campo MEMO ) 
   METHOD GetMultiLine()               // Recupera numero de linhas para visualiza��o MultiLine
   
ENDCLASS 


// ------------------------------------------------------
// Construtor 
// Recebe o nome do campo 

METHOD NEW(cFld,cType,nSize,nDec) CLASS ZFIELDDEF
::cField     := cFld
::cType      := cType
::nSize      := nSize
::nDec       := nDec
::cLabel     := ''
::cDescr     := ''
::cPicture   := ''
::lRequired   := .F. 
::lEnabled   := .T. 
::lVisible   := .T. 
::lReadOnly  := .F. 
::lVirtual   := .F. 
::nMultiLine := 8
::cLookTab := ""
::cLookKey := ""
::cLookFld := ""

Return self


// ------------------------------------------------------

METHOD SetLabel(cLabel,cDescr) CLASS ZFIELDDEF
::cLabel := cLabel
::cDescr := cDescr
Return

// ------------------------------------------------------
// Seta uma m�scara de entrada para o campo 

METHOD SetPicture(cPict) CLASS ZFIELDDEF
::cPicture := cPict
Return

// ------------------------------------------------------
// Seta Tabela e campo da chave estrangeira 
// O campo normalmente � um UNIQUE INDEX 

METHOD SetLookUp(cFTable,cFKey,cFField) CLASS ZFIELDDEF  
::cLookTab := cFTable
::cLookKey := cFKey
::cLookFld := cFField
Return

// ------------------------------------------------------
// Recupera tabela da chave estrangeira 

METHOD GetLookTable() CLASS ZFIELDDEF  
Return ::cLookTab

// ------------------------------------------------------
// Recupera campo da chave estrangeira 

METHOD GetLookKey() CLASS ZFIELDDEF  
Return ::cLookKey

// ------------------------------------------------------
// Informacao a ser mostrada do relacionamento 

METHOD GetLookField() CLASS ZFIELDDEF  
Return ::cLookFld

// ------------------------------------------------------
// Recupera o nome do campo 

METHOD GetField() CLASS ZFIELDDEF  
Return ::cField

// ------------------------------------------------------
// Recupera o laber ou descri��o curta do campo 

METHOD GetLabel() CLASS ZFIELDDEF  
Return ::cLabel

// ------------------------------------------------------
// Recupera a descri��o longa do campo 

METHOD GetDescr() CLASS ZFIELDDEF
Return ::cDescr

// ------------------------------------------------------
// Recupera a mascara de entrada de dados do campo 

METHOD GetPicture(cPict) CLASS ZFIELDDEF
Return ::cPicture

// ------------------------------------------------------
// Recupera o tipo do campo em AdvPL 

METHOD GetType() CLASS ZFIELDDEF
Return ::cType 

// ------------------------------------------------------
// Recupera o tamanho do campo em AdvPL 

METHOD GetSize() CLASS ZFIELDDEF
Return ::nSize

// ------------------------------------------------------
// Recupera o numero de decimais para campo numerico 

METHOD GetDec() CLASS ZFIELDDEF
Return ::nDec

// ------------------------------------------------------
// Recupera o valor default do campo vazio
// Caso tenha sido setado um valor default para o campo, este
// tem precedencia sobre o valor vazio 
// [c] Caractere com espacos em branco 
// [d] data vazia
// [n] zero
// [l] falso 
// [m] String vazia 

METHOD DefaultValue() CLASS ZFIELDDEF

If ::xDefault != NIL
	Return ::xDefault
Endif

If ::cType  = 'C'
	Return Space(::nSize)
ElseIF ::cType  = 'N'
	Return 0
ElseIF ::cType  = 'D'
	Return CTOD("")
ElseIF ::cType  = 'L'
	Return .T. 
ElseIF ::cType  = 'M'
	Return ""
Endif

Return NIL 


// ------------------------------------------------------
// Permite setar um valor default para o campo 

METHOD SetDefault(xValue) CLASS ZFIELDDEF
::xDefault := xValue
Return


// ------------------------------------------------------
// Seta se o campo � de preenchimento obrigatorio 
// ( nao pode ser vazio ) 

METHOD SetRequired(lSet)  CLASS ZFIELDDEF
::lRequired := lSet
Return

// ------------------------------------------------------
// Recupera o flag de Obrigatorio

METHOD IsRequired() CLASS ZFIELDDEF
Return ::lRequired


// ------------------------------------------------------

METHOD SetEnabled(lSet) CLASS ZFIELDDEF
::lEnabled   := lSet
Return


// ------------------------------------------------------

METHOD SetVisible(lSet) CLASS ZFIELDDEF
::lVisible   := lSet
Return

// ------------------------------------------------------

METHOD SetReadOnly(lSet) CLASS ZFIELDDEF
::lReadOnly   := lSet
Return

// ------------------------------------------------------

METHOD SetVirtual(lSet) CLASS ZFIELDDEF
::lVirtual   := lSet
Return


// ------------------------------------------------------

METHOD IsEnabled() CLASS ZFIELDDEF
Return ::lEnabled


// ------------------------------------------------------

METHOD IsVisible()  CLASS ZFIELDDEF
Return ::lVisible


// ------------------------------------------------------

METHOD IsReadOnly() CLASS ZFIELDDEF
Return ::lReadOnly

// ------------------------------------------------------

METHOD IsVirtual() CLASS ZFIELDDEF
Return ::lVirtual

// ------------------------------------------------------

METHOD SetMultiLine(nRows) CLASS ZFIELDDEF
::nMultiLine := nRows
Return

// ------------------------------------------------------

METHOD GetMultiLine() CLASS ZFIELDDEF
Return ::nMultiLine


