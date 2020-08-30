#cython: language_level=3, boundscheck=False, wraparound=False, cdivision=True

cdef class Coord:
    """Temporary until Pycharm supports ctuples"""
    cdef readonly int row
    cdef readonly int col

    cdef __cinit__(self, int row, int col):
        self.row = row
        self.col = col


cdef class Location:
    """Location class for quick conversion between array and grid location"""
    cdef readonly int board_dim
    cdef readonly int position
    cdef readonly Coord coord

    cdef __cinit__(self, int board_dim):
        self.board_dim = board_dim
        self.position = -1
        self.coord = Coord(-1, -1)

    @property
    cdef int array_pos(self):
        return self.position

    @array_pos.setter
    cdef array_pos(self, int val):
        self.position = val
        self.coord.row = val / self.board_dim
        self.coord.col = val

    @property
    cdef Coord grid_pos(self):
        return self.coord

    @grid_pos.setter
    cdef grid_pos(self, Coord new_pos):
        self.coord.row = new_pos.row
        self.coord.col = new_pos.col
        self.position = new_pos.row * self.board_dim + new_pos.col

ctypedef enum MoveType:
    A1 = 0
    A2 = 1
    A3 = 2
    A4 = 3
    A5 = 4
    A6 = 5
    A7 = 6
    A8 = 7
    A9 = 8
    A10 = 9
    A11 = 10
    B1 = 11
    B2 = 12
    B3 = 13
    B4 = 14
    B5 = 15
    B6 = 16
    B7 = 17
    B8 = 18
    B9 = 19
    B10 = 20
    B11 = 21
    C1 = 22
    C2 = 23
    C3 = 24
    C4 = 25
    C5 = 26
    C6 = 27
    C7 = 28
    C8 = 29
    C9 = 30
    C10 = 31
    C11 = 32
    D1 = 33
    D2 = 34
    D3 = 35
    D4 = 36
    D5 = 37
    D6 = 38
    D7 = 39
    D8 = 40
    D9 = 41
    D10 = 42
    D11 = 43
    E1 = 44
    E2 = 45
    E3 = 46
    E4 = 47
    E5 = 48
    E6 = 49
    E7 = 50
    E8 = 51
    E9 = 52
    E10 = 53
    E11 = 54
    F1 = 55
    F2 = 56
    F3 = 57
    F4 = 58
    F5 = 59
    F6 = 60
    F7 = 61
    F8 = 62
    F9 = 63
    F10 = 64
    F11 = 65
    G1 = 66
    G2 = 67
    G3 = 68
    G4 = 69
    G5 = 70
    G6 = 71
    G7 = 72
    G8 = 73
    G9 = 74
    G10 = 75
    G11 = 76
    H1 = 77
    H2 = 78
    H3 = 79
    H4 = 80
    H5 = 81
    H6 = 82
    H7 = 83
    H8 = 84
    H9 = 85
    H10 = 86
    H11 = 87
    I1 = 88
    I2 = 89
    I3 = 90
    I4 = 91
    I5 = 92
    I6 = 93
    I7 = 94
    I8 = 95
    I9 = 96
    I10 = 97
    I11 = 98
    J1 = 99
    J2 = 100
    J3 = 101
    J4 = 102
    J5 = 103
    J6 = 104
    J7 = 105
    J8 = 106
    J9 = 107
    J10 = 108
    J11 = 109
    K1 = 110
    K2 = 111
    K3 = 112
    K4 = 113
    K5 = 114
    K6 = 115
    K7 = 116
    K8 = 117
    K9 = 118
    K10 = 119
    K11 = 120
    SWAP = 121
    INVALID = 122