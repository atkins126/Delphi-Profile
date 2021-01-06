unit Delphi.Profile.ScopeInfo;

interface

uses
  Delphi.Profile.PerformanceMetrics;

type

  TScopeInfo = class
    private
      FScopeName   : string;
      FTotalHits   : Int64;
      FTotalMetrics: TPerformanceMetrics;

      class function GetCommaHeader: string; static;
      function GetCommaText: string;
      function GetAverageMicroseconds: Double;
      function GetAverageCpuTime: Double;

    public
      constructor Create(const AScopeName: string);

      procedure Add(const AMetrics: TPerformanceMetrics);

      class property CommaHeader: string read GetCommaHeader;
      property CommaText: string read GetCommaText;
      property TotalHits: Int64 read FTotalHits;
      property TotalMetrics: TPerformanceMetrics read FTotalMetrics;
      property AverageMicroseconds: Double read GetAverageMicroseconds;
      property AverageCpuTime: Double read GetAverageCpuTime;
  end;

implementation

uses
  System.SysUtils;

{ TScopeInfo }

procedure TScopeInfo.Add(const AMetrics: TPerformanceMetrics);
begin
  Inc(FTotalHits);
  FTotalMetrics.Add(AMetrics);
end;

constructor TScopeInfo.Create(const AScopeName: string);
begin
  FScopeName := AScopeName;
end;

class function TScopeInfo.GetCommaHeader: string;
const
  CHeaderFormat = '"%s","%s","%s","%s","%s","%s"';
begin
  Result := Format(CHeaderFormat, ['Scope Name', 'Total Hits', 'Total Time (us)', 'Average Time (us)', 'Total Cycles',
      'Average Cycles']);
end;

function TScopeInfo.GetCommaText: string;
const
  CTextFormat = '"%s","%d","%.1f","%.3f","%d","%.1f"';
begin
  Result := Format(CTextFormat, [FScopeName, FTotalHits, FTotalMetrics.Microseconds, GetAverageMicroseconds,
      FTotalMetrics.CpuTime, GetAverageCpuTime]);
end;

function TScopeInfo.GetAverageCpuTime: Double;
begin
  Assert(FTotalHits > 0);
  Result := FTotalMetrics.CpuTime / FTotalHits;
end;

function TScopeInfo.GetAverageMicroseconds: Double;
begin
  Assert(FTotalHits > 0);
  Result := FTotalMetrics.Microseconds / FTotalHits;
end;

end.
