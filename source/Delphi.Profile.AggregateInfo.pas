unit Delphi.Profile.AggregateInfo;

interface

type

  TAggregateInfo = class
    private
      FMeasureName: string;
      FTotal      : Double;
      FMedian     : Double;
      FMean       : Double;
      FStddev     : Double;

      class function GetMedian(var AValues: TArray<Double>): Double;
      class function GetCommaHeader: string; static;
      function GetCommaText: string;

    public
      constructor Create(const AMeasureName: string; AValues: TArray<Double>);

      class property CommaHeader: string read GetCommaHeader;
      property CommaText: string read GetCommaText;
      property Total: Double read FTotal;
      property Median: Double read FMedian;
      property Mean: Double read FMean;
      property Stddev: Double read FStddev;
  end;

implementation

uses
  System.Generics.Collections,
  System.SysUtils,
  System.Math;

{ TAggregateInfo }

constructor TAggregateInfo.Create(const AMeasureName: string; AValues: TArray<Double>);
begin
  FMeasureName := AMeasureName;
  if Length(AValues) > 0 then
    begin
      FTotal  := Sum(AValues);
      FMedian := GetMedian(AValues);
      MeanAndStdDev(AValues, FMean, FStddev);
    end;
end;

class function TAggregateInfo.GetMedian(var AValues: TArray<Double>): Double;
var
  Count : Integer;
  Middle: Integer;
begin
  TArray.Sort<Double>(AValues);
  Count    := Length(AValues);
  Assert(Count > 0);
  Middle   := Count div 2;
  if (Count mod 2) = 0 then
    Result := (AValues[Middle - 1] + AValues[Middle]) / 2
  else
    Result := AValues[Middle];
end;

class function TAggregateInfo.GetCommaHeader: string;
const
  CHeaderFormat = '"%s","%s","%s","%s","%s"';
begin
  Result := Format(CHeaderFormat, ['Measure', 'Total', 'Median', 'Mean', 'Standard Deviation']);
end;

function TAggregateInfo.GetCommaText: string;
const
  CTextFormat = '"%s","%.3f","%.3f","%.3f","%.3f"';
begin
  Result := Format(CTextFormat, [FMeasureName, FTotal, FMedian, FMean, FStddev]);
end;

end.
