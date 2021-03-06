import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

plt.rc('text', usetex=True)
plt.rc('font', family='serif', serif='cm10')
plt.rc('path', simplify=False)
plt.rcParams['text.latex.preamble']=[r'\usepackage{amsmath}']
    
def read_txt(filename):
    df = pd.read_csv(filename, header=None, skipinitialspace=True, 
                     delim_whitespace=True, engine='c')
    return df.values.T
    
def init_fig(xlabel='$x$', ylabel='$y$'):
    fig = plt.figure()
    ax = fig.add_subplot(111)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    ax.xaxis.label.set_fontsize(24)
    ax.yaxis.label.set_fontsize(24)
    ax.tick_params(axis='both', which='major', labelsize=16)
    plt.tight_layout()
    return fig, ax

def plot_shadow(filename, plotname, nx, ny):
    d = read_txt(filename)
    x, y, r, th, phi, status = d.reshape(d.shape[0], nx, ny)

    fig, ax = init_fig(xlabel='$x/r_g$', ylabel='$y/r_g$')

    dth = np.pi / 10
    dphi = 2*np.pi / 20
    th_ring = np.remainder((th/dth).astype(int), 2)
    phi_ring = np.remainder((phi/dphi).astype(int), 2)
    escaped_and_th_even = np.logical_and(status==1, th_ring==0) 
    escaped_and_th_odd = np.logical_and(status==1, th_ring==1) 
    escaped_and_phi_even = np.logical_and(status==1, phi_ring==0) 
    escaped_and_phi_odd = np.logical_and(status==1, phi_ring==1) 
    captured_and_th_even = np.logical_and(status==0, th_ring==0) 
    captured_and_th_odd = np.logical_and(status==0, th_ring==1) 
    captured_and_phi_even = np.logical_and(status==0, phi_ring==0) 
    captured_and_phi_odd = np.logical_and(status==0, phi_ring==1) 
    
    status[captured_and_th_even] = 0.5
    #status[escaped_and_phi_even * escaped_and_th_even] = 0.5
    #status[escaped_and_phi_odd * escaped_and_th_odd] = 1.5

    ax.imshow(status.T, extent=[x.min(), x.max(), y.min(), y.max()], 
              cmap=plt.get_cmap('gray'), interpolation='bicubic')

    fig.savefig(plotname+'.png', format='png', dpi=300)
    plt.close(fig)

if __name__ == '__main__':
    filename = 'data/data_1024_a9ks_90_10.txt'
    plotname = 'figures/shadow'
    nx = 1024
    ny = 1024
    plot_shadow(filename, plotname, nx, ny)
