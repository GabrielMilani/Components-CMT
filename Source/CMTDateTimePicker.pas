unit CMTDateTimePicker;

interface

uses
  System.Classes,
  Winapi.Windows,
  System.DateUtils,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Mask,
  Vcl.ComCtrls, Vcl.Graphics,
  CMTCustomButton, Winapi.Messages, Vcl.Forms;

type
  TCMTDateEdit = class(TCustomPanel)
  private
    FEdit: TMaskEdit;
    FButton: TCMTCustomButton;
    FPicker: TDateTimePicker;

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

    // === Compatibilidade ===
    function GetText: string;
    procedure SetText(const Value: string);

    // === Data ===
    function GetDate: TDate;
    procedure SetDate(const Value: TDate);

    // === Internos ===
    procedure ButtonClick(Sender: TObject);
    procedure PickerChange(Sender: TObject);
    procedure SyncFonts;
    procedure EditEnter(Sender: TObject);

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
  protected
    procedure Paint; override;
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
  System.SysUtils;

procedure Register;
begin
  RegisterComponents('CMT', [TCMTDateEdit]);
end;

{ TCMTDateEdit }

constructor TCMTDateEdit.Create(AOwner: TComponent);
begin
  inherited;

  Width := 160;
  Height := 26;
  BevelOuter := bvNone;

  // ===== Fonte padrão =====
  Font.Name := 'Segoe UI';
  Font.Size := 11;

  // ===== Cores padrão =====
  FFieldColor := clBtnFace;
  FBorderColor := clGray;
  FButtonColor := clBtnFace;
  FButtonFontColor := clWindowText;

  Color := FFieldColor;

  // ===== BOTÃO ▼ =====
  FButton := TCMTCustomButton.Create(Self);
  FButton.Parent := Self;
  FButton.Align := alRight;
  FButton.Width := 28;
  FButton.Caption := '▼';
  FButton.BaseColor := FButtonColor;
  FButton.FontColor := FButtonFontColor;
  FButton.HoverColor := $00E6E6E6;
  FButton.CornerRadius := 0;
  FButton.SetSubComponent(True);
  FButton.OnClick := ButtonClick;

  // ===== EDIT (__/__/____) SEM BORDA =====
  FEdit := TMaskEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.Align := alClient;
  FEdit.Margins.SetBounds(6, 4, 6, 4);
  FEdit.EditMask := '99/99/9999';

  FEdit.BorderStyle := bsNone;
  FEdit.Ctl3D := False;
  FEdit.ParentColor := True;
  FEdit.BevelInner := bvNone;
  FEdit.BevelOuter := bvNone;
  FEdit.OnEnter := EditEnter;
  FEdit.Color := FFieldColor;
  FEdit.Clear;

  // ===== DATETIMEPICKER (POPUP NATIVO) =====
  FPicker := TDateTimePicker.Create(Self);
  FPicker.Parent := Self;
  FPicker.Align := alRight;
  FPicker.Width := 1;
  FPicker.Kind := dtkDate;
  FPicker.TabStop := False;
  FPicker.OnChange := PickerChange;

  FEdit.OnEnter    := InternalEditEnter;
  FEdit.OnExit     := InternalEditExit;
  FEdit.OnChange   := InternalEditChange;

  FEdit.OnKeyDown  := InternalEditKeyDown;
  FEdit.OnKeyUp    := InternalEditKeyUp;
  FEdit.OnKeyPress := InternalEditKeyPress;

  FEdit.OnClick    := InternalClick;

  SyncFonts;
end;

procedure TCMTDateEdit.EditEnter(Sender: TObject);
begin
  if Trim(FEdit.Text) = '' then
  begin
    FEdit.EditMask := '';
    FEdit.Text := '';
  end;
end;

procedure TCMTDateEdit.SyncFonts;
begin
  if Assigned(FEdit) then
    FEdit.Font.Assign(Font);

  if Assigned(FButton) then
    FButton.Font.Assign(Font);
end;

procedure TCMTDateEdit.CMFontChanged(var Message: TMessage);
begin
  inherited;
  SyncFonts;
end;

procedure TCMTDateEdit.Paint;
begin
  inherited;

  // ===== BORDA ÚNICA DO COMPONENTE =====
  Canvas.Pen.Color := FBorderColor;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(0, 0, Width, Height);

  // ===== DIVISOR ENTRE EDIT E BOTÃO =====
  Canvas.MoveTo(Width - FButton.Width - 1, 2);
  Canvas.LineTo(Width - FButton.Width - 1, Height - 2);
end;

procedure TCMTDateEdit.ButtonClick(Sender: TObject);
begin
  // Ação ORIGINAL (popup)
  FPicker.SetFocus;
  SendMessage(FPicker.Handle, WM_SYSKEYDOWN, VK_DOWN, 0);

  // Evento EXPOSTO do componente
  if Assigned(FOnClick) then
    FOnClick(Self);
end;

procedure TCMTDateEdit.PickerChange(Sender: TObject);
begin
  FEdit.Text := FormatDateTime('dd/mm/yyyy', FPicker.Date);
end;

function TCMTDateEdit.GetDate: TDate;
var
  D: TDateTime;
begin
  if Trim(FEdit.Text) = '' then
    Result := 0
  else if TryStrToDate(FEdit.Text, D) then
    Result := DateOf(D)
  else
    Result := 0;
end;

procedure TCMTDateEdit.SetDate(const Value: TDate);
begin
  if Value > 0 then
  begin
    FPicker.Date := Value;
    FEdit.Text := FormatDateTime('dd/mm/yyyy', Value);
  end
  else
  begin
    FEdit.Clear;
    FPicker.Date := Date; // evita lixo interno
  end;
end;

function TCMTDateEdit.GetText: string;
begin
  Result := FEdit.Text;
end;

procedure TCMTDateEdit.InternalClick(Sender: TObject);
begin
  if Assigned(FOnClick) then
    FOnClick(Self);
end;

procedure TCMTDateEdit.InternalEditChange(Sender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TCMTDateEdit.InternalEditEnter(Sender: TObject);
begin
  if Assigned(FOnEnter) then
    FOnEnter(Self);
end;

procedure TCMTDateEdit.InternalEditExit(Sender: TObject);
begin
  // ainda está dentro do componente
  if IsFocusInside then
    Exit;

  if Assigned(FOnExit) then
    FOnExit(Self);
end;

procedure TCMTDateEdit.InternalEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Assigned(FOnKeyDown) then
    FOnKeyDown(Self, Key, Shift);
end;

procedure TCMTDateEdit.InternalEditKeyPress(Sender: TObject; var Key: Char);
begin
  if Assigned(FOnKeyPress) then
    FOnKeyPress(Self, Key);
end;

procedure TCMTDateEdit.InternalEditKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
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
var
  D: TDateTime;
begin
  FEdit.Text := Value;

  if TryStrToDate(Value, D) then
    FPicker.Date := D;
end;

procedure TCMTDateEdit.SetFieldColor(const Value: TColor);
begin
  FFieldColor := Value;
  Color := Value;
  FEdit.Color := Value;
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
  FButton.BaseColor := Value;
end;

procedure TCMTDateEdit.SetButtonFontColor(const Value: TColor);
begin
  FButtonFontColor := Value;
  FButton.FontColor := Value;
end;

end.
