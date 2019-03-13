#include 'protheus.ch'
#include 'zlib.ch' 

#define CALCSIZEGET( X )  (( X * 4 ) + 8)      

#define VIDEO_RES_WIDTH    1024
#define VIDEO_RES_HEIGHT    768

#define VIEW_FR_COLOR      CLR_WHITE
#define VIEW_BG_COLOR      CLR_BLACK
#define VIEW_LOOKUP_COLOR  CLR_YELLOW

#define VIEW_GETFR_COLOR      CLR_WHITE
#define VIEW_GETBG_COLOR      CLR_BLUE

#define VIEW_BTNFR_COLOR      CLR_BLACK
#define VIEW_BTNBG_COLOR      CLR_WHITE

// Evento disparado na atualiza��o de campos 
#define VIEW_ONDISPLAY    1

// Interface sem botoes de navegacao por hora 
// Parece nao fazer muito sentido, a nao ser em um browser ou lista
// #define HAS_NAVBUTTONS 

/* ======================================================

Classe de View Modelo -- Interface Smartclient

View Layer:

This is a presentation layer.
It consists of HTML, JSP, etc. into it.
It normally presents the UI of the application.
It is used to display the data which is fetched from the controller which in turn fetching data from model layer classes.
This view layer shows the data on UI of the application.

====================================================== */

CLASS ZMVCVIEW FROM LONGNAMECLASS

	DATA oControl        // Objeto de controle dos dados 
	DATA cTitle          // Titulo da Janela de Interface
	DATA aGets           // Array com objetos da interface e definicao 
	DATA oDlg            // Janela de di�logo 
    
#ifdef HAS_NAVBUTTONS
	DATA aBtnNav         // Botoes de Navega��o 
#endif

	DATA aBtnAct         // Bot�es de a��o padr�o ( incluir, sair, etc ) 
	DATA aActions        // Acoes adicionais do componente
    DATA aViewEvents     // Eventos internos da View 
	DATA cRunning        // A��o em execu��o 
	DATA oBtnOk          // Bot�o de conforma��o de a��o 
	DATA oBtnCanc        // Bot�o de cancelamento de a��o 
	DATA cError          // Ultimo erro da interface
	DATA oLogger         // Objeto de log 
	DATA nRecno          // Registro atual em foco 
	DATA aOldRecord      // Registro com valores de campos no inicio de uma opera��o 

    METHOD NEW()         // Construtor
    METHOD SetControl()  // Abarra objeto de controle de dados
	METHOD RUN()         // Inicia a interface
	METHOD RUNINTF()     // Monta componentes de tela
	METHOD DONE()        // Encerra a interface

    METHOD UpdRelField()  // Roda atualiza��o de campo relacionado -- LookUp 
    METHOD RunViewEvent() // Roda eventos internos da View 

    METHOD SEARCH()      // Pesquisa de registros
	METHOD INSERT()      // Inser��o de novo registro
	METHOD UPDATE()      // Altera��o de registro existente
	METHOD DELETE()      // Exclus�o de registro j� existente
	                    
#ifdef HAS_NAVBUTTONS
    METHOD GOFIRST()
    METHOD GONEXT()
    METHOD GOPREV() 
    METHOD GOLAST() 
#endif

	METHOD CONFIRM()     // Confirma opera��o em execu��o
	METHOD CANCEL()      // Cancela opera��o em execu��o
	
	METHOD GETERRORSTR() // Recupera ultima ocorencoa de erro 
	METHOD SETERROR()    // Seta uma ocorrencia de error 
	METHOD ClearError()  // Limpa ocorrencia de erro 
	
	METHOD RunAction()

ENDCLASS


// ----------------------------------------------------------
// Construtor

METHOD NEW(cTitle) CLASS ZMVCVIEW
::cTitle  := cTitle
::cError  := ''
::aGets   := {}
::aOldRecord := {}

#ifdef HAS_NAVBUTTONS
::aBtnNav := {}
#endif

::aViewEvents := {}
::aActions := {}
::cRunning := ''
::nRecno  := 0

::oLogger := ZLOGGER():New("ZMVCVIEW")
::oLogger:Write("NEW","Interface ["+cTitle+"]")

Return self

// ----------------------------------------------------------
// Recebe o objeto de controle  

METHOD SetControl(oObj)  CLASS ZMVCVIEW
::oLogger:Write("SetControl","Set Control ["+GetClassName(oObj)+"]")
::oControl := oObj
Return

// ----------------------------------------------------------
// Monta e executa a interface (view)

METHOD RUN() CLASS ZMVCVIEW
Local oFont
Local oDlg

::oLogger:Write("Run","Begin Interface")
::ClearError()

// Antes de rodar verifica se o objeto de controle foi setado
If ::oControl = NIL
	::SetError("ZMVCVIEW:RUN() -- CONTROL OBJECT NOT SET")
	Return .F.
Endif

// Usa uma fonte Fixed Size
oFont := TFont():New('Courier new',,-14,.T.)
oFont:Bold := .T. 

// Cria a janela principal como uma DIALOG
DEFINE DIALOG oDlg TITLE (::cTitle) ;
	FROM 0,0 TO VIDEO_RES_HEIGHT,VIDEO_RES_WIDTH ;
	FONT oFont ;
	COLOR VIEW_FR_COLOR,VIEW_BG_COLOR PIXEL

// Guarda o di�logo na classe da View
::oDlg := oDlg

// Interface montada na inicializa��o da janela
oDlg:bInit := {|| self:RUNINTF(oDlg) }

ACTIVATE DIALOG oDlg CENTER ;
	VALID ( MsgYesNo("Deseja fechar e sair da aplica��o ?") )

::oLogger:Write("Run","End Interface")

Return .T.

// ----------------------------------------------------------
// A execu��o da interface monta a tela
// Baseado na defini��o dos campos

METHOD RUNINTF(oDlg)  CLASS ZMVCVIEW
Local oPanelMenu
Local oPanelBase
Local oPanelCrud
Local nI, nFldCount
Local oFldDef
Local nRow , cPicture , nScrSize , nGetSize
Local _Dummy_
Local oNewSay , oNewGet
Local nActRow
Local oBtnAct, cPrompt
Local cFTable, cFKey, cFName , bAction
Local oFontSay

oFontSay := TFont():New('Courier new',,-14,.T.)
oFontSay:Bold := .T. 


#ifdef HAS_NAVBUTTONS
Local oPanelNav
Local oBtnFirst, oBtnPrev, oBtnNext, oBtnLast
#endif

::oLogger:Write("RunIntf")

// Monta o menu de op��es
@ 0,0 MSPANEL oPanelMenu OF oDlg SIZE 70,600 COLOR VIEW_FR_COLOR,VIEW_BG_COLOR
oPanelMenu:ALIGN := CONTROL_ALIGN_LEFT

#ifdef HAS_NAVBUTTONS

	// Painel com as op��es de navega��o
	@ 0,0 MSPANEL oPanelNav OF oDlg SIZE 70,600 COLOR VIEW_FR_COLOR,VIEW_BG_COLOR
	oPanelNav:ALIGN := CONTROL_ALIGN_RIGHT

#endif

// Pergunta ao controller as a��es do componente
::aActions := ::oControl:GetActions()

// Ajusta as a��es reservadas
For nI := 1 to len(::aActions)

	cAction := ::aActions[nI][1]
	
	If cAction == 'SEARCH'
		::aActions[nI][3] := {|| self:Search() }
	ElseIf cAction == 'INSERT'
		::aActions[nI][3] := {|| self:Insert() }
	ElseIf cAction == 'UPDATE'
		::aActions[nI][3] := {|| self:Update() }
	ElseIf cAction == 'DELETE'
		::aActions[nI][3] := {|| self:Delete() }
	Endif
	
Next

// Acrescenta a a��o de sa�da 
AADD(::aActions , { "EXIT" , "Sair" , NIL } ) 

// Cria os bot�es de a��o na interface
nActRow := 05

For nI := 1 to len(::aActions)

    cAction := ::aActions[nI][1]
    cPrompt := ::aActions[nI][2]

	@ nActRow,05  BUTTON oBtnAct PROMPT cPrompt  ;
	SIZE 60,15 OF oPanelMenu PIXEL
	
	oBtnAct:BACTION := &("{|| self:RunAction('"+cAction+"') }")
	oBtnAct:SetColor(VIEW_BTNFR_COLOR,VIEW_BTNBG_COLOR)
	

	oBtnAct := NIL 
	nActRow += 15 
	
Next


// Monta os botoes de navega��o

#ifdef HAS_NAVBUTTONS

	@ 05,05  BUTTON oBtnFirst PROMPT "Primeiro" SIZE 60,15 ;
		ACTION ( self:GOFIRST() ) OF oPanelNav PIXEL
	oBtnFirst:SetColor(VIEW_BTNFR_COLOR,VIEW_BTNBG_COLOR)

	@ 020,05  BUTTON oBtnPrev PROMPT "Anterior" SIZE 60,15 ;
		ACTION ( self:GOPREV() ) OF oPanelNav PIXEL
	oBtnPrev:SetColor(VIEW_BTNFR_COLOR,VIEW_BTNBG_COLOR)

	@ 35,05  BUTTON oBtnNext PROMPT "Pr�ximo" SIZE 60,15 ;
		ACTION ( self:GONEXT() ) OF oPanelNav PIXEL
	oBtnNext:SetColor(VIEW_BTNFR_COLOR,VIEW_BTNBG_COLOR)

	@ 50,05  BUTTON oBtnLast PROMPT "�ltimo" SIZE 60,15 ;
		ACTION ( self:GOLAST() ) OF oPanelNav PIXEL
	oBtnLast:SetColor(VIEW_BTNFR_COLOR,VIEW_BTNBG_COLOR)

	// Guarda botoes de navega��o
	aadd(::aBtnNav,oBtnFirst)
	aadd(::aBtnNav,oBtnPrev)
	aadd(::aBtnNav,oBtnNext)
	aadd(::aBtnNav,oBtnLast)
#endif

// Monta a tela do CRUD com os campos da tabela

@ 0,0 SCROLLBOX oPanelBase SIZE 100,100 OF oDlg VERTICAL     
oPanelBase:ALIGN := CONTROL_ALIGN_ALLCLIENT  

@ 0,0 MSPANEL oPanelCrud OF oPanelBase SIZE 1,1 COLOR VIEW_FR_COLOR,VIEW_BG_COLOR
oPanelCrud:ALIGN := CONTROL_ALIGN_ALLCLIENT  

// Pega o array a definicao dos campos a partir da definicao do componente
aFieldsDef := ::oControl:GetObjectDef():GetFields()

// Monta os arrays de objetos e variaveis de interface
nFldCount := len( aFieldsDef )

// Inicializa os Gets e suas Variaveis
::aGets := Array( nFldCount )

// Limpa registro anterior
::aOldRecord := {}

// Come�a na linha 5, um campo por linha
nRow := 5

For nI := 1 to nFldCount
	
	// Pega o objeto da definicao deste campo
	oFldDef := aFieldsDef[nI]
	
	IF oFldDef:IsVisible()

		// Monta o label deste campo -- incialmente em branco 
		@   nRow+3,05 SAY oNewSay PROMPT " " RIGHT SIZE 60,12 FONT oFontSay ; 
		   COLOR VIEW_FR_COLOR,VIEW_BG_COLOR OF oPanelCrud PIXEL
		oNewSay:SetText( oFldDef:GetLabel() )
		oNewSay := NIL 

    Endif
	
    // Calcula o tamanho do campo baseado na picture 
	cPicture := oFldDef:GetPicture()
	nScrSize := oFldDef:GetSize()
	If oFldDef:GetType() == 'D'
		// Campo data com mais 2 caraceres 
		nScrSize += 2	
	Endif
	If left(cPicture,3) == '@R '
		nGetSize := CALCSIZEGET( MAX( nScrSize, len(cPicture)-3 ) ) 
	Else
		nGetSize := CALCSIZEGET( nScrSize ) 
	Endif	
	
	// Monta o GET para este campo , inicialmente com uma variavel "dummy"
	@   nRow,70 GET oNewGet VAR _Dummy_ PICTURE (cPicture)   ;
		COLOR VIEW_GETFR_COLOR,VIEW_GETBG_COLOR SIZE nGetSize ,12 OF oPanelCrud PIXEL

	// Guarda o objeto GET montado no array aGets
	// [1] Nome do campo
	// [2] Objeto tGet de interface
	// [3] Objeto da definicao do campo
	// [4] Valor do campo no GET 
	// [5] Objeto TSAY para informa��o relacionada
	// --- Inicializado com o valor default
	
	::aGets[nI] := { oFldDef:GetField() , oNewGet , oFldDef , oFldDef:DefaultValue() , NIL  }
	
	// Troco a variavel do GET
	// Monta codeblock para usar a quarta coluna 
	// do proprio array de Gets como vari�vel de conte�do do GET 
	
	cBLock := "{ |x| IIF( PCOUNT() > 0 , self:aGets["+cValToChar(nI)+"][4] := x , self:aGets["+cValToChar(nI)+"][4] ) }"
	oNewGet:bSetGet := &(cBLock)

	// Nenhum GET tem botao auxiliar 
	// Nesta tela, nem calend�rio, nem calculadora 
    oNewGet:LHASBUTTON := .F. 
    oNewGet:LNOBUTTON  := .T. 
    oNewGet:LCALENDARIO := .F. 
	
    // Verifica se este GET est� vis�vel 
	oNewGet:LVISIBLE := oFldDef:IsVisible()
	
	If !empty(oFldDef:GetLookTable())

		// Campo relacionado a conteudo de tabela estrangeira 
		// Monta um tSAY para mostrar o conte�do relacionado
		// e guarda no 5o elemento do ::aGets
		
		@   nRow+3,75 + nGetSize SAY oNewSay PROMPT " " SIZE 100,12 FONT oFontSay ;
		   COLOR VIEW_LOOKUP_COLOR,VIEW_BG_COLOR OF oPanelCrud PIXEL
		oNewSay:SetText(" ")
		::aGets[nI][5] := oNewSay
		oNewSay := NIL 

		// A view precisa gerar um evento interno para atualizar o 
		// conteudo deste campo na tela, inclusive quando necessario 
		// acionar o modelo para isso 
        cFTable := oFldDef:GetLookTable()
        cFKey   := oFldDef:GetLookKey()
        cFName  := oFldDef:GetLookField() 

        bAction := &("{|o| o:UpdRelField(.F.,'"+cFTable+"','"+cFKey+"','"+cFName+"',"+cValtoChar(nI)+") }")

		// Acrescenta o evento interno da View
		aadd( ::aViewEvents , { VIEW_ONDISPLAY , bAction  } ) 

		// Tambem dispara a atualiza��o de campo na valida��o do proprio campo 
		oNewGet:BVALID := &("{|| self:UpdRelField(.T.,'"+cFTable+"','"+cFKey+"','"+cFName+"',"+cValtoChar(nI)+") }")

	Endif

	// O Get nasce desabilitado
	oNewGet:SetEnable(.F.)  

	// Cada novo campo pula 15 PIXELS 
	// ( caso o campo esteja visivel ) 
	IF oFldDef:IsVisible()
		nRow += 15
	Endif
	
Next

// Pula mais uma linha
nRow += 15

@ nRow,60  BUTTON ::oBtnOk PROMPT "Confirmar" SIZE 60,15 ;
	ACTION ( self:CONFIRM() ) OF oPanelCrud PIXEL
::oBtnOk:SetColor(VIEW_BTNFR_COLOR,VIEW_BTNBG_COLOR)

@ nRow,180  BUTTON ::oBtnCanc PROMPT "Cancelar" SIZE 60,15 CANCEL ;
	ACTION ( self:CANCEL() ) OF oPanelCrud PIXEL
::oBtnCanc:SetColor(VIEW_BTNFR_COLOR,VIEW_BTNBG_COLOR)

// Seta a altura interna do painel do CRUD 
// Movendo o painel para novas coordenadas, calculando 
// a altura interna baseado na ultima linha da tela

oPanelCrud:Move(0,0,oPanelCrud:nWidth,(nRow+20)*2,,.T.)

// Esconde os bot�es de confirmar e cancelar
::oBtnOk:Hide()
::oBtnCanc:Hide()

#ifdef HAS_NAVBUTTONS
	// Esconde os botoes de navega��o
	aEval (::aBtnNav , {|x| x:Hide() } )
#endif

Return

// ----------------------------------------------------------
// Metodo de finalizacao da interface
// Por hora nao precisa fazer nada, os objetos utilizados
// devem ser destruidos pelo componente que criou

METHOD DONE() CLASS ZMVCVIEW

::oLogger:Write("Done")

::aGets      := {}
::aOldRecord := {}
#ifdef HAS_NAVBUTTONS
::aBtnNav    := {}
#endif
::aBtnAct    := {}

Return


// ----------------------------------------------------------
// Metodo de inser��o
// Inicia interface com registro em branco para inser��o
// O registro � inicializado com os valores default

METHOD INSERT() CLASS ZMVCVIEW
Local nFldCount
Local nI , oFldDef, oGet
Local aRecord := {}
Local nPos

::oLogger:Write("Insert","Create New Record")

// A inser��o via interface deve partir de um registro inicializado
// com os valores default, atraves do controlador

If !::oControl:NewRecord(aRecord)
	MsgStop("N�o � poss�vel iniciar uma inser��o neste momento","oControl:NewRecord()")
	Return 
Endif

// Registro anterior com valores default
::aOldRecord := aClone(aRecord)

// Alimenta interface com os valoes iniciais dos campos
// Inicializa os campos com os valores default

nFldCount := len( ::aGets )

For nI := 1 to nFldCount
	
	// Pega o nome do campo, o objeto do GET e a definicao do campo 
	cFldName := ::aGets[nI][1]
	oGet     := ::aGets[nI][2]
	oFldDef  := ::aGets[nI][3]
	
	// Busca o conteudo do registro 
	// Caso nao seja encontrado usa o valor default
	nPos := ascan( aRecord , {|x| x[1] == cFldName })

	If nPos > 0 
		// Atualiza gets com valor inicial do campo
		::aGets[nI][4] := aRecord[nPos][2]
	Else
		// Inicializa com valor default 
		::aGets[nI][4] := oFldDef:DefaultValue()
	Endif

	// Define campos ativos baseados na definicao
	oGet:SetEnable( oFldDef:IsEnabled() )

	// Define se o campo � somente leitura ou nao 
	oGet:LREADONLY := oFldDef:IsReadOnly()       
	
	// SE tem um label relacionado, limpa
	If ::aGets[nI][5] != NIL 
		::aGets[nI][5]:SetText(" ")
	Endif

Next

#ifdef HAS_NAVBUTTONS
	// Esconde os bot�es de navega��o
	aEval (::aBtnNav , {|x| x:Hide() } )
#endif

// Mostra bot�es de confirmar e cancelar
::oBtnOk:Show()
::oBtnCanc:Show()

Return 

// ----------------------------------------------------------
// Confirma��o da opera��o atual

METHOD CONFIRM() CLASS ZMVCVIEW
Local lOk
Local nFldCount
Local cFldName
Local nFld , nPos
Local aRecord := {}
Local aFound := {}

::oLogger:Write("Confirm","Action="+::cRunning)

nFldCount := len(::aGets)

If ::cRunning == 'SEARCH'
	
	// Confirma��o de Busca (search)
	// A busca gen�rica pode informar um ou mais campos para serem pesquisados.
	// Ser� trazido o primeiro registro onde todos os campos preenchidos atenderem
	// ao criterio de busca.
	
	// Primeiro preenche o registro na memoria com os valores informados
	// Por hora Somente envia valores preenchidos 
	For nFld := 1 to nFldCount
		If !empty(::aGets[nFld][4])
			aadd(aRecord,{::aGets[nFld][1],::aGets[nFld][4]})
		Endif
	Next
	
	lOk := ::oControl:Search( aRecord , aFound )
	
	If !lOk
		
		MsgStop(::oControl:GetErrorStr(),"Aten��o")
		
	Else
		
		// Opera��o deu certo.
		// Atualiza valores de tela com o registro encontrado 
		// E coloca todos os gets como read only 
				
		For nFld := 1 to nFldCount
			cFldName := ::aGets[nFld][1]
			nPos := ascan( aFound , {|x| x[1] == cFldName })
			If nPos > 0 
				::aGets[nFld][4] := aFound[nPos][2]
			Else
				// Campo nao existe na estrutura 
				// ou nao foi retornado ?! Que medo ... 
				// Por hora desliga o GET
				::oLogger:Write("Confirm","Warning: Interface Field ["+cFldName+"] not found.")
				::aGets[nFld][2]:SetEnable(.F.)
			Endif
			::aGets[nFld][2]:LREADONLY := .T.
		Next
		               
		nPos := ascan( aFound , {|x| x[1] == 'RECNO' })
		If nPos > 0 
			::nRecno  := aFound[nPos][2]
			aDel(aFound,nPos)
			aSize(aFound,len(aFound)-1)
		Else
			::nRecno  := 0 
		Endif

		// Registro antigo com valores atuais
		::aOldRecord := aClone(aFound)

#ifdef HAS_NAVBUTTONS
		// Mostra botoes de navegacao 
		aEval (::aBtnNav , {|x| x:Show() } )
#endif

        // Esconde o botao de confirmar 		
        ::oBtnOk:Hide()

		// A opera��o em execu��o agora � "VIEW"
		::cRunning := 'VIEW'           
		
		// Roda os eventos de visualiza��o de registro 
		::RunViewEvent(VIEW_ONDISPLAY)
		

	Endif
	
ElseIf ::cRunning == 'INSERT'
	
	// Confirmar inclus�o de registro
	// Monta um array com o registro a incluir
	// e passa para o Controler
	
	For nFld := 1 to nFldCount
		aadd(aRecord,{::aGets[nFld][1],::aGets[nFld][4]})
	Next
	
	// O Controller � que faz as honras
	// repassando para o modelo
	lOk := ::oControl:Write( aRecord )
	
	If !lOk
		
		MsgStop(::oControl:GetErrorStr(),"FALHA DE INCLUSAO")
		
	Else
		
		// Opera��o deu certo. 
		If MsgYesNo("<html>Registro inclu�do com sucesso.<br>Deseja incluir mais um registro ?")
			::Insert()
		Else
			// Nao quero inserir mais, volta ao estado inicial 
			// sem pedir confirma��o 
			::Cancel(.F.)
		Endif
		
	Endif
	
ElseIf ::cRunning == 'UPDATE'

	// Confirmar altera��o de registro
	// Monta um array com os dados a alterar 
	// e passa para o Controler repassar ao Modelo 
	// -- Passa todos os campos 
	
	For nFld := 1 to nFldCount
		aadd(aRecord,{ ::aGets[nFld][1], ::aGets[nFld][4] })
	Next
	
	If len(aRecord) < 1 
		// Nada foi alterado, volta pra tela de altera��o 
		MsgStop("Nenhuma informa��o foi alterada.","ALTERA��O")
		Return
	Endif
	
	// Acrescenta o RECNO para localizar o registro 
	aadd(aRecord,{"RECNO",::nRecno})
	
	// O Controller � que faz as honras
	// repassando para o modelo
	lOk := ::oControl:Update( aRecord )
	
	If !lOk
		
		MsgStop(::oControl:GetErrorStr(),"FALHA DE ALTERA��O")
		
	Else

        MsgInfo("Altera��es gravadas com sucesso.")
				
		// Opera��o deu certo. Volta ao estado inicial
		// sem pedir confirma��o 
		::Cancel(.F.)
		
	Endif

Else
	
	MsgStop("*** TODO ACTION "+::cRunning+" ***","Confirmar")
	
Endif

Return


// ----------------------------------------------------------
// O metodo de cancelamento atualiza novamente a a interface
// com um registro vazio -- estado inicial de entrada da rotina

METHOD CANCEL(lConfirm) CLASS ZMVCVIEW
Local nFldCount
Local oFldDef
Local nFld
Local lCancel := .T. 

If lConfirm = NIL
	lConfirm := .T. 
Endif

If lConfirm
	If ::cRunning == 'INSERT'
		lCancel := MsgYesNo("Deseja cancelar a inser��o em andamento ? Os dados informados n�o ser�o gravados.")
	ElseIf ::cRunning == 'UPDATE'
		lCancel := MsgYesNo("Deseja cancelar a atualiza��o em andamento ? Os dados informados n�o ser�o gravados.")
	Endif
Endif

If lCancel

	// Registra log de cancelamento e qual a a��o em andamento 
	::oLogger:Write("Cancel","Action="+::cRunning)
	
	// Esconde bot�es de confirmar e cancelar
	::oBtnOk:Hide()
	::oBtnCanc:Hide()
	
	/// A��o volta ao zero
	::cRunning := '' 

	// Atualiza titulo padrao da janela 	
	::oDlg:cTitle := ::cTitle

	// Preenche os campos com os valores default
	nFldCount := len( ::aGets )
	
	For nFld := 1 to nFldCount
		
		// Pega o objeto da definicao deste campo
		oFldDef := ::aGets[nFld][3]
		  
		// Atualiza gets com valor inicial do campo ( vazio ) 
		::aGets[nFld][4] := oFldDef:DefaultValue()
	
		// Desabilita todos os gets
		::aGets[nFld][2]:SetEnable(.F.)
		
		// SE tem um label relacionado, limpa
		If ::aGets[nFld][5] != NIL 
			::aGets[nFld][5]:SetText(" ")
		Endif
		
	Next
	
	#ifdef HAS_NAVBUTTONS
		// Mostra novamente botoes de navega��o
		aEval (::aBtnNav , {|x| x:Show() } )
	#endif
	
	#ifdef HAS_NAVBUTTONS
	// Esconde os botoes de navega��o
	aEval (::aBtnNav , {|x| x:Hide() } )
	#endif
	
Endif

Return


// ----------------------------------------------------------
// A opera��o de busca abre a tela em branco com todos os campos
// Para a pesquisa ser feita partindo das informa��es preenchidas

METHOD SEARCH()      CLASS ZMVCVIEW
Local nFldCount
Local oGet,oFldDef

::oLogger:Write("Search","Open Search Interface")

nFldCount := len( ::aGets )

// Habilita todos os GETS e preenche com valor default em branco

For nI := 1 to nFldCount

	oGet := ::aGets[nI][2]
	oFldDef := ::aGets[nI][3]

	// Atualiza valor default 
	::aGets[nI][4] := oFldDef:DefaultValue()

	// Define campos ativos baseados na definicao
	oGet:SetEnable( oFldDef:IsEnabled() )

	// Define se o campo � somente leitura ou nao 
	oGet:LREADONLY := oFldDef:IsReadOnly()
	
	// SE tem um label relacionado, limpa
	If ::aGets[nI][5] != NIL 
		::aGets[nI][5]:SetText(" ")
	Endif
	
Next

#ifdef HAS_NAVBUTTONS
// Esconde os bot�es de navega��o
aEval (::aBtnNav , {|x| x:Hide() } )
#endif

// Mostra bot�es de confirmar e cancelar
::oBtnOk:Show()
::oBtnCanc:Show()

Return .T.

#ifdef HAS_NAVBUTTONS

// ==================================================
// Botoes de navegacao 
// Somente sao mostrados quando tem um registro 
// sendo mostrado na tela 
// ==================================================

METHOD GOFIRST()      CLASS ZMVCVIEW
Return MsgStop("*** TODO ***")

METHOD GONEXT()      CLASS ZMVCVIEW
Return MsgStop("*** TODO ***")

METHOD GOPREV()      CLASS ZMVCVIEW
Return MsgStop("*** TODO ***")

METHOD GOLAST()      CLASS ZMVCVIEW
Return MsgStop("*** TODO ***")

#endif

// ==================================================
// ==================================================

METHOD UPDATE()      CLASS ZMVCVIEW
Local nFldCount
Local oGet,oFldDef

::oLogger:Write("Update","Open Update Interface")

nFldCount := len( ::aGets )

// Habilita todos os GETS baseado na defini��o

For nI := 1 to nFldCount

	oGet    := ::aGets[nI][2]
	oFldDef := ::aGets[nI][3]

	// Define campos ativos baseados na definicao
	oGet:SetEnable( oFldDef:IsEnabled() )

	// Define se o campo � somente leitura ou nao 
	oGet:LREADONLY := oFldDef:IsReadOnly()

Next

#ifdef HAS_NAVBUTTONS
	// Esconde os bot�es de navega��o
	aEval (::aBtnNav , {|x| x:Hide() } )
#endif

// Mostra bot�es de confirmar e cancelar
::oBtnOk:Show()
::oBtnCanc:Show()

Return

METHOD DELETE()      CLASS ZMVCVIEW
Return MsgStop("*** DELETE AINDA NAO IMPLEMENTADO ***")

// ----------------------------------------------------------
// Retorna string com ultimo erro 

METHOD GETERRORSTR() CLASS ZMVCVIEW
Return ::cError

// ----------------------------------------------------------
// Seta uma ocorrencia de error 
METHOD SETERROR(cError) CLASS ZMVCVIEW
::cError := cError
::oLogger:Write("SetError",cError)
Return

// ----------------------------------------------------------
// Limpa ocorrencia de erro 

METHOD ClearError()   CLASS ZMVCVIEW
::cError := ''
Return

// ----------------------------------------------------------
// Pede ao controle para executar as a��es 
// Observa��o : As a��es default / reservadas tem controle 
// especial por aqui mesmo 
//

METHOD RunAction(cAction) CLASS ZMVCVIEW
Local lRun := .F. 
Local nPos
Local cPrompt

nPos := ascan(::aActions , {|x| x[1] == cAction })
cPrompt := ::aActions[nPos][2]

::oLogger:Write("RunAction","Act="+cAction)

If cAction == ::cRunning
	// A a��o em execu��o � a mesma. 
	MsgInfo("Voc� j� est� executando a opera��o de ["+cPrompt+"].")
	Return
Endif

If cAction == 'SEARCH'
	If empty(::cRunning) .OR. ::cRunning == 'VIEW'
		lRun := .T. 
	Else
		MsgStop("N�o � poss�vel executar esta opera��o. Confirme ou Cancele a opera��o atual em andamento.")
	Endif
ElseIf cAction == 'INSERT'
	If empty(::cRunning) .OR. ::cRunning == 'VIEW'
		lRun := .T. 
	Else
		MsgStop("N�o � poss�vel executar esta opera��o. Confirme ou Cancele a opera��o atual em andamento.")
	Endif
ElseIf cAction == 'UPDATE'
	If ::cRunning ==  'VIEW' 
		lRun := .T. 
	ElseIf empty(::cRunning)
		MsgStop("Atualiza��o n�o dispon�vel. Primeiro efetue uma Pesquisa para selecionar o registro a ser alterado. ")
	Else
		MsgStop("N�o � poss�vel executar esta opera��o. Confirme ou Cancele a opera��o atual em andamento.")
	Endif
ElseIf cAction == 'DELETE'
	If ::cRunning ==  'VIEW' 
		lRun := .T. 
	ElseIf empty(::cRunning)
		MsgStop("Exclus�o n�o dispon�vel. Primeiro efetue uma Pesquisa para selecionar o registro a ser exclu�do. ")
	Else
		MsgStop("N�o � poss�vel executar uma nova opera��o. Confirme ou Cancele a opera��o atual em andamento.")
	Endif
ElseIf cAction == 'EXIT' 
	If empty(::cRunning)
		::oDlg:End()
		Return
	Else
		MsgStop("N�o � poss�vel executar esta opera��o. Confirme ou Cancele a opera��o atual.")
	Endif
Else
	// TODO 
	// Verificar se a opera��o tem algum pre-requisito
	// Por hora qualquer opera��o adicional exige o estado "VIEW"
	If ::cRunning == 'VIEW'
		lRun := .T. 
	ElseIf Empty(::cRunning)
		MsgStop("Opera��o n�o dispon�vel. Primeiro efetue uma Pesquisa para selecionar um registro. ")
	Else
		MsgStop("N�o � poss�vel executar uma nova opera��o. Confirme ou Cancele a opera��o atual em andamento.")
	Endif
Endif

If lRun
	::cRunning := cAction
	::oDlg:cTitle := ::cTitle+" ("+cPrompt+")"
	::oControl:RunAction(cAction)
	If !empty(::oControl:GetErrorStr())
		MsgStop(::oControl:GetErrorStr(),cAction)
	Endif
Endif

Return 

// ----------------------------------------------------------
// A��o de atualiza��o de campo relacionado
// Por exemplo um campo de uma tabela ligada por chave estrangeira 
// ( descri��o de um produto ou item por exemplo ) 

METHOD UpdRelField( lValid, cFTable , cFKey , cFName , nPosGet ) CLASS ZMVCVIEW
Local oFldDef  := ::aGets[nPosGet][3]
Local xValue := ::aGets[nPosGet][4]
Local oSay    := ::aGets[nPosGet][5]
Local aSearch := {}
Local aFound := {}
Local lOk := .F. 
Local nPos

If Empty(xValue)
	// Verifica se o campo � obrigat�rio
	// e a valida��o est� habilitada 
	oSay:SetText(" ")
	If oFldDef:IsRequired() .and. lValid
		MsgStop("Este campo � de preenchimento obrigat�rio. Preencha o conte�do do campo para continuar.")
		Return .F.
	Else
		Return .T.
	Endif
Endif

// Troca o modelo ativo para o modelo da rela��o 
// E faz uma busca no modelo pelo campo informado 
::oControl:SetModel(cFTable)
aadd(aSearch,{cFKey,xValue})
lOk := ::oControl:Search( aSearch , aFound )
::oControl:SetModel("AGENDA")

If lOk
	nPos := ascan(aFound , {|x| x[1] == cFName } )
	oSay:SetText(aFound[nPos][2])
	Return .T.
Endif

If lValid
	MsgStop("Valor informado n�o encontrado. Informe um valor v�lido.")
	oSay:SetText(" ")
	Return .F.
Endif

Return .T.

// ----------------------------------------------------------
// Disparo de a��es internas da View 

METHOD RunViewEvent(nEvent)  CLASS ZMVCVIEW
Local nI
For nI := 1 to len(::aViewEvents)
	If ::aViewEvents[nI][1] == nEvent
		Eval(::aViewEvents[nI][2],self)
	Endif
Next
Return

/*

    == Desligar calendario do GET 

LHASBUTTON

	If oFldDef:GetType() == 'D'
		// desliga calendario 
	    oNewGet:LCALENDARIO := .F. 
	Endif
		


*/
