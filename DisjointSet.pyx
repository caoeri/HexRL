import itertools
import numpy as np
cimport numpy as np

def grouper(iterable, n, fillvalue=None):
    """From python documentation iter tools:
    https://docs.python.org/3/library/itertools.html"""
    "Collect data into fixed-length chunks or blocks"
    # grouper('ABCDEFG', 3, 'x') --> ABC DEF Gxx"
    args = [iter(iterable)] * n
    return itertools.zip_longest(*args, fillvalue=fillvalue)

cdef class DisjointSets:
    cdef readonly np.ndarray sets

    cdef __cinit__(self, int size):
        self.sets = np.ones(size, dtype=np.int32) * -1

    cdef void reset(self):
        self.sets = np.ones(len(self.sets), dtype=np.int32) * -1

    cdef union_group(self, elems:'groupable iterable'):
        if len(elems) == 1:
            return

        for i, j in grouper(elems, 2, None):
            self.union(i, j)

        self.union_group(elems[::2])

    cdef void union(self, a, b):
        if a is None or b is None:
            return

        repA = self.find(a)
        repB = self.find(b)

        if repA == repB:
            return

        if self.sets[repA] <= self.sets[repB]:
            self.sets[repA] += self.sets[repB]
            self.sets[repB] = repA
        else:
            self.sets[repB] += self.sets[repA]
            self.sets[repA] = repB

    cdef void find(self, elem):
        if self.sets[elem] < 0:
            return elem

        i = self.find(self.sets[elem])
        self.sets[elem] = i
        return i

    cdef void __setitem__(self, key, val):
        self.sets[key] = val

    cdef void __len__(self):
        return len(self.sets)

    cdef void copy(self):
        ret = DisjointSets(len(self.sets))
        ret.sets = np.copy(self.sets)
        return ret