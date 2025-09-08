unit CMTButton;

interface

uses
  System.Classes, Vcl.Controls,  System.Math, Vcl.StdCtrls, Vcl.Graphics, Winapi.Messages, Winapi.Windows, System.StrUtils;

type
  TCMTButton = class(TButton)
  private
    FBackgroundColor: TColor;
    FTextColor: TColor;
    FHoverColor: TColor;
    FCornerRadius: Integer;
    FIsHovering: Boolean;
    procedure SetBackgroundColor(const Value: TColor);
    procedure SetTextColor(const Value: TColor);
    procedure SetHoverColor(const Value: TColor);
    procedure SetCornerRadius(const Value: Integer);
    procedure CNDrawItem(var Message: TWMDrawItem); message WM_DRAWITEM;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure PaintButton(Canvas: TCanvas; Rect: TRect);
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BackgroundColor: TColor read FBackgroundColor write SetBackgroundColor default clSkyBlue;
    property TextColor: TColor read FTextColor write SetTextColor default clWhite;
    property HoverColor: TColor read FHoverColor write SetHoverColor default clNavy;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius default 8;
  end;


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CMT', [TCMTButton]);
end;

constructor TCMTButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBackgroundColor := clSkyBlue;
  FTextColor := clWhite;
  FHoverColor := clNavy;
  FCornerRadius := 8;
  FIsHovering := False;
  Font.Name := 'Segoe UI';
  Font.Size := 10;
  Font.Style := [fsBold];
end;

procedure TCMTButton.SetBackgroundColor(const Value: TColor);
begin
  FBackgroundColor := Value;
  Invalidate;
end;

procedure TCMTButton.SetTextColor(const Value: TColor);
begin
  FTextColor := Value;
  Invalidate;
end;

procedure TCMTButton.SetHoverColor(const Value: TColor);
begin
  FHoverColor := Value;
  Invalidate;
end;

procedure TCMTButton.SetCornerRadius(const Value: Integer);
begin
  FCornerRadius := Value;
  Invalidate;
end;

procedure TCMTButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  FIsHovering := True;
  Invalidate;
end;

procedure TCMTButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FIsHovering := False;
  Invalidate;
end;

procedure TCMTButton.CNDrawItem(var Message: TWMDrawItem);
var
  TmpCanvas: TCanvas;
begin
  TmpCanvas := TCanvas.Create;
  try
    TmpCanvas.Handle := Message.DrawItemStruct.hDC;
    PaintButton(TmpCanvas, Message.DrawItemStruct.rcItem);
  finally
    TmpCanvas.Free;
  end;
end;

procedure TCMTButton.PaintButton(Canvas: TCanvas; Rect: TRect);
var
  R: TRect;
  BtnColor: TColor;
begin
  Canvas.Font := Font;
  Canvas.Brush.Style := bsSolid;

  BtnColor := IfThen(FIsHovering, FHoverColor, FBackgroundColor);
  Canvas.Brush.Color := BtnColor;
  Canvas.FillRect(Rect);

  // Desenhar bordas arredondadas (simples)
  R := Rect;
  InflateRect(R, -1, -1);
  Canvas.Pen.Color := clGray;
  Canvas.RoundRect(R.Left, R.Top, R.Right, R.Bottom, FCornerRadius, FCornerRadius);

  // Texto centralizado
  Canvas.Font.Color := FTextColor;
  DrawText(Canvas.Handle, PChar(Caption), -1, R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
end;

end.

