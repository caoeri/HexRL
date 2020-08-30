#cython: language_level=3, boundscheck=False, wraparound=True, cdivision=True

include "HexUtils.pyx"
include "DisjointSet.pyx"

ctypedef enum result:
    NO_WINNER = 0
    RED_WINS = 1
    BLUE_WINS = 2

cdef enum constants:
    LEGAL = 1
    ILLEGAL = 0

    TOP_OFFSET = -1
    LEFT_OFFSET = -2
    BOTTOM_OFFSET = -3
    RIGHT_OFFSET = -4

    NONE = 0
    PLAYER_ONE = 1
    PLAYER_TWO = 2

cdef class HexBoard:
    cdef readonly int board_dim
    cdef int action_shape
    cdef readonly np.ndarray board

    cdef readonly bint resigned
    cdef readonly bint swap_rule
    cdef readonly result done

    cdef readonly np.ndarray actions

    # self.action_notation = "" # String concat is slow in cython

    cdef readonly np.ndarray legal_actions

    # # sets[-1] and sets[-3] are the opposite vertical sizes
    # self.sets = DisjointSets(shape[0] * shape[1] + 4)
    #
    # self.TOP = len(self.sets) + HexEnv.TOP_OFFSET
    # self.LEFT = len(self.sets) + HexEnv.LEFT_OFFSET
    # self.BOTTOM = len(self.sets) + HexEnv.BOTTOM_OFFSET
    # self.RIGHT = len(self.sets) + HexEnv.RIGHT_OFFSET



    def __init__(self, board_dim:int=11, swap_rule=True):
        """Creates a hex environment of specified shape.
        Holds 4 main parts:
            - The board represented by a 2D numpy array.
            - The legal actions is represented by a flattened numpy
                array with one extra item for the swap rule
            - The actions taken represented by a numpy array (plus string notation)
            - A disjoint sets for quick detemination if a game is done.
                Has 4 extra items for each edge
        """
        self.board_dim = board_dim
        self.board = np.zeros((board_dim, board_dim), dtype=np.int32)

        self.action_shape = board_dim * board_dim + 1
        self.actions = np.full(self.action_shape, MoveType.INVALID, np.int32)

        self.resigned = False
        self.done = result.NO_WINNER
        self.swap_rule = swap_rule

        self.legal_actions = np.ones(self.action_shape, dtype=np.int32)
        self.legal_actions[-1] = ILLEGAL # swap rule not immediately legal

        # sets[-1] and sets[-3] are the opposite vertical sizes
        self.sets = DisjointSets(board_dim * board_dim + 4)

        self.TOP = len(self.sets) + TOP_OFFSET
        self.LEFT = len(self.sets) + LEFT_OFFSET
        self.BOTTOM = len(self.sets) + BOTTOM_OFFSET
        self.RIGHT = len(self.sets) + RIGHT_OFFSET

    def move(self, move):
        if isinstance(move, str):
            move = self.uci_to_int(move)
        self._move(move)

    cdef _move(self, move):
        if (move is not None) and ((self.legal_actions[move] == HexEnv.ILLEGAL) or (self.done != HexEnv.NONE)):
            print('Illegal Move:', self.generate_move_notation(move))
            print(self.board)
            return ILLEGAL

        if move is None: # Resign
            # even length - player-two moved last and wins
            if len(self.actions) % 2 == 0:
                self.done = PLAYER_TWO
            else:
                self.done = PLAYER_ONE
            self.resigned = True
            return

        if move == self.shape[0] * self.shape[1] or move == -1:
            # Swap rule Invoked
            # ADD TO BOARD
            assert len(self.actions) == 1
            row, col = self.get_move_position(self.actions[0])

            assert self.board[row][col] == HexEnv.PLAYER_ONE
            self.board[row][col] = HexEnv.NONE
            self.board[col][row] = HexEnv.PLAYER_TWO

            # UPDATE LEGAL ACTIONS
            self.legal_actions[self.get_action_position(row, col)] = HexEnv.LEGAL
            self.legal_actions[self.get_action_position(col, row)] = HexEnv.ILLEGAL

            # UPDATE DISJOINT SET
            self.sets.reset()
            neighbors = self.get_neighbors(self.get_action_position(col, row), self.board[col][row])
            self.sets.union_group(neighbors)

        else:
            # ADD TO BOARD
            row, col = self.get_move_position(move)
            self.board[row][col] = (len(self.actions) % 2) + 1

            # UPDATE LEGAL ACTIONS
            self.legal_actions[move] = HexEnv.ILLEGAL

            # UPDATE DISJOINT SET
            neighbors = self.get_neighbors(move, self.board[row][col])
            self.sets.union_group(neighbors)

        # SET WINNER  # XXX
        if self.sets.find(self.TOP) == self.sets.find(self.BOTTOM):
            self.done = HexEnv.PLAYER_ONE

        if self.sets.find(self.LEFT) == self.sets.find(self.RIGHT):
            self.done = HexEnv.PLAYER_TWO

        # ADD TO ACTIONS
        self.actions = np.append(self.actions, move)
        self.action_notation += " " + self.generate_move_notation(move)
        self.action_notation = self.action_notation.strip()

        # Update swap rule
        self.legal_actions[-1] = 1 if len(self.actions) == 1 else 0
        return HexEnv.LEGAL

    @property
    def action_notation(self):
        pass

    def get_neighbors(self, move_num, player):
        neighbors = []
        row, col = self.get_move_position(move_num)

        for i in [-1, 0, 1]:
            for j in [-1, 0, 1]:
                if i * j ==1:
                    continue

                curr_row, curr_col = row + i, col + j

                if curr_row < 0 or curr_col < 0:
                    continue
                if curr_row >= self.shape[0] or curr_col >= self.shape[1]:
                    continue

                # All are in array (without index wrapping)
                if self.board[curr_row][curr_col] == player:
#                     print('Normal')
                    neighbors.append(self.get_action_position(curr_row, curr_col))

                    # add which edge it is on
                    if curr_col == 0 and player == HexEnv.PLAYER_ONE:
#                         print('TOP')
                        neighbors.append(self.TOP)

                    if curr_col == self.shape[0] - 1 and player == HexEnv.PLAYER_ONE:
#                         print('BOTTOM')
                        neighbors.append(self.BOTTOM)

                    if curr_row == 0 and player == HexEnv.PLAYER_TWO:
#                         print('LEFT')
                        neighbors.append(self.LEFT)

                    if curr_row == self.shape[1] - 1 and player == HexEnv.PLAYER_TWO:
#                         print('RIGHT')
                        neighbors.append(self.RIGHT)

        return neighbors

    def invoke_swap_rule(self):
        """Activate swap rule on board. Only the second player can invoke swap rule.

        It is really just a transpose along the main diagnol + a value change."""
        pass

    def get_legal_moves(self):
        return self.legal_actions

    def get_legal_moves_expensive(self):
        # The played spaces happen to be the exact illegal spaces
        # excluding swap rule.
        legal_mat = np.copy(self.board).flatten()
        legal_mat[legal_mat > 1] = 1
        legal_mat = 1 - legal_mat

        # add swap legality (1 if legal)
        legal_mat = np.append(legal_mat, 1 if len(self.actions) == 1 else 0)

        return legal_mat

    def calc_output_prob(self, policy_output):
        """
        Returns:
            Normalized list of possible moves with swap being listed last

            Note - If the predicted output for legal values sum to zero, it will assume
                    all legal values have the same probability
            Note - An array of NaN will be returned if there are no legal moves
        """
        legal_mat = self.get_legal_moves()

        # zero out if illegal
        confidence_mat = np.zeros(policy_output.shape)
        np.putmask(confidence_mat, legal_mat == 1, policy_output)

        # normalize probs
        total = np.sum(confidence_mat)
        if total != 0:
            return confidence_mat / total
        else:
            return legal_mat / np.sum(legal_mat)

    def generate_model_inputs(self, mat=None, channels_format='channels_last'):
        if mat is None:
            mat = self.board
        formats = {
            'channels_first': 0,
            'channels_last': -1,
        }

        rows, cols = self.board_dim, self.board_dim

        # 2 channels for two players and no extras since
        # Hex is NOT completely observable (due to swap rule)
        player_one = np.zeros((rows, cols), dtype=np.float32)
        np.putmask(player_one, mat == 1, 1)

        player_two = np.zeros((rows, cols), dtype=np.float32)
        np.putmask(player_two, mat == 2, 1)

        if len(self.actions) % 2 == 0:
            player_turn = np.zeros(self.board_dim, dtype=np.float32)
        else:
            player_turn = np.ones(self.board_dim, dtype=np.float32)

        return np.stack(
            (player_one, player_two, player_turn),
            axis=formats[channels_format])

    def generate_move_notation(self, move_num):
        # if move_num == self.board_dim * self.board_dim or move_num == -1:
            # return "SWAP"
        # else:
        row, col = self.get_move_position(move_num)
        return "".join([chr(ord('A') + row), str(1 + col)])

    def generate_key(self):
        return self.action_notation

    def generate_actions(self, key_string):
        actions = key_string.split(" ")
        return [self.uci_to_int(a) for a in actions]

    def uci_to_int(self, uci):
        uci = uci.strip()
        if uci == "SWAP":
            return self.shape[0] * self.shape[1]
        else:
            row, col = uci[0], uci[1:]
            return self.get_action_position(ord(row) - ord('A'), int(col) - 1)

    # def copy(self):
    #     env = HexEnv()
    #     env.shape = self.shape
    #     env.done = self.done
    #     env.swap_rule = self.swap_rule
    #
    #     env.board = np.copy(self.board)
    #     env.actions = np.copy(self.actions)
    #     env.action_notation = self.action_notation
    #
    #     env.legal_actions = np.copy(env.legal_actions)
    #
    #     # sets[-1] and sets[-3] are the opposite vertical sizes
    #     env.sets = self.sets.copy()
    #
    #     env.TOP = self.TOP
    #     env.LEFT = self.LEFT
    #     env.BOTTOM = self.BOTTOM
    #     env.RIGHT = self.RIGHT
    #     return env
