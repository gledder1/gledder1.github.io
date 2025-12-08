breed [cells cell]
breed [ladybugs ladybug]

globals
[
  maxticks ; total time for experiment -- set on setup/set-parameters
  movetime ; ticks required for a move -- set on setup/set-parameters
  waittime ; ticks required for a wait -- set on setup/set-parameters
  replace ; replacement or not -- set on setup/set-parameters
  move? ; move or wait -- set on go/reset-experiment, go/do-move, go/do-wait
  endtick ; ending tick for current move or wait -- set on go/reset-experiment, go/do-move, go/do-wait
  captures ; counts total captures -- set on go/reset-experiment, go/do-move
  bugnumber ; ID number for the ladybug -- set on go/populate
  capture? ; checks cell for aphid at end of move -- set on go/do-move/ask-capture

  xlist ; list of x coordinate values -- set on setup, go/record-results
  ylist ; list of y coordinate values -- set on setup, go/record-results
]

cells-own
[
  hex-neighbors  ;; agentset of 6 neighboring cells
]

ladybugs-own
[
  speed
  deltax
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  output-print (word species ", replacement " replacement?)
  reset-ticks
  set-current-plot "Experiment Outcomes"
  plotxy 0 0
  set xlist [0]
  set ylist [0]
  set-parameters
  make-world
  populate
end

;;;;;;;;;;;;;;;;;;;;;

to go
  reset-experiment
  populate

  foreach range maxticks
  [
    tick
    ifelse move? [do-move] [do-wait]
  ]

  record-results
end

;;;;;;;;;;;;;;;;;;;;;

to save-output
  let file user-new-file
  if is-string? file
  [
    let L length file
    ifelse L > 4
    [if item (L - 4) file != "." [set file (word file ".csv")]]
    [set file (word file ".csv")]

    if file-exists? file [file-delete file]
    file-open file
    file-print (word species ", replacement " replacement?)

    file-print (word "")
    file-print (word "x values")
    file-print xlist

    file-print (word "")
    file-print (word "y values")
    file-print ylist

    file-close-all
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to set-parameters  ;; on setup
  set maxticks 400
  set-default-shape cells "hex"
  ifelse species = "P-steadius"
  [
    set-default-shape ladybugs "ladybug-1"
    set movetime 9
    set waittime 1
  ]
  [
    set-default-shape ladybugs "ladybug-2"
    set movetime 2
    set waittime 8
  ]
  ifelse replacement? [set replace 1][set replace 0]
end

;;;;;;;;;;;;;;;;;;;;;

to make-world  ;; on setup
  ask patches
  [
    set pcolor white
    sprout-cells 1
    [
      set size 0.7
      set color white
      if pxcor mod 2 = 0 [set ycor ycor - 0.5]
    ]
  ]

  ask cells
  [ ifelse xcor mod 2 = 0
    [ set hex-neighbors cells-on patches at-points [[0 1] [1 0] [1 -1] [0 -1] [-1 -1] [-1 0]] ]
    [ set hex-neighbors cells-on patches at-points [[0 1] [1 1] [1  0] [0 -1] [-1  0] [-1 1]] ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to reset-experiment  ;; on go
  set move? true
  set endtick ticks + movetime
  set captures 0
  ask cells [set shape "hex"]
  ask ladybugs [die]
end

;;;;;;;;;;;;;;;;;;;;;

to populate  ;; on go
  ask n-of aphids-start cells [set shape "aphid"]
  create-ladybugs 1
  [
    set size 0.9
    set speed 1 / movetime
    set deltax 0.144 * speed
    move-to one-of cells with [shape = "hex" and ycor > 0]
    set heading 0
    right one-of [-120 -60 0 60 120 180]
  ]
  ask ladybugs [set bugnumber who]
end

;;;;;;;;;;;;;;;;;;;;;

to do-wait  ;; on go
  if ticks = endtick
  [
    set move? true
    set endtick ticks + movetime
    ask ladybug bugnumber
    [
      right one-of [-120 -60 -60 -60 -60 0 0 0 0 0 0 0 0 0 0 60 60 60 60 120]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;

to do-move  ;; on go
  ask ladybug bugnumber
  [
    forward speed
    (ifelse
      heading = 60 or heading = 120 [set xcor xcor + deltax]
      heading = 240 or heading = 300 [set xcor xcor - deltax]
    )

    if ticks = endtick  ; tidy up and set up for next phase
    [
      set xcor round xcor
      set ycor 0.5 * round (2 * ycor)

      ask-capture

      ifelse capture? = true
      [
        set captures captures + 1
        if replace = 1
        [
          ask n-of 1 cells with [shape = "hex"]
          [set shape "aphid"]
        ]
        set capture? false
        set move? false
        set endtick ticks + waittime
      ]
      [
        set endtick ticks + movetime
      ]

      right one-of [-60 0 0 0 60]
    ]

  ]
end

;;;;;;;;;;;;;;;;;;;;;

to record-results  ;; on go
  output-print (word aphids-start " prey, " captures " captures")
  set xlist lput aphids-start xlist
  set ylist lput captures ylist
  plotxy aphids-start captures
end

;;;;;;;;;;;;;;;;;;;;;

to ask-capture  ;; on go/do-move
  ask ladybug bugnumber
  [
    let x xcor
    let y ycor
    ask cells with [xcor = x and ycor = y]
    [
      if shape = "aphid"
      [
        set capture? true
        set shape "hex"
      ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
468
10
908
451
-1
-1
36.0
1
10
1
1
1
0
1
1
1
0
11
0
11
1
1
1
ticks
30.0

BUTTON
138
150
198
183
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
8
150
130
183
aphids-start
aphids-start
10
140
50.0
2
1
NIL
HORIZONTAL

CHOOSER
7
37
145
82
species
species
"P-steadius" "P-speedius"
1

MONITOR
247
151
304
196
aphids
count cells with [shape = \"aphid\"]
0
1
11

MONITOR
315
151
377
196
NIL
captures
0
1
11

BUTTON
295
39
358
72
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
156
39
285
72
replacement?
replacement?
0
1
-1000

OUTPUT
8
236
192
496
11

TEXTBOX
12
15
189
45
Set at beginning of experiment.
12
0.0
1

TEXTBOX
12
124
243
154
Do one run of the experiment.
12
0.0
1

TEXTBOX
9
92
412
120
----------------------------------------------------------------------------------------------------
11
0.0
1

TEXTBOX
10
210
446
252
------------------------------------------------------------------------------------------------------------
11
0.0
1

PLOT
199
236
438
395
Experiment Outcomes
prey density
captures
0.0
140.0
0.0
41.0
false
true
"" ""
PENS
"captures" 1.0 2 -6917194 true "" ""

BUTTON
339
405
437
438
save output
save-output
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

@#$#@#$#@
## WHAT IS IT?

BUGBOX-predator-original is a virtual version of the human simulation described in C.S. Holling's classic 1959 paper that derived what is now called the Holling type 2 predation model.  As Holling did with his students, instructors can use the observational experience from this virtual laboratory to build the intuition needed to derive the Holling type 2 predation model.

For an enhanced version that is designed for empiricial modeling and parameter studies, get BUGBOX-predator-analysis.

The simulation is centered around a predation experiment, in which a predator is placed in an arena with some prey and given a fixed amount of time to capture and handle the prey.  Each experiment run yields results for the number of prey captures as a function of the initial prey density.  There are two species of predator: P. steadius and P. speedius, whose characteristics roughly match their suggestive names.

If you don't want students to see all of the information in this Info document (such as references to Holling or citations), just delete what you want to keep hidden before sharing it with the students.

## HOW IT WORKS

To keep things simple, the prey remain fixed in place.  The predator moves randomly with speed and handling time determined by the user's choice of species.  Prey animals are removed when encountered by the predator.  These can be replaced, to maintain a constant prey population, or not, to better simulate a real experiment.  Each run determines the number of captures and plots a point on a graph of captures vs initial prey population.  The predator direction, like the prey locations, is determined stochastically, with a probability of 50% of going straight, 20% each for turning 60 degrees clockwise or counter-clockwise, and 5% each for turning 120 degrees clockwise or counter-clockwise.  Movement is simplified by the standard NetLogo assumption of a world that wraps around in both directions, rather than the more realistic assumption of fixed boundaries.

## HOW TO USE IT

Begin by choosing a species and decide on replacement.  P steadius is best for deriving a linear predation function that neglects handling time, while P speedius is best for building the intuition needed to derive the nonlinear Holling type 2 function.  Replacement 'on' is best unless you are specifically interested in comparing results with and without.  Then hit the 'setup' button.  Next, choose a start population and hit the 'go' button.  The experiment will run for a fixed amount of time, all the while keeping track of the current prey population and the cumulative number of captures.  At the end of the run, the values of starting prey population and capture count are printed in the monitor and a corresponding point is plotted on the graph.  Use the prey count slider to repeat the experiment with different numbers of prey (hit the 'go' button, but don't hit the 'setup' button, which would delete prior results).  This will gradually populate the graph with points.  Do a few of the runs at normal speed, particularly with P. speedius, before doing runs at high speed to collect the data quickly.  When you are satisfied, you can save the data using the corresponding button.  The program will save the experiment parameters and the xy pairs to a .csv file of your choosing.  You need not include the file extension '.csv', as the program will add it to your file name if it isn't there.

## THINGS TO NOTICE

Observation of the simulation runs at normal speed illustrates the importance of handling time, particularly when prey density is high, and particularly with P speedius.  Advanced modeling students can be asked to derive the appropriate nonlinear model using the assumption that simulation time is divided between search time and handling time, with the latter dependent in a simple way on the as-yet-unknown capture rate.

A number of empirical investigations can be done with the simulation, but it is best to use the extended version, BUGBOX-predator-analysis, which automates multiple experiment runs and the data analysis.

## NETLOGO FEATURES

The creation of cells was copied from the Hex Cells example packaged with Netlogo.  'Cells' are single turtles for each patch.  Since the prey doesn't move, the code identifies cells containing prey simply by replacing the standard hex image with an image of an aphid.  This makes 'shape' a Boolean variable that indicates the presence or absence of an aphid in each cell.

The predator movement required some finesse because of the need to have the predator's coordinates match that of the prey for a capture, combined with the angles required for the hex cells.  For a move time of 8 ticks, for example, the predator needs to move at speed 1/8.  This works fine for north-south movement.  For horizontal movement, the full 8 ticks change the y coordinate by 0.5, as required, but the x-coordinate lags behind the proper angle for a move straight to the next cell.  Each move tick includes a correction to advance the x-coordinate to match the correct value to the nearest 0.01, which makes the movement appear straight to the eye.  At the end of the 8 movement ticks, the x-coordinate is not exactly an integer (and the y-coordinate is not always exactly a half-integer), so there is extra code to adjust the coordinates with appropriate rounding.  This may not be the best way to ensure straight movement in a hex grid, but it gets the job done.

Using ticks to mark time during a run was problematic because resetting ticks also resets the plot windows.  Instead, a foreach loop is used to count steps in the simulation, with ticks used merely to trigger the display updates.  This also allows an entire run, with setup and simulation, to be handled by a single one-time 'go' button.  

Another challenge was how to produce a plot that uses only summary points and not points based on data that updates with each tick.  The Netlogo documentation is a bit obscure on this point.  The solution is to omit all plot commands from the interface and enter these in the code instead.  This is generally a best practice anyway, as commands in the interface are not as transparent as commands in the code.

## CREDITS AND REFERENCES

The original BUGBOX software was written in python and converted to windows executable.  It became dated when python was updated and some of the specialized packages needed for BUGBOX.py were not.  Netlogo is a much better platform for agent-based modeling.  The use of this software (albeit in its python implementation) is described in Ledder, An Experimental Approach to Mathematical Modeling in Biology, published online by PRIMUS in 2008 and available at https://www.tandfonline.com/doi/abs/10.1080/10511970701753423.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

aphid
true
0
Circle -13840069 true false 108 154 82
Circle -13840069 true false 115 51 70
Line -16777216 false 150 60 105 15
Line -16777216 false 150 60 195 15
Circle -13840069 true false 120 210 60
Line -13840069 false 120 210 120 210
Circle -13840069 true false 110 178 78
Circle -13840069 true false 109 140 82
Circle -13840069 true false 108 127 82
Circle -13840069 true false 109 114 82
Circle -13840069 true false 108 108 82
Circle -13840069 true false 109 103 82
Circle -13840069 true false 109 94 82
Polygon -16777216 true false 121 105 130 110 173 111 180 103 172 109 130 108 119 102
Circle -16777216 true false 155 65 10
Circle -16777216 true false 136 65 10

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

hex
false
0
Polygon -7500403 true true 0 150 75 30 225 30 300 150 225 270 75 270

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

ladybug-1
true
0
Circle -16777216 true false 102 34 96
Line -16777216 false 135 60 93 10
Line -16777216 false 165 62 218 8
Circle -2674135 true false 135 50 10
Circle -2674135 true false 156 50 10
Circle -2674135 true false 62 109 172
Circle -16777216 true false 131 178 32
Circle -16777216 true false 86 133 32
Circle -16777216 true false 177 133 32
Circle -16777216 true false 88 223 32
Circle -16777216 true false 175 223 32

ladybug-2
true
0
Circle -16777216 true false 102 34 96
Line -16777216 false 135 60 93 10
Line -16777216 false 165 62 218 8
Circle -955883 true false 135 50 10
Circle -955883 true false 156 50 10
Circle -955883 true false 62 109 172
Circle -16777216 true false 138 185 18
Circle -16777216 true false 108 140 18
Circle -16777216 true false 169 140 18
Circle -16777216 true false 195 186 18
Circle -16777216 true false 81 185 18
Circle -16777216 true false 110 230 18
Circle -16777216 true false 167 230 18

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
