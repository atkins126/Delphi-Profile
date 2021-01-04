unit Delphi.Profile.AggregateReport;

interface

uses
  Delphi.Profile.ScopeInfo,
  Delphi.Profile.AggregateInfo,
  System.Generics.Collections,
  System.Classes;

type

  TAggregateReport = class
    private
      FReportEntries      : TList<TAggregateInfo>;
      FTotalHits          : TList<Double>;
      FTotalMicroseconds  : TList<Double>;
      FAverageMicroseconds: TList<Double>;

    public
      constructor Create;
      destructor Destroy; override;

      procedure Add(const AScopeInfo: TScopeInfo);
      procedure Clear;
      procedure Compute;
      procedure GetLines(ALines: TStrings);
  end;

implementation

{ TAggregateReport }

constructor TAggregateReport.Create;
begin
  FReportEntries       := TObjectList<TAggregateInfo>.Create;
  FTotalHits           := TList<Double>.Create;
  FTotalMicroseconds   := TList<Double>.Create;
  FAverageMicroseconds := TList<Double>.Create;
end;

destructor TAggregateReport.Destroy;
begin
  FReportEntries.Free;
  FTotalHits.Free;
  FTotalMicroseconds.Free;
  FAverageMicroseconds.Free;
  inherited;
end;

procedure TAggregateReport.Add(const AScopeInfo: TScopeInfo);
begin
  FTotalHits.Add(AScopeInfo.TotalHits);
  FTotalMicroseconds.Add(AScopeInfo.TotalMicroseconds);
  FAverageMicroseconds.Add(AScopeInfo.AverageMicroseconds);
end;

procedure TAggregateReport.Clear;
begin
  FTotalHits.Clear;
  FTotalMicroseconds.Clear;
  FAverageMicroseconds.Clear;
end;

procedure TAggregateReport.Compute;
begin
  FReportEntries.Clear;
  FReportEntries.Add(TAggregateInfo.Create('Total Hits', FTotalHits.ToArray));
  FReportEntries.Add(TAggregateInfo.Create('Total Time (us)', FTotalMicroseconds.ToArray));
  FReportEntries.Add(TAggregateInfo.Create('Average Time (us)', FAverageMicroseconds.ToArray));
end;

procedure TAggregateReport.GetLines(ALines: TStrings);
var
  AggregateInfo: TAggregateInfo;
begin
  ALines.Clear;
  ALines.Add(TAggregateInfo.CommaHeader);
  for AggregateInfo in FReportEntries do
    ALines.Add(AggregateInfo.CommaText);
end;

end.
