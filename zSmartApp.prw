#include 'protheus.ch'
#include 'zlib.ch' 

/* ======================================================

====================================================== */

CLASS ZSMARTAPP FROM LONGNAMECLASS

   DATA oEnv
   DATA cAppTitle
   DATA oMainWnd
   DATA oMainMenuBar
   DATA aMenus

   METHOD New() 					// Construtor 
   METHOD SetZLIBEnv()              // Seta o ambiente 
   METHOD SetMenu()                 // Configura a MenuBar da aplica��o 
   METHOD Call()                    // Encapsula a execu��o de uma fun��o
   METHOD CallZApp()                // Chama um modelo de aplica��o ZAPP 
   METHOD Run()						// Roda a Aplica��o 
   METHOD Close()                   // Fechamento da aplica��o 
   METHOD Done()                    // Finaliza os objetos 
  
ENDCLASS


// ------------------------------------------------------
// Construtor

METHOD NEW(cTitle) CLASS ZSMARTAPP
::cAppTitle := cTitle
Return self

// ------------------------------------------------------
// Seta o ambiente 

METHOD SetZLIBEnv(oEnv) CLASS ZSMARTAPP
::oEnv := oEnv
Return

// ------------------------------------------------------

METHOD SetMenu(aMenus) CLASS ZSMARTAPP
::aMenus := aMenus
Return

// ------------------------------------------------------
// Executor

METHOD RUN() CLASS ZSMARTAPP
Local oFont
Local nI , nJ
Local oThisMenu  
Local cCaption
Local oThisItem 
Local oMainPanel

// Usa uma fonte Fixed Size
oFont := TFont():New('Courier new',,-14,.T.)
oFont:Bold := .T. 

// Seta que a partir daqui esta � a fonte default
SetDefFont(oFont)

// Cria a janela principal da aplica��o
DEFINE WINDOW ::oMainWnd FROM 0,0 TO 800,600  PIXEL TITLE ::cAPPTitle COLOR CLR_WHITE,CLR_BLACK

// Painel Central da aplica��o 
// Fundo da Main Window 
@ 00,00 MSPANEL oMainPanel OF ::oMainWnd COLOR CLR_WHITE,CLR_RED  SIZE 1,1 RAISED
oMainPanel:Align:= CONTROL_ALIGN_ALLCLIENT

// Cria a barra de menu superior dentro do painel 
::oMainMenuBar := tMenuBar():New(oMainPanel)

// Popula os menus da aplica��o 
For nI := 1 to len(::aMenus)

	// Cria um Menu 
	oThisMenu := TMenu():New(0,0,0,0,.T., NIL ,::oMainWnd)

	// Acrescenta as op��es no Menu 
	For nJ := 1 to len(::aMenus[nI][2])

		cCaption := ::aMenus[nI][2][nJ][1]
		If 	cCaption == '-'
			oThisItem := TMenuItem():New(::oMainWnd,cCaption	, NIL , NIL , .F. , NIL ,,,,,,,,,.T.)
			oThisMenu:Add( oThisItem )
		Else
			oThisItem := TMenuItem():New(::oMainWnd,cCaption	, NIL , NIL , .T. , ::aMenus[nI][2][nJ][2],,,,,,,,,.T.)
			oThisMenu:Add( oThisItem )
		Endif
	Next	

	// Acrescenta o Menu na Barra de Menus 
	::oMainMenuBar:AddItem( ::aMenus[nI][1],oThisMenu ,.T.)
	
Next

::oMainWnd:LESCCLOSE := .T.

ACTIVATE WINDOW ::oMainWnd  ; // MAXIMIZED ;
	VALID ( MsgYesNo("Deseja encerrar o aplicativo ?") )

Return


// ------------------------------------------------------
// Encapsula a execu��o de uma fun��o

METHOD Call(cFnCall)  CLASS ZSMARTAPP
&cFnCall.()
Return

// ------------------------------------------------------
// Chama um modelo de aplica��o ZAPP 

METHOD CallZApp(cFnCall)  CLASS ZSMARTAPP
Local aCoords 

aCoords := { ::oMainWnd:nTop+40,::oMainWnd:nLeft+10,::oMainWnd:nBottom-40,::oMainWnd:nRight-20 }
&cFnCall.(aCoords,,)

Return

// ------------------------------------------------------
// Encapsula o fechamento da aplica��o 

METHOD Close()  CLASS ZSMARTAPP
::oMainWnd:End()
Return


// ------------------------------------------------------

METHOD Done() CLASS ZSMARTAPP
Return

