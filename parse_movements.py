import os 
import sys
import csv
import re
import operator
from itertools import izip
from collections import defaultdict
from ctypes import *
import numpy as np
import matplotlib as mp
import matplotlib.pyplot as plt
import sklearn as sk
start_time = 1000 * 115
sampling_time = 2000
sampling_iter = 10

def chomp_raw_data(champ_info):
    if champ_info[1] == 'nil':
        return
    else:
        network_id = champ_info[0]
        x_pos = float(champ_info[1])
        z_pos = float(champ_info[2])
        ms = float(champ_info[3])
        return network_id, x_pos, z_pos, ms



def is_raw(champ_info):
    if champ_info[1] == 'nil':
        return True
    else:
        return False

def grouped(iterable, n):
    "s -> (s0,s1,s2,...sn-1), (sn,sn+1,sn+2,...s2n-1), (s2n,s2n+1,s2n+2,...s3n-1), ..."
    return izip(*[iter(iterable)]*n)





filename = 'Movements_syndra.txt' #specify inputs

movement_list = list(csv.reader(open(filename, 'r'), delimiter="\t"))

list_of_arrays = []
for i in range(10):
    list_of_arrays.append([])
counts = [0]*10
final_time = 0 
for time, champ1, champ2, champ3, champ4, champ5, champ6, champ7, champ8, champ9, champ10, space in grouped(movement_list, 12):
    time = float(time[0])
    final_time = time
    if not is_raw(champ1):
        network_id, x_pos, z_pos, ms = chomp_raw_data(champ1)
        to_push_array = [time, x_pos, z_pos, ms]
        list_of_arrays[0].append(to_push_array)
        counts[0] += 1
    if not is_raw(champ2):
        network_id, x_pos, z_pos, ms = chomp_raw_data(champ2)
        to_push_array = [time, x_pos, z_pos, ms]
        list_of_arrays[1].append(to_push_array)
        counts[1] += 1
    if not is_raw(champ3):
        network_id, x_pos, z_pos, ms = chomp_raw_data(champ3)
        to_push_array = [time, x_pos, z_pos, ms]
        list_of_arrays[2].append(to_push_array)
        counts[2] += 1
    if not is_raw(champ4):
        network_id, x_pos, z_pos, ms = chomp_raw_data(champ4)
        to_push_array = [time, x_pos, z_pos, ms]
        list_of_arrays[3].append(to_push_array)
        counts[3] += 1
    if not is_raw(champ5):
        network_id, x_pos, z_pos, ms = chomp_raw_data(champ5)
        to_push_array = [time, x_pos, z_pos, ms]
        list_of_arrays[4].append(to_push_array)
        counts[4] += 1
    if not is_raw(champ6):
        network_id, x_pos, z_pos, ms = chomp_raw_data(champ6)
        to_push_array = [time, x_pos, z_pos, ms]
        list_of_arrays[5].append(to_push_array)
        counts[5] += 1
    if not is_raw(champ7):
        network_id, x_pos, z_pos, ms = chomp_raw_data(champ7)
        to_push_array = [time, x_pos, z_pos, ms]
        list_of_arrays[6].append(to_push_array)
        counts[6] += 1
    if not is_raw(champ8):
        network_id, x_pos, z_pos, ms = chomp_raw_data(champ8)
        to_push_array = [time, x_pos, z_pos, ms]
        list_of_arrays[7].append(to_push_array)
        counts[7] += 1
    if not is_raw(champ9):
        network_id, x_pos, z_pos, ms = chomp_raw_data(champ9)
        to_push_array = [time, x_pos, z_pos, ms]
        list_of_arrays[8].append(to_push_array)
        counts[8] += 1
    if not is_raw(champ10):
        network_id, x_pos, z_pos, ms = chomp_raw_data(champ10)
        to_push_array = [time, x_pos, z_pos, ms]
        list_of_arrays[9].append(to_push_array)
        counts[9] += 1



current_time = start_time

for idx, val in enumerate(list_of_arrays):
    fig = plt.figure()
    plt.clf()
    #plt.axis([-1,1,-1,1])
    plt.hold()
    plt.title(str(idx))
    current_array = val
    to_plot_array = []
    current_idx = 0 
    for idx2, val2 in enumerate(current_array):
        if idx2<len(current_array)-sampling_iter*2 and idx2 > current_idx:
            vec1 = np.asarray([float(current_array[idx2][1]), float(current_array[idx2][2])])
            vec2 = np.asarray([float(current_array[idx2+sampling_iter][1]), float(current_array[idx2+sampling_iter][2])])
            #print vec1
            #print vec2
            #print "\n"
            if not (float(vec2[0]) - float(vec1[0]) == 0) and not (float(vec2[1]) - float(vec1[1]) == 0):
                #print "I have a hit\n"
                dif_vec = np.subtract(vec2, vec1)
                #norm_dif_vec = dif_vec/np.linalg.norm(dif_vec)
                norm_dif_vec = dif_vec
                plt.scatter(norm_dif_vec[0], norm_dif_vec[1])
                #print "plotting " + str(norm_dif_vec[0]) + "\t" + str(norm_dif_vec[1]) + "\n"
                current_time = val2[0]
                current_idx += sampling_iter
    plt.hold(False)
    plt.show()


