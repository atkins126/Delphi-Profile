object FormViewer: TFormViewer
  Left = 0
  Top = 0
  Caption = 'FormViewer'
  ClientHeight = 761
  ClientWidth = 584
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object AggregateSplitter: TSplitter
    Left = 0
    Top = 638
    Width = 584
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 0
    ExplicitWidth = 761
  end
  object CallsGrid: TStringGrid
    Left = 0
    Top = 0
    Width = 584
    Height = 638
    Align = alClient
    ColCount = 4
    DrawingStyle = gdsClassic
    FixedCols = 0
    RowCount = 4
    TabOrder = 0
    OnDrawCell = CallsGridDrawCell
    OnKeyDown = CallsGridKeyDown
  end
  object AggregateGrid: TStringGrid
    Left = 0
    Top = 641
    Width = 584
    Height = 120
    Align = alBottom
    DrawingStyle = gdsClassic
    FixedCols = 0
    RowCount = 4
    TabOrder = 1
    OnDrawCell = AggregateGridDrawCell
    OnKeyDown = AggregateGridKeyDown
  end
end
