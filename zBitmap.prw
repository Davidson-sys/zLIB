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

/* ===========================================================================

Classe		ZBITMAP
Autor		J�lio Wittwer
Data		05/2019

Leitura e edi��o de Bitmap monocromatico em AdvPL 

Referencia do formato do arquivo 
https://en.wikipedia.org/wiki/BMP_file_format

Release 20190727   Metodo LoadFromPNG()

=========================================================================== */

CLASS ZBITMAP FROM LONGNAMECLASS

    DATA cFileName     // Nome do arquivo de imagem 
    DATA nFileSize     // Tamanho em bytes total do arquivo
    DATA nHeight       // Altura da imagem em pixels
    DATA nWidth        // largura da imagem em pixels
    DATA nBPP          // Bits por Pixel ( 1,4,8,24 )
    DATA cERROR        // String com ultima ocorrencia de erro da classe         
    DATA aMatrix       // Matrix de pontos do Bitmap ( cores ) 
    DATA aClipBoard        // Area interna de transferencia
    DATA aColors       // Tabela de cores do Bitmap ( BGRA ) 
    DATA cFormat       // Identificador do formato do arquivo 
    DATA nOffSet       // Offset de inico dos dados 
    DATA nRawData      // Tamanho dos dados 
    DATA nRowSize      // Tamanho em bytes de uma linha da imagem 
    DATA nHeadSize     // Tamanho do Info Header 
    DATA nCompress     // Nivel de compressao 
    DATA nColorPlanes  // Numero de planos de cor ( 1 ) 
    DATA nHRes         // Resolucao horizontal 
    DATA nVRes         // Resolucao vertical 
    DATA nColorPal     // Paleta de cores
    DATA nImpColors    // Cores importantes
    DATA nFRColor      // Cor de pintural atual ( default =0 / preto ) 
    DATA nBgColor      // Cor de fundo ( default = branco ) 
    DATA nMargin       // Margem da imagem   
    DATA nPenSize      // Grossura da "caneta" de desenho ( default=1 ) 
    DATA lTransparent  // Transparencia ( PNG Only ) 
    
    METHOD New()           // Cria uma imagem vazia 
    METHOD LoadFromFile()  // Le imagem de um arquivo BMP
    METHOD LoadFromPNG()   // Le imagem de um arquivo PNG
    METHOD GetErrorStr()   // Recupera ultimo erro da classe
    METHOD Clear()         // Limpa a imagem ( preenche com a cor de fundo ) ou uma parte dela  
    METHOD SetPixel()      // Seta a cor de um ponto 
    METHOD GetPixel()      // Recupera a cor de um ponto 
    METHOD BgColor()       // Seta ou Recupera a cor de fundo 
    METHOD Negative()      // Inverte as cores da imagem ( = Negativo ) 
    METHOD SaveToBMP()     // Salva a imagem em disco como Bitmap
    METHOD SaveToJPG()     // Salva a imagem em disco como JPEG
    METHOD SaveToPNG()     // Salva a imagem em disco como PNG
    METHOD Rectangle()     // Desenha um ret�ngulo na imagem
    METHOD Line()          // Desenha uma linha na imagem entre dois pontos
    METHOD Circle()        // Desenha um c�rculo 
    METHOD SetBPP()        // Troca a resolu�ao de cores
    METHOD Paint()         // pintura de �rea da imagem delimitada
    METHOD FlipH()         // Inverte horizontalmente uma �rea da imagem ou a imagem inteira
    METHOD FlipV()         // Inverte verticalmente uma �rea da imagem ou a imagem inteira
    METHOD Cut()           // Copia uma parte da imagem para a �rea interna de transferencia e limpa a �rea da imagem
    METHOD Copy()          // Copia uma parte da imagem para a �rea interna de transferencia
    METHOD Paste()         // Plota a imagem da area interna de transferencia na coordenada indicada
    METHOD Resize()        // Redimensiona BMP em percentual horizontal e vertical
    METHOD SetTransparent()// Liga/DEsliga transparencia da cor de fundo 

ENDCLASS


// Cria um objeto BMP
// Pode ser criado sem parametros, para carregar uma imagem do disco 

METHOD NEW(nWidth,nHeight,nBPP) CLASS ZBITMAP
Local nL
Local nC
Local aRow

IF nWidth = NIL
	::nWidth := 32
Else
	::nWidth := nWidth
Endif

If nHeight = NIL 
	::nHeight := 32
Else
	::nHeight := nHeight
Endif

If nBPP = NIL
	::nBPP := 1
Else
	::nBPP := nBPP
Endif

::aColors := GetColorTab(nBPP)

::cFileName := ''
::nPenSize  := 1               

::nFRColor := 0 // Preto 

IF ::nBPP = 1
	::nOffSet  := 62
	::nBgColor := 1 // Branco 
ElseIf ::nBPP = 4
	::nOffSet  := 118
	::nBgColor := 15 // Branco 
ElseIf ::nBPP = 8
	::nOffSet  := 1078
	::nBgColor := 255 // Branco 
ElseIf ::nBPP = 24
	::nOffSet  := 54
	::nBgColor := RGB(256,256,256)-1 // branco 
Endif        
aRow := {}

// Inicializa matrix com a cor de fundo
::aMatrix := {}
For nC := 1 to ::nWidth
	aadd(aRow,::nBgColor)
Next
For nL := 1 to ::nHeight
	aadd(::aMatrix,aClone(aRow))
Next

::nHeadSize  := 40
::nColorPlanes := 1
::nCompress  := 0
::nHRes      := 0
::nVRes      := 0
::nColorPal  := 0
::nImpColors := 0

// Tamanho calculado de cada linha em bytes
::nRowSize   := int( ( (::nBPP*::nWidth) + 31 ) / 32 ) * 4 

// Tamando da area de dados da imagem 
::nRawData   := ::nRowSize  * ::nHeight

// Tamanho final da imagem 
::nFileSize :=   ::nRawData + ::nOffSet

// Transprencia ( PNG ) 
// Por hora define que a cor de fundo ser� transparente
::lTransparent := .F.

Return self


// Carrega uma imagem BMP do disco 

METHOD LOADFROMFILE(cFile)  CLASS ZBITMAP
Local nH
Local cBuffer := ''
Local cBinSize  
Local nBmpSize
Local nL , nC, nI
Local nByte
Local nReadOffset 
Local aRow := {}
Local cBits      
Local lTopDown := .F. 
Local nPos, nCor, nRed, nGreen,nBlue,nAlpha   

::cFileName := cFile

nH := Fopen(cFile)

If  nH < 0 
	UserException("Fopen error ("+cValToChar(Ferror())+")")
Endif

::nFileSize := fSeek(nH,0,2)

fSeek(nH,0)

If ::nFileSize < 54
	::cError := "Invalid BMP -- file too small"
	Return .F.
Endif

// Aloca o Buffer e l� o arquivo intero 
// para arquivos maiores que 1MB, aumentar o tamanho 
// m�ximo de string no AdvPL -- MaxStringSize

fRead(nH,@cBuffer,::nFileSize)
fClose(nH)

::cFormat := substr(cBuffer,0,2)

If ::cFormat <> "BM"
	::cError := "Unknow BMP Format ["+::cFormat+"]"
	Return .F.
Endif

cBinSize := substr(cBuffer,3,4)
nBmpSize := bin2l(cBinSize)

If ::nFileSize <> nBmpSize
	::cError := "BMP Incorrect Format -- File size mismatch"
	Return .F.
Endif


/*
                                                
Windows BITMAPINFOHEADER[1]

Offset (hex)	Offset (dec)	Size (bytes)	Information 
0E	14	4	the size of this header (40 bytes)
12	18	4	the bitmap width in pixels (signed integer)
16	22	4	the bitmap height in pixels (signed integer)
1A	26	2	the number of color planes (must be 1)
1C	28	2	the number of bits per pixel, which is the color depth of the image. Typical values are 1, 4, 8, 16, 24 and 32.
1E	30	4	the compression method being used. See the next table for a list of possible values
22	34	4	the image size. This is the size of the raw bitmap data; a dummy 0 can be given for BI_RGB bitmaps.
26	38	4	the horizontal resolution of the image. (pixel per metre, signed integer)
2A	42	4	the vertical resolution of the image. (pixel per metre, signed integer)
2E	46	4	the number of colors in the color palette, or 0 to default to 2n
32	50	4	the number of important colors used, or 0 when every color is important; generally ignored

*/

::nOffSet    := bin2l(substr(cBuffer,11,4))
::nHeadSize  := bin2l(substr(cBuffer,15,4))
::nWidth     := bin2l(substr(cBuffer,19,4))
::nHeight    := bin2l(substr(cBuffer,23,4))
::nColorPlanes := bin2i(substr(cBuffer,27,2))
::nBPP       := bin2i(substr(cBuffer,29,2))
::nCompress  := bin2l(substr(cBuffer,31,4))
::nRawData   := bin2l(substr(cBuffer,35,4))
::nHRes      := bin2l(substr(cBuffer,39,4))
::nVRes      := bin2l(substr(cBuffer,43,4))
::nColorPal  := bin2l(substr(cBuffer,47,4))
::nImpColors := bin2l(substr(cBuffer,51,4))

If ::nHeight < 0 
	// Linhas do Bitmap "de cima pra baixo"
	// Normalmente o formato padrao � "Bottom-Up" ( de baixo pra cima ) 
	lTopDown := .T.
	::nHeight := abs(::nHeight)
Endif

// Tamanho calculado de cada linha em bytes
::nRowSize   := int( ( (::nBPP*::nWidth) + 31 ) / 32 ) * 4 

// Tabela de cores para 4 bytes por pixel ( 16 cores ) 
::aColors := {}
If ::nBPP = 1
	nCores := 2
ElseIF ::nBPP = 4
	nCores := 16
ElseIF ::nBPP = 8
	nCores := 256
ElseIF ::nBPP = 24
	// Nao tem tabela de cores 
	nCores := 0
Else	
	UserException("Formato (ainda) nao suportado: "+cValToChar(::nBPP)+" BPP" )
Endif
	
nPos := 55
For nCor := 0 to nCores-1
	
	nBlue  := asc(substr(cBuffer,nPos,1))
	nGreen := asc(substr(cBuffer,nPos+1,1))
	nRed   := asc(substr(cBuffer,nPos+2,1))
	nAlpha := asc(substr(cBuffer,nPos+3,1))
	
	aadd(::aColors,{nBlue,nGreen,nRed,nAlpha})
	
	//conout("aadd(::aColors,{"+cValToChaR(nBlue)+","+cValToChaR(nGreen)+","+cValToChaR(nRed)+","+cValToChaR(nAlpha)+"})")
	
	nPos += 4
	
	// Conout("BGRA("+cValToChar(nCor)+") = ("+cValToChar(nBlue)+","+cValToChar(nGreen)+","+cValToChar(nRed)+","+cValToChar(nAlpha)+")")
	
Next

// Leitura dos dados na matriz

::aMatrix := {}

For nL := 0 to ::nHeight-1
	nReadOffset := ::nOffSet + ( ::nRowSize * nL ) + 1
	For nC := 0 to ::nWidth-1 
		nByte := asc(substr(cBuffer,nReadOffset,1))
		If ::nBPP == 1 
			// Bitmap monocromatico 
			// um bit por pixel, converte para binario direto 
			// 0 = preto, 1 = branco
			cBits := NTOBIT8(nByte) 
			For nI := 1 to 8
				aadd(aRow,IIF(substr(cBits,nI,1)=='0',0,1))
			Next
		ElseIf ::nBPP == 4
			// Bitmap de 16 cores
			// 2 pixels por byte
			cBits := NTOBIT8(nByte) 
			aadd(aRow, BITSTON(Substr(cBits,1,4)))
			aadd(aRow, BITSTON(Substr(cBits,5,4)))
		ElseIf ::nBPP == 8
			// Bitmap de 256 cores
			// 1 pixels por byte
			aadd(aRow, nByte)
		ElseIf ::nBPP == 24
			// Bitmap de 256*256*256 cores
			// 1 pixel a cada 3 bytes
			nBlue := asc(substr(cBuffer,nReadOffset,1))
			nGreen := asc(substr(cBuffer,nReadOffset+1,1))
			nRed := asc(substr(cBuffer,nReadOffset+2,1))
			aadd(aRow, RGB(nRed,nGreen,nBlue) )
		Else
			UserException("Unsupported ("+cValToChar(::nBPP)+") Bytes per Pixel")
		Endif
		If ::nBPP == 24
			nReadOffset += 3 
		Else
			nReadOffset += 1
		Endif
	Next
	aSize(aRow,::nWidth)
	If lTopDown
		// Armazenamento de cima pra baixo
		aadd(::aMatrix,aClone(aRow))
	Else
		// Windows BMP normalmente � armazenado de baixo pra cima
		// Somente � de cima pra baixo caso a altura seja negativa
		aadd(::aMatrix,NIL)
		aIns(::aMatrix,1)
		::aMatrix[1] := aClone(aRow)
	Endif
	aSize(aRow,0)
Next

Return .T.


#define PNG_WIDTH			1
#define PNG_HEIGHT			2
#define PNG_BIT_DEPHT       3
#define PNG_COLOR_TYPE      4
#define PNG_COMPRESSION     5
#define PNG_FILTER          6
#define PNG_INTERLACE       7
#define PNG_SRGB            8
#define PNG_GAMA            9
#define PNG_PIXELPERUNIT_X  10
#define PNG_PIXELPERUNIT_Y  11
#define PNG_PIXEL_UNIT      12
#define PNG_PALLETE         13
#define PNG_IMAGEDATA       14

#define PNG_HEADER 		chr(137)+chr(80)+chr(78)+chr(71)+chr(13)+chr(10)+chr(26)+chr(10)

METHOD LoadFromPNG(cFile) CLASS ZBITMAP
Local nH,cBuffer := ''
Local aPng := Array(14)
Local iTam , cData , nCRC // Dados do Chunk
Local cBufferOut := ''
Local nLenghtOut 
Local nColSize , cRowBuffer
Local nColPos,cBits
Local nL , nC
Local aRow := {}
Local cIdat

::cFileName := cFile

nH := fopen(cFile)

IF nH == -1
	::cError := "File Open Error - FERROR = "+cValToChar(Ferror())
	Return .F.
Endif

// Determina o tamanho e le o arquivo inteiro 
::nFileSize := fSeek(nH,0,2)
fSeek(nH,0)
fREad(nH,@cBuffer,::nFileSize)
fClose(nH)

IF !(Left(cBuffer,8) == PNG_HEADER )
	::cError := "File is NOT A PNG"
	Return .F.
Endif

// Corta o header fora
cBuffer := substr(cBuffer,9)

// Data Compacted Stream
cIDAT := ''
             
// Varre o resto do buffer 
while len(cBuffer) > 0
	
	// Tamanho dos dados do chunk
	iTam := Bin4toN(left(cBuffer,4))
	cBuffer := substr(cBuffer,5)
	
	// Tipo do Chunk
	cType := left(cBuffer,4)
	cBuffer := substr(cBuffer,5)
	
	If iTam > 0
		cData := left(cBuffer,iTam)
		cBuffer := substr(cBuffer,iTam+1)
	Else
		cData := ''
	Endif
	
	nCRC := Bin4toN(left(cBuffer,4))
	cBuffer := substr(cBuffer,5)

	nChkCRC := PNGCRC(cType+cData)

	If Upper(cType) == 'IHDR'
		
		/*
		Width:              4 bytes
		Height:             4 bytes
		Bit depth:          1 byte
		Color type:         1 byte
		Compression method: 1 byte
		Filter method:      1 byte
		Interlace method:   1 byte
		*/
		       
		aPng[PNG_WIDTH]        := Bin4toN(substr(cData,1,4))
		aPng[PNG_HEIGHT]       := Bin4toN(substr(cData,5,4))
		aPng[PNG_BIT_DEPHT]    := asc(substr(cData,9,1))
		aPng[PNG_COLOR_TYPE]   := asc(substr(cData,10,1))
		aPng[PNG_COMPRESSION]  := asc(substr(cData,11,1))
		aPng[PNG_FILTER]       := asc(substr(cData,12,1))
		aPng[PNG_INTERLACE]    := asc(substr(cData,13,1))

		// Por enqianto aproveita apenas comprimento e altura
		// e  Bit Depth ( Bits Per Pixel ) 
		::nWidth := aPng[PNG_WIDTH]
		::nHeight := aPng[PNG_HEIGHT]
	
		IF aPng[PNG_COLOR_TYPE] = 3 // Cada pixel � um indice da paleta de cores
			IF aPng[PNG_BIT_DEPHT] = 1
				::nBPP     := 1 
				::nOffSet  := 62
				::nBgColor := 1 // Branco 
			ElseIf aPng[PNG_BIT_DEPHT]= 4
				::nBPP     := 4
				::nOffSet  := 118
				::nBgColor := 15 // Branco 
			ElseIf aPng[PNG_BIT_DEPHT] = 8
				::nBPP     := 8 
				::nOffSet  := 1078
				::nBgColor := 255 // Branco 
			Else
	        	UserException("PNG Unsupported Bit Depth ("+cValToChar(aPng[PNG_BIT_DEPHT])+") on ColorType=3")
			Endif        
		ElseIf aPng[PNG_COLOR_TYPE] = 2
			// Cada pixel � um RGB 
			If aPng[PNG_BIT_DEPHT] = 8
				::nBPP     := 24 
				::nOffSet  := 54
				::nBgColor := RGB(256,256,256)-1 // branco 
			Else
	        	UserException("PNG Unsupported Bit Depth ("+cValToChar(aPng[PNG_BIT_DEPHT])+") on ColorType=2")
			Endif			
		ElseIf aPng[PNG_COLOR_TYPE] = 6
			// Cada pixel � um RGB + alpha 
			If aPng[PNG_BIT_DEPHT] = 8
				::nBPP     := 24 
				::nOffSet  := 54
				::nBgColor := RGB(256,256,256)-1 // branco 
			Else
	        	UserException("PNG Unsupported Bit Depth ("+cValToChar(aPng[PNG_BIT_DEPHT])+") on ColorType=2")
			Endif			
		Else
			UserException("PNG Unsupported Color Type "+cValToChar(aPng[PNG_COLOR_TYPE]))
		Endif	
		
	ElseIF Upper(cType) == 'SRGB'
		
		/*
		0: Perceptual
		1: Relative colorimetric
		2: Saturation
		3: Absolute colorimetric
		*/
		
		aPNG[PNG_SRGB] := asc(substr(cData,1,1))
		
	ElseIF Upper(cType) == 'GAMA'

		// The value is encoded as a 4-byte unsigned integer, representing gamma times 100000.
		// For example, a gamma of 1/2.2 would be stored as 45455.
		aPng[PNG_GAMA] := Bin4toN(substr(cData,1,4))

	ElseIF Upper(cType) == 'PLTE'

		// Paleta de cores sequencias de 3 bytes  RGB
                     
		::aColors := {}
		aPng[PNG_PALLETE] := {}

		While len(cData) > 0 	
			nRed := asc(substr(cData,1,1))
			nGreen := asc(substr(cData,2,1))
			nBlue := asc(substr(cData,3,1))
		    cData := substr(cData,4)
		    aadd( aPng[PNG_PALLETE] , {nRed,nGreen,nBlue} )
		    
		    // Paleta do BITMAP : BGRA
		    aadd(::aColors,{nBlue,nGreen,nRed,0}) // BGRA

		Enddo

	ElseIF Upper(cType) == 'PHYS'

		/*
		Pixels per unit, X axis: 4 bytes (unsigned integer)
		Pixels per unit, Y axis: 4 bytes (unsigned integer)
		Unit specifier:          1 byte
		*/

		aPng[PNG_PIXELPERUNIT_X] := Bin4toN(substr(cData,1,4))
		aPng[PNG_PIXELPERUNIT_Y] := Bin4toN(substr(cData,5,4))
		aPng[PNG_PIXEL_UNIT]     := asc(substr(cData,9,1))
		
		
	ElseIF Upper(cType) == 'IDAT'

		// Soma o stream compactado, caso haja mais que um      
     	cIdat += cData
		
	ElseIF Upper(cType) == 'IEND'

		// Fim do arquivo 
		EXIT
		
	Else

		Conout("WARNING - LoadFromPNG - Ignored Chunk ["+cType+"]")
		conout(hexstrdump(cData))

	Endif
	
Enddo

IF !empty(cIdat)

	cBufferOut := ''
	nLenghtOut := 10*1024*1024
	UnCompress( @cBufferOut ,  @nLenghtOut , cIdat, len(cIdat)  )

	nColSize := nLenghtOut / aPng[PNG_HEIGHT]
	
	// Inicializa BMP com fundo branco
	::aMatrix := {}
	For nC := 1 to ::nWidth
		aadd(aRow,::nBgColor)
	Next
	For nL := 1 to ::nHeight
		aadd(::aMatrix,aClone(aRow))
	Next
	
	// Mastiga o buffer binario alimentando a matrix do Bitmap
	For nL := 1 to 	aPng[PNG_HEIGHT]
		cRowBuffer := substr(cBufferOut,1,nColSize)
		cBufferOut := substr(cBufferOut,nColSize+1)
		nColPos := 1
		If aPng[PNG_COLOR_TYPE] == 3 .and. ::nBPP = 1
			For nC := 2 to nColSize
				cBits := NTOBIT8( asc(substr(cRowBuffer,nC,1)) )
				While len(cBits) > 0
					IF nColPos < aPng[PNG_WIDTH]
						::aMatrix[nL,nColPos] := val(left(cBits,1))
					Endif
					nColPos++
					cBits := substr(cBits,2)
				Enddo
			Next
		ElseIf aPng[PNG_COLOR_TYPE] == 2 .and. ::nBPP = 24
			// Trinca RGB
			For nC := 2 to nColSize STEP 3
				nRed := asc(substr(cRowBuffer,nC,1))
				nGreen := asc(substr(cRowBuffer,nC+1,1))
				nBlue := asc(substr(cRowBuffer,nC+2,1))
				::aMatrix[nL,nColPos] := RGB(nRed,nGreen,nBlue)
				nColPos++
			Next
		ElseIf aPng[PNG_COLOR_TYPE] == 6 .and. ::nBPP = 24
			// Trinca RGB + Alpha 
			For nC := 2 to nColSize STEP 4
				nRed := asc(substr(cRowBuffer,nC,1))
				nGreen := asc(substr(cRowBuffer,nC+1,1))
				nBlue := asc(substr(cRowBuffer,nC+2,1))
				::aMatrix[nL,nColPos] := RGB(nRed,nGreen,nBlue)
				nColPos++
			Next
		Else
			UserException("ColorType ["+cValToChar(aPng[PNG_COLOR_TYPE])+"] BPP ["+cValToChar(::nBPP)+"] unsupported.")
		Endif
	Next

Endif


Return .T. 




// Recupera a �ltima informa��o de erro da Classe

METHOD GetErrorStr()  CLASS ZBITMAP 
Return ::cError

// Limpa a imagem preenchendo os pontos com 
// a cor de fundo 

METHOD Clear(L1,C1,L2,C2) CLASS ZBITMAP
Local nL, nC

IF pCount() == 0
	// Limpa a imagem inteira
	L1 := 0
	C1 := 0
	L2 := ::nHeight-1
	C2 := ::nWidth-1
Else
	// Valida coordenadas informadas para limpeza
	IF L1 < 0 .or. L1 >= ::nHeight
		::cError := "Invalid 1o Line -- Out Of Image Area"
		Return .F.
	ElseIF L2 < 0 .or. L2 >= ::nHeight
		::cError := "Invalid 2o Line -- Out Of Image Area"
		Return .F.
	ElseIf C1 < 0 .or. C1 >= ::nWidth
		::cError := "Invalid 1o Column -- Out Of Image Area"
		Return .F.
	ElseIf C2 < 0 .or. C2 >= ::nWidth
		::cError := "Invalid 2o Column -- Out Of Image Area"
		Return .F.
	ElseIf L1 > L2
		::cError := "Invalid Lines -- Order mismatch"
		Return .F.
	ElseIf C1 > C2
		::cError := "Invalid Columns -- Order mismatch"
		Return .F.
	Endif
Endif

// Limpa a �rea informada
For nL := L1+1 to L2+1
	For nC := C1+1 to C2+1
		::aMatrix[nL][nC] := ::nBGColor
	Next
Next

Return

// -------------------------------------------------
// Seta um pixel com uma cor em uma coordenada 
// linha e coluna, base 0 , cor � opcional 
// Diametro da caneta (Pen) opcional

METHOD SETPIXEL(nL,nC,nColor,nPen) CLASS ZBITMAP
Local nRow := nL+1
Local nCol := nC+1

If nPen = NIL
	nPen := ::nPenSize
Endif

IF nColor = NIL 
	nColor := ::nFRColor
Endif

IF nRow < 1 .or. nRow > ::nHeight
	return
ElseIF nCol < 1 .or. nCol > ::nWidth
	return
Endif

::aMatrix[nRow][nCol] := nColor

IF nPen > 1
	// 2x2
	::aMatrix[nRow+1][nCol  ] := nColor
	::aMatrix[nRow  ][nCol+1] := nColor
	::aMatrix[nRow+1][nCol+1] := nColor
Endif

If nPen > 2
	// 3x3
	::aMatrix[nRow-1][nCol  ] := nColor
	::aMatrix[nRow+1][nCol  ] := nColor
	::aMatrix[nRow  ][nCol-1] := nColor
	::aMatrix[nRow  ][nCol+1] := nColor
Endif

If nPen > 3
	// 4x4
	::aMatrix[nRow+2][nCol  ] := nColor
	::aMatrix[nRow  ][nCol+2] := nColor
	::aMatrix[nRow+2][nCol+2] := nColor
Endif

IF nPen > 4
	// Caneta Acima de 4 ..
	// Verifica limites da imagem 
	nHalf := nPen/2
	For nRow := nL+1-nHalf TO nL+1+nHalf
		If nRow > 0 .and. nRow <= ::nHeight
			For nCol := nC+1-nHalf TO nC+1+nHalf
				IF nCol > 0 .and. nCol <= ::nWidth
					::aMatrix[nRow][nCol] := nColor
				Endif
			Next
		Endif
	Next
Endif

Return
              
// -------------------------------------------------
// Retorna a cor de um pixel 
// linha e coluna, base 0 
METHOD GETPIXEL(nRow,nCol) CLASS ZBITMAP
Return ::aMatrix[nRow+1][nCol+1]

// -------------------------------------------------
// Retorna a cor de fundo da imagem 
// se informado um parametro, seta a cor de fundo 
METHOD BgColor(nSet) CLASS ZBITMAP
If pCount()>0
	::nBgColor := nSet
Endif
Return ::nBgColor

// --------------------------------------------------------
// Faz o "negativo" da imagem 
// Recalcula as cores complementares da tabela de cores

METHOD Negative()  CLASS ZBITMAP
Local nI
Local nL , nC
Local nRed := 0
Local nGreen := 0
Local nBlue := 0

If ::nBPP < 24
	
	// Formatos menores que True Color, altera a tabela de cores
	
	For nI := 1 to len(::aColors)
		::aColors[nI][1] := 255-::aColors[nI][1]
		::aColors[nI][2] := 255-::aColors[nI][2]
		::aColors[nI][3] := 255-::aColors[nI][3]
	Next
	
Else
	
	// Imagem True Color, inverte as cores ponto a ponto                      
	
	For nL := 1 to ::nHeight
		For nC := 1 to ::nWidth
			RGB2Dec(::aMatrix[nL][nC],@nRed,@nGreen,@nBlue)
			nRed := 255 - nRed
			nGreen := 255 - nGreen
			nBlue := 255 - nBlue
			::aMatrix[nL][nC] := RGB(nRed,nGreen,nBlue)
		Next
	Next
	
Endif

Return

// ---------------------------------------------------
// Salva o arquivo em disco                           

METHOD SaveToBMP(cFile)  CLASS ZBITMAP
Local nH, nI, nC, nL
Local cHeader := ''
Local cHeadInfo := ''

If ::nBPP <> 1	.and. ::nBPP <> 4 .and. ::nBPP <> 8 .and. ::nBPP <> 24
	UserException("Format not implemented (yet) to save")
Endif

nH := fCreate(cFile)
           
cHeader := "BM"               // 2 bytes
cHeader += L2bin(::nFileSize) // 4 bytes 
cHeader += chr(0)+chr(0)      // 2 bytes
cHeader += chr(0)+chr(0)      // 2 bytes
cHeader += L2bin(::nOffset)   // 4 bytes

// Grava o primeiro Header
fWrite(nH,cHeader,len(cHEader)) // 14 bytes 

cHeadInfo += L2bin(40)             // This Header Size
cHeadInfo += L2bin(::nWidth)       // 
cHeadInfo += L2bin(::nHeight)      // 
cHeadInfo += I2Bin(::nColorPlanes) // Color planes
cHeadInfo += I2Bin(::nBPP)         // Bits Per Pixel
cHeadInfo += L2bin(::nCompress)    // Compression Method ( 0 = No Compression ) 
cHeadInfo += L2bin(::nRawData)     // RAW Data Size 
cHeadInfo += L2bin(::nHRes)        // Resolucao Horizontal
cHeadInfo += L2bin(::nVRes)        // Resolucao vertical
cHeadInfo += L2bin(::nColorPal)    // Color Pallete
cHeadInfo += L2bin(::nImpColors)   // Important Colors

// At� aqui o Header ocupou 54 bytes

// BMP Monocromatico 
// Para o Offset 62, ainda faltam 8 bytes 
// a tabela de cores tem apenas duas entradas, preto e branco 

// BMP de 16 cores
// At� o offset 118 sao 64 bytes
// Tabela de Cores em BGRA - ( Blue Green Red Alpha ) 4 bytes por cor

For nI := 1 to len(::aColors)
	cHeadInfo += chr(::aColors[nI][1])+chr(::aColors[nI][2])+chr(::aColors[nI][3])+chr(::aColors[nI][4])
Next

fWrite(nH,cHeadInfo,len(cHeadInfo))
            
// Armazena por default a imagem de baixo pra cima 

If ::nBPP == 1
	
	// Grava��o de imagem monocrom�tica
	For nL := ::nHeight to 1 STEP -1
		cBinRow := ''
		cBitRow := ''
		For nC := 1 to ::nWidth
			cBitRow += chr( 48 + ::aMatrix[nL][nC])
		Next
		While len(cBitRow)%32 > 0
			// Padding Bits to 32 ( 4 bytes )
			cBitRow += '1'
		Enddo
		For nC := 0 to len(cBitRow)-1 STEP 8
			cByteBit := Substr(cBitRow,nC+1,8)
			nByte    := BitsToN(cByteBit)
			cBinRow  += Chr(nByte)
		Next
		while len(cBinRow) < ::nRowSize
			// Padding Bytes ( ASCII 0 )
			cBinRow += Chr(0)
		Enddo
		// Grava os bytes da linha no arquivo
		fWrite(nH,cBinRow)
	Next
	
ElseIf ::nBPP == 4

	// Grava��o de imagem 16 cores
	// 4 bits por cor

	For nL := ::nHeight to 1 STEP -1
		cBinRow := ''
		cBitRow := ''
		For nC := 1 to ::nWidth 
			cBitRow += Right(NTOBITS(::aMatrix[nL][nC]),4)
			IF len(cBitRow) == 8 
				cBinRow += chr(BITSToN(cBitRow))
				cBitRow := ''
			Endif
		Next
		If !Empty(cBitRow)
			cBitRow += '0000'
			cBinRow += chr(BITSToN(cBitRow))
			cBitRow := ''
		Endif
		while len(cBinRow) < ::nRowSize
			// Padding Bytes ( ASCII 0 )
			cBinRow += Chr(0)
		Enddo
		// Grava os bytes da linha no arquivo
		fWrite(nH,cBinRow)
	Next
	
ElseIf ::nBPP == 8

	// Grava��o de imagem 256 cores
	// 8 bits por cor

	For nL := ::nHeight to 1 STEP -1
		cBinRow := ''
		For nC := 1 to ::nWidth 
			cBinRow += chr(::aMatrix[nL][nC])
		Next
		while len(cBinRow) < ::nRowSize
			// Padding Bytes ( ASCII 0 )
			cBinRow += Chr(0)
		Enddo
		// Grava os bytes da linha no arquivo
		fWrite(nH,cBinRow)
	Next
	

ElseIf ::nBPP == 24

	// Grava��o de imagem True Color 24 bits
	// 3 bytes por pixel 

	nTimer := seconds()

	For nL := ::nHeight to 1 STEP -1
		cBinRow := ''
		For nC := 1 to ::nWidth 
			nRed := 0 
			nGreen := 0 
			nBlue := 0 
			RGB2Dec(::aMatrix[nL][nC],@nRed,@nGreen,@nBlue)
			cBinRow += ( chr(nBlue)+chr(nGreen)+chr(nRed) )
		Next
		while len(cBinRow) < ::nRowSize
			// Padding Bytes ( ASCII 0 )
			cBinRow += Chr(0)
		Enddo
		// Grava os bytes da linha no arquivo
		fWrite(nH,cBinRow)
	Next

    conout(seconds()-nTimer)

Else

	// UserException("TODO")
	
Endif
fClose(nH)

Return .T.

// ---------------------------------------------------
// Salva a imagem em disco como PNG 
// Por hora suporte apenas monocromatico

METHOD SaveToPNG(cFile)    CLASS ZBITMAP
Local aPng := Array(14)
Local nH
Local nI, nL , nC
Local cBuffer , nDataSize , cData , cBits, nByte

aPng[PNG_WIDTH]             := ::nWidth
aPng[PNG_HEIGHT]            := ::nHeight
aPng[PNG_BIT_DEPHT]         := 1
aPng[PNG_COLOR_TYPE]        := 3
aPng[PNG_COMPRESSION]       := 0
aPng[PNG_FILTER]            := 0
aPng[PNG_INTERLACE]         := 0 
aPng[PNG_SRGB]              := 0
aPng[PNG_GAMA]              := 45455
aPng[PNG_PIXELPERUNIT_X]    := 4724
aPng[PNG_PIXELPERUNIT_Y]    := 4724
aPng[PNG_PIXEL_UNIT]        := 1

nH := fCreate(cFile)

If nH == -1
	::cError := "File Create Error - FERROR = "+cValToChar(ferror())
	Return .F.
Endif 

// Inicia com o header PNG
fWrite(nH , PNG_HEADER)

// Monta o Chunk IHDR 13 bytes

cData := ''
cData += nToBin4(aPng[PNG_WIDTH])
cData += nToBin4(aPng[PNG_HEIGHT])
cData += chr(aPng[PNG_BIT_DEPHT])
cData += chr(aPng[PNG_COLOR_TYPE])
cData += chr(aPng[PNG_COMPRESSION])
cData += chr(aPng[PNG_FILTER])
cData += chr(aPng[PNG_INTERLACE])

PNGSaveChunk(nH,"IHDR",cData)

// Monta o Chunk PLTE

cData := ''
For nI := 1 to len(::aColors)
	// Monta o Chucn RGB partindo da matriz BGRA 
	cData += chr(::aColors[nI][3]) + Chr(::aColors[nI][2]) + chr(::aColors[nI][1]) 
NExt

PNGSaveChunk(nH,"PLTE",cData)

if ::lTransparent
	// SE tiver transparencia, por hora seta apenas para cor de fundo da imagem 
	// Cria o Chunk tRNS para isso ( baseado no tipo de cor 3 ( indexed colors ) 
	// para as cores da palete 
	
	cData := ''
	For nI := 0 to len(::aColors)-1
		If nI == ::nBgColor
			cData += chr(0) // Transparente
		Else
			cData += chr(255) // Opaco 
		Endif
	NExt
	
	PNGSaveChunk(nH,"tRNS",cData)

Endif


// Monta o chunk IDAT -- por enquanto apenas um 

cBuffer := ''
For nL := 1 to ::nHeight
	cBits := '00000000'
	For nC := 1 to ::nWidth
		cBits += STR(::aMAtrix[nL][nC],1)
	Next
	while len(cBits)%8 > 0 
		cBits += '1'
	Enddo  
	while !empty(cBits)        
		BIT8TON(substr(cBits,1,8),nByte)
		cBuffer += chr(nByte)
		cBits := substr(cBits,9)
	Enddo	
Next

// Comprime o buffer 
cData := ''
nDataSize := 0
compress(@cData,@nDataSize,cBuffer,len(cBuffer))

// Salva o buffer comprimido 
PNGSaveChunk(nH,"IDAT",cData)

// Salva o final da imagem

PNGSaveChunk(nH,"IEND","")

fClose(nH)

Return .T. 




// ---------------------------------------------------
// Desenha um ret�ngulo na cor e espessura especificadas
// Cor e espessura sao opcionais
// Espessura > 1 , preenche a �rea interna do ret�ngulo 

METHOD Rectangle(L1,C1,L2,C2,nColor,nPen,nFill)  CLASS ZBITMAP
Local nL , nC, nPen

If nPen = NIL 
	nPen := ::nPenSize
Endif

For nPen := 0 to nPen

	// Espessura de linha de retangulo sempre 
	// para a �rea interna do Retangulo 

	// Tra�a linhas horizontais
	For nC := C1+nPen to C2-nPen
		::SetPixel(L1+nPen,nC,nColor,1)
		::SetPixel(L2-nPen,nC,nColor,1)
	Next
	
	// Traca as linhas verticais
	For nL := L1+nPen to L2-nPen
		::SetPixel(nL,C1+nPen,nColor,1)
		::SetPixel(nL,C2-nPen,nColor,1)
	Next
	
	IF nFill != NIL 
		// Retangulo com preenchimento
		For nL := L1+nPen to L2-nPen
			For nC := C1+nPen+1 to C2-nPen-1
				::SetPixel(nL,nC,nFill,1)
			Next
		Next	
	Endif
	
Next

Return

// ---------------------------------------------------
// Tra�a uma linha entre as coordenadas informadas
// pode ser horizontal, vertical ou diagonal 

METHOD Line(L1,C1,L2,C2,nColor,nPen)  CLASS ZBITMAP
Local nDH , nDV , nX
Local nStepH , nStepV 
Local nPoints 
Local nRow,nCol

If nPen = NIL
	nPen := ::nPenSize
Endif
	
	// Calcula as distancias entre os pontos
	nDH := C2 - C1 
	nDV := L2 - L1

	nStepH := 1
	nStepV := 1
	
	// Calcula a maior distancia e o passo
	// decimal
	If abs(nDH) > abs(nDV)
		nStepV := nDV / nDH
	ElseIf abs(nDV) > abs(nDH)
		nStepH := nDH / nDV
	Endif
	
	// Pontos que vao compor a reta
	nPoints := Max(abs(nDV),abs(nDH))
	
	// Tra�a a reta ponto a ponto , menos o ultimo
	nRow := L1 
	nCol := C1 
	For nX := 0 to nPoints-1
		::SetPixel(Round(nRow,1),round(nCol,1),nColor,nPen)
		nRow += nStepV
		nCol += nStepH
	Next
	
	// O ultimo ponto seta com as coordenadas informadas
	// Pode haver perda de precisao na aritmetica dos passos
	::SetPixel(L2,C2,nColor)

Return

// ---------------------------------------------------
// Desenha um c�rculo com o centro na coordenada informada

METHOD Circle(nL , nC , nRadius , nColor, nPen ) CLASS ZBITMAP
Local nRow , nCol
Local nAngle
Local nPoints
Local nStep
Local nI,nR

If nPen = NIL
	nPen := ::nPenSize
Endif

For nR := 1 to nPen
	// Seno e cosseno em Radianos
	// Faz o loop de 0 a 2*PI para calcular as coordenadas
	// dos pontos para desenhar o c�rculo
	nAngle := 0
	nPoints := 2 * PI * nRadius
	nStep   := (2*PI) / nPoints
	For nI := 0 to nPoints
		nRow := round(Sin(nAngle) * nRadius,1)
		nCol := round(Cos(nAngle) * nRadius,1)
		::SetPixel(nL-nRow,nC+nCol,nColor)
		nAngle += nStep
	Next
	nRadius--
Next

Return


METHOD SetBPP(nBPP) CLASS ZBITMAP

IF ::nBPP == 1 .and. nBPP == 4

	// Trocou de preto e branco para 16 cores 
	// Nao mexe em nada 
	
	::nBPP := 4
	
Endif

Return


STATIC Function GetColorTab(nBPP)
Local aColors := {}

If nBPP = 1
	
	aadd(aColors,{ 0   , 0   , 0   , 0 })  // 0  Black
	aadd(aColors,{ 255 , 255 , 255 , 0 })  // 15 White
	
ElseIf nBPP = 4
	
	// Paleta de Cores Padrao ( 16 cores )	// Azul Verde Vermelho Alpha ( BGRA - Blue , Green , Red , Alpha )
	
	aadd(aColors,{ 0   , 0   , 0   , 0 })  // 0  Black
	aadd(aColors,{ 0   , 0   , 128 , 0 })  // 1  Maroon
	aadd(aColors,{ 0   , 128 , 0   , 0 })  // 2  Green
	aadd(aColors,{ 0   , 128 , 128 , 0 })  // 3  Olive
	aadd(aColors,{ 128 , 0   , 0   , 0 })  // 4  Navy
	aadd(aColors,{ 128 , 0   , 128 , 0 })  // 5  Magenta or Purple
	aadd(aColors,{ 128 , 128 , 0   , 0 })  // 6  Teal
	aadd(aColors,{ 128 , 128 , 128 , 0 })  // 7  Gray
	aadd(aColors,{ 192 , 192 , 192 , 0 })  // 8  Silver
	aadd(aColors,{ 0   , 0   , 255 , 0 })  // 9  Red
	aadd(aColors,{ 0   , 255 , 0   , 0 })  // 10 Lime Green
	aadd(aColors,{ 0   , 255 , 255 , 0 })  // 11 Yelow
	aadd(aColors,{ 255 , 0   , 0   , 0 })  // 12 Blue
	aadd(aColors,{ 255 , 0   , 255 , 0 })  // 13 Fuchsia
	aadd(aColors,{ 255 , 255 , 0   , 0 })  // 14 Cyan or Aqua
	aadd(aColors,{ 255 , 255 , 255 , 0 })  // 15 White
	
ElseIf nBPP = 8
	
	// Paleta de Cores Padrao ( 256 cores )	

	aadd(aColors,{0,0,0,0})
	aadd(aColors,{0,0,128,0})
	aadd(aColors,{0,128,0,0})
	aadd(aColors,{0,128,128,0})
	aadd(aColors,{128,0,0,0})
	aadd(aColors,{128,0,128,0})
	aadd(aColors,{128,128,0,0})
	aadd(aColors,{192,192,192,0})
	aadd(aColors,{192,220,192,0})
	aadd(aColors,{240,202,166,0})
	aadd(aColors,{0,32,64,0})
	aadd(aColors,{0,32,96,0})
	aadd(aColors,{0,32,128,0})
	aadd(aColors,{0,32,160,0})
	aadd(aColors,{0,32,192,0})
	aadd(aColors,{0,32,224,0})
	aadd(aColors,{0,64,0,0})
	aadd(aColors,{0,64,32,0})
	aadd(aColors,{0,64,64,0})
	aadd(aColors,{0,64,96,0})
	aadd(aColors,{0,64,128,0})
	aadd(aColors,{0,64,160,0})
	aadd(aColors,{0,64,192,0})
	aadd(aColors,{0,64,224,0})
	aadd(aColors,{0,96,0,0})
	aadd(aColors,{0,96,32,0})
	aadd(aColors,{0,96,64,0})
	aadd(aColors,{0,96,96,0})
	aadd(aColors,{0,96,128,0})
	aadd(aColors,{0,96,160,0})
	aadd(aColors,{0,96,192,0})
	aadd(aColors,{0,96,224,0})
	aadd(aColors,{0,128,0,0})
	aadd(aColors,{0,128,32,0})
	aadd(aColors,{0,128,64,0})
	aadd(aColors,{0,128,96,0})
	aadd(aColors,{0,128,128,0})
	aadd(aColors,{0,128,160,0})
	aadd(aColors,{0,128,192,0})
	aadd(aColors,{0,128,224,0})
	aadd(aColors,{0,160,0,0})
	aadd(aColors,{0,160,32,0})
	aadd(aColors,{0,160,64,0})
	aadd(aColors,{0,160,96,0})
	aadd(aColors,{0,160,128,0})
	aadd(aColors,{0,160,160,0})
	aadd(aColors,{0,160,192,0})
	aadd(aColors,{0,160,224,0})
	aadd(aColors,{0,192,0,0})
	aadd(aColors,{0,192,32,0})
	aadd(aColors,{0,192,64,0})
	aadd(aColors,{0,192,96,0})
	aadd(aColors,{0,192,128,0})
	aadd(aColors,{0,192,160,0})
	aadd(aColors,{0,192,192,0})
	aadd(aColors,{0,192,224,0})
	aadd(aColors,{0,224,0,0})
	aadd(aColors,{0,224,32,0})
	aadd(aColors,{0,224,64,0})
	aadd(aColors,{0,224,96,0})
	aadd(aColors,{0,224,128,0})
	aadd(aColors,{0,224,160,0})
	aadd(aColors,{0,224,192,0})
	aadd(aColors,{0,224,224,0})
	aadd(aColors,{64,0,0,0})
	aadd(aColors,{64,0,32,0})
	aadd(aColors,{64,0,64,0})
	aadd(aColors,{64,0,96,0})
	aadd(aColors,{64,0,128,0})
	aadd(aColors,{64,0,160,0})
	aadd(aColors,{64,0,192,0})
	aadd(aColors,{64,0,224,0})
	aadd(aColors,{64,32,0,0})
	aadd(aColors,{64,32,32,0})
	aadd(aColors,{64,32,64,0})
	aadd(aColors,{64,32,96,0})
	aadd(aColors,{64,32,128,0})
	aadd(aColors,{64,32,160,0})
	aadd(aColors,{64,32,192,0})
	aadd(aColors,{64,32,224,0})
	aadd(aColors,{64,64,0,0})
	aadd(aColors,{64,64,32,0})
	aadd(aColors,{64,64,64,0})
	aadd(aColors,{64,64,96,0})
	aadd(aColors,{64,64,128,0})
	aadd(aColors,{64,64,160,0})
	aadd(aColors,{64,64,192,0})
	aadd(aColors,{64,64,224,0})
	aadd(aColors,{64,96,0,0})
	aadd(aColors,{64,96,32,0})
	aadd(aColors,{64,96,64,0})
	aadd(aColors,{64,96,96,0})
	aadd(aColors,{64,96,128,0})
	aadd(aColors,{64,96,160,0})
	aadd(aColors,{64,96,192,0})
	aadd(aColors,{64,96,224,0})
	aadd(aColors,{64,128,0,0})
	aadd(aColors,{64,128,32,0})
	aadd(aColors,{64,128,64,0})
	aadd(aColors,{64,128,96,0})
	aadd(aColors,{64,128,128,0})
	aadd(aColors,{64,128,160,0})
	aadd(aColors,{64,128,192,0})
	aadd(aColors,{64,128,224,0})
	aadd(aColors,{64,160,0,0})
	aadd(aColors,{64,160,32,0})
	aadd(aColors,{64,160,64,0})
	aadd(aColors,{64,160,96,0})
	aadd(aColors,{64,160,128,0})
	aadd(aColors,{64,160,160,0})
	aadd(aColors,{64,160,192,0})
	aadd(aColors,{64,160,224,0})
	aadd(aColors,{64,192,0,0})
	aadd(aColors,{64,192,32,0})
	aadd(aColors,{64,192,64,0})
	aadd(aColors,{64,192,96,0})
	aadd(aColors,{64,192,128,0})
	aadd(aColors,{64,192,160,0})
	aadd(aColors,{64,192,192,0})
	aadd(aColors,{64,192,224,0})
	aadd(aColors,{64,224,0,0})
	aadd(aColors,{64,224,32,0})
	aadd(aColors,{64,224,64,0})
	aadd(aColors,{64,224,96,0})
	aadd(aColors,{64,224,128,0})
	aadd(aColors,{64,224,160,0})
	aadd(aColors,{64,224,192,0})
	aadd(aColors,{64,224,224,0})
	aadd(aColors,{128,0,0,0})
	aadd(aColors,{128,0,32,0})
	aadd(aColors,{128,0,64,0})
	aadd(aColors,{128,0,96,0})
	aadd(aColors,{128,0,128,0})
	aadd(aColors,{128,0,160,0})
	aadd(aColors,{128,0,192,0})
	aadd(aColors,{128,0,224,0})
	aadd(aColors,{128,32,0,0})
	aadd(aColors,{128,32,32,0})
	aadd(aColors,{128,32,64,0})
	aadd(aColors,{128,32,96,0})
	aadd(aColors,{128,32,128,0})
	aadd(aColors,{128,32,160,0})
	aadd(aColors,{128,32,192,0})
	aadd(aColors,{128,32,224,0})
	aadd(aColors,{128,64,0,0})
	aadd(aColors,{128,64,32,0})
	aadd(aColors,{128,64,64,0})
	aadd(aColors,{128,64,96,0})
	aadd(aColors,{128,64,128,0})
	aadd(aColors,{128,64,160,0})
	aadd(aColors,{128,64,192,0})
	aadd(aColors,{128,64,224,0})
	aadd(aColors,{128,96,0,0})
	aadd(aColors,{128,96,32,0})
	aadd(aColors,{128,96,64,0})
	aadd(aColors,{128,96,96,0})
	aadd(aColors,{128,96,128,0})
	aadd(aColors,{128,96,160,0})
	aadd(aColors,{128,96,192,0})
	aadd(aColors,{128,96,224,0})
	aadd(aColors,{128,128,0,0})
	aadd(aColors,{128,128,32,0})
	aadd(aColors,{128,128,64,0})
	aadd(aColors,{128,128,96,0})
	aadd(aColors,{128,128,128,0})
	aadd(aColors,{128,128,160,0})
	aadd(aColors,{128,128,192,0})
	aadd(aColors,{128,128,224,0})
	aadd(aColors,{128,160,0,0})
	aadd(aColors,{128,160,32,0})
	aadd(aColors,{128,160,64,0})
	aadd(aColors,{128,160,96,0})
	aadd(aColors,{128,160,128,0})
	aadd(aColors,{128,160,160,0})
	aadd(aColors,{128,160,192,0})
	aadd(aColors,{128,160,224,0})
	aadd(aColors,{128,192,0,0})
	aadd(aColors,{128,192,32,0})
	aadd(aColors,{128,192,64,0})
	aadd(aColors,{128,192,96,0})
	aadd(aColors,{128,192,128,0})
	aadd(aColors,{128,192,160,0})
	aadd(aColors,{128,192,192,0})
	aadd(aColors,{128,192,224,0})
	aadd(aColors,{128,224,0,0})
	aadd(aColors,{128,224,32,0})
	aadd(aColors,{128,224,64,0})
	aadd(aColors,{128,224,96,0})
	aadd(aColors,{128,224,128,0})
	aadd(aColors,{128,224,160,0})
	aadd(aColors,{128,224,192,0})
	aadd(aColors,{128,224,224,0})
	aadd(aColors,{192,0,0,0})
	aadd(aColors,{192,0,32,0})
	aadd(aColors,{192,0,64,0})
	aadd(aColors,{192,0,96,0})
	aadd(aColors,{192,0,128,0})
	aadd(aColors,{192,0,160,0})
	aadd(aColors,{192,0,192,0})
	aadd(aColors,{192,0,224,0})
	aadd(aColors,{192,32,0,0})
	aadd(aColors,{192,32,32,0})
	aadd(aColors,{192,32,64,0})
	aadd(aColors,{192,32,96,0})
	aadd(aColors,{192,32,128,0})
	aadd(aColors,{192,32,160,0})
	aadd(aColors,{192,32,192,0})
	aadd(aColors,{192,32,224,0})
	aadd(aColors,{192,64,0,0})
	aadd(aColors,{192,64,32,0})
	aadd(aColors,{192,64,64,0})
	aadd(aColors,{192,64,96,0})
	aadd(aColors,{192,64,128,0})
	aadd(aColors,{192,64,160,0})
	aadd(aColors,{192,64,192,0})
	aadd(aColors,{192,64,224,0})
	aadd(aColors,{192,96,0,0})
	aadd(aColors,{192,96,32,0})
	aadd(aColors,{192,96,64,0})
	aadd(aColors,{192,96,96,0})
	aadd(aColors,{192,96,128,0})
	aadd(aColors,{192,96,160,0})
	aadd(aColors,{192,96,192,0})
	aadd(aColors,{192,96,224,0})
	aadd(aColors,{192,128,0,0})
	aadd(aColors,{192,128,32,0})
	aadd(aColors,{192,128,64,0})
	aadd(aColors,{192,128,96,0})
	aadd(aColors,{192,128,128,0})
	aadd(aColors,{192,128,160,0})
	aadd(aColors,{192,128,192,0})
	aadd(aColors,{192,128,224,0})
	aadd(aColors,{192,160,0,0})
	aadd(aColors,{192,160,32,0})
	aadd(aColors,{192,160,64,0})
	aadd(aColors,{192,160,96,0})
	aadd(aColors,{192,160,128,0})
	aadd(aColors,{192,160,160,0})
	aadd(aColors,{192,160,192,0})
	aadd(aColors,{192,160,224,0})
	aadd(aColors,{192,192,0,0})
	aadd(aColors,{192,192,32,0})
	aadd(aColors,{192,192,64,0})
	aadd(aColors,{192,192,96,0})
	aadd(aColors,{192,192,128,0})
	aadd(aColors,{192,192,160,0})
	aadd(aColors,{240,251,255,0})
	aadd(aColors,{164,160,160,0})
	aadd(aColors,{128,128,128,0})
	aadd(aColors,{0,0,255,0})
	aadd(aColors,{0,255,0,0})
	aadd(aColors,{0,255,255,0})
	aadd(aColors,{255,0,0,0})
	aadd(aColors,{255,0,255,0})
	aadd(aColors,{255,255,0,0})
	aadd(aColors,{255,255,255,0})

ElseIf nBPP = 24
	
	// Paleta de Cores Padrao ( 24 Bits True Color )	
	// NAO TEM TABELA DE CORES 
		
Endif

Return aColors

// Metodo de pintura 
// Dado um ponto e uma cor, todos os pontos ligados a ele
// na horizontal e vertical ser�o pintados, caso a cor de pintura
// seja diferente da cor do ponto, sendo apenas considerados 
// os pontos adjacentes com cor igual ao ponto original 

METHOD Paint(nL,nC,nColor)  CLASS ZBITMAP
Local aPaint := {}                   
Local nCurrent
Local nLNext, nCNext
Local nPL, nPC, nPColor

IF nColor = NIL 
	nColor := ::nFRColor
Endif

// Pega a cor do ponto atual 
nPColor := ::GetPixel(nL,nC)

aadd(aPaint,{nL,nC})

While len(aPaint) > 0 

	// Pega o primeiro ponto pendente
	nPL := aPaint[1][1]
	nPC := aPaint[1][2]

	// Remove das pendencias
	aDel(aPaint,1)
	aSize(aPaint,len(aPaint)-1)
	
	// Pega a cor desta coordenada
	nCurrent := ::GetPixel(nPL,nPC)
	
	If nCurrent <> nColor .and. nCurrent == nPColor

		// Se o ponto nao tem a cor final, e � da cor 
		// do ponto original, pinta ele 
		::SetPixel(nPL,nPC,nColor,1)      
		
		// ao pintar um ponto, seta os pontos adjacentes
		// como pendencias caso eles tambem precisem ser pintados
 
		// Ponto superior
		nLNext := nPL-1
		nCNext := nPC
		If nLNext >= 0 
			nCurrent := ::GetPixel(nLNext,nCNext)
			If nCurrent <> nColor .and. nCurrent == nPColor
				aadd(aPAint,{nLNext,nCNext}) 
			Endif
		Endif
		
		// Ponto inferior
		nLNext := nPL+1
		nCNext := nPC
		If nLNext < ::nHeight 
			nCurrent := ::GetPixel(nLNext,nCNext)
			If nCurrent <> nColor .and. nCurrent == nPColor
				aadd(aPaint,{nLNext,nCNext}) 
			Endif
		Endif

		// Ponto a direita
		nLNext := nPL
		nCNext := nPC+1
		If nLNext < ::nWidth
			nCurrent := ::GetPixel(nLNext,nCNext)
			If nCurrent <> nColor .and. nCurrent == nPColor
				aadd(aPaint,{nLNext,nCNext}) 
			Endif
		Endif

		// Ponto a esquerda
		nLNext := nPL
		nCNext := nPC-1
		If nLNext >= 0
			nCurrent := ::GetPixel(nLNext,nCNext)
			If nCurrent <> nColor .and. nCurrent == nPColor
				aadd(aPaint,{nLNext,nCNext}) 
			Endif
		Endif
		
	Endif

Enddo

Return

// Inverte horizontalmente uma �rea da imagem
// Ou a imagem inteira caso a �rea nao seja especificada
METHOD FlipH(L1,C1,L2,C2) CLASS ZBITMAP
Local nL  , nC            
Local nCol, nSwap
IF pCount() == 0
	// Faz flip horizontal da imagem inteira
	L1 := 0
	C1 := 0
	L2 := ::nHeight-1
	C2 := ::nWidth-1
Else
	// Valida coordenadas informados
	IF L1 < 0 .or. L1 >= ::nHeight
		::cError := "Invalid 1o Line -- Out Of Image Area"
		Return .F.
	ElseIF L2 < 0 .or. L2 >= ::nHeight
		::cError := "Invalid 2o Line -- Out Of Image Area"
		Return .F.
	ElseIf C1 < 0 .or. C1 >= ::nWidth
		::cError := "Invalid 1o Column -- Out Of Image Area"
		Return .F.
	ElseIf C2 < 0 .or. C2 >= ::nWidth
		::cError := "Invalid 2o Column -- Out Of Image Area"
		Return .F.
	ElseIf L1 > L2
		::cError := "Invalid Lines -- Order mismatch"
		Return .F.
	ElseIf C1 > C2
		::cError := "Invalid Columns -- Order mismatch"
		Return .F.
	Endif
Endif

For nL := L1+1 to L2+1
	nCol := C2+1
	For nC := C1 + 1 TO C1 + INT( ( C2-C1 ) / 2 ) + 1
		ZSWAP( ::aMatrix[nL][nC] , ::aMatrix[nL][nCol] , nSwap )
		nCol--
	Next
Next

Return .T. 

// Inverte verticalmente uma �rea da imagem
// Ou a imagem inteira caso a �rea nao seja especificada
METHOD FlipV(L1,C1,L2,C2) CLASS ZBITMAP
Local nL  , nC            
Local nRow, nSwap
IF pCount() == 0
	// Faz flip vertical da imagem inteira
	L1 := 0
	C1 := 0
	L2 := ::nHeight-1
	C2 := ::nWidth-1
Else
	// Valida coordenadas informados
	IF L1 < 0 .or. L1 >= ::nHeight
		::cError := "Invalid 1o Line -- Out Of Image Area"
		Return .F.
	ElseIF L2 < 0 .or. L2 >= ::nHeight
		::cError := "Invalid 2o Line -- Out Of Image Area"
		Return .F.
	ElseIf C1 < 0 .or. C1 >= ::nWidth
		::cError := "Invalid 1o Column -- Out Of Image Area"
		Return .F.
	ElseIf C2 < 0 .or. C2 >= ::nWidth
		::cError := "Invalid 2o Column -- Out Of Image Area"
		Return .F.
	ElseIf L1 > L2
		::cError := "Invalid Lines -- Order mismatch"
		Return .F.
	ElseIf C1 > C2
		::cError := "Invalid Columns -- Order mismatch"
		Return .F.
	Endif
Endif

// Troca os pontos da primeira linha com a ultima
// depois da segunda com a penultima 
// at� chegar na linha central da �rea a ser invertida      
nRow := L2+1
For nL := L1+1 to L1 + INT( ( L2-L1 ) / 2 ) + 1
	For nC := C1+1 to C2+1
		ZSWAP( ::aMatrix[nL][nC] , ::aMatrix[nRow][nC] , nSwap )
	Next
	nRow--
Next

Return .T. 

// ----------------------------------------------------
// Copia uma parte da imagem para a �rea interna 
// de transferencia e limpa a �rea da imagem

METHOD Cut(L1,C1,L2,C2)            CLASS ZBITMAP
::Copy(L1,C1,L2,C2)
::Clear(L1,C1,L2,C2)
Return .T. 

// ----------------------------------------------------
// Copia uma parte da imagem para a �rea interna de transferencia

METHOD Copy(L1,C1,L2,C2)           CLASS ZBITMAP
Local nL  , nC            
Local aRow := {}

IF pCount() == 0
	// Copia a imagem inteira para a area de transferencia
	::aClipBoard := aClone(::aMatrix)
    Return .T.
Endif

// Valida coordenadas informados
IF L1 < 0 .or. L1 >= ::nHeight
	::cError := "Invalid 1o Line -- Out Of Image Area"
	Return .F.
ElseIF L2 < 0 .or. L2 >= ::nHeight
	::cError := "Invalid 2o Line -- Out Of Image Area"
	Return .F.
ElseIf C1 < 0 .or. C1 >= ::nWidth
	::cError := "Invalid 1o Column -- Out Of Image Area"
	Return .F.
ElseIf C2 < 0 .or. C2 >= ::nWidth
	::cError := "Invalid 2o Column -- Out Of Image Area"
	Return .F.
ElseIf L1 > L2
	::cError := "Invalid Lines -- Order mismatch"
	Return .F.
ElseIf C1 > C2
	::cError := "Invalid Columns -- Order mismatch"
	Return .F.
Endif

::aClipBoard := {}

// Copia a �rea informada para a area de transferencia interna
For nL := L1+1 to L2+1
	For nC := C1+1 to C2+1
		aadd(aRow,::aMatrix[nL][nC])
	Next
	aadd(::aClipBoard,aClone(aRow))
	aSize(aRow,0)
Next

Return .T.

// ----------------------------------------------------
// Plota a imagem da area interna de transferencia na coordenada indicada

METHOD Paste(L1,C1)                CLASS ZBITMAP
Local nL , nC

// Valida a area de transferencis
If empty(::aClipBoard)
	::cError := "Empty Transfer Area"
	Return .F.
Endif

// Valida as cordenadas
IF L1 < 0 .or. L1 >= ::nHeight
	::cError := "Invalid Target Line -- Out Of Image Area"
	Return .F.
ElseIf C1 < 0 .or. C1 >= ::nWidth
	::cError := "Invalid Target Column -- Out Of Image Area"
	Return .F.
Endif
                       
// Plota a imagem da area de transferencia
// Validando as coordenadas de colagem caso 
// a imagem colada nas coordenadas saia 
// "fora" da �rea total da imagem 
For nL := 0 to len(::aClipBoard)-1
	IF L1+nL < ::nHeight
		For nC := 0 to len(::aClipBoard[nL+1])-1
			If C1+nC < ::nWidth
				::aMatrix[L1+nL+1][C1+nC+1] := ::aClipBoard[nL+1][nC+1]
			Else
				EXIT
			Endif
		Next
	Else
		EXIT
	Endif
Next

Return .T. 

// ----------------------------------------------
// Salva a imagem em disco como JPEG
// NA verdade, por hora salva um BMP em um arquivo 
// tempor�rio e converte para JPEG :D

METHOD SaveToJPG(cJpgFile)         CLASS ZBITMAP
Local cTmpFile := "\tmpbitmap.bmp"

If file(cTmpFile)
	Ferase(cTmpFile)
Endif

::SaveToBMP(cTmpFile)
nRet := BMPTOJPG(cTmpFile,cJpgFile)

Ferase(cTmpFile)

Return


// ---------------------------------------------------------------------
// Aumenta ou diminui o tamanho da imagem, horizontal e/ou verticalmente
// Valores informacos em percentual , base = 100 % , respectivamente 

METHOD Resize(nPctH, nPctV) CLASS ZBITMAP
Local nNewWidth
Local nNewHeight
Local nNewX := 1
Local nNewY := 1
Local nOldX
Local nOldY
Local nStepNewX 
Local nStepNewY
Local nStepOldX
Local nStepOldY
Local oNewBMP

If nPctH = 100 .and. nPctV = 100 
	Return .T.
Endif

nNewWidth := ::nWidth * (nPctH / 100) 
nNewHeight := ::nHeight * (nPctV / 100) 

nStepOldX := ::nWidth / nNewWidth 
nStepNewX := 1

nStepOldY := ::nHeight / nNewHeight 
nStepNewY := 1

oNewBMP := zBitmap():New( nNewWidth , nNewHeight , ::nBPP )

nNewX := 1
nNewY := 1
nOldX := 1 
nOldY := 1 

While int(nOldY) <= ::nHeight .and. int(nNewY) <= nNewHeight
	nOldX := 1
	nNewX := 1
	While int(nOldX) <= ::nWidth .and. int(nNewX) <= nNewWidth
		oNewBMP:aMatrix[nNewY][nNewX] := ::aMatrix[nOldY][nOldX]		
		nOldX += nStepOldX
		nNewX += nStepNewX
	Enddo
	nOldY += nStepOldY
	nNewY += nStepNewY
Enddo

::nFileSize     := oNewBMP:nFileSize
::nHeight       := oNewBMP:nHeight
::nWidth        := oNewBMP:nWidth
::aMatrix       := aClone(oNewBMP:aMatrix)
::aClipBoard    := aClone(oNewBMP:aClipBoard)
::aColors       := aClone(oNewBMP:aColors)
::cFormat       := oNewBMP:cFormat
::nOffSet       := oNewBMP:nOffSet
::nRawData      := oNewBMP:nRawData
::nRowSize      := oNewBMP:nRowSize
::nHeadSize     := oNewBMP:nHeadSize
::nCompress     := oNewBMP:nCompress
::nColorPlanes  := oNewBMP:nColorPlanes
::nHRes         := oNewBMP:nHRes
::nVRes         := oNewBMP:nVRes
::nColorPal     := oNewBMP:nColorPal
::nImpColors    := oNewBMP:nImpColors
::nFRColor      := oNewBMP:nFRColor
::nBgColor      := oNewBMP:nBgColor

freeobj(oNewBMP)

Return .T. 

Method SetTransparent(lSet) CLASS ZBITMAP
::lTransparent := lSet
Return

// Converte uma cor de decimal para RGB
// ( <nRed> + ( <nGreen> * 256 ) + ( <nBlue> * 65536 ) )

Static Function RGB2Dec(nColor,nRed,nGreen,nBlue)
Local cBitColor := padl(NTOBITS(nColor),24,'0')
BIT8TON(substr(cBitColor,1,8),@nBlue)
BIT8TON(substr(cBitColor,9,8),@nGreen)
BIT8TON(substr(cBitColor,17,8),@nRed)
Return


// PNG
// C�lculo de CRC dos Chunks do PNG 
// Tabela pr�-calculada para gera��o do CRC

STATIC aCRCTable := CRCTable()

STATIC Function CRCTable()
Local aTable := {}
Local nI, nJ , C
For nI := 0 to 255
	C := nI
	For nJ := 0 to 7
		IF nAnd(C,1)
			C := nXor( 3988292384 , Int( C / 2 ) )
		Else 
			C := Int( C / 2 )
		Endif
	Next
	aadd(aTable,C)
Next
Return aTable

// PNG
// C�lculo do CRC sobre um buffer ( Type + Data ) 

STATIC Function PNGCRC(cBuffer)
Local C := 4294967295 // 0xFFFFFFFF
Local nI , nIndex

For nI := 1 to len(cBuffer)
	nASC := asc(substr(cBuffer,nI,1))
	nIndex := nAnd ( nXor( C , nASC ) , 255 ) // oxFF
	C := nXor ( aCRCTable[nIndex+1] , INT( C / 256)  )  // C >> 8 
Next

Return nXor( C , 4294967295 ) // 0xFFFFFFFF


STATIC Function PNGSaveChunk(nH , cType,cData)
Local nSize :=  len(cData)
Local nCRC := PNGCRC(cType+cData)
fWrite( nH , nToBin4(nSize) + cType + cData + nToBin4(nCRC) )
Return


