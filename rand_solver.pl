:-dynamic field/2.
:-dynamic local_answer/3.
:-dynamic answer/3.

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

%%Needed for rand_pass. It checks if our random pass was successfull. (Did not meet orc or end of field)
go(X,Y,X1,Y1,DX,DY):-
	(h(X,Y); o(X,Y); not(field(X,Y))),
	X1 is X, Y1 is Y;
	Next_X is (X+DX), Next_Y is (Y + DY),
	go(Next_X,Next_Y, X1, Y1, DX,DY).

%%Randomly chosing direction of pass and then checking it
%%Last two numbers mean the vector-directon
rand_pass(X,Y,New_X,New_Y):-
	random_between(0,7,R), !,
	(R =:= 0, go(X,Y,New_X, New_Y, 0,1), !; 
	 R =:= 1, go(X,Y,New_X, New_Y, 0,-1), !;
	 R =:= 2, go(X,Y,New_X, New_Y, 1,0), !;
	 R =:= 3, go(X,Y,New_X, New_Y, -1,0), !;
	 R =:= 4, go(X,Y,New_X, New_Y, 1,1), !;
	 R =:= 5, go(X,Y,New_X, New_Y, 1,-1), !;
	 R =:= 6, go(X,Y,New_X, New_Y, -1,1), !;
	 R =:= 7, go(X,Y,New_X, New_Y, -1,-1), !).


%%At each state we are randomly chosing our next step
%%It's either move up, move down, move sides.
%%If our random variable R is 4 then we are trying to make pass
%% X, Y - our current place
%% Pass - flag for checking if we already made pass some steps ago (We can make only one pass in round)
%% Depth - variable needed in printing route.Basically, it just shows in which step we visited this yard
%% Iterations - our limit for random search. By assignment statement we should not make more 100 moves. XD
%% Warning - when our next move lead to 'bad' position. random_between works such way that it makes reroll for our next step
%% So, basically, if we had not limit, algorithm would always find solution (of course with very bad time).  
rand_move(X,Y,Pass, Depth, Iterations):-
	not(o(X,Y)), field(X,Y),
	(t(X,Y), !;
	Iterations > 10000, !; 
	random_between(0,4,R),
	(R =:= 0, New_Y is (Y+1), New_Depth is Depth +1, New_Iterations is Iterations + 1, %% First line of each branch, we just increment our utility vars.
		rand_move(X, New_Y, Pass, New_Depth, New_Iterations), assert(answer(X, New_Y, New_Depth)), !;
	 R =:= 1, New_Y is (Y-1), New_Depth is Depth +1, New_Iterations is Iterations + 1, 
	    rand_move(X, New_Y, Pass, New_Depth, New_Iterations), assert(answer(X, New_Y, New_Depth)), !;
	 R =:= 2, New_X is (X+1), New_Depth is Depth +1, New_Iterations is Iterations + 1, 
	    rand_move(New_X, Y, Pass, New_Depth, New_Iterations), assert(answer(New_X, Y, New_Depth)), !;
	 R =:= 3, New_X is (X-1), New_Depth is Depth +1, New_Iterations is Iterations + 1, 
	    rand_move(New_X, Y, Pass, New_Depth, New_Iterations), assert(answer(New_X, Y, New_Depth)), !;
	 R =:= 4, Pass =:= 0, rand_pass(X,Y,New_X, New_Y), New_Depth is Depth +1, New_Iterations is Iterations + 1, 
	    rand_move(New_X, New_Y, 1, New_Depth, New_Iterations), assert(answer(New_X, New_Y, New_Depth)), !;
	 New_Iterations is Iterations + 1, rand_move(X,Y,Pass, Depth, New_Iterations))). %%Special, if we rolled pass, but we already did pass some moves ago, we make reroll

%%Make pass to field...
print_route(X,Y,N) :-
	t(X,Y);
	New_N is (N+1),
	answer(X_to,Y_to,New_N),
	(neighbours(X,Y,X_to,Y_to),
	format('~w ~w',[X_to,Y_to]),nl, !;
	format('P ~w ~w',[X_to,Y_to]), nl),
	print_route(X_to, Y_to, New_N).

%%Main, it takes map's file name as an argument
solve(File):-
	read_map(File),
	statistics(walltime, [_|[_]]),
	add_to_field(0,0),
	rand_move(0,0,0,0,0),
	t(X,Y),
	answer(X,Y,Answer),
	statistics(walltime, [_|[ExecutionTime]]),nl,
	format('~w ms.',[ExecutionTime]),nl,
	format('Touch down is in ~w steps',[Answer]),nl,
	print_route(0,0,0),nl;
	statistics(walltime, [_|[ExecutionTime]]),
	format('~w ms.',[ExecutionTime]),nl,
	format('Not Solvable',[]),nl.
