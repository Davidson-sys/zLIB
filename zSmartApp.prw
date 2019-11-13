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

====================================================== */

CLASS ZSMARTAPP FROM LONGNAMECLASS

   DATA oEnv
   DATA cAppTitle
   DATA oMainWnd
   DATA oMainMenuBar
   DATA aMenus
   
   DATA bDefFactory                 // Factory de defini��es diferenciado

   METHOD New() 					// Construtor 
   METHOD SetTitle(cTitle)          // Define o titulo da aplica��o
   METHOD fromJSON()                // Cria a aplica��o baseado em um arquivo JSON
   METHOD SetDefFactory()           // Seta factory de definicoes diferenciado
   METHOD SetZLIBEnv()              // Seta o ambiente 
   METHOD SetMenu()                 // Configura a MenuBar da aplica��o 
   METHOD Call()                    // Encapsula a execu��o de uma fun��o
   METHOD CallZApp()                // Chama um modelo de aplica��o ZAPP 
   METHOD CallZautoApp()            // Modelo de chamada automatizado ZAUTOAPP
   METHOD Run()						// Roda a Aplica��o 
   METHOD Close()                   // Fechamento da aplica��o 
   METHOD Done()                    // Finaliza os objetos 
  
ENDCLASS


// ------------------------------------------------------
// Construtor

METHOD NEW() CLASS ZSMARTAPP
Return self

// ------------------------------------------------------
// Seta o T�tulo da aplica��o
METHOD SetTitle(cTitle) CLASS ZSMARTAPP
::cAppTitle := cTitle
Return

// ------------------------------------------------------
// Seta o ambiente 

METHOD SetZLIBEnv(oEnv) CLASS ZSMARTAPP
::oEnv := oEnv
Return

// ------------------------------------------------------
// Permite trocar / encapsular o factory de definicoes

METHOD SetDefFactory(bDefBlock)  CLASS ZSMARTAPP
::bDefFactory := bDefBlock
Return

// ------------------------------------------------------
// Cria a aplica��o baseado em um arquivo JSON

METHOD fromJSON(cJsonFile) CLASS ZSMARTAPP           
Local aMenus := {}
Local aProgs := {}
Local aAjuda := {}
Local oJSon
Local cJsonStr
Local aJsonMenu 
Local nJ

// L� a defini��o da aplica��o 
cJsonStr := memoread(cJsonFile)

// Cria o objeto JSON baseado na defini��o 
oJson 		:= JsonObject():New()
oJson:fromJson(cJsonStr)

// Recupera o t�tulo da aplica��o 
::cAppTitle := oJson:GetJsonText("DisplayName")

// Recupera o menu de Programas
aJsonMenu := oJson:GetJsonObject("Menu")

IF valtype(aJsonMenu) <> 'A'
	UserException("Menu not found or invalid on JSON App Definition")
Endif

For nJ := 1 to len(aJsonMenu)
	oMenuOpt   := aJsonMenu[nJ]
	cMenuLabel := oMenuOpt:GetJSonText('name')
	cMenuType  := oMenuOpt:GetJSonText('type')
	
	IF cMenuType == 'ZAUTOAPP'
		cDefName := oMenuOpt:GetJSonText('definition')
		aadd(aProgs,{cMenuLabel    , &("{ || self:CallZAutoApp('"+cDefName+"') }") } )
	Else
		conout("Unsupported Menu ["+cMenuLabel+"] Type ["+cMenuType+"]")
	Endif

Next

// Joga jora o objeto 
freeObj(oJson)

// complementa menu de programas
aadd(aProgs,{"-" , NIL } )
aadd(aProgs,{"Sai&r"     ,{ || self:Close() }} )
aadd(aMenus , {"&Programas" , aProgs } )

// Acrescenta o menu de Ajuda -> Sobre 
aadd(aAjuda,{"&Sobre"   ,{ || MsgInfo("<html><b>"+::cAppTitle+"</b><br>Aplicativo em Desenvolvimento","*** ZLIB ***") }} )
aadd(aMenus , {"&Ajuda" , aAjuda } )

// Define o menu da aplica��o 
::SetMenu(aMenus)

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
// Chama um modelo de aplica��o ZAUTOAPP 
// Aplica��o automatica criada sobe a defini��o 
// A AutoApp permite a troca do factory de definicoes

METHOD CallZAutoApp(cDefName)  CLASS ZSMARTAPP
Local aCoords 
Local oApp := ZAUTOAPP():New()

// Pega as coordenadas da janela principal para rodar a aplica��o em cima
aCoords := { ::oMainWnd:nTop+40,::oMainWnd:nLeft+10,::oMainWnd:nBottom-40,::oMainWnd:nRight-20 }

IF ::bDefFactory != NIL 
	// Seta um encapsulamento para o factory de definicoes
	oApp:SetDefFactory(::bDefFactory)
Endif

// Roda o MVC baseado na definicao informada
oApp:RunMVC(cDefName,aCoords)

// Libera o objeto 
FreeObj(oApp)

Return

// ------------------------------------------------------
// Encapsula o fechamento da aplica��o 

METHOD Close()  CLASS ZSMARTAPP
::oMainWnd:End()
Return


// ------------------------------------------------------

METHOD Done() CLASS ZSMARTAPP
Return

