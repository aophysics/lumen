#!/usr/bin/python3
import argparse
import numpy as np
import re
import sys

"""
Analise ypp output to extract Kerr, two-photon absorption by means of Richardson extrapolation
Author:  C. Attaccalite and M. Grüning
"""
#
# parse command line
#
parser = argparse.ArgumentParser(prog='lumen_PP',description='Analise ypp output to extract Kerr and two-photon absorption',epilog="Copyright C. Attaccalite and M. Grüning 2017")
parser.add_argument('-nx', help="number of harmonics", type=int , default=4, dest="nX")
parser.add_argument('-nr', help="number of intensities",type=int , default=2, dest="nR")
parser.add_argument('-J', help="job identifies",type=str , default=None, dest="jobname")
args = parser.parse_args()

print("\n * * * Analize ypp output to extract Kerr and two-photon absorption * * * \n\n")

args = parser.parse_args()

if args.jobname == None:
    file_begin="o.YPP-X_probe"
else:
    file_begin="o-"+args.jobnem+".YPP-X_probe"

#
# Read the number of frequencies
#
xhi0=open(file_begin+"_int_1_order_0","r")
lines=xhi0.read()
pattern=r'Number of freqs  :\s*(\d*)'
try:
    match = re.search(pattern, lines, re.MULTILINE)
    nfreqs= int(match.group(1))
except:
    exit_error("Error reading nfreqs")
xhi0.close()

print("Number of frequency step: %d \n " % nfreqs)

XHI=np.zeros([args.nR,args.nX,nfreqs,7],dtype=float)

for iR in range(0,args.nR):
    for iX in range(0,args.nX):
        file_name=file_begin+"_int_"+str(iR+1)+"_order_"+str(iX)
        print("Reading %s " % file_name)
        XHI[iR,iX,:,:]=np.genfromtxt(file_name,comments="#")
#
# Apply Richardson to correct XHI2(2w) 
# XHI2(2w: w, w )
#
# Remove any possible linear dependence from the field
# intensity
#
# XHI2 = 2/E^2 [ P(E) - 2 * P(E/2) ] = 2 XHI2(E) - XHI2(E/2)

XHI2=np.zeros([nfreqs,7],dtype=float)

XHI2=2.0*XHI[0,2,:,:]-XHI[1,2,:,:]

#
# Apply Richardson to correct XHI3(3w) 
# XHI3(3w: w, w, w )
#
XHI3=np.zeros([nfreqs,7],dtype=float)
#
#
if args.nR == 2:
    #
    # Remove any linear dependence 
    # from the field intensity in XH3
    #
    # XHI3 = 1/3 [ 4 P(E)/E^3 - 8/E^3 P(E/2) ] = 1/3 [4 XHI3(E) - XHI3(E/2) ]
    #
    XHI3=1.0/3.0*(4.0*XHI[0,3,:,:]-XHI[1,3,:,:])
    #
elif args.nR == 3:
    #
    # Remove any linear and quadratic dependence 
    # from the field intensity in XH3
    #  TO BE DONE
    XHI3=1.0/3.0*(4.0*XHI[0,3,:,:]-XHI[1,3,:,:])
    #


XHI3=np.zeros([nfreqs,7],dtype=float)

#
# Extract Kerr and Two-photon absorption 
# XHI3(w: w, -w , w)
# 

KERR=np.zeros([nfreqs,7],dtype=float)
