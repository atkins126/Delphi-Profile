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

      class function GetMedian(AValues: TArray<Double>): Double;

    public
      constructor Create(const AMeasureName: string; AValues: TArray<Double>);
      class function CommaHeader: string;
      function CommaText: string;
  end;

implementation

uses
  System.Generics.Collections,
  System.SysUtils,
  System.Math;

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

class function TAggregateInfo.GetMedian(AValues: TArray<Double>): Double;
var
  len: Integer;
begin
  len := Length(AValues);
  Assert(len > 0);
  TArray.Sort<Double>(AValues);
  if (len mod 2) = 0 then
    Result := (AValues[(len div 2) - 1] + AValues[len div 2]) / 2
  else
    Result := AValues[len div 2];
end;

class function TAggregateInfo.CommaHeader: string;
const
  CHeaderFormat = '"%s","%s","%s","%s","%s"';
begin
  Result := Format(CHeaderFormat, ['Measure', 'Total', 'Median', 'Mean', 'Standard Deviation']);
end;

function TAggregateInfo.CommaText: string;
const
  CTextFormat = '"%s","%.3f","%.3f","%.3f","%.3f"';
begin
  Result := Format(CTextFormat, [FMeasureName, FTotal, FMedian, FMean, FStddev]);
end;

end.
