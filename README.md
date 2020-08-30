# HexRL
Hex AI based on AlphaGo

This was my first project in python (2016) and I got to learn a lot about deep learning and python as played.
The architecture is based around InceptionResNet and the algorithm follows AlphaZero. I fell in love with deep learning and got to learn a lot
of new libraries like Cython, Tensorflow, Google Protobuf, and PyDrive. Additionally, this my first experience with multiprocessing since at the time
Tensorflow only supported compute from one process due to how it handled the compute graph.

Hex is a game that is played in much the same way as Go, but with a much different objective. In go you claim territory; in Hex you build connections.
The goal is to get from one edge of the board to another as can be seen here http://www.lutanho.net/play/hex.html.

## Results

As I didn't have a Nvidia graphics card, I used Google colaboratory to train my model. The model never got very good and I estimated based on compute power alone,
it would have taken a decade of training to get a really good AI. This is in part due to the model (ResNet and the non-square kernels harm performance), 
my lack of compute power, and the sheer state space of Hex.

You can see the AI results in the python notebook and look at how some of the games played out. Pick one of the move sequences like

```
A2 B1 K3 D4 F9 D3 B6 H8 D11 H5 A6 F2 F3 B2 G7 I11 C2 A9 K9 C3 K11 C1 C6 B8 F7 E11 F8 J9 G9 H10 I9 A1 J4 D10 G1 H2 K4 D2 J8 J3 K10 D8 G2 A4 F5 J1 D9 E4 B10 B4 A11 G8 H3 C8 E2 H11 E10 B3 K2 F11 J10 E9 G10 A3 I7 E1 I3 I2 G6 J5 D7 C5 B7 F1 F4 C10 I4 I10 K6 C7 B5 A10 H4 B11 A8 H7 A5 I5 J6 E6 I8 J2 K7 F10 J11 D6 H9 I1 G5 K5 G11 H1 C9 K8 E8
```

and paste it into the move list in http://www.lutanho.net/play/hex.html. Make sure to set the player to blue begins since I went went with the notation of black vs white to mimic go.
