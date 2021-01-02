unit Delphi.Profile.AggregateReport;

interface

uses
  Delphi.Profile.AggregateInfo,
  Delphi.Profile.CallInfo,
  System.Generics.Collections,
  System.Classes;

type

  TAggregateReport = class
    private
      FReportPath         : string;
      FReportLines        : TStrings;
      FReportInfo         : TList<TAggregateInfo>;
      FTotalCalls         : TList<Double>;
      FTotalMicroseconds  : TList<Double>;
      FAverageMicroseconds: TList<Double>;

    public
      constructor Create;
      destructor Destroy; override;

      procedure Add(const ACallInfo: TCallInfo);
      procedure Compute;
      procedure SaveToFile;

    public
      property ReportPath: string write FReportPath;
  end;

implementation

constructor TAggregateReport.Create;
begin
  inherited;
  FReportLines         := TStringList.Create;
  FReportInfo          := TObjectList<TAggregateInfo>.Create;
  FTotalCalls          := TList<Double>.Create;
  FTotalMicroseconds   := TList<Double>.Create;
  FAverageMicroseconds := TList<Double>.Create;
end;

destructor TAggregateReport.Destroy;
begin
  FReportLines.Free;
  FReportInfo.Free;
  FTotalCalls.Free;
  FTotalMicroseconds.Free;
  FAverageMicroseconds.Free;
  inherited;
end;

procedure TAggregateReport.Add(const ACallInfo: TCallInfo);
begin
  FTotalCalls.Add(ACallInfo.TotalCalls);
  FTotalMicroseconds.Add(ACallInfo.TotalMicroseconds);
  FAverageMicroseconds.Add(ACallInfo.AverageMicroseconds);
end;

procedure TAggregateReport.Compute;
begin
  FReportInfo.Add(TAggregateInfo.Create('Total Calls', FTotalCalls.ToArray));
  FReportInfo.Add(TAggregateInfo.Create('Total Time (us)', FTotalMicroseconds.ToArray));
  FReportInfo.Add(TAggregateInfo.Create('Average Time (us)', FAverageMicroseconds.ToArray));
end;

procedure TAggregateReport.SaveToFile;
var
  Info: TAggregateInfo;
begin
  FReportLines.Clear;
  FReportLines.Add(TAggregateInfo.CommaHeader);
  for Info in FReportInfo do
    FReportLines.Add(Info.CommaText);
  FReportLines.SaveToFile(FReportPath);
end;

end.
