:- use_module(library(clpfd)).
:- use_module(library(yall)).
:- use_module(library(pairs)).

% Show constraints for debugging
assert(clpfd:full_answer).

% Pair with index
enum([], [], _).
enum([X|Xs], [C-X|Ys], C) :-
    writeln("enum"),
    succ(C,C2),
    enum(Xs, Ys, C2).


% Helper predicate for removing nth element of list
list_nth1_dropped(As,N1,Bs) :-
   same_length(As,[_|Bs]),
   append(Prefix,[_|Suffix],As),
   length([_|Prefix],N1),
   append(Prefix,Suffix,Bs).


% Helper predicate for reading file lines to list
stream_lines(In, Lines) :-
    read_string(In, _, Str),
    split_string(Str, "\n", "", Lines).


% ascending([A, B| R]) constrains the input list to be in ascending order, 
% assuming an orderable A and B 
ascending([A, B| R]):-
   freeze(A, 
      freeze(B, (A < B, 
            freeze(R, (R=[] -> true ; ascending([B|R])))))).


% num_list(N, L) relates a list size N to a list L, ensuring that it has N 
% elements in ascending order, starting at 1. This leaves only a single 
% possible list, reducing irrelevant isomorphic states.
num_list(N, L) :-
    length(L, N),
    L ins 1..N,
    all_distinct(L),
    ascending(L).


% input_attributes(
%    +InputFileLines, -NumberDays, -NumberTeams, -AvailabilityMatrix) 
% relates a list of lists of strings representing the number of days, teams, 
% and their availability, with parsed variables representing the same
input_attributes(InputFileLines, NumberDays, NumberTeams, AvailabilityMatrix) :-
    maplist([InL,OutL]>>split_string(InL, "\t", "\r ", OutL), InputFileLines, 
        [DaysLine, TeamsLine | AvailLines]),
    % Instantiate list without blank line at the end
    append(AvailLinesNoBlank, [_], AvailLines),
    % Relate lines with data to the specific numbers we're interested in
    nth0(0, DaysLine, DaysString),
    number_string(NumberDays, DaysString),
    nth0(0, TeamsLine, TeamsString),
    number_string(NumberTeams, TeamsString),
    maplist([InSL, OutSL]>>maplist(number_string, OutSL, InSL), 
        AvailLinesNoBlank, AvailabilityMatrix).

% days_diff(-Games, -Rmax) enforces constraint that a team's games are at least Rmax days apart
days_diff([], _).
days_diff([Game|GamesTail], Rmax) :-
    write("days_diff: "),
    writeln(GamesTail),
    maplist({Game}/[GN]>>((Rmax #< (GN - Game)) #\/ (Rmax #< (Game - GN))), GamesTail),
    days_diff(GamesTail, Rmax).

index_cardinality(N-0, N-V) :- V in 0..5.
index_cardinality(N-1, N-1).
index_cardinality(N-2, N-0).

% games_requirements(-TeamGames, -TeamAvailabilities) enforces that teams play their home games, and aren't
% scheduled for any games which they aren't available for 
games_requirements(TeamGames, TeamAvailabilities) :-
    enum(TeamAvailabilities, IndexedAvails, 0),
    writeln(IndexedAvails),
    maplist(index_cardinality, IndexedAvails, AvailCardinalities),
    writeln(AvailCardinalities),
    global_cardinality(TeamGames, AvailCardinalities).


% availability_schedule(-AvailabilityColumns, -ScheduleMatrixN, +ScheduleMatrixN0) is a recursive relation
% between the availability matrix in column major order, the schedule matrix, and the inner schedule matrix
% without the head row and column (that is, the current team being assigned dates)
availability_schedule(TeamN, AvailabilityColumns, ScheduleRows, ScheduleColumns, RMax) :-
    writeln("availability_schedule"),
    nth1(TeamN, ScheduleRows, ScheduleRowsTeam),
    nth1(TeamN, ScheduleColumns, ScheduleColumnsTeam),
    list_nth1_dropped(ScheduleRowsTeam, TeamN, ScheduleRowsTeamNoSelf),
    list_nth1_dropped(ScheduleColumnsTeam, TeamN, ScheduleColumnsTeamNoSelf),
    writeln(ScheduleRowsTeamNoSelf),
    append(ScheduleRowsTeamNoSelf, ScheduleColumnsTeamNoSelf, TeamGames),
    all_distinct(TeamGames),
    nth1(TeamN, AvailabilityColumns, TeamAvailabilities),
    days_diff(TeamGames, RMax),
    games_requirements(TeamGames, TeamAvailabilities).


% tournament_schedule(
%       -NumberTeams, -NumberDays, -Rmax, -AvailabilityMatrix, +ScheduleMatrix)
% models our constraints for scheduling based on our desired attributes
tournament_schedule(NumberTeams, NumberDays, Rmax, AvailabilityMatrix, ScheduleRows) :-
    % Schedule Matrix is composed of match days for NumberTeams against
    % NumberTeams (rows and columns)
    writeln("tournament_schedule"),
    length(ScheduleRows, NumberTeams),
    maplist(same_length(ScheduleRows), ScheduleRows),
    append(ScheduleRows, Vs), Vs ins 1..NumberDays,
    length(ScheduleColumns, NumberTeams),
    maplist(all_distinct, ScheduleRows),
    transpose(ScheduleRows, ScheduleColumns),
    maplist(all_distinct, ScheduleColumns),
    transpose(AvailabilityMatrix, AvailabilityColumns),
    num_list(NumberTeams, TeamsIndex),
    maplist({AvailabilityColumns, ScheduleRows, ScheduleColumns, Rmax}/[N]>>availability_schedule(N, AvailabilityColumns, ScheduleRows, ScheduleColumns, Rmax), TeamsIndex),
    writeln("end tournament_schedule").


% input_schedule(-InputFilePath, -Rmax, -OutputFilePath) reads the input data from
% the given InputFilePath, uses Rmax in the relation tournament_schedule, and writes the 
% matched schedule to the OutputFilePath
input_schedule(InputFilePath, Rmax, OutputFilePath) :-
    setup_call_cleanup(open(InputFilePath, read, In),
       stream_lines(In, LinesUnsep),
       close(In)),
    input_attributes(LinesUnsep, NumberDays, NumberTeams, AvailabilityMatrix),
    tournament_schedule(
        NumberTeams, NumberDays, Rmax, AvailabilityMatrix, ScheduleMatrix),
    nth0(0, ScheduleMatrix, SchedMat0),
    nth0(2, SchedMat0, SchedMat00),
    fd_dom(SchedMat00, SchedMat00Dom),
    writeln(SchedMat00Dom),
    writeln(ScheduleMatrix),
    open(OutputFilePath, write, Out),
    maplist({Out}/[ScheduleRow]>>(labeling([ffc], ScheduleRow), writeln(ScheduleRow), writeln(Out, ScheduleRow)), ScheduleMatrix),
    close(Out).


% Comparison with approach described in "Scheduling a non-professional indoor football league: a tabu search based approach" by
% Bulck, Goossens, Spieksma - the approach in the aforementioned paper lays out a particular algorithm for scheduling teams in
% a tournament, which fundamentally returns to perturbation of the schedule followed by comparison to an existing possible
% schedule. In comparison, the clpfd solution creates a higher level model, which is then broken down by clpfd into Hoare logic
% which can be understood by Prolog's unification alogirthm, which is itself more general than the algorithm described by Bulck, et al.