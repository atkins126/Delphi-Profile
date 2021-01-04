unit Delphi.Profile;

interface

function Trace(const AScopeName: string): IInterface;

implementation

uses
  Delphi.Profile.Trace;

function Trace(const AScopeName: string): IInterface;
begin
  Result := TTrace.Create(AScopeName);
end;

end.
