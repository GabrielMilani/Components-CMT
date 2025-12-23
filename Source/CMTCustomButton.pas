unit CMTCustomButton;

interface

uses
  Vcl.Graphics, Winapi.Windows, System.Classes, Vcl.Controls, Winapi.Messages;

type
  TImagePosition = (ipLeft, ipRight, ipTop, ipBottom);

type
  TCMTCustomButton = class(TCustomControl)
  private
    FBaseColor: TColor;
    FHoverColor: TColor;
    FFontColor: TColor;
    FHoverFontColor: TColor;
    FCornerRadius: Integer;
    FHovering: Boolean;
    FImage: TPicture;
    FImagePosition: TImagePosition;
    FImageSpacing: Integer;
    FTextAlignment: TAlignment;
    FCenterImageOnly: Boolean;
    FActive: Boolean;

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
    procedure CMEnter(var Message: TCMEnter); message CM_ENTER;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure Click; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
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

    property OnClick;
    property OnDblClick;

    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;

    property OnKeyDown;
    property OnKeyUp;
    property OnKeyPress;

    property OnEnter;
    property OnExit;

    property OnContextPopup;

    property BaseColor: TColor read FBaseColor write SetBaseColor default clSkyBlue;
    property HoverColor: TColor read FHoverColor write SetHoverColor default clNavy;
    property FontColor: TColor read FFontColor write SetFontColor default clWhite;
    property HoverFontColor: TColor read FHoverFontColor write SetHoverFontColor default clWhite;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius default 10;
    property Image: TPicture read FImage write SetImage;
    property ImagePosition: TImagePosition read FImagePosition write SetImagePosition default ipLeft;
    property ImageSpacing: Integer read FImageSpacing write SetImageSpacing default 4;
    property TextAlignment: TAlignment read FTextAlignment write SetTextAlignment default taCenter;
    property CenterImageOnly: Boolean read FCenterImageOnly write SetCenterImageOnly default False;

    property Active: Boolean read FActive write SetActive;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CMT', [TCMTCustomButton]);
end;

constructor TCMTCustomButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse, csClickEvents, csDoubleClicks];
  DoubleBuffered := True;
  FTextAlignment := taCenter;
  FActive := False; // Inicializa a nova propriedade como False

  Width := 120;
  Height := 40;

  FBaseColor := clSkyBlue;
  FHoverColor := clNavy;
  FFontColor := clWhite;
  FHoverFontColor := clWhite;
  FCornerRadius := 10;

  Font.Name := 'Segoe UI';
  Font.Size := 10;
  Cursor := crHandPoint;
  TabStop := True;

  FImage := TPicture.Create;
  FImagePosition := ipLeft;
  FImageSpacing := 4;
end;

destructor TCMTCustomButton.Destroy;
begin
  FImage.Free;
  inherited;
end;

procedure TCMTCustomButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if (Key = VK_RETURN) or (Key = VK_SPACE) then
  begin
    Click;
    Key := 0;
  end;
end;

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

procedure TCMTCustomButton.SetCenterImageOnly(const Value: Boolean);
begin
  if FCenterImageOnly <> Value then
  begin
    FCenterImageOnly := Value;
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

procedure TCMTCustomButton.SetActive(const Value: Boolean);
begin
  if FActive <> Value then
  begin
    FActive := Value;
    // Define FHovering de acordo com a nova propriedade 'Active'
    FHovering := Value;
    Invalidate;
  end;
end;

procedure TCMTCustomButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  // Apenas muda o estado se o botão não estiver ativo permanentemente
  if not FActive then
  begin
    FHovering := True;
    Invalidate;
  end;
end;

procedure TCMTCustomButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  // Apenas muda o estado se o botão não estiver ativo permanentemente
  if not FActive then
    FHovering := Focused; // mantém o hover se ainda estiver com foco
  Invalidate;
end;

procedure TCMTCustomButton.CMEnter(var Message: TCMEnter);
begin
  inherited;
  FHovering := True;
  Invalidate;
end;

procedure TCMTCustomButton.CMExit(var Message: TCMExit);
begin
  inherited;
  // Apenas muda o estado se o botão não estiver ativo permanentemente
  if not FActive then
    FHovering := False;
  Invalidate;
end;

procedure TCMTCustomButton.Paint;
var
  R, TextRect, ImgRect: TRect;
  BgColor, TxtColor: TColor;
  Flags: Longint;
  ImgW, ImgH, TotalHeight: Integer;
begin
  inherited;

  R := ClientRect;

  // Usa a cor de hover se estiver ativo ou se o mouse estiver sobre ele
  if FActive or FHovering then
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
      ImgRect.Left := (R.Width - ImgW) div 2;
      ImgRect.Top := (R.Height - ImgH) div 2;
      ImgRect.Right := ImgRect.Left + ImgW;
      ImgRect.Bottom := ImgRect.Top + ImgH;

      Canvas.Draw(ImgRect.Left, ImgRect.Top, FImage.Graphic);
      Exit;
    end;

    case FImagePosition of
      ipLeft:
        begin
          ImgRect.Left := R.Left + 8;
          ImgRect.Top := (R.Height - ImgH) div 2;
          ImgRect.Right := ImgRect.Left + ImgW;
          ImgRect.Bottom := ImgRect.Top + ImgH;
          TextRect.Left := ImgRect.Right + FImageSpacing;
        end;

      ipRight:
        begin
          ImgRect.Right := R.Right - 8;
          ImgRect.Top := (R.Height - ImgH) div 2;
          ImgRect.Left := ImgRect.Right - ImgW;
          ImgRect.Bottom := ImgRect.Top + ImgH;
          TextRect.Right := ImgRect.Left - FImageSpacing;
        end;

      ipTop:
        begin
          TotalHeight := ImgH + FImageSpacing + Canvas.TextHeight(Caption);
          ImgRect.Top := (R.Height - TotalHeight) div 2;
          ImgRect.Left := (R.Width - ImgW) div 2;
          ImgRect.Bottom := ImgRect.Top + ImgH;
          ImgRect.Right := ImgRect.Left + ImgW;

          TextRect.Top := ImgRect.Bottom + FImageSpacing;
          TextRect.Left := R.Left;
          TextRect.Right := R.Right;
          TextRect.Bottom := TextRect.Top + Canvas.TextHeight(Caption);
        end;

      ipBottom:
        begin
          TotalHeight := ImgH + FImageSpacing + Canvas.TextHeight(Caption);
          TextRect.Top := (R.Height - TotalHeight) div 2;
          TextRect.Left := R.Left;
          TextRect.Right := R.Right;
          TextRect.Bottom := TextRect.Top + Canvas.TextHeight(Caption);

          ImgRect.Top := TextRect.Bottom + FImageSpacing;
          ImgRect.Left := (R.Width - ImgW) div 2;
          ImgRect.Bottom := ImgRect.Top + ImgH;
          ImgRect.Right := ImgRect.Left + ImgW;
        end;
    end;

    Canvas.Draw(ImgRect.Left, ImgRect.Top, FImage.Graphic);
  end;

  // Alinhamento do texto
  Flags := DT_SINGLELINE;

  case FImagePosition of
    ipTop, ipBottom:
      Flags := Flags or DT_CENTER or DT_TOP;
  else
    Flags := Flags or DT_VCENTER;
    case FTextAlignment of
      taLeftJustify: Flags := Flags or DT_LEFT;
      taCenter:      Flags := Flags or DT_CENTER;
      taRightJustify: Flags := Flags or DT_RIGHT;
    end;
  end;

  DrawText(Canvas.Handle, PChar(Caption), -1, TextRect, Flags);
end;

procedure TCMTCustomButton.Resize;
begin
  inherited;
  Invalidate;
end;

procedure TCMTCustomButton.Click;
begin
  inherited;
end;

end.
