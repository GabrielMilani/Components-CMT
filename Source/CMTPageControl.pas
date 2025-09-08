unit CMTPageControl;

interface

uses
  System.Classes, Vcl.ComCtrls, Vcl.Graphics, Vcl.Controls, Winapi.Windows, Vcl.Imaging.pngimage;

type
  TBackgroundStyle = (bsStretch, bsCenter, bsTile);

  TCMTPageControl = class(TPageControl)
  private
    FBackground: TPicture;
    FBackgroundColor: TColor;
    FBackgroundStyle: TBackgroundStyle;
    procedure SetBackground(const Value: TPicture);
    procedure SetBackgroundColor(const Value: TColor);
    procedure SetBackgroundStyle(const Value: TBackgroundStyle);
  protected
    procedure PaintWindow(DC: HDC); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  published
    property Background: TPicture read FBackground write SetBackground;
    property BackgroundColor: TColor read FBackgroundColor write SetBackgroundColor default clBtnFace;
    property BackgroundStyle: TBackgroundStyle read FBackgroundStyle write SetBackgroundStyle default bsStretch;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('CMT', [TCMTPageControl]);
end;


constructor TCMTPageControl.Create(AOwner: TComponent);
begin
  inherited;
  FBackground := TPicture.Create;
  FBackgroundColor := clBtnFace;   // cor padrão
  FBackgroundStyle := bsStretch;   // estilo padrão
end;

destructor TCMTPageControl.Destroy;
begin
  FBackground.Free;
  inherited;
end;

procedure TCMTPageControl.PaintWindow(DC: HDC);
var
  R: TRect;
  X, Y: Integer;
  Png: TPngImage;
begin
  inherited;

  Canvas.Handle := DC;
  R := ClientRect;

  // pinta o fundo com a cor escolhida
  Canvas.Brush.Color := FBackgroundColor;
  Canvas.FillRect(R);

  // desenha imagem de fundo, se houver
  if Assigned(FBackground.Graphic) then
  begin
    // caso seja PNG, preserva transparência
    if FBackground.Graphic is TPngImage then
    begin
      Png := TPngImage(FBackground.Graphic);
      case FBackgroundStyle of
        bsStretch:
          Canvas.StretchDraw(R, Png);
        bsCenter:
          begin
            X := (Width - Png.Width) div 2;
            Y := (Height - Png.Height) div 2;
            Canvas.Draw(X, Y, Png);
          end;
        bsTile:
          for X := 0 to Width div Png.Width do
            for Y := 0 to Height div Png.Height do
              Canvas.Draw(X * Png.Width, Y * Png.Height, Png);
      end;
    end
    else
    begin
      // caso não seja PNG (BMP, JPG etc.)
      case FBackgroundStyle of
        bsStretch:
          Canvas.StretchDraw(R, FBackground.Graphic);
        bsCenter:
          begin
            X := (Width - FBackground.Graphic.Width) div 2;
            Y := (Height - FBackground.Graphic.Height) div 2;
            Canvas.Draw(X, Y, FBackground.Graphic);
          end;
        bsTile:
          for X := 0 to Width div FBackground.Graphic.Width do
            for Y := 0 to Height div FBackground.Graphic.Height do
              Canvas.Draw(X * FBackground.Graphic.Width, Y * FBackground.Graphic.Height, FBackground.Graphic);
      end;
    end;
  end;
end;

procedure TCMTPageControl.SetBackground(const Value: TPicture);
begin
  FBackground.Assign(Value);
  Invalidate;
end;

procedure TCMTPageControl.SetBackgroundColor(const Value: TColor);
begin
  if FBackgroundColor <> Value then
  begin
    FBackgroundColor := Value;
    Invalidate;
  end;
end;

procedure TCMTPageControl.SetBackgroundStyle(const Value: TBackgroundStyle);
begin
  if FBackgroundStyle <> Value then
  begin
    FBackgroundStyle := Value;
    Invalidate;
  end;
end;

end.
