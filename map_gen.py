import random
import sys

n_humans = int(random.randint(0,50))
n_orcs = int(random.randint(10,100))
dim = 20

cells = []
for i in range(dim):
	for j in range(dim):
		cell = []
		cell.extend([i, j])
		cells.append(cell.copy())

cells.remove([0, 0])

f = open('tests/map{}.txt'.format(sys.argv[1]), 'w+')

humans = random.sample(cells, n_humans)
for h in humans:
	f.write('h(%d, %d).\n' % (h[0], h[1]))
	cells.remove(h)
orcs = random.sample(cells, n_orcs)
for o in orcs:
	f.write('o(%d, %d).\n' % (o[0], o[1]))
	cells.remove(o)
td = random.choice(cells)
f.write('t(%d, %d).' % (td[0], td[1]))
f.close()

# for i in range(dim-1, -1, -1):
# 	for j in range(dim):
# 		cell = [j, i]
# 		if cell in humans:
# 			print('H', end=' ')
# 		elif cell in orcs:
# 			print('O', end=' ')
# 		elif cell == td:
# 			print('T', end=' ')
# 		elif i == j == 0:
# 			print('P', end=' ')
# 		else:
# 			print('.', end=' ')
# 	print()