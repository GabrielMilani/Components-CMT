unit CMTDateTimePicker;

interface

uses
  System.Classes,
  Winapi.Windows,
  System.DateUtils,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Mask,
  Vcl.Graphics,
  CMTDateEditCalendario, Winapi.Messages, Vcl.Forms;

const
  WM_CMTDATE_APLICAR_SUGESTAO = WM_USER + 1;

type
  TCMTDateEdit = class;

  // Edit interno: mostra "dd/mm/aaaa" quando vazio e fecha o calendário ao perder o foco
  TCMTDateMaskEdit = class(TMaskEdit)
  private
    FCampo: TCMTDateEdit;
    procedure WMPaint(var Message: TWMPaint); message WM_PAINT;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
  protected
    procedure CreateWnd; override;
  end;

  TCMTDateAreaMouse = (amNada, amIcone, amLimpar);

  TCMTDateEdit = class(TCustomPanel)
  private
    FEdit: TCMTDateMaskEdit;
    FCalendario: TCMTCalendarioPopup;

    // Aparência
    FFieldColor: TColor;
    FBorderColor: TColor;
    FButtonColor: TColor;
    FButtonFontColor: TColor;
    FOnExit: TNotifyEvent;
    FOnKeyPress: TKeyPressEvent;
    FOnKeyDown: TKeyEvent;
    FOnChange: TNotifyEvent;
    FOnEnter: TNotifyEvent;
    FOnClick: TNotifyEvent;
    FOnKeyUp: TKeyEvent;

    // Mouse
    FMouseDentro: Boolean;
    FAreaMouse: TCMTDateAreaMouse;

    // Última data aceita, para desfazer texto incompleto ou inválido ao sair
    FUltimaDataValida: TDate;

    // Sugestão de data durante a digitação
    FSugestaoPendente: Boolean;
    FTextoSugerido: string;
    FTextoDigitado: string;
    FPosicaoSugestao: Integer;
    FDigitando: Boolean;
    FAjustandoTexto: Boolean;

    // === Compatibilidade ===
    function GetText: string;
    procedure SetText(const Value: string);

    // === Data ===
    function GetDate: TDate;
    procedure SetDate(const Value: TDate);

    // === Internos ===
    procedure SyncFonts;
    function AlturaDoTexto: Integer;
    procedure AjustarEdit;

    procedure SetFieldColor(const Value: TColor);
    procedure SetBorderColor(const Value: TColor);
    procedure SetButtonColor(const Value: TColor);
    procedure SetButtonFontColor(const Value: TColor);


    procedure InternalEditEnter(Sender: TObject);
    procedure InternalEditExit(Sender: TObject);
    procedure InternalEditChange(Sender: TObject);

    procedure InternalEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure InternalEditKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure InternalEditKeyPress(Sender: TObject; var Key: Char);

    procedure InternalClick(Sender: TObject);

    function IsFocusInside: Boolean;

    function TextoAtual: string;
    procedure DefinirTextoInterno(const AText: string);
    procedure NotificarMudanca;
    procedure AtualizarUltimaDataValida;
    procedure DesfazerDataInvalida;

    function PrepararSugestao: Boolean;
    procedure ConfirmarSugestao;
    procedure RemoverSugestao;

    // === Aparência e áreas clicáveis ===
    function CorDoPai: TColor;
    function CorDoFundo: TColor;
    function CorDoTextoVazio: TColor;
    function TextoInvalido: Boolean;
    function CabeBotaoLimpar: Boolean;
    function BotaoLimparVisivel: Boolean;
    function RetanguloIcone: TRect;
    function RetanguloLimpar: TRect;
    function AreaEm(const AX, AY: Integer): TCMTDateAreaMouse;
    procedure AtualizarMouseDentro;

    // === Calendário ===
    procedure AbrirCalendario;
    procedure FecharCalendario;
    procedure CalendarioEscolheu(Sender: TObject; const AData: TDate);
    procedure CalendarioLimpou(Sender: TObject);
    procedure CalendarioFechou(Sender: TObject);

    procedure WMAplicarSugestao(var Message: TMessage); message WM_CMTDATE_APLICAR_SUGESTAO;
    procedure CMChildKey(var Message: TCMChildKey); message CM_CHILDKEY;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;

  public
    constructor Create(AOwner: TComponent); override;

  published
    // ===== USO CORRETO =====
    property Date: TDate read GetDate write SetDate;

    // ===== COMPATIBILIDADE =====
    property Text: string read GetText write SetText;

    // ===== APARÊNCIA =====
    property FieldColor: TColor read FFieldColor write SetFieldColor;
    // Sem uso no desenho: o campo só tem borda no foco e com data inválida.
    // Continuam publicadas pelos DFMs e pelo tema
    property BorderColor: TColor read FBorderColor write SetBorderColor;
    property ButtonColor: TColor read FButtonColor write SetButtonColor;
    property ButtonFontColor: TColor read FButtonFontColor write SetButtonFontColor;

    // ===== PADRÃO VCL =====
    property Font;
    property Align;
    property Anchors;
    property Enabled;
    property Visible;
    property TabOrder;
    property TabStop;

      // ===== EVENTOS =====
    property OnEnter: TNotifyEvent read FOnEnter write FOnEnter;
    property OnExit: TNotifyEvent read FOnExit write FOnExit;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;

    property OnKeyDown: TKeyEvent read FOnKeyDown write FOnKeyDown;
    property OnKeyUp: TKeyEvent read FOnKeyUp write FOnKeyUp;
    property OnKeyPress: TKeyPressEvent read FOnKeyPress write FOnKeyPress;

    property OnClick: TNotifyEvent read FOnClick write FOnClick;
  end;

procedure Register;

implementation

uses
  System.SysUtils, System.Types, CMTDateEditRegras;

const
  TEXTO_VAZIO = 'dd/mm/aaaa';

  // Medidas a 96 DPI
  ESPACO_BORDA = 2; // cabe a borda de foco, a mais grossa
  MARGEM_TEXTO = 7;
  LARGURA_ICONE = 26;
  LARGURA_LIMPAR = 20;
  LARGURA_MINIMA_COM_LIMPAR = 150;

  COR_ERRO = TColor($004F53D9);            // #D9534F

type
  // Acesso à cor do pai (protegida em TControl)
  TWinControlAcesso = class(TWinControl);

procedure Register;
begin
  RegisterComponents('CMT', [TCMTDateEdit]);
end;

{ TCMTDateMaskEdit }

procedure TCMTDateMaskEdit.CreateWnd;
begin
  inherited;
  // A altura automática do edit só é conhecida com a janela criada
  FCampo.AjustarEdit;
end;

procedure TCMTDateMaskEdit.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  FCampo.FecharCalendario;
end;

procedure TCMTDateMaskEdit.WMPaint(var Message: TWMPaint);
var
  vContexto: HDC;
  vPincel: HBRUSH;
  vFonteAnterior: HGDIOBJ;
  vRect: TRect;
begin
  inherited;

  // Com foco ficam as barras da máscara, que mostram onde o próximo dígito entra
  if Focused or not TextoDataVazio(Text) then
    Exit;

  vContexto := GetDC(Handle);
  try
    vRect := ClientRect;
    vPincel := CreateSolidBrush(ColorToRGB(Color));
    FillRect(vContexto, vRect, vPincel);
    DeleteObject(vPincel);

    vFonteAnterior := SelectObject(vContexto, Font.Handle);
    SetBkMode(vContexto, TRANSPARENT);
    SetTextColor(vContexto, ColorToRGB(FCampo.CorDoTextoVazio));
    TextOut(vContexto, 1, 0, PChar(TEXTO_VAZIO), Length(TEXTO_VAZIO));
    SelectObject(vContexto, vFonteAnterior);
  finally
    ReleaseDC(Handle, vContexto);
  end;
end;

{ TCMTDateEdit }

constructor TCMTDateEdit.Create(AOwner: TComponent);
begin
  inherited;

  Width := 160;
  Height := 26;
  BevelOuter := bvNone;
  ParentBackground := False;
  DoubleBuffered := True;

  // ===== Fonte padrão =====
  Font.Name := 'Segoe UI';
  Font.Size := 11;

  // ===== Cores padrão =====
  FFieldColor := clBtnFace;
  FBorderColor := clGray;
  FButtonColor := clBtnFace;
  FButtonFontColor := clWindowText;

  Color := FFieldColor;

  // ===== EDIT (  /  /    ) SEM BORDA =====
  FEdit := TCMTDateMaskEdit.Create(Self);
  FEdit.FCampo := Self;
  FEdit.Parent := Self;
  FEdit.DoubleBuffered := False;
  FEdit.AutoSize := False; // a altura vem de AjustarEdit, sempre dentro da borda
  FEdit.EditMask := '99/99/9999;1; ';

  FEdit.BorderStyle := bsNone;
  FEdit.Ctl3D := False;
  FEdit.ParentColor := True;
  FEdit.BevelInner := bvNone;
  FEdit.BevelOuter := bvNone;
  FEdit.Color := FFieldColor;
  FEdit.Clear;

  FEdit.OnEnter    := InternalEditEnter;
  FEdit.OnExit     := InternalEditExit;
  FEdit.OnChange   := InternalEditChange;

  FEdit.OnKeyDown  := InternalEditKeyDown;
  FEdit.OnKeyUp    := InternalEditKeyUp;
  FEdit.OnKeyPress := InternalEditKeyPress;

  FEdit.OnClick    := InternalClick;

  SyncFonts;
end;

procedure TCMTDateEdit.SyncFonts;
begin
  if Assigned(FEdit) then
  begin
    FEdit.Font.Assign(Font);
    AjustarEdit;
  end;
end;

function TCMTDateEdit.AlturaDoTexto: Integer;
var
  vContexto: HDC;
  vFonteAnterior: HGDIOBJ;
  vMetricas: TTextMetric;
begin
  Result := FEdit.Height;
  if not FEdit.HandleAllocated then
    Exit;

  vContexto := GetDC(FEdit.Handle);
  try
    vFonteAnterior := SelectObject(vContexto, FEdit.Font.Handle);
    GetTextMetrics(vContexto, vMetricas);
    SelectObject(vContexto, vFonteAnterior);
    Result := vMetricas.tmHeight;
  finally
    ReleaseDC(FEdit.Handle, vContexto);
  end;
end;

procedure TCMTDateEdit.AjustarEdit;
var
  vEsquerda, vReservado, vEspaco, vAltura: Integer;
begin
  // Sem janela ainda (campo criado por código, antes de ter pai): ClientHeight pediria a
  // janela e daria "has no parent window". O CreateWnd do edit chama de novo depois
  if not Assigned(FEdit) or not HandleAllocated then
    Exit;

  vEsquerda := ScaleValue(MARGEM_TEXTO);
  vReservado := ScaleValue(LARGURA_ICONE);
  if CabeBotaoLimpar then
    Inc(vReservado, ScaleValue(LARGURA_LIMPAR));

  // O edit nunca pode cobrir a linha da borda
  vEspaco := ScaleValue(ESPACO_BORDA);
  vAltura := AlturaDoTexto;
  if vAltura > ClientHeight - 2 * vEspaco then
    vAltura := ClientHeight - 2 * vEspaco;

  FEdit.SetBounds(vEsquerda, (ClientHeight - vAltura) div 2,
    ClientWidth - vEsquerda - vReservado, vAltura);
end;

procedure TCMTDateEdit.Resize;
begin
  inherited;
  AjustarEdit;
end;

procedure TCMTDateEdit.CMFontChanged(var Message: TMessage);
begin
  inherited;
  SyncFonts;
end;

procedure TCMTDateEdit.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  if Assigned(FEdit) then
  begin
    FEdit.Enabled := Enabled;
    FEdit.Color := CorDoFundo; // o edit e o campo ficam sempre no mesmo tom
  end;
  Invalidate;
end;

function TCMTDateEdit.CorDoPai: TColor;
begin
  if Assigned(Parent) then
    Result := TWinControlAcesso(Parent).Color
  else
    Result := clBtnFace;
end;

function TCMTDateEdit.CorDoFundo: TColor;
begin
  if Enabled then
    Result := FFieldColor
  else
    Result := MesclarCores(FFieldColor, CorDoPai, 55);
end;

function TCMTDateEdit.CorDoTextoVazio: TColor;
begin
  Result := MesclarCores(Font.Color, FFieldColor, 50);
end;

function TCMTDateEdit.TextoInvalido: Boolean;
var
  vData: TDateTime;
begin
  Result := (Length(DigitosIniciais(FEdit.Text)) = 8) and not TryTextoParaData(FEdit.Text, vData);
end;

function TCMTDateEdit.CabeBotaoLimpar: Boolean;
begin
  Result := Width >= ScaleValue(LARGURA_MINIMA_COM_LIMPAR);
end;

function TCMTDateEdit.BotaoLimparVisivel: Boolean;
begin
  Result := Enabled and CabeBotaoLimpar and not TextoDataVazio(TextoAtual) and
    (FMouseDentro or FEdit.Focused);
end;

function TCMTDateEdit.RetanguloIcone: TRect;
begin
  Result := Rect(ClientWidth - ScaleValue(LARGURA_ICONE), 1, ClientWidth - 1, ClientHeight - 1);
end;

function TCMTDateEdit.RetanguloLimpar: TRect;
begin
  Result := RetanguloIcone;
  Result.Right := Result.Left;
  Result.Left := Result.Right - ScaleValue(LARGURA_LIMPAR);
end;

function TCMTDateEdit.AreaEm(const AX, AY: Integer): TCMTDateAreaMouse;
begin
  if PtInRect(RetanguloIcone, Point(AX, AY)) then
    Result := amIcone
  else if BotaoLimparVisivel and PtInRect(RetanguloLimpar, Point(AX, AY)) then
    Result := amLimpar
  else
    Result := amNada;
end;

procedure TCMTDateEdit.Paint;
var
  vBorda, vTracos: TColor;
  vEspessura, vLinha: Integer;
  vEscala, vCentroX, vCentroY, vBraco: Single;
  vRect: TRect;
begin
  vEscala := ScaleValue(100) / 100;

  // ===== BORDA: SÓ NO FOCO E COM DATA INVÁLIDA =====
  // Sem borda o campo ocupa a mesma área dos edits vizinhos
  vEspessura := 0;
  vBorda := clNone;
  if Enabled then
    if TextoInvalido then
    begin
      vEspessura := 2;
      vBorda := COR_ERRO;
    end
    else if FEdit.Focused then
    begin
      vEspessura := 2;
      vBorda := COR_DESTAQUE_CAMPO;
    end;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := CorDoFundo;
  Canvas.FillRect(ClientRect);

  vRect := ClientRect;
  Canvas.Brush.Color := vBorda;
  for vLinha := 1 to vEspessura do
  begin
    Canvas.FrameRect(vRect);
    InflateRect(vRect, -1, -1);
  end;

  // ===== ÍCONE DO CALENDÁRIO E BOTÃO LIMPAR =====
  vTracos := MesclarCores(Font.Color, CorDoFundo, 70);

  vRect := RetanguloIcone;
  if Enabled and ((FAreaMouse = amIcone) or (Assigned(FCalendario) and FCalendario.Aberto)) then
  begin
    InflateRect(vRect, -ScaleValue(2), -ScaleValue(2));
    Canvas.Brush.Color := MesclarCores(FFieldColor, clBlack, 88);
    Canvas.FillRect(vRect);
    vRect := RetanguloIcone;
  end;
  DesenharIconeCalendario(Canvas, vRect, vTracos, vEscala);

  if BotaoLimparVisivel then
  begin
    vRect := RetanguloLimpar;
    vCentroX := (vRect.Left + vRect.Right) / 2;
    vCentroY := (vRect.Top + vRect.Bottom) / 2;
    vBraco := 3.5 * vEscala;
    if FAreaMouse = amLimpar then
      vTracos := Font.Color;
    DesenharLinhas(Canvas, vTracos, 1.4 * vEscala, [
      vCentroX - vBraco, vCentroY - vBraco, vCentroX + vBraco, vCentroY + vBraco,
      vCentroX - vBraco, vCentroY + vBraco, vCentroX + vBraco, vCentroY - vBraco]);
  end;
end;

procedure TCMTDateEdit.AtualizarMouseDentro;
var
  vDentro: Boolean;
begin
  vDentro := PtInRect(ClientRect, ScreenToClient(Mouse.CursorPos));
  if not vDentro then
    FAreaMouse := amNada;

  if vDentro <> FMouseDentro then
  begin
    FMouseDentro := vDentro;
    Invalidate;
  end;
end;

procedure TCMTDateEdit.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  AtualizarMouseDentro;
end;

procedure TCMTDateEdit.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  AtualizarMouseDentro;
  Invalidate;
end;

procedure TCMTDateEdit.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vArea: TCMTDateAreaMouse;
begin
  inherited;
  vArea := AreaEm(X, Y);
  if vArea <> FAreaMouse then
  begin
    FAreaMouse := vArea;
    if vArea = amNada then
      Cursor := crDefault
    else
      Cursor := crHandPoint;
    Invalidate;
  end;
end;

procedure TCMTDateEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button <> mbLeft then
    Exit;

  case AreaEm(X, Y) of
    amIcone:
      AbrirCalendario;
    amLimpar:
      begin
        SetDate(0);
        if FEdit.CanFocus then
          FEdit.SetFocus;
      end;
  else
    if FEdit.CanFocus then
      FEdit.SetFocus;
  end;
end;

procedure TCMTDateEdit.AbrirCalendario;
var
  vPonto: TPoint;
begin
  if Assigned(FCalendario) and FCalendario.Aberto then
    Exit;

  ConfirmarSugestao;
  if FEdit.CanFocus then
    FEdit.SetFocus;

  if not Assigned(FCalendario) then
  begin
    FCalendario := TCMTCalendarioPopup.Create(Self);
    FCalendario.Parent := Self;
    FCalendario.OnEscolher := CalendarioEscolheu;
    FCalendario.OnLimpar := CalendarioLimpou;
    FCalendario.OnFechar := CalendarioFechou;
  end;

  vPonto := ClientToScreen(Point(0, 0));
  FCalendario.Abrir(GetDate, System.SysUtils.Date, BrilhoCor(CorDoPai) < 128,
    Rect(vPonto.X, vPonto.Y, vPonto.X + Width, vPonto.Y + Height));
  Invalidate;

  // Evento EXPOSTO do componente
  if Assigned(FOnClick) then
    FOnClick(Self);
end;

procedure TCMTDateEdit.FecharCalendario;
begin
  if Assigned(FCalendario) then
    FCalendario.Fechar;
end;

procedure TCMTDateEdit.CalendarioEscolheu(Sender: TObject; const AData: TDate);
begin
  FSugestaoPendente := False;
  FEdit.Text := FormatarData(AData);
end;

procedure TCMTDateEdit.CalendarioLimpou(Sender: TObject);
begin
  SetDate(0);
end;

procedure TCMTDateEdit.CalendarioFechou(Sender: TObject);
begin
  Invalidate;
end;

// Com o calendário aberto a tecla é dele: não chega ao edit, à tela (KeyPreview)
// nem aos botões padrão e de cancelar do form.
procedure TCMTDateEdit.CMChildKey(var Message: TCMChildKey);
begin
  if Assigned(FCalendario) and FCalendario.Aberto then
  begin
    if FCalendario.TratarTecla(Message.CharCode) then
    begin
      Message.Result := 1;
      Exit;
    end;

    FCalendario.Fechar;
  end;

  inherited;
end;

function TCMTDateEdit.TextoAtual: string;
begin
  if FSugestaoPendente then
    Result := FTextoSugerido
  else
    Result := FEdit.Text;
end;

function TCMTDateEdit.GetDate: TDate;
var
  vData: TDateTime;
begin
  if TryTextoParaData(TextoAtual, vData) then
    Result := DateOf(vData)
  else
    Result := 0;
end;

procedure TCMTDateEdit.SetDate(const Value: TDate);
begin
  FSugestaoPendente := False;

  if Value > 0 then
  begin
    FUltimaDataValida := Value;
    FEdit.Text := FormatarData(Value);
  end
  else
  begin
    FUltimaDataValida := 0;
    FEdit.Clear;
  end;
end;

function TCMTDateEdit.GetText: string;
begin
  Result := TextoAtual;
end;

procedure TCMTDateEdit.InternalClick(Sender: TObject);
begin
  ConfirmarSugestao;

  // Campo vazio: o primeiro dígito sempre entra no dia, onde quer que tenha clicado
  if TextoDataVazio(FEdit.Text) then
  begin
    FEdit.SelStart := 0;
    FEdit.SelLength := 1;
  end;

  if Assigned(FOnClick) then
    FOnClick(Self);
end;

procedure TCMTDateEdit.InternalEditChange(Sender: TObject);
var
  vDigitou: Boolean;
begin
  Invalidate;
  if not FEdit.Focused then
    FEdit.Invalidate;

  if FAjustandoTexto then
    Exit;

  vDigitou := FDigitando;
  FDigitando := False;
  FSugestaoPendente := False;

  // Com sugestão a data ainda não foi aceita: a tela só fica sabendo ao confirmar
  if vDigitou and PrepararSugestao then
    Exit;

  NotificarMudanca;
end;

procedure TCMTDateEdit.NotificarMudanca;
begin
  AtualizarUltimaDataValida;

  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TCMTDateEdit.AtualizarUltimaDataValida;
var
  vData: TDateTime;
begin
  if TextoDataVazio(FEdit.Text) then
    FUltimaDataValida := 0
  else if TryTextoParaData(FEdit.Text, vData) then
    FUltimaDataValida := DateOf(vData);
end;

procedure TCMTDateEdit.DesfazerDataInvalida;
var
  vData: TDateTime;
begin
  if not TextoDataVazio(FEdit.Text) and not TryTextoParaData(FEdit.Text, vData) then
    SetDate(FUltimaDataValida);
end;

procedure TCMTDateEdit.DefinirTextoInterno(const AText: string);
begin
  FAjustandoTexto := True;
  try
    FEdit.Text := AText;
  finally
    FAjustandoTexto := False;
  end;
end;

function TCMTDateEdit.PrepararSugestao: Boolean;
var
  vDigitos: string;
begin
  FTextoDigitado := FEdit.Text;
  vDigitos := DigitosIniciais(FTextoDigitado);
  FTextoSugerido := SugerirData(vDigitos, System.SysUtils.Date);

  Result := FTextoSugerido <> '';
  if not Result then
    Exit;

  FSugestaoPendente := True;
  FPosicaoSugestao := PosicaoAposDigitos(Length(vDigitos));

  // A máscara ainda reposiciona o cursor depois deste evento e desfaria a seleção
  PostMessage(Handle, WM_CMTDATE_APLICAR_SUGESTAO, 0, 0);
end;

procedure TCMTDateEdit.WMAplicarSugestao(var Message: TMessage);
begin
  if not FSugestaoPendente or (FEdit.Text <> FTextoDigitado) then
    Exit;

  DefinirTextoInterno(FTextoSugerido);
  FEdit.SelStart := FPosicaoSugestao;
  FEdit.SelLength := Length(FTextoSugerido) - FPosicaoSugestao;
end;

procedure TCMTDateEdit.ConfirmarSugestao;
begin
  if not FSugestaoPendente then
    Exit;

  FSugestaoPendente := False;
  DefinirTextoInterno(FTextoSugerido);
  FEdit.SelStart := Length(FTextoSugerido);
  NotificarMudanca;
end;

procedure TCMTDateEdit.RemoverSugestao;
begin
  if not FSugestaoPendente then
    Exit;

  FSugestaoPendente := False;
  DefinirTextoInterno(FTextoDigitado);

  // A máscara trabalha sempre com um caractere selecionado na posição do cursor
  FEdit.SelStart := FPosicaoSugestao;
  FEdit.SelLength := 1;
end;

procedure TCMTDateEdit.InternalEditEnter(Sender: TObject);
begin
  Invalidate;
  FEdit.Invalidate;

  if Assigned(FOnEnter) then
    FOnEnter(Self);
end;

procedure TCMTDateEdit.InternalEditExit(Sender: TObject);
begin
  Invalidate;
  FEdit.Invalidate;

  ConfirmarSugestao;

  // ainda está dentro do componente
  if IsFocusInside then
    Exit;

  DesfazerDataInvalida;

  if Assigned(FOnExit) then
    FOnExit(Self);
end;

procedure TCMTDateEdit.InternalEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  FDigitando := False;

  if (Key = VK_DOWN) and (ssAlt in Shift) then
  begin
    AbrirCalendario;
    Key := 0;
    Exit;
  end;

  case Key of
    VK_RETURN, VK_LEFT, VK_RIGHT, VK_HOME, VK_END:
      ConfirmarSugestao;
  end;

  if Assigned(FOnKeyDown) then
    FOnKeyDown(Self, Key, Shift);

  if not FSugestaoPendente then
    Exit;

  case Key of
    VK_BACK, VK_DELETE:
      begin
        RemoverSugestao;
        NotificarMudanca;
        Key := 0; // apagou só a sugestão, não o que foi digitado
      end;
    VK_ESCAPE:
      begin
        RemoverSugestao;
        NotificarMudanca;
      end;
  end;
end;

procedure TCMTDateEdit.InternalEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Assigned(FOnKeyPress) then
    FOnKeyPress(Self, Key);

  if CharInSet(Key, ['0'..'9']) then
  begin
    // Volta ao que foi digitado para a máscara escrever um caractere só e avisar uma vez
    RemoverSugestao;
    FDigitando := True;
  end
  else if FSugestaoPendente and (Key >= ' ') then
    Key := #0; // a barra digitada por hábito não pode apagar a sugestão
end;

procedure TCMTDateEdit.InternalEditKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  FDigitando := False;

  if Assigned(FOnKeyUp) then
    FOnKeyUp(Self, Key, Shift);
end;

function TCMTDateEdit.IsFocusInside: Boolean;
var
  Wnd: HWND;
begin
  Result := False;
  Wnd := GetFocus;
  if Wnd = 0 then Exit;

  Result := (Wnd = Handle) or IsChild(Handle, Wnd);
end;

procedure TCMTDateEdit.SetText(const Value: string);
begin
  FSugestaoPendente := False;
  FEdit.Text := Value;
  AtualizarUltimaDataValida;
end;

procedure TCMTDateEdit.SetFieldColor(const Value: TColor);
begin
  FFieldColor := Value;
  Color := Value;
  FEdit.Color := CorDoFundo;
  Invalidate;
end;

procedure TCMTDateEdit.SetBorderColor(const Value: TColor);
begin
  FBorderColor := Value;
  Invalidate;
end;

procedure TCMTDateEdit.SetButtonColor(const Value: TColor);
begin
  FButtonColor := Value;
end;

procedure TCMTDateEdit.SetButtonFontColor(const Value: TColor);
begin
  FButtonFontColor := Value;
end;

end.
