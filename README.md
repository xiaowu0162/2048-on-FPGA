# 2048-on-FPGA
---Project Proposal---<br />
Overview<br />
In this project, we will design a 2048 game and implement it on the FPGA board. 2048 is a popular single player grid-based strategy game. In the game, a player can only shift all the blocks to a certain direction (up, down, left, or right). In our design, the user will use four buttons to control the shifting direction. Switches and buttons will also be used for resetting the game or selecting the difficulty level.<br />

Game Rules<br />
	The game starts with a 4x4 grid (16 empty slots), and a block with value 2 or 4 placed in a randomly chosen slot. In every iteration of the game, the user chooses to move all existing blocks in a certain direction D (up, down, left, right), and the system performs a series of actions. First, the system merges blocks according to the user input direction D. If block B is in the direction D of block A (with no other blocks between them), and both these blocks have value 2^N, then A and B are merged into one block with value 2^(N+1), placed at the original position of block A. In a single row/column, the merge operation is evaluated starting from the D side, and a block can only be merged once in one iteration. After merging, all blocks are shifted one position to direction D. If a row is full when D is left/right, or if a column is full when D is up/down, then the column/row does not move. After merging and shifting, the game system creates a new block with value 2 or 4 at a vacant position, and the current iteration ends. <br />
	A player loses when the grid is full and no two adjacent blocks can be merged. A player wins when he/she manages to merge two blocks with value 1024 to create a block with value 2048. In our implementation, the game ends when the player has won or lost, and a new game can be started by pressing the reset button. <br />

Normal Game Interface<br />
	We will display the main game grid on screen via UART, refreshed after every iteration. The player can use four buttons on the FPGA to enter a move command. In addition, a reset button and a set of switches for selecting difficulty level will be available. <br />

Score Display<br />
	A player’s performance can be evaluated with two scores: the sum of all existing blocks’ values, and the highest value of existing block. We plan to display the former score on the screen via UART output, and to display the latter score using the 7-segment display on the board. The 7-segment display might show certain characters if the player has won or lost the game. <br />


Difficulty Levels<br />
	The game’s difficulty is mainly determined by where the system would place a new block at the end of each iteration. If a new block is placed very close to existing blocks (especially blocks with large values), then it might be harder to manipulate the blocks for a successful merge. Depending on the difficulty level selected by the player, the system will choose to place a new block 1) closest to the existing blocks; 2) in a random position; 3) furthest to existing blocks.<br />

