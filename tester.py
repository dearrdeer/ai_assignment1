import os

from subprocess import Popen, PIPE,run

rand = 'rand_solver.pl'
dfs = 'solver3.pl'
bfs = 'solver2.pl'

avg_ms = [0.0,0.0,0.0]
n = [100,100,100]
avg_steps = [0,0,0]



for k in range(1, 101):
	print('#####################################')
	print('Map {} is in process...'.format(k))
	s = "solve('tests/map{}.txt')".format(k)
	l = ['rand_solver.pl', 'backtrack_solver.pl', 'heuristics_solver.pl' ]
	for j in range(3):
		process = Popen(['swipl', '-q', '-l', l[j], '-g', s, '-g', 'halt'], stdout=PIPE, stderr=PIPE)
		stdout, stderr = process.communicate()
		output = stdout.decode('utf-8')
		lines = output.split('\n')
		time = ''
		solution = ''
		for i in lines:
			if 'ms' in i:
				time = i.split(' ')[0]
				avg_ms[j] += int(time)
				time += 'ms.'
			if 'Not' in i:
				solution = 'Couldn\'t solve'
				n[j] -= 1

			if 'Touch' in i:
				solution = i.split(' ')[4]
				avg_steps[j] += int(solution)
				solution += ' steps.'


		print()
		print(time + ' ' + solution)

print('###############AVERAGE####################')
print('Average time for random = {}'.format(avg_ms[0]/100))
print('Average time for backtrack = {}'.format(avg_ms[1]/100))
print('Average time for breadt-first = {}'.format(avg_ms[2]/100))
print()
print('Average steps for random = {}'.format(avg_steps[0]/n[0]))
print('Average steps for backtrack = {}'.format(avg_steps[1]/n[1]))
print('Average steps for breadt-first = {}'.format(avg_steps[2]/n[2]))