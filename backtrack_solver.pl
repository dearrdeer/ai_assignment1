:-dynamic field/2.
:-dynamic visited/2.
:-dynamic answer/3.
:-dynamic visited_after_pass/2.

:-dynamic o/2.
:-dynamic h/2.
:-dynamic t/2.

%% Map reader
read_next(_, end_of_file):- !.
read_next(Stream, Term):-
    assertz(Term),
    read(Stream, Term2),
    read_next(Stream, Term2).

read_map(File):-
    open(File, read, Stream),
    read(Stream, Term),
    read_next(Stream, Term),
    close(Stream).

%% Building field, so we do not need to make 400 bases
add_to_field(X,Y):-
	X is 20, !;
	Y is 20, X1 is (X+1), add_to_field(X1, 0), !;
	assert(field(X,Y)), Y1 is (Y+1), add_to_field(X,Y1), !.
	

%%Checking if 2 field are neighbours
neighbours(X1,Y1,X2,Y2):-
	X2 is X1, Y2 is (Y1+1), field(X2,Y2);
	X2 is (X1+1), Y2 is Y1, field(X2,Y2);
	X2 is X1, Y2 is (Y1-1), field(X2,Y2);
	X2 is (X1-1), Y2 is Y1, field(X2,Y2).

%%When making pass this checks if we have not anybody between our pos and destination pos
has_between(X_from, Y_from, X_to, Y_to, Mode):-
	(o(X_potential, Y_potential); h(X_potential, Y_potential)),
	(not(((X_potential =:= X_from), (Y_potential =:= Y_from))),
	 not(((X_potential =:= X_to), (Y_potential =:= Y_to)))),
	(
	Mode =:= 1, X_from =:= X_potential, (abs(Y_from - Y_potential) + abs(Y_to - Y_potential)) =:= (abs(Y_to - Y_from)), !;
	Mode =:= 2, Y_from =:= Y_potential, (abs(X_from - X_potential) + abs(X_to - X_potential)) =:= (abs(X_to - X_from)), !;
	Mode =:= 3, abs(Y_from - Y_potential) =:= abs(X_from - X_potential), abs(Y_to - Y_potential) =:= abs(X_to - X_potential), (abs(Y_from - Y_potential) + abs(Y_to - Y_potential)) =:= (abs(Y_to - Y_from)), !	).


%%Make pass to field...
%%algorithm looks for every human, and checks if we are one the same line(diagonal)
pass_to(X_from, Y_from, X_to, Y_to):-
	h(X_to,Y_to),
	not((X_from =:= X_to,Y_from =:= Y_to)),
	(X_from =:= X_to, not(has_between(X_from, Y_from, X_to, Y_to, 1));
	 Y_from =:= Y_to, not(has_between(X_from, Y_from, X_to, Y_to, 2));
	 abs(Y_to - Y_from) =:= abs(X_to - X_from), not(has_between(X_from, Y_from, X_to, Y_to, 3))).


%%our algorithm
%%staying in current pos we check all neighbours (priority is following: Up, Left, Down, Right)
%%if we met orc or we are in the pos that we already visited some steps ago, we cut branch in backtrack
%%X1, Y1, - current pos
%%Depth - used for printing route. It shows in which step we entered this yard
%%Attention: I am using 2 different flags for tracking visited field (visited and visited_after_pass)
%%It is need because when we made pass which lead to unsolvable states, after we are back in backtracking tree we need to erase 
%%fields which was visited after pass.(We may come to them by foot)
move_from(X1,Y1,Depth,Pass):-
	not(visited(X1,Y1)),
	not(o(X1,Y1)),
	not(visited_after_pass(X1,Y1)),
	(Pass =:= 0, assert(visited(X1,Y1)), !; %%Flagging our current pos
	 Pass =:= 1, assert(visited_after_pass(X1,Y1)), !),
	(t(X1,Y1), format('Touch down is in ~w steps', [Depth]), nl; %%We found touchdown!
	(Pass =:= 1, neighbours(X1,Y1,X_to,Y_to), New_Depth is (Depth+1), 
		move_from(X_to, Y_to, New_Depth, Pass), assert(answer(X_to, Y_to, New_Depth)); %%Moving to neighbour fields, but flagging that we already made pass 
	 Pass =:= 0, neighbours(X1,Y1,X_to,Y_to), retractall(visited_after_pass(_,_)), New_Depth is (Depth+1),
	    move_from(X_to, Y_to, New_Depth, Pass), assert(answer(X_to, Y_to, New_Depth)); %%Standart moving to neighbour fields
	 Pass =:= 0, pass_to(X1,Y1,X_to,Y_to), retractall(visited_after_pass(_,_)),  New_Depth is (Depth+1),  
	 	move_from(X_to, Y_to, New_Depth, 1),  assert(answer(X_to, Y_to, New_Depth)))). %%Making pass


print_route(X,Y,N) :-
	t(X,Y);
	New_N is (N+1),
	answer(X_to,Y_to,New_N),
	field(X_to,Y_to),
	(neighbours(X,Y,X_to,Y_to),
	format('~w ~w',[X_to,Y_to]),nl;
	format('P ~w ~w',[X_to,Y_to]), nl),
	print_route(X_to, Y_to, New_N).

%%Main, it takes map's file name as an argument
solve(File) :-
	read_map(File),
	statistics(walltime, [_|[_]]),
	add_to_field(0,0),
	move_from(0,0,0,0),
	statistics(walltime, [_|[ExecutionTime]]),nl,
	format('~w ms.',[ExecutionTime]),nl,
	print_route(0,0,0),nl;
	statistics(walltime, [_|[ExecutionTime]]),
	format('~w ms.',[ExecutionTime]),nl,
	format('Not Solvable',[]),nl.
