unit Delphi.Profile.AggregateReport;

interface

uses
  Delphi.Profile.CallInfo,
  Delphi.Profile.AggregateInfo,
  System.Generics.Collections,
  System.Classes;

type

  TAggregateReport = class
    private
      FReportEntries      : TList<TAggregateInfo>;
      FTotalCalls         : TList<Double>;
      FTotalMicroseconds  : TList<Double>;
      FAverageMicroseconds: TList<Double>;

    public
      constructor Create;
      destructor Destroy; override;

      procedure Add(const ACallInfo: TCallInfo);
      procedure Clear;
      procedure Compute;
      procedure GetLines(ALines: TStrings);
  end;

implementation

uses
  System.SysUtils,
  System.Diagnostics;

{ TAggregateReport }

constructor TAggregateReport.Create;
begin
  FReportEntries       := TObjectList<TAggregateInfo>.Create;
  FTotalCalls          := TList<Double>.Create;
  FTotalMicroseconds   := TList<Double>.Create;
  FAverageMicroseconds := TList<Double>.Create;
end;

destructor TAggregateReport.Destroy;
begin
  FReportEntries.Free;
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

procedure TAggregateReport.Clear;
begin
  FTotalCalls.Clear;
  FTotalMicroseconds.Clear;
  FAverageMicroseconds.Clear;
end;

procedure TAggregateReport.Compute;
begin
  FReportEntries.Clear;
  FReportEntries.Add(TAggregateInfo.Create('Total Calls', FTotalCalls.ToArray));
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
