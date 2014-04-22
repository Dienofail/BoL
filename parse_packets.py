import os
import sys
import csv
import re
import operator
from itertools import izip
from collections import defaultdict
from ctypes import *
cutoff = 3
p = re.compile("\s+")

def grouped(iterable, n):
    "s -> (s0,s1,s2,...sn-1), (sn,sn+1,sn+2,...s2n-1), (s2n,s2n+1,s2n+2,...s3n-1), ..."
    return izip(*[iter(iterable)]*n)
def convert(s):
    i = int(s, 16)                   # convert from hex to a Python int
    cp = pointer(c_int(i))           # make this into a c integer
    fp = cast(cp, POINTER(c_float))  # cast the int pointer to a float pointer
    return fp.contents.value         # dereference the pointer, get the float


filename = 'packets.txt'
packet_list = list(csv.reader(open(filename, 'r'), delimiter=':'))
rec = []
sent = []

packet_list = packet_list[4:]
linecounter = 0
#for idx, val in enumerate(packet_list):
#    if idx < 50:
#        print('Current idx is ' + str(idx))
#        if len(val) > 1:
#            toprint = re.sub(' ', '', val[1])
#            sys.stdout.write(str(line_counter) + ' ' + str(toprint) + "\n")
#        line_counter += 1

for x,y,z,w in grouped(packet_list, 4):
    linecounter += 4
    x[1] = re.sub(' ', '', x[1])
    y[1] = re.sub(' ', '', y[1])
    z[1] = re.sub(' ', '', z[1])
#    print('Current x is ' + str(x[1]))
#    print('Current y is ' + str(y[1]))
#    print('Current z is ' + str(z[1]))
#    print('Current w is ' + str(w))
    if y[1] == 'RECV':
        current_recv_topush = []
        data_to_push = re.sub(' ', '', z[1])
        header_to_push = re.sub(' ', '', x[1])
#        print('Pushing recv ' + str(header_to_push) + ' with data ' + str(data_to_push))
        current_recv_topush.append(header_to_push)
        current_recv_topush.append(data_to_push)
        rec.append(current_recv_topush)
    elif y[1] == 'SEND':
        current_send_topush = []
        data_to_push = re.sub(' ', '', z[1])
        header_to_push = re.sub(' ', '', x[1])
#        print('Pushing send ' + str(header_to_push) + ' with data ' + str(data_to_push))
        current_send_topush.append(header_to_push)
        current_send_topush.append(data_to_push)
        sent.append(current_send_topush)
        if(header_to_push == '0x08'):
            print('Found 0x08 in ' + str(linecounter) + "\n" + str(data_to_push) + "\n" + str(len(data_to_push)))
        if(header_to_push == '0xE5'):
            print('Found 0xE5 in ' + str(linecounter) + "\n" + str(data_to_push) + "\n" + str(len(data_to_push)))
        if(header_to_push == '0x71'):
            print('Found 0x71 in ' + str(linecounter) + "\n" + str(data_to_push) + "\n" + str(len(data_to_push)))
        if(header_to_push == '0x99'):
            print('Found 0x99 in ' + str(linecounter) + "\n" + str(data_to_push) + "\n" + str(len(data_to_push)))
        if(header_to_push == '0xAE'):
            print('Found 0xAE in ' + str(linecounter) + "\n" + str(data_to_push) + "\n" + str(len(data_to_push)))
        if(header_to_push == '0x2D'):
            print('Found 0x2D in ' + str(linecounter) + "\n" + str(data_to_push) + "\n" + str(len(data_to_push)))

recv_dict = defaultdict(list)
sent_dict = defaultdict(list)
for k, v in rec:
    recv_dict[k].append(v)
for k, v in sent:
    sent_dict[k].append(v)
#print(recv_dict.items())
#print(sent_dict.items())

recv_count = defaultdict(int)
sent_count = defaultdict(int)
recv_to_decode = []
sent_to_decode = []

for key, value in recv_dict.iteritems():
    recv_count[key] += len(value)


for key, value in sent_dict.iteritems():
    sent_count[key] += len(value)


for key, value in recv_count.iteritems():
    if cutoff == value:
        recv_to_decode.append(key)

for key, value in sent_count.iteritems():
    if cutoff == value:
        sent_to_decode.append(key)

#let's decode
#print(str(len(recv_to_decode)))
#for idx, val in enumerate(recv_to_decode):
#    current_list = recv_dict[val]
#    for idx2, val2 in enumerate(current_list):
#        #let's try
#        array = list(val2)
#        print('For ' + str(val) + ' print on index ' + str(idx2))
#        print(array)
#        if (len(array) % 8 == 0):
#            print('Current array is divisible by 8')

for idx, val in enumerate(sent_to_decode):
    current_list = sent_dict[val]
    for idx2, val2 in enumerate(current_list):
        #let's try
        array = list(val2)
#        print('For ' + str(val) + ' print on index ' + str(idx2))
#        print(array)
#        print(str(len(array)))
#        if (len(array) % 8 == 0):
#            print('Current array is divisible by 8')
#
#
#print(str(recv_dict['0x3A'][0]))
print('received items')
print(recv_count.items())
print('sent items ')
print(sent_count.items())
sorted_recv = sorted(recv_count.iteritems(), key=operator.itemgetter(1))
sorted_sent = sorted(sent_count.iteritems(), key=operator.itemgetter(1))
# print('received items ')
# print(sorted_recv)
# print('sent items ')
# print(sorted_sent)

class fl:
    def __init__(this, value=0, byte_size=4):

        this.value = value

        if this.value: # speedy check (before performing any calculations)
            Fe=((byte_size*8)-1)//(byte_size+1)+(byte_size>2)*byte_size//2+(byte_size==3)
            Fm,Fb,Fie=(((byte_size*8)-(1+Fe)), ~(~0<<Fe-1), (1<<Fe)-1)

            FS,FE,FM=((this.value>>((byte_size*8)-1))&1,(this.value>>Fm)&Fie,this.value&~(~0 << Fm))
            if FE == Fie: this.value=(float('NaN') if FM!=0 else (float('+inf') if FS else float('-inf')))
            else: this.value=((pow(-1,FS)*(2**(FE-Fb-Fm)*((1<<Fm)+FM))) if FE else pow(-1,FS)*(2**(1-Fb-Fm)*FM))

            del Fe; del Fm; del Fb; del Fie; del FS; del FE; del FM

        else: this.value = 0.0