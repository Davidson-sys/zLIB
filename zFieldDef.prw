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
   DATA lObrigat                       // Campo ;e de preenchimento obrigat�rio 

   METHOD New()                        // Construtor 
   METHOD SetLabel()                   // Informa label e descri��o do campo 
   METHOD SetObrigat()                 // Seta se o campo � de preenchimento obrigat�rio 
   METHOD SetPicture()                 // Coloca m�scara no campo
   METHOD GetField()                   // Recupera o nome do campo 
   METHOD GetLabel()                   // Recupera o label informado 
   METHOD GetDescr()                   // Recupera a descri��o longa do campo 
   METHOD GetObrigat()                 // Retorna se o campo � de preencimento obrigatorio 
   METHOD GetPicture()                 // Recupera m�scara no campo
   METHOD GetType()                    // Recupera o Tipo AdvPL do campo 
   METHOD GetSize()                    // Recupera o tamanho do campo 
   METHOD GetDec()                     // Recupera o numero de casas decimais do campo 
   METHOD DefaultFalue()               // Recupera o valor do cammpo "Vazio" de acordo com o tipo 
   
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
::lObrigat   := .F. 
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

METHOD DefaultFalue() CLASS ZFIELDDEF

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

METHOD SetObrigat(lSet)  CLASS ZFIELDDEF
::lObrigat := lSet
Return

// ------------------------------------------------------
// Recupera o flag de obrigatorio 

METHOD GetObrigat()  CLASS ZFIELDDEF
Return ::lObrigat

