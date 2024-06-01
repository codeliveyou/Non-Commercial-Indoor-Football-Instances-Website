:- use_module(library(clpfd)).
:- dynamic scheduled/3, home_availability/2, away_availability/2, forbidden/2.

% Load the input file
:- consult('PrologFacts/Input1.pl').

not_same_team(T1, T2) :- T1 #\= T2.

% Constraint 2 & 3: Home team availability and away team unavailability are respected
home_away_respected(Slot, T1, T2) :-
    home_availability(Slot, T1),
    away_availability(Slot, T2),
    \+ forbidden(Slot, T1),
    \+ forbidden(Slot, T2).

% Constraint 1: Each team plays a home game against each other team at most once
at_most_once(T1, T2) :-
    not_same_team(T1, T2),
    \+ scheduled(T1, T2, _).

% Constraint 4: Ensure each team plays only one game in a game time slot
one_game_per_slot(T, S) :-
    \+ (scheduled(T, _, S); scheduled(_, T, S)).

% Constraint 5: Each team plays at most 2 games in a period of R_max time slots
at_most_2_games(R_max, T1, S) :-
    S_start #= S - R_max + 1,
    findall(Slot, (scheduled(T1, _, Slot), between(S_start, S, Slot)), TeamSlots1),
    findall(Slot, (scheduled(_, T1, Slot), between(S_start, S, Slot)), TeamSlots2),
    append(TeamSlots1, TeamSlots2, AllSlots),
    length(AllSlots, Len),
    Len #=< 2.

% Constraint 6: There are at least m time slots between two games with the same pair of teams
at_least_m_slots_apart(M, T1, T2, S) :-
    findall(Slot1, scheduled(T1, T2, Slot1), Slots1),
    findall(Slot2, scheduled(T2, T1, Slot2), Slots2),
    append(Slots1, Slots2, AllSlots),
    forall(member(PrevSlot, AllSlots), abs(S - PrevSlot) #>= M).

% Solve the scheduling problem
schedule_games(R_max, M) :-
    findall((T1, T2, S),
            (team(T1), team(T2), slot(S),
             T1 \= T2,
             home_away_respected(S, T1, T2),
             at_most_once(T1, T2),
             one_game_per_slot(T1, S),
             one_game_per_slot(T2, S),
             at_most_2_games(R_max, T1, S),
             at_most_2_games(R_max, T2, S),
             at_least_m_slots_apart(M, T1, T2, S)),
            Games),
    schedule(Games, R_max, M).

schedule([], _, _).
schedule([(T1, T2, S)|Rest], R_max, M) :-
    one_game_per_slot(T1, S),
    one_game_per_slot(T2, S),
    at_most_once(T1, T2),
    home_away_respected(S, T1, T2),
    at_most_2_games(R_max, T1, S),
    at_most_2_games(R_max, T2, S),
    at_least_m_slots_apart(M, T1, T2, S),
    assertz(scheduled(T1, T2, S)),
    schedule(Rest, R_max, M).
schedule([_|Rest], R_max, M) :-
    schedule(Rest, R_max, M).

% Save the schedule to a file
save_schedule_to_file(Filename) :-
    open(Filename, write, Stream),
    findall((T1, T2, S), scheduled(T1, T2, S), Schedule),
    sort(Schedule, SortedSchedule),
    forall(member((T1, T2, S), SortedSchedule),
           format(Stream, 'game(~w, ~w, ~w).~n', [T1, T2, S])),
    close(Stream).

% Run the scheduling and save the result to a file
run(R_max, M, Filename) :-
    retractall(scheduled(_, _, _)), % Clear previous results
    schedule_games(R_max, M),
    save_schedule_to_file(Filename).

