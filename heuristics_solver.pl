:-dynamic field/2.

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

%%Checking if 2 field are neighbours
neighbours(X1,Y1,X2,Y2):-
	X2 is X1, Y2 is (Y1+1), field(X2,Y2);
	X2 is (X1+1), Y2 is Y1, field(X2,Y2);
	X2 is X1, Y2 is (Y1-1), field(X2,Y2);
	X2 is (X1-1), Y2 is Y1, field(X2,Y2).

:-dynamic in_depth/4.

%%How it works:
%%At each state we know shortest path to some fields -> go there
%%Update all neighbours and field to where we can make pass from there. Now we know shortest path to them
%%We keep 2 variables for each field, shortest path without passes(first) and with pass(second) (Keep in mind we can make only 1 pass!) 
move(Depth):-
	t(T_X,T_Y),
	in_depth(T_X,T_Y,_,_);	
	
	in_depth(X1,Y1,Depth,0),	%%Updating first value of neighbours if we did not make pass yet 
	neighbours(X1,Y1,X2,Y2),
	not(o(X2,Y2)),
	not(in_depth(X2,Y2,_, 0)),
	New_Depth is (Depth+1),
	assert(in_depth(X2,Y2,New_Depth, 0)),
	fail,!;

	in_depth(X1,Y1,Depth,0),	%%Updating second values of the fields where we can make pass, (using first value of current - we did not make pass yet)
	pass_to(X1,Y1,X2,Y2),
	not(o(X2,Y2)),
	not(in_depth(X2,Y2,_,_)),
	New_Depth is (Depth+1),
	assert(in_depth(X2,Y2,New_Depth, 1)),
	fail, !;	

	in_depth(X1,Y1,Depth,1),    %%Updating first value of neighbours if we DID pass 
	neighbours(X1,Y1,X2,Y2),
	not(o(X2,Y2)),
	not(in_depth(X2,Y2,_, 1)),
	New_Depth is (Depth+1),
	assert(in_depth(X2,Y2,New_Depth, 1)),
	fail, !;

	Depth =< 400,				%%Checking next fiels to which we now shortest path
	New_Depth is (Depth+1),
	move(New_Depth).

print_moves(X,Y,Depth,Pass):-
	(X =:= 0, Y =:= 0);

	Prev_Depth is (Depth-1),
	neighbours(X,Y,X2,Y2),
	in_depth(X2, Y2, Prev_Depth, Pass),
	print_moves(X2,Y2,Prev_Depth, Pass),
	format('~w ~w', [X, Y]),nl;

	Prev_Depth is (Depth-1),
	Pass =:= 1,
	in_depth(X2, Y2, Prev_Depth, 0),
	pass_to(X2,Y2,X,Y),
	print_moves(X2,Y2,Prev_Depth, 0),
	format('P ~w ~w', [X, Y]),nl.

%%Main, it takes map's file name as an argument
solve(File) :-
	read_map(File),
	statistics(walltime, [_|[_]]),
	add_to_field(0,0),
	assert(in_depth(0,0,0,0)),
	move(0),
	statistics(walltime, [_|[ExecutionTime]]),
	format('~w ms.',[ExecutionTime]),nl,
	t(X,Y),
	in_depth(X,Y,Answer,Pass),
	format('Touch down is in ~w steps',[Answer]),nl,
	print_moves(X,Y,Answer, Pass);
	statistics(walltime, [_|[ExecutionTime]]),
	format('~w ms.',[ExecutionTime]),nl,
	format('Not Solvable',[]),nl.