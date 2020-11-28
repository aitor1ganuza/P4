import matplotlib.pyplot as plt
import matplotlib.cbook as cbook
import numpy as np


lp = np.loadtxt('lp_2_3.txt')
lpcc = np.loadtxt('lpcc_2_3.txt')
mfcc = np.loadtxt('mfcc_2_3.txt')

fig, ax = plt.subplots()
ax.set(xlabel='Coeficientes 2', ylabel='Coeficientes 3')
line1, = ax.plot(lp[:, 0], lp[:, 1])
line2, = ax.plot(lpcc[:, 0], lpcc[:, 1])
line3, = ax.plot(mfcc[:, 0], mfcc[:, 1])
ax.legend((line1, line2, line3), ('lp', 'lpcc', 'mfcc'))
ax.grid()
plt.title("Coeficientes 2 y 3 de las parametrizaciones LP, LPCC y MFCC de todas las señales de un locutor")
plt.show()
