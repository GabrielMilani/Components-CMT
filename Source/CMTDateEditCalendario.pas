unit CMTDateEditCalendario;

// Calendario proprio do TCMTDateEdit e os desenhos com suavizacao usados pelo campo.
// E uma janela popup que nunca recebe o foco (como a lista de um combo): o foco fica
// no campo, que repassa as teclas, e a captura do mouse detecta o clique fora.

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics;

const
  COR_DESTAQUE_CAMPO = TColor($00F08C3B); // #3B8CF0, o azul de destaque do tema

type
  TCMTCalendarioEscolha = procedure(Sender: TObject; const AData: TDate) of object;

  TCMTCalendarioArea = (caNada, caMesAnterior, caMesSeguinte, caTitulo, caCelula, caHoje, caLimpar);

  // O titulo sobe de dias para meses e de meses para anos; escolher uma celula desce.
  TCMTCalendarioVisao = (cvDias, cvMeses, cvAnos);

  TCMTCalendarioPopup = class(TCustomControl)
  private
    FAberto: Boolean;
    FTemaEscuro: Boolean;
    FVisao: TCMTCalendarioVisao;
    FMes: TDateTime;
    FSelecionada: TDateTime;
    FHoje: TDateTime;
    FAreaSobMouse: TCMTCalendarioArea;
    FDataSobMouse: TDateTime;
    FOnEscolher: TCMTCalendarioEscolha;
    FOnLimpar: TNotifyEvent;
    FOnFechar: TNotifyEvent;

    function Escala(const AValor: Integer): Integer;
    function RetanguloMesAnterior: TRect;
    function RetanguloMesSeguinte: TRect;
    function RetanguloTitulo: TRect;
    function RetanguloDia(const AIndice: Integer): TRect;
    function RetanguloMesOuAno(const AIndice: Integer): TRect;
    function DataDaCelula(const AIndice: Integer): TDateTime;
    function RetanguloHoje: TRect;
    function RetanguloLimpar: TRect;
    function AreaEm(const AX, AY: Integer; out AData: TDateTime): TCMTCalendarioArea;

    procedure Escolher(const AData: TDateTime);
    procedure MudarPagina(const ADirecao: Integer);
    procedure MudarVisao(const AVisao: TCMTCalendarioVisao);
    procedure MoverSelecao(const ADias: Integer);
    procedure EscreverCentralizado(ARect: TRect; AText: string);

    procedure WMMouseActivate(var Message: TWMMouseActivate); message WM_MOUSEACTIVATE;
    procedure WMCaptureChanged(var Message: TMessage); message WM_CAPTURECHANGED;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // AAreaCampo em coordenadas de tela: abre abaixo dela, ou acima se nao couber.
    procedure Abrir(const AData, AHoje: TDateTime; const ATemaEscuro: Boolean; const AAreaCampo: TRect);
    procedure Fechar;
    // Verdadeiro quando a tecla pertence ao calendario e nao deve seguir para o campo.
    function TratarTecla(const ATecla: Word): Boolean;

    property Aberto: Boolean read FAberto;
    property OnEscolher: TCMTCalendarioEscolha read FOnEscolher write FOnEscolher;
    property OnLimpar: TNotifyEvent read FOnLimpar write FOnLimpar;
    property OnFechar: TNotifyEvent read FOnFechar write FOnFechar;
  end;

function BrilhoCor(const ACor: TColor): Integer;
function MesclarCores(const ACor, AFundo: TColor; const APercentual: Integer): TColor;

// clNone em AFundo ou ABorda deixa de preencher ou de contornar.
procedure DesenharRetanguloArredondado(const ACanvas: TCanvas; const ARect: TRect;
  const ARaio: Integer; const AFundo, ABorda: TColor; const AEspessura: Single);
// ACoordenadas em grupos de quatro: x1, y1, x2, y2 de cada traco.
procedure DesenharLinhas(const ACanvas: TCanvas; const ACor: TColor; const AEspessura: Single;
  const ACoordenadas: array of Single);
procedure DesenharIconeCalendario(const ACanvas: TCanvas; const ARect: TRect;
  const ACor: TColor; const AEscala: Single);

implementation

uses
  System.SysUtils, System.DateUtils, Vcl.Forms, Winapi.Dwmapi,
  Winapi.GDIPAPI, Winapi.GDIPOBJ, CMTDateEditRegras;

const
  // Medidas a 96 DPI
  LARGURA_CALENDARIO = 262;
  ALTURA_CALENDARIO = 308;
  MARGEM = 10;
  TOPO_SEMANA = 45;
  ALTURA_SEMANA = 22;
  TOPO_DIAS = 67;
  ALTURA_DIA = 32;
  TAMANHO_SETA = 26;
  TOPO_RODAPE = 272;
  ALTURA_RODAPE = 26;
  LARGURA_BOTAO_HOJE = 56;
  LARGURA_BOTAO_LIMPAR = 60;

  COLUNAS = 7;
  QUANTIDADE_DIAS = 42;

  // Grade de meses e de anos, no mesmo espaco da semana mais os dias
  COLUNAS_MES_ANO = 3;
  LINHAS_MES_ANO = 4;
  QUANTIDADE_MES_ANO = 12;
  ALTURA_GRADE_MES_ANO = ALTURA_SEMANA + 6 * ALTURA_DIA;
  MESES_POR_ANO = 12;
  ANO_MINIMO = 1900;

  LETRAS_SEMANA: array[0..COLUNAS - 1] of string = ('D', 'S', 'T', 'Q', 'Q', 'S', 'S');

function ParaCorGdi(const ACor: TColor): ARGB;
var
  vCor: DWORD;
begin
  vCor := DWORD(ColorToRGB(ACor));
  Result := MakeColor(255, GetRValue(vCor), GetGValue(vCor), GetBValue(vCor));
end;

function IfThenCor(const ACondicao: Boolean; const ACorVerdadeira, ACorFalsa: TColor): TColor;
begin
  if ACondicao then
    Result := ACorVerdadeira
  else
    Result := ACorFalsa;
end;

function BrilhoCor(const ACor: TColor): Integer;
var
  vCor: DWORD;
begin
  vCor := DWORD(ColorToRGB(ACor));
  Result := (GetRValue(vCor) * 299 + GetGValue(vCor) * 587 + GetBValue(vCor) * 114) div 1000;
end;

function MesclarCores(const ACor, AFundo: TColor; const APercentual: Integer): TColor;
var
  vCor, vFundo: DWORD;
begin
  vCor := DWORD(ColorToRGB(ACor));
  vFundo := DWORD(ColorToRGB(AFundo));
  Result := TColor(RGB(
    (GetRValue(vCor) * APercentual + GetRValue(vFundo) * (100 - APercentual)) div 100,
    (GetGValue(vCor) * APercentual + GetGValue(vFundo) * (100 - APercentual)) div 100,
    (GetBValue(vCor) * APercentual + GetBValue(vFundo) * (100 - APercentual)) div 100));
end;

procedure DesenharRetanguloArredondado(const ACanvas: TCanvas; const ARect: TRect;
  const ARaio: Integer; const AFundo, ABorda: TColor; const AEspessura: Single);
var
  vGrafico: TGPGraphics;
  vCaminho: TGPGraphicsPath;
  vPincel: TGPSolidBrush;
  vCaneta: TGPPen;
  vRecuo, vEsquerda, vTopo, vDireita, vBase, vDiametro: Single;
begin
  // A caneta e centrada na linha: recua para a borda inteira ficar dentro do retangulo
  vRecuo := AEspessura / 2;
  vEsquerda := ARect.Left + vRecuo;
  vTopo := ARect.Top + vRecuo;
  vDireita := ARect.Right - vRecuo;
  vBase := ARect.Bottom - vRecuo;
  vDiametro := ARaio * 2;

  vGrafico := TGPGraphics.Create(ACanvas.Handle);
  vCaminho := TGPGraphicsPath.Create;
  try
    vGrafico.SetSmoothingMode(SmoothingModeAntiAlias);

    vCaminho.AddArc(vEsquerda, vTopo, vDiametro, vDiametro, 180, 90);
    vCaminho.AddArc(vDireita - vDiametro, vTopo, vDiametro, vDiametro, 270, 90);
    vCaminho.AddArc(vDireita - vDiametro, vBase - vDiametro, vDiametro, vDiametro, 0, 90);
    vCaminho.AddArc(vEsquerda, vBase - vDiametro, vDiametro, vDiametro, 90, 90);
    vCaminho.CloseFigure;

    if AFundo <> clNone then
    begin
      vPincel := TGPSolidBrush.Create(ParaCorGdi(AFundo));
      try
        vGrafico.FillPath(vPincel, vCaminho);
      finally
        vPincel.Free;
      end;
    end;

    if ABorda <> clNone then
    begin
      vCaneta := TGPPen.Create(ParaCorGdi(ABorda), AEspessura);
      try
        vGrafico.DrawPath(vCaneta, vCaminho);
      finally
        vCaneta.Free;
      end;
    end;
  finally
    vCaminho.Free;
    vGrafico.Free;
  end;
end;

procedure DesenharLinhas(const ACanvas: TCanvas; const ACor: TColor; const AEspessura: Single;
  const ACoordenadas: array of Single);
var
  vGrafico: TGPGraphics;
  vCaneta: TGPPen;
  vIndice: Integer;
begin
  vGrafico := TGPGraphics.Create(ACanvas.Handle);
  vCaneta := TGPPen.Create(ParaCorGdi(ACor), AEspessura);
  try
    vGrafico.SetSmoothingMode(SmoothingModeAntiAlias);
    vCaneta.SetLineCap(LineCapRound, LineCapRound, DashCapRound);

    vIndice := 0;
    while vIndice + 3 <= High(ACoordenadas) do
    begin
      vGrafico.DrawLine(vCaneta, ACoordenadas[vIndice], ACoordenadas[vIndice + 1],
        ACoordenadas[vIndice + 2], ACoordenadas[vIndice + 3]);
      Inc(vIndice, 4);
    end;
  finally
    vCaneta.Free;
    vGrafico.Free;
  end;
end;

procedure DesenharIconeCalendario(const ACanvas: TCanvas; const ARect: TRect;
  const ACor: TColor; const AEscala: Single);
var
  vEsquerda, vTopo: Single;
  vCorpo: TRect;
begin
  // Icone de 17 x 17 centrado em ARect
  vEsquerda := (ARect.Left + ARect.Right - 17 * AEscala) / 2;
  vTopo := (ARect.Top + ARect.Bottom - 17 * AEscala) / 2;

  vCorpo := Rect(Round(vEsquerda + 2 * AEscala), Round(vTopo + 3 * AEscala),
    Round(vEsquerda + 15 * AEscala), Round(vTopo + 15 * AEscala));
  DesenharRetanguloArredondado(ACanvas, vCorpo, Round(2 * AEscala), clNone, ACor, 1.4 * AEscala);

  DesenharLinhas(ACanvas, ACor, 1.4 * AEscala, [
    vEsquerda + 2 * AEscala, vTopo + 7 * AEscala, vEsquerda + 15 * AEscala, vTopo + 7 * AEscala,
    vEsquerda + 5.4 * AEscala, vTopo + 1.5 * AEscala, vEsquerda + 5.4 * AEscala, vTopo + 4.5 * AEscala,
    vEsquerda + 11.6 * AEscala, vTopo + 1.5 * AEscala, vEsquerda + 11.6 * AEscala, vTopo + 4.5 * AEscala]);
end;

{ TCMTCalendarioPopup }

constructor TCMTCalendarioPopup.Create(AOwner: TComponent);
begin
  inherited;
  // Sem csCaptureMouse: a captura e mantida aqui, a VCL nao pode solta-la a cada clique
  ControlStyle := [csOpaque, csNoDesignVisible];
  Visible := False;
  DoubleBuffered := True;
end;

destructor TCMTCalendarioPopup.Destroy;
begin
  // A janela solta a captura ao ser destruida, quando o campo dono ja esta indo embora
  FAberto := False;
  inherited;
end;

procedure TCMTCalendarioPopup.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := WS_POPUP;
  Params.ExStyle := WS_EX_TOOLWINDOW;
  Params.WindowClass.Style := CS_DROPSHADOW;
end;

procedure TCMTCalendarioPopup.CreateWnd;
var
  vCantos: Integer;
begin
  inherited;
  // Windows 11 arredonda os cantos; nas versoes anteriores o pedido e ignorado
  vCantos := DWMWCP_ROUND;
  DwmSetWindowAttribute(Handle, DWMWA_WINDOW_CORNER_PREFERENCE, @vCantos, SizeOf(vCantos));
end;

function TCMTCalendarioPopup.Escala(const AValor: Integer): Integer;
begin
  Result := Parent.ScaleValue(AValor);
end;

procedure TCMTCalendarioPopup.Abrir(const AData, AHoje: TDateTime; const ATemaEscuro: Boolean;
  const AAreaCampo: TRect);
var
  vTela: TRect;
  vEsquerda, vTopo: Integer;
begin
  FHoje := Trunc(AHoje);
  FSelecionada := Trunc(AData);
  FMes := StartOfTheMonth(DataInicialCalendario(FSelecionada, FHoje));
  FTemaEscuro := ATemaEscuro;
  FVisao := cvDias;
  FAreaSobMouse := caNada;

  HandleNeeded;
  SetBounds(0, 0, Escala(LARGURA_CALENDARIO), Escala(ALTURA_CALENDARIO));

  vTela := Screen.MonitorFromRect(AAreaCampo).WorkareaRect;
  vEsquerda := AAreaCampo.Left;
  if vEsquerda + Width > vTela.Right then
    vEsquerda := vTela.Right - Width;
  vTopo := AAreaCampo.Bottom + Escala(2);
  if vTopo + Height > vTela.Bottom then
    vTopo := AAreaCampo.Top - Height - Escala(2);

  SetWindowPos(Handle, HWND_TOP, vEsquerda, vTopo, 0, 0,
    SWP_NOSIZE or SWP_NOACTIVATE or SWP_SHOWWINDOW);
  Invalidate;

  FAberto := True;
  SetCapture(Handle);
end;

procedure TCMTCalendarioPopup.Fechar;
begin
  if not FAberto then
    Exit;

  FAberto := False;
  if GetCapture = Handle then
    ReleaseCapture;
  SetWindowPos(Handle, 0, 0, 0, 0, 0,
    SWP_NOZORDER or SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_HIDEWINDOW);

  if Assigned(FOnFechar) then
    FOnFechar(Self);
end;

procedure TCMTCalendarioPopup.Escolher(const AData: TDateTime);
begin
  // Fecha antes: a tela pode pesquisar ou abrir um dialogo ao saber da nova data
  Fechar;
  if Assigned(FOnEscolher) then
    FOnEscolher(Self, AData);
end;

procedure TCMTCalendarioPopup.MudarPagina(const ADirecao: Integer);
var
  vNovoMes: TDateTime;
begin
  case FVisao of
    cvDias:
      vNovoMes := IncMonth(FMes, ADirecao);
    cvMeses:
      vNovoMes := IncMonth(FMes, ADirecao * MESES_POR_ANO);
  else
    vNovoMes := IncMonth(FMes, ADirecao * MESES_POR_ANO * QUANTIDADE_MES_ANO);
  end;

  if YearOf(vNovoMes) < ANO_MINIMO then
    Exit;

  FMes := vNovoMes;
  Invalidate;
end;

procedure TCMTCalendarioPopup.MudarVisao(const AVisao: TCMTCalendarioVisao);
begin
  FVisao := AVisao;
  FAreaSobMouse := caNada;
  Invalidate;
end;

procedure TCMTCalendarioPopup.MoverSelecao(const ADias: Integer);
begin
  if FSelecionada <= 0 then
    FSelecionada := FHoje
  else
    FSelecionada := FSelecionada + ADias;

  FMes := StartOfTheMonth(FSelecionada);
  FVisao := cvDias;
  Invalidate;
end;

function TCMTCalendarioPopup.TratarTecla(const ATecla: Word): Boolean;
begin
  Result := True;
  case ATecla of
    VK_ESCAPE:
      Fechar;
    VK_RETURN:
      Escolher(DataInicialCalendario(FSelecionada, FHoje));
    VK_LEFT:
      MoverSelecao(-1);
    VK_RIGHT:
      MoverSelecao(1);
    VK_UP:
      MoverSelecao(-7);
    VK_DOWN:
      MoverSelecao(7);
    VK_PRIOR:
      MudarPagina(-1);
    VK_NEXT:
      MudarPagina(1);
    VK_SHIFT, VK_CONTROL, VK_MENU:
      ; // sozinhas nao fecham o calendario
  else
    Result := False;
  end;
end;

procedure TCMTCalendarioPopup.WMMouseActivate(var Message: TWMMouseActivate);
begin
  Message.Result := MA_NOACTIVATE;
end;

procedure TCMTCalendarioPopup.WMCaptureChanged(var Message: TMessage);
begin
  inherited;
  // Outro programa ou um dialogo tomou o mouse
  Fechar;
end;

function TCMTCalendarioPopup.RetanguloMesAnterior: TRect;
begin
  Result := Rect(Escala(MARGEM), Escala(MARGEM), Escala(MARGEM + TAMANHO_SETA), Escala(MARGEM + TAMANHO_SETA));
end;

function TCMTCalendarioPopup.RetanguloMesSeguinte: TRect;
begin
  Result := Rect(Escala(LARGURA_CALENDARIO - MARGEM - TAMANHO_SETA), Escala(MARGEM),
    Escala(LARGURA_CALENDARIO - MARGEM), Escala(MARGEM + TAMANHO_SETA));
end;

function TCMTCalendarioPopup.RetanguloTitulo: TRect;
begin
  Result := Rect(Escala(MARGEM + TAMANHO_SETA), Escala(MARGEM),
    Escala(LARGURA_CALENDARIO - MARGEM - TAMANHO_SETA), Escala(MARGEM + TAMANHO_SETA));
end;

function TCMTCalendarioPopup.RetanguloMesOuAno(const AIndice: Integer): TRect;
var
  vLarguraUtil, vColuna, vLinha: Integer;
begin
  vLarguraUtil := LARGURA_CALENDARIO - 2 * MARGEM;
  vColuna := AIndice mod COLUNAS_MES_ANO;
  vLinha := AIndice div COLUNAS_MES_ANO;
  Result := Rect(Escala(MARGEM + vLarguraUtil * vColuna div COLUNAS_MES_ANO),
    Escala(TOPO_SEMANA + ALTURA_GRADE_MES_ANO * vLinha div LINHAS_MES_ANO),
    Escala(MARGEM + vLarguraUtil * (vColuna + 1) div COLUNAS_MES_ANO),
    Escala(TOPO_SEMANA + ALTURA_GRADE_MES_ANO * (vLinha + 1) div LINHAS_MES_ANO));
end;

function TCMTCalendarioPopup.DataDaCelula(const AIndice: Integer): TDateTime;
begin
  case FVisao of
    cvDias:
      Result := PrimeiraDataDaGrade(FMes) + AIndice;
    cvMeses:
      Result := EncodeDate(YearOf(FMes), AIndice + 1, 1);
  else
    Result := EncodeDate(PrimeiroAnoDaPagina(YearOf(FMes)) + AIndice, MonthOf(FMes), 1);
  end;
end;

function TCMTCalendarioPopup.RetanguloDia(const AIndice: Integer): TRect;
var
  vLarguraUtil, vColuna, vLinha: Integer;
begin
  vLarguraUtil := LARGURA_CALENDARIO - 2 * MARGEM;
  vColuna := AIndice mod COLUNAS;
  vLinha := AIndice div COLUNAS;
  Result := Rect(Escala(MARGEM + vLarguraUtil * vColuna div COLUNAS),
    Escala(TOPO_DIAS + ALTURA_DIA * vLinha),
    Escala(MARGEM + vLarguraUtil * (vColuna + 1) div COLUNAS),
    Escala(TOPO_DIAS + ALTURA_DIA * (vLinha + 1)));
end;

function TCMTCalendarioPopup.RetanguloHoje: TRect;
begin
  Result := Rect(Escala(MARGEM), Escala(TOPO_RODAPE), Escala(MARGEM + LARGURA_BOTAO_HOJE),
    Escala(TOPO_RODAPE + ALTURA_RODAPE));
end;

function TCMTCalendarioPopup.RetanguloLimpar: TRect;
begin
  Result := Rect(Escala(LARGURA_CALENDARIO - MARGEM - LARGURA_BOTAO_LIMPAR), Escala(TOPO_RODAPE),
    Escala(LARGURA_CALENDARIO - MARGEM), Escala(TOPO_RODAPE + ALTURA_RODAPE));
end;

function TCMTCalendarioPopup.AreaEm(const AX, AY: Integer; out AData: TDateTime): TCMTCalendarioArea;
var
  vPonto: TPoint;
  vIndice: Integer;
begin
  AData := 0;
  vPonto := Point(AX, AY);

  if PtInRect(RetanguloMesAnterior, vPonto) then
    Exit(caMesAnterior);
  if PtInRect(RetanguloMesSeguinte, vPonto) then
    Exit(caMesSeguinte);
  if PtInRect(RetanguloHoje, vPonto) then
    Exit(caHoje);
  if PtInRect(RetanguloLimpar, vPonto) then
    Exit(caLimpar);

  if (FVisao <> cvAnos) and PtInRect(RetanguloTitulo, vPonto) then
    Exit(caTitulo);

  if FVisao = cvDias then
  begin
    for vIndice := 0 to QUANTIDADE_DIAS - 1 do
      if PtInRect(RetanguloDia(vIndice), vPonto) then
      begin
        AData := DataDaCelula(vIndice);
        Exit(caCelula);
      end;
  end
  else
    for vIndice := 0 to QUANTIDADE_MES_ANO - 1 do
      if PtInRect(RetanguloMesOuAno(vIndice), vPonto) then
      begin
        AData := DataDaCelula(vIndice);
        Exit(caCelula);
      end;

  Result := caNada;
end;

procedure TCMTCalendarioPopup.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vData: TDateTime;
  vArea: TCMTCalendarioArea;
begin
  inherited;
  vArea := AreaEm(X, Y, vData);
  if (vArea <> FAreaSobMouse) or (vData <> FDataSobMouse) then
  begin
    FAreaSobMouse := vArea;
    FDataSobMouse := vData;
    Invalidate;
  end;
end;

procedure TCMTCalendarioPopup.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vData: TDateTime;
begin
  inherited;

  // Clique fora do calendario so fecha, como o calendario do Windows
  if not PtInRect(ClientRect, Point(X, Y)) then
  begin
    Fechar;
    Exit;
  end;

  if Button <> mbLeft then
    Exit;

  case AreaEm(X, Y, vData) of
    caMesAnterior:
      MudarPagina(-1);
    caMesSeguinte:
      MudarPagina(1);
    caTitulo:
      if FVisao = cvDias then
        MudarVisao(cvMeses)
      else
        MudarVisao(cvAnos);
    caCelula:
      case FVisao of
        cvDias:
          Escolher(vData);
        cvMeses:
          begin
            FMes := vData;
            MudarVisao(cvDias);
          end;
        cvAnos:
          begin
            FMes := vData;
            MudarVisao(cvMeses);
          end;
      end;
    caHoje:
      Escolher(FHoje);
    caLimpar:
      begin
        Fechar;
        if Assigned(FOnLimpar) then
          FOnLimpar(Self);
      end;
  end;
end;

procedure TCMTCalendarioPopup.EscreverCentralizado(ARect: TRect; AText: string);
begin
  Canvas.Brush.Style := bsClear;
  Canvas.TextRect(ARect, AText, [tfCenter, tfVerticalCenter, tfSingleLine]);
end;

procedure TCMTCalendarioPopup.Paint;
const
  RAIO_DIA = 4;
var
  vFundo, vBorda, vTexto, vApagado, vSobMouse: TColor;
  vEscala, vCentroX, vCentroY: Single;
  vPrimeira, vData: TDateTime;
  vIndice, vPrimeiroAno: Integer;
  vRect: TRect;
  vTitulo: string;

  procedure DesenharCelula(ARect: TRect; const AText: string; const ASelecionada, AAtual, ASobMouse, AApagada: Boolean);
  var
    vFundoCelula, vContorno: TColor;
  begin
    InflateRect(ARect, -Escala(1), -Escala(1));

    vFundoCelula := clNone;
    vContorno := clNone;
    if ASelecionada then
      vFundoCelula := COR_DESTAQUE_CAMPO
    else if ASobMouse then
      vFundoCelula := vSobMouse;
    if AAtual then
      vContorno := COR_DESTAQUE_CAMPO;

    if (vFundoCelula <> clNone) or (vContorno <> clNone) then
      DesenharRetanguloArredondado(Canvas, ARect, Escala(RAIO_DIA), vFundoCelula, vContorno, vEscala);

    if ASelecionada then
      Canvas.Font.Color := clWhite
    else if AApagada then
      Canvas.Font.Color := vApagado
    else
      Canvas.Font.Color := vTexto;

    if AAtual then
      Canvas.Font.Style := [fsBold]
    else
      Canvas.Font.Style := [];

    EscreverCentralizado(ARect, AText);
  end;

begin
  if FTemaEscuro then
  begin
    vFundo := TColor($00363636);
    vBorda := TColor($004C4C4C);
    vTexto := TColor($00E5E5E5);
    vApagado := TColor($00A0A0A0);
    vSobMouse := TColor($00484848);
  end
  else
  begin
    vFundo := clWhite;
    vBorda := TColor($00D0D0D0);
    vTexto := TColor($00262626);
    vApagado := TColor($00808080);
    vSobMouse := TColor($00ECECEC);
  end;

  vEscala := Escala(100) / 100;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := vFundo;
  Canvas.FillRect(ClientRect);
  Canvas.Pen.Color := vBorda;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(ClientRect);

  Canvas.Font.Name := 'Segoe UI';

  // ===== Cabecalho: mes e setas =====
  vRect := RetanguloMesAnterior;
  DesenharRetanguloArredondado(Canvas, vRect, Escala(RAIO_DIA),
    IfThenCor(FAreaSobMouse = caMesAnterior, MesclarCores(vTexto, vSobMouse, 15), vSobMouse), clNone, 0);
  vCentroX := (vRect.Left + vRect.Right) / 2;
  vCentroY := (vRect.Top + vRect.Bottom) / 2;
  DesenharLinhas(Canvas, vTexto, 1.5 * vEscala, [
    vCentroX + 2 * vEscala, vCentroY - 4 * vEscala, vCentroX - 2 * vEscala, vCentroY,
    vCentroX - 2 * vEscala, vCentroY, vCentroX + 2 * vEscala, vCentroY + 4 * vEscala]);

  vRect := RetanguloMesSeguinte;
  DesenharRetanguloArredondado(Canvas, vRect, Escala(RAIO_DIA),
    IfThenCor(FAreaSobMouse = caMesSeguinte, MesclarCores(vTexto, vSobMouse, 15), vSobMouse), clNone, 0);
  vCentroX := (vRect.Left + vRect.Right) / 2;
  vCentroY := (vRect.Top + vRect.Bottom) / 2;
  DesenharLinhas(Canvas, vTexto, 1.5 * vEscala, [
    vCentroX - 2 * vEscala, vCentroY - 4 * vEscala, vCentroX + 2 * vEscala, vCentroY,
    vCentroX + 2 * vEscala, vCentroY, vCentroX - 2 * vEscala, vCentroY + 4 * vEscala]);

  case FVisao of
    cvDias:
      vTitulo := NomeMesAno(FMes);
    cvMeses:
      vTitulo := IntToStr(YearOf(FMes));
  else
    vPrimeiroAno := PrimeiroAnoDaPagina(YearOf(FMes));
    vTitulo := IntToStr(vPrimeiroAno) + ' - ' + IntToStr(vPrimeiroAno + QUANTIDADE_MES_ANO - 1);
  end;

  if FAreaSobMouse = caTitulo then
    DesenharRetanguloArredondado(Canvas, RetanguloTitulo, Escala(RAIO_DIA), vSobMouse, clNone, 0);

  Canvas.Font.Height := -Escala(14);
  Canvas.Font.Style := [fsBold];
  Canvas.Font.Color := vTexto;
  EscreverCentralizado(RetanguloTitulo, vTitulo);

  // A setinha ao lado do titulo mostra que ele abre a grade de meses e de anos
  if FVisao <> cvAnos then
  begin
    vRect := RetanguloTitulo;
    vCentroX := (vRect.Left + vRect.Right + Canvas.TextWidth(vTitulo)) / 2 + 8 * vEscala;
    vCentroY := (vRect.Top + vRect.Bottom) / 2;
    DesenharLinhas(Canvas, vTexto, 1.3 * vEscala, [
      vCentroX - 3 * vEscala, vCentroY - 1.5 * vEscala, vCentroX, vCentroY + 1.5 * vEscala,
      vCentroX, vCentroY + 1.5 * vEscala, vCentroX + 3 * vEscala, vCentroY - 1.5 * vEscala]);
  end;

  if FVisao = cvDias then
  begin
    // ===== Dias da semana =====
    Canvas.Font.Height := -Escala(11);
    Canvas.Font.Color := vApagado;
    for vIndice := 0 to COLUNAS - 1 do
    begin
      vRect := RetanguloDia(vIndice);
      vRect.Top := Escala(TOPO_SEMANA);
      vRect.Bottom := Escala(TOPO_SEMANA + ALTURA_SEMANA);
      EscreverCentralizado(vRect, LETRAS_SEMANA[vIndice]);
    end;

    // ===== Dias =====
    Canvas.Font.Height := -Escala(13);
    vPrimeira := PrimeiraDataDaGrade(FMes);
    for vIndice := 0 to QUANTIDADE_DIAS - 1 do
    begin
      vData := vPrimeira + vIndice;
      DesenharCelula(RetanguloDia(vIndice), IntToStr(DayOf(vData)),
        Trunc(vData) = Trunc(FSelecionada), Trunc(vData) = Trunc(FHoje),
        (FAreaSobMouse = caCelula) and (vData = FDataSobMouse), MonthOf(vData) <> MonthOf(FMes));
    end;
  end
  else
  begin
    // ===== Meses ou anos =====
    Canvas.Font.Height := -Escala(13);
    for vIndice := 0 to QUANTIDADE_MES_ANO - 1 do
    begin
      vData := DataDaCelula(vIndice);
      if FVisao = cvMeses then
        DesenharCelula(RetanguloMesOuAno(vIndice), NomeMesCurto(vIndice + 1),
          (FSelecionada > 0) and (YearOf(FSelecionada) = YearOf(vData)) and (MonthOf(FSelecionada) = MonthOf(vData)),
          (YearOf(FHoje) = YearOf(vData)) and (MonthOf(FHoje) = MonthOf(vData)),
          (FAreaSobMouse = caCelula) and (vData = FDataSobMouse), False)
      else
        DesenharCelula(RetanguloMesOuAno(vIndice), IntToStr(YearOf(vData)),
          (FSelecionada > 0) and (YearOf(FSelecionada) = YearOf(vData)),
          YearOf(FHoje) = YearOf(vData),
          (FAreaSobMouse = caCelula) and (vData = FDataSobMouse), False);
    end;
  end;

  // ===== Rodape =====
  Canvas.Pen.Color := vBorda;
  Canvas.MoveTo(Escala(MARGEM), Escala(TOPO_RODAPE - 6));
  Canvas.LineTo(Escala(LARGURA_CALENDARIO - MARGEM), Escala(TOPO_RODAPE - 6));

  Canvas.Font.Style := [];
  Canvas.Font.Color := vTexto;
  DesenharRetanguloArredondado(Canvas, RetanguloHoje, Escala(RAIO_DIA),
    IfThenCor(FAreaSobMouse = caHoje, MesclarCores(vTexto, vSobMouse, 15), vSobMouse), clNone, 0);
  EscreverCentralizado(RetanguloHoje, 'Hoje');

  if FAreaSobMouse = caLimpar then
    DesenharRetanguloArredondado(Canvas, RetanguloLimpar, Escala(RAIO_DIA), vSobMouse, clNone, 0);
  Canvas.Font.Color := vApagado;
  EscreverCentralizado(RetanguloLimpar, 'Limpar');
end;

end.
