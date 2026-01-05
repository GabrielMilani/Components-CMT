unit CMTCustomButton;

interface

uses
  Vcl.Graphics, Winapi.Windows, System.Classes, System.SysUtils,
  Vcl.Controls, Winapi.Messages;

type
  TImagePosition = (ipLeft, ipRight, ipTop, ipBottom);

type
  TCMTCustomButton = class(TCustomControl)
  private
    // Aparência
    FBaseColor: TColor;
    FHoverColor: TColor;
    FFontColor: TColor;
    FHoverFontColor: TColor;
    FActiveColor: TColor;
    FFocusBackColor: TColor;
    FCornerRadius: Integer;

    // Estados
    FHovering: Boolean;
    FActive: Boolean;
    FAllowActive: Boolean;

    // Foco
    FFocusOnClick: Boolean;
    FUseFocusBackColor: Boolean;

    // Imagem
    FImage: TPicture;
    FImagePosition: TImagePosition;
    FImageSpacing: Integer;
    FCenterImageOnly: Boolean;

    // Texto
    FTextAlignment: TAlignment;

    procedure SetBaseColor(Value: TColor);
    procedure SetHoverColor(Value: TColor);
    procedure SetFontColor(Value: TColor);
    procedure SetHoverFontColor(Value: TColor);
    procedure SetCornerRadius(Value: Integer);
    procedure SetImage(Value: TPicture);
    procedure SetImagePosition(Value: TImagePosition);
    procedure SetImageSpacing(Value: Integer);
    procedure SetTextAlignment(const Value: TAlignment);
    procedure SetCenterImageOnly(const Value: Boolean);
    procedure SetActive(const Value: Boolean);

    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;

    procedure WMLButtonDown(var Message: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMSetFocus(var Message: TWMSetFocus); message WM_SETFOCUS;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;

  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure Click; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function CanFocus: Boolean; override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ClearHover;

  published
    // Básico
    property Caption;
    property Align;
    property Anchors;
    property Enabled;
    property Visible;
    property Font;
    property ParentFont;
    property ParentShowHint;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Cursor;

    // Eventos
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;
    property OnKeyDown;
    property OnKeyUp;
    property OnKeyPress;
    property OnEnter;
    property OnExit;
    property OnContextPopup;

    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;

    // Aparência
    property BaseColor: TColor read FBaseColor write SetBaseColor default clSkyBlue;
    property HoverColor: TColor read FHoverColor write SetHoverColor default clNavy;
    property FontColor: TColor read FFontColor write SetFontColor default clWhite;
    property HoverFontColor: TColor read FHoverFontColor write SetHoverFontColor default clWhite;
    property ActiveColor: TColor read FActiveColor write FActiveColor default clNavy;
    property FocusBackColor: TColor read FFocusBackColor write FFocusBackColor default clHighlight;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius default 10;

    // Estados
    property AllowActive: Boolean read FAllowActive write FAllowActive default True;
    property Active: Boolean read FActive write SetActive;

    // Foco
    property FocusOnClick: Boolean read FFocusOnClick write FFocusOnClick default True;
    property UseFocusBackColor: Boolean read FUseFocusBackColor write FUseFocusBackColor default True;

    // Imagem
    property Image: TPicture read FImage write SetImage;
    property ImagePosition: TImagePosition read FImagePosition write SetImagePosition default ipLeft;
    property ImageSpacing: Integer read FImageSpacing write SetImageSpacing default 4;
    property CenterImageOnly: Boolean read FCenterImageOnly write SetCenterImageOnly default False;

    // Texto
    property TextAlignment: TAlignment read FTextAlignment write SetTextAlignment default taCenter;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CMT', [TCMTCustomButton]);
end;

{ CONSTRUCTOR / DESTRUCTOR }

constructor TCMTCustomButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [
    csOpaque,
    csCaptureMouse,
    csClickEvents,
    csDoubleClicks
  ];

  DoubleBuffered := True;
  Width := 120;
  Height := 40;
  Cursor := crHandPoint;
  TabStop := True;

  Font.Name := 'Segoe UI';
  Font.Size := 10;

  FBaseColor := clSkyBlue;
  FHoverColor := clNavy;
  FFontColor := clWhite;
  FHoverFontColor := clWhite;
  FActiveColor := clNavy;
  FFocusBackColor := $002B2B2B;
  FCornerRadius := 10;

  FAllowActive := True;
  FActive := False;
  FHovering := False;

  FFocusOnClick := True;
  FUseFocusBackColor := True;

  FTextAlignment := taCenter;

  FImage := TPicture.Create;
  FImagePosition := ipLeft;
  FImageSpacing := 4;
  FCenterImageOnly := False;
end;

destructor TCMTCustomButton.Destroy;
begin
  FImage.Free;
  inherited;
end;

{ FOCO }

function TCMTCustomButton.CanFocus: Boolean;
begin
  Result := inherited CanFocus and TabStop and Enabled and Visible;
end;

procedure TCMTCustomButton.WMSetFocus(var Message: TWMSetFocus);
begin
  inherited;
  Invalidate;
end;

procedure TCMTCustomButton.WMKillFocus(var Message: TWMKillFocus);
begin
  inherited;
  Invalidate;
end;

{ TECLADO / MOUSE }

procedure TCMTCustomButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) or (Key = VK_SPACE) then
  begin
    Click;
    Key := 0;
  end;
end;

procedure TCMTCustomButton.WMLButtonDown(var Message: TWMLButtonDown);
begin
  inherited;
  if FFocusOnClick and TabStop and CanFocus then
    SetFocus;
end;

procedure TCMTCustomButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  FHovering := True;
  Invalidate;
end;

procedure TCMTCustomButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FHovering := False;
  Invalidate;
end;

{ SETTERS }

procedure TCMTCustomButton.SetBaseColor(Value: TColor);
begin
  if FBaseColor <> Value then
  begin
    FBaseColor := Value;
    Invalidate;
  end;
end;

procedure TCMTCustomButton.SetHoverColor(Value: TColor);
begin
  if FHoverColor <> Value then
  begin
    FHoverColor := Value;
    Invalidate;
  end;
end;

procedure TCMTCustomButton.SetFontColor(Value: TColor);
begin
  if FFontColor <> Value then
  begin
    FFontColor := Value;
    Invalidate;
  end;
end;

procedure TCMTCustomButton.SetHoverFontColor(Value: TColor);
begin
  if FHoverFontColor <> Value then
  begin
    FHoverFontColor := Value;
    Invalidate;
  end;
end;

procedure TCMTCustomButton.SetCornerRadius(Value: Integer);
begin
  if FCornerRadius <> Value then
  begin
    FCornerRadius := Value;
    Invalidate;
  end;
end;

procedure TCMTCustomButton.SetImage(Value: TPicture);
begin
  FImage.Assign(Value);
  Invalidate;
end;

procedure TCMTCustomButton.SetImagePosition(Value: TImagePosition);
begin
  if FImagePosition <> Value then
  begin
    FImagePosition := Value;
    Invalidate;
  end;
end;

procedure TCMTCustomButton.SetImageSpacing(Value: Integer);
begin
  if FImageSpacing <> Value then
  begin
    FImageSpacing := Value;
    Invalidate;
  end;
end;

procedure TCMTCustomButton.SetTextAlignment(const Value: TAlignment);
begin
  if FTextAlignment <> Value then
  begin
    FTextAlignment := Value;
    Invalidate;
  end;
end;

procedure TCMTCustomButton.SetCenterImageOnly(const Value: Boolean);
begin
  if FCenterImageOnly <> Value then
  begin
    FCenterImageOnly := Value;
    Invalidate;
  end;
end;

procedure TCMTCustomButton.SetActive(const Value: Boolean);
begin
  if not FAllowActive then
    Exit;

  if FActive <> Value then
  begin
    FActive := Value;
    Invalidate;
  end;
end;

{ PINTURA }

procedure TCMTCustomButton.Paint;
var
  R, TextRect, ImgRect: TRect;
  BgColor, TxtColor: TColor;
  Flags: Longint;
  ImgW, ImgH, TotalHeight: Integer;
begin
  R := ClientRect;

  if not Enabled then
  begin
    BgColor := clBtnShadow;
    TxtColor := clBtnHighlight;
  end
  else if Focused and TabStop and FUseFocusBackColor then
  begin
    BgColor := FFocusBackColor;
    TxtColor := FHoverFontColor;
  end
  else if FActive then
  begin
    BgColor := FActiveColor;
    TxtColor := FHoverFontColor;
  end
  else if FHovering then
  begin
    BgColor := FHoverColor;
    TxtColor := FHoverFontColor;
  end
  else
  begin
    BgColor := FBaseColor;
    TxtColor := FFontColor;
  end;

  Canvas.Brush.Color := BgColor;
  Canvas.Pen.Style := psClear;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, FCornerRadius, FCornerRadius);

  Canvas.Font.Assign(Font);
  Canvas.Font.Color := TxtColor;

  ImgW := 0;
  ImgH := 0;
  ImgRect := Rect(0, 0, 0, 0);
  TextRect := R;

  if Assigned(FImage.Graphic) and not FImage.Graphic.Empty then
  begin
    ImgW := FImage.Width;
    ImgH := FImage.Height;

    if Caption = '' then
    begin
      ImgRect := Rect(
        (R.Width - ImgW) div 2,
        (R.Height - ImgH) div 2,
        0, 0
      );
      Canvas.Draw(ImgRect.Left, ImgRect.Top, FImage.Graphic);
      Exit;
    end;

    case FImagePosition of
      ipLeft:
        begin
          ImgRect.Left := R.Left + 8;
          ImgRect.Top := (R.Height - ImgH) div 2;
          TextRect.Left := ImgRect.Left + ImgW + FImageSpacing;
        end;
      ipRight:
        begin
          ImgRect.Left := R.Right - ImgW - 8;
          ImgRect.Top := (R.Height - ImgH) div 2;
          TextRect.Right := ImgRect.Left - FImageSpacing;
        end;
      ipTop:
        begin
          TotalHeight := ImgH + FImageSpacing + Canvas.TextHeight(Caption);
          ImgRect.Top := (R.Height - TotalHeight) div 2;
          ImgRect.Left := (R.Width - ImgW) div 2;
          TextRect.Top := ImgRect.Top + ImgH + FImageSpacing;
        end;
      ipBottom:
        begin
          TotalHeight := ImgH + FImageSpacing + Canvas.TextHeight(Caption);
          TextRect.Top := (R.Height - TotalHeight) div 2;
          ImgRect.Top := TextRect.Top + Canvas.TextHeight(Caption) + FImageSpacing;
          ImgRect.Left := (R.Width - ImgW) div 2;
        end;
    end;

    Canvas.Draw(ImgRect.Left, ImgRect.Top, FImage.Graphic);
  end;

  Flags := DT_SINGLELINE or DT_VCENTER;
  case FTextAlignment of
    taLeftJustify:  Flags := Flags or DT_LEFT;
    taCenter:       Flags := Flags or DT_CENTER;
    taRightJustify: Flags := Flags or DT_RIGHT;
  end;

  DrawText(Canvas.Handle, PChar(Caption), -1, TextRect, Flags);
end;

procedure TCMTCustomButton.Resize;
begin
  inherited;
  Invalidate;
end;

procedure TCMTCustomButton.ClearHover;
begin
  FHovering := False;
  Invalidate;
end;

procedure TCMTCustomButton.Click;
begin
  inherited;
end;

end.
