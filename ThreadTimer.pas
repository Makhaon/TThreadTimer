unit ThreadTimer;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
 SysUtils,
 Classes,
 SyncObjs;

type
 TThreadTimer = class;

 TTimerThread = class(TThread)
 private
  FEvent:         TEvent;
  FRestartThread: boolean;
  FInterval:      longword;
  FOwner:         TThreadTimer;
  procedure Cycle;
  procedure DoTimer;
 protected
  procedure Execute; override;
 public
  constructor Create(AOwner: TThreadTimer); overload;
  destructor Destroy; override;
  property RestartThread: boolean Read FRestartThread Write FRestartThread;
  property Interval: longword Read FInterval Write FInterval default 1000;
 end;

 TThreadTimer = class(TComponent)
 private
  FOnTimer:     TNotifyEvent;
  FInterval:    cardinal;
  FEnabled:     boolean;
  FTimerThread: TTimerThread;
  procedure SetInterval(const Value: cardinal);
  procedure SetEnabled(const Value: boolean);
  { Private declarations }
 protected
  { Protected declarations }
 public
  constructor Create(AOwner: TComponent); override;
  destructor Destroy; override;
  procedure Start;
  procedure Stop;
  procedure Restart(EnableTimer: boolean = False);
  procedure TermiteAndWait;
  procedure Termite;
  function Terminaed: boolean;
  { Public declarations }
 published
  property Interval: cardinal Read FInterval Write SetInterval default 1000;
  property OnTimer: TNotifyEvent Read FOnTimer Write FOnTimer;
  property Enabled: boolean Read FEnabled Write SetEnabled default False;
  { Published declarations }
 end;

function CreateThreadTimer(AInterval: integer; AOnTimer: TNotifyEvent): TThreadTimer;

procedure Register;

implementation

function CreateThreadTimer(AInterval: integer; AOnTimer: TNotifyEvent): TThreadTimer;
begin
 Result := TThreadTimer.Create(nil);
 Result.Enabled := False;
 Result.Interval := AInterval;
 Result.OnTimer := AOnTimer;
end;

procedure Register;
begin
 RegisterComponents('Makhaon', [TThreadTimer]);
end;

{ TThreadTimer }

constructor TThreadTimer.Create(AOwner: TComponent);
begin
 inherited Create(AOwner);
 FInterval := 1000;
 FEnabled  := False;
 FTimerThread := TTimerThread.Create(Self);
end;

destructor TThreadTimer.Destroy;
begin
 FreeAndNil(FTimerThread);
 inherited;
end;

procedure TThreadTimer.Restart(EnableTimer: boolean = False);
begin
 if EnableTimer then
  FEnabled := True;
 if FEnabled then
  FTimerThread.Interval := FInterval
 else
  FTimerThread.Interval := INFINITE;
 FTimerThread.RestartThread := True;
 FTimerThread.Cycle;
end;

procedure TThreadTimer.SetEnabled(const Value: boolean);
begin
 if FEnabled <> Value then
 begin
  FEnabled := Value;
  Restart;
 end;
end;

procedure TThreadTimer.SetInterval(const Value: cardinal);
begin
 FInterval := Value;
 if FEnabled then
  Restart;
end;

procedure TThreadTimer.Start;
begin
 SetEnabled(True);
end;

procedure TThreadTimer.Stop;
begin
 SetEnabled(False);
end;

function TThreadTimer.Terminaed: boolean;
begin
 Result := not Assigned(FTimerThread) or FTimerThread.Terminated;
end;

procedure TThreadTimer.Termite;
begin
 if Assigned(FTimerThread) then
  with FTimerThread do
   Terminate;
end;

procedure TThreadTimer.TermiteAndWait;
begin
 if Assigned(FTimerThread) then
  with FTimerThread do
  begin
   Terminate;
   Cycle;
   WaitFor;
  end;
end;

{ TTimerThread }

constructor TTimerThread.Create(AOwner: TThreadTimer);
begin
 FEvent := TEvent.Create(nil, True, False, '');
 FOwner := AOwner;
 FInterval := INFINITE;
 inherited Create(False);
end;

destructor TTimerThread.Destroy;
begin
 Terminate;
 Cycle;
 WaitFor;
 FreeAndNil(FEvent);
 inherited;
end;

procedure TTimerThread.DoTimer;
begin
 if Assigned(FOwner.FOnTimer) then
  FOwner.FOnTimer(Self);
end;

procedure TTimerThread.Execute;
begin
 while not Terminated do
 begin
  FEvent.ResetEvent;
  FEvent.WaitFor(FInterval);
  if FRestartThread then
   FRestartThread := False
  else if not Terminated then
   DoTimer;
 end;
end;

procedure TTimerThread.Cycle;
begin
 FEvent.SetEvent;
end;

end.
