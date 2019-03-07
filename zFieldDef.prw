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
   DATA lRequired                       // Campo de preenchimento Required�rio -- nao pode estar vazio 
   DATA lEnabled                       // Indica se o campo habilitado 
   DATA lVisible                       // Indica se o campo est� visivel 
   DATA lReadOnly                      // Indica se o campo somente pode ser lido -- mas nao editado 

   METHOD New()                        // Construtor 
   METHOD SetLabel()                   // Informa label e descri��o do campo 
   METHOD SetPicture()                 // Coloca m�scara no campo
   METHOD GetField()                   // Recupera o nome do campo 
   METHOD GetLabel()                   // Recupera o label informado 
   METHOD GetDescr()                   // Recupera a descri��o longa do campo 
   METHOD GetPicture()                 // Recupera m�scara no campo
   METHOD GetType()                    // Recupera o Tipo AdvPL do campo 
   METHOD GetSize()                    // Recupera o tamanho do campo 
   METHOD GetDec()                     // Recupera o numero de casas decimais do campo 
   METHOD DefaultValue()               // Recupera o valor do cammpo "Vazio" de acordo com o tipo 
   METHOD SetEnabled()                 // Seta se o campo est� habilitado 
   METHOD SetVisible()                 // Seta se o campo est� visivel 
   METHOD SetReadOnly()                // Seta se o campo � somente leitura ( nao editavel ) 
   METHOD SetRequired()                 // Seta se o campo � de preenchimento Required�rio 
   METHOD IsEnabled()                  // Consulta se o campo est� habilitado 
   METHOD IsVisible()                  // Consulta se o campo est� visivel 
   METHOD IsReadOnly()                 // Consulta se o campo somente pode ser lido ( n�o edit�vel ) 
   METHOD IsRequired()                 // Retorna se o campo � de preencimento Requiredorio 
   
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
// [c] Caractere com espacos em branco 
// [d] data vazia
// [n] zero
// [l] falso 
// [m] String vazia 

METHOD DefaultValue() CLASS ZFIELDDEF

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

METHOD IsEnabled() CLASS ZFIELDDEF
Return ::lEnabled


// ------------------------------------------------------

METHOD IsVisible()  CLASS ZFIELDDEF
Return ::lVisible


// ------------------------------------------------------

METHOD IsReadOnly() CLASS ZFIELDDEF
Return ::lReadOnly

