breed [cells cell]

globals
[
  n-larvae ; starting larva population -- set on setup
  n-pupae ; starting pupa population -- set on setup
  n-adults ; starting adult population -- set on setup

  maxtime  ; largest time -- set on setup
  n-total ; total population -- set on setup, go
  tlist ; list of time values -- set on setup, go
  nlist ; list of n-total values -- set on setup, go

  mstar ; best fit slope -- set on plot-models/do-exponential
  bstar ; best fit intercept -- set on plot-models/do-exponential
  lambda ; best fit eigenvalue -- set on plot-models/do-exponential
]

cells-own
[
  hex-neighbors  ;; agentset of 6 neighboring cells
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  make-world
  set n-larvae 4
  set n-pupae 2
  set n-adults 2
  populate
  set n-total n-larvae + n-pupae + n-adults
  reset-ticks
  set tlist [0]
  set nlist []
  set nlist lput n-total nlist
  set maxtime 20
end

;;;;;;;;;;;;;;;;;;;;;

to go
  make-copy
  promote
  reproduce
  set n-total count cells with [xcor > 0 and shape != "hex"]
  tick
  set tlist lput ticks tlist
  set nlist lput n-total nlist
  if timelimit? and ticks > maxtime - 1 [stop]
end

;;;;;;;;;;;;;;;;;;;;;

to plot-model
  set-current-plot-pen "model"
  plot-pen-reset
  do-exponential
  plot-exponential
  set-current-plot-pen "ln-total"
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-world  ;; on setup
  set-default-shape cells "hex"
  ask patches
  [
    ifelse pxcor = 0
    [set pcolor black]
    [
      set pcolor white
      sprout-cells 1
      [
        set color white
        if pxcor mod 2 = 0 [set ycor ycor - 0.5]
      ]
    ]
  ]

  ask cells
  [ ifelse xcor mod 2 = 0
    [ set hex-neighbors cells-on patches at-points [[0 1] [1 0] [1 -1] [0 -1] [-1 -1] [-1 0]] ]
    [ set hex-neighbors cells-on patches at-points [[0 1] [1 1] [1  0] [0 -1] [-1  0] [-1 1]] ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;

to populate  ;; on setup
  ask n-of n-larvae cells with [xcor > 0 and xcor mod 2 = 1] [set shape "larva"]
  ask n-of n-adults cells with [xcor > 0 and xcor mod 2 = 0 and abs ycor < max-pycor] [set shape "bug-2"]
  ask n-of n-pupae cells with [xcor > 0 and shape = "hex"] [set shape "pupa"]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-copy  ;; on go
  ask cells with [xcor > 0]
  [
    let x xcor - max-pxcor - 1
    let y ycor
    let shaype shape
    let hedding heading
    ask cells with [xcor = x and ycor = y]
    [
      set shape shaype
      set heading hedding
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;

to promote
  ask cells with [xcor > 0]
  [
    (ifelse
      shape = "larva"
      [
        ifelse species > 1 and random 4 = 0
        [set shape "hex"]
        [if species < 4 or random 3 > 0 [set shape "pupa"]]
      ]
      shape = "pupa" [set shape "bug-2"]
      shape = "bug-2" [if species < 3 or random 3 > 0 [set shape "hex"]]
    )
  ]
end

;;;;;;;;;;;;;;;;;;;;;

to reproduce
  ask cells with [xcor < 0 and shape = "bug-2"]
  [
    ask hex-neighbors with [shape = "hex"]
    [
      let x xcor + max-pxcor + 1
      let y ycor
      ask cells with [xcor = x and ycor = y]
      [
        if random 3 < 1 [set shape "larva"]
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to do-exponential  ;; on plot-models  fits linear model to logarithmic data
  let xlist sublist tlist start-time (end-time + 1)
  let ylist []
  foreach (range start-time (end-time + 1))
    [
      [n] -> set ylist lput (ln item n nlist) ylist
    ]

  let X []
  let mean-x mean xlist
  foreach xlist [xx -> set X lput (xx - mean-x) X]

  let Y []
  let mean-y mean ylist
  foreach ylist [yy -> set Y lput (yy - mean-y) Y]

  let Sxx dot X X
  let Sxy dot X Y
  let Syy dot Y Y
  set mstar Sxy / Sxx
  set bstar (mean-y - mstar * mean-x)
  set lambda exp mstar

  output-type (word "growth rate ")
  let d1 decimaldigits lambda 4
  output-print (precision lambda d1)
end

;;;;;;;;;;;;;;;;;;;;;

to plot-exponential  ;; on plot-model
  plotxy 0 bstar
  plotxy ticks (bstar + mstar * ticks)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report dot [xvals yvals]
  let product []
  (
    foreach xvals yvals
    [
      [x y] -> set product lput (x * y) product
    ]
  )
  report sum product
end

;;;;;;;;;;;;;;;;;;;;;

to-report decimaldigits [number sigfigs]  ; determines decimal digits from significant figures
  let nn abs number
  report sigfigs - 1 - floor (log nn 10)
end
@#$#@#$#@
GRAPHICS-WINDOW
188
38
1036
455
-1
-1
24.0
1
10
1
1
1
0
1
0
1
-17
17
-8
8
1
1
1
ticks
30.0

BUTTON
4
60
59
93
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

BUTTON
67
59
122
92
go once
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

CHOOSER
0
10
92
55
species
species
1 2 3 4
0

TEXTBOX
335
10
485
30
PREVIOUS time
16
13.0
1

TEXTBOX
770
11
920
31
CURRENT time
16
103.0
1

MONITOR
93
100
165
145
larvae
count cells with [xcor > 0 and shape = \"larva\"]
0
1
11

MONITOR
93
145
165
190
pupae
count cells with [xcor > 0 and shape = \"pupa\"]
0
1
11

MONITOR
93
189
165
234
adults
count cells with [xcor > 0 and shape = \"bug-2\"]
0
1
11

PLOT
0
236
184
356
population fractions
time
totals
0.0
20.0
0.0
0.6
true
false
"" ""
PENS
"larvae" 1.0 2 -10899396 true "" "plot count cells with [shape = \"larva\"] / count cells with [shape != \"hex\"]"
"pupae" 1.0 2 -13345367 true "" "plot count cells with [shape = \"pupa\"] / count cells with [shape != \"hex\"]"
"adults" 1.0 2 -6459832 true "" "plot count cells with [shape = \"bug-2\"] / count cells with [shape != \"hex\"]"

PLOT
1
357
185
485
logarithm of population
time
ln(total)
0.0
20.0
2.0
5.0
true
false
"" ""
PENS
"ln-total" 1.0 0 -16777216 true "" "plot ln n-total"
"model" 1.0 0 -955883 true "" ""

SWITCH
96
11
186
44
timelimit?
timelimit?
0
1
-1000

BUTTON
130
59
185
92
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
15
101
88
146
old larvae
count cells with [xcor < 0 and shape = \"larva\"]
0
1
11

MONITOR
15
145
88
190
old pupae
count cells with [xcor < 0 and shape = \"pupa\"]
0
1
11

MONITOR
15
190
88
235
old adults
count cells with [xcor < 0 and shape = \"bug-2\"]
0
1
11

INPUTBOX
189
461
262
521
start-time
0.0
1
0
Number

INPUTBOX
266
461
339
521
end-time
20.0
1
0
Number

BUTTON
343
462
431
495
plot model
plot-model
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
436
463
676
517
11

@#$#@#$#@
## WHAT IS IT?

BUGBOX-population is a virtual laboratory, intended for use by students to develop skills in mathematical modeling.  It serves as an authentic alternative to collecting data from real biological experiments, although of course the virtual world does not actually match any real world scenario.  It was originally written in 2007 to teach stage-structured population models and has been rewritten in Netlogo in 2022.  

There are four species of boxbugs, identical in appearance but with an increasingly complex life cycle.  Each species requires the modeler to add an additional parameter and sometimes additional non-zero terms to the model.

## HOW IT WORKS

Because boxbugs were 'bred' to introduce mathematical modeling to students, boxbug biology is conveniently simple.  They grow and reproduce without need for food or mates, and they are immobile, which means that a pupa with a particular orientation in a particular location must be the same individual as a larva that previously occupied the same location with the same orientation.  They begin life as larvae, metamorphose into pupae, mature into adults, and eventually die.  Adults give birth to new larvae, which occupy adjacent sites in the bugbox.  The view shows two bugboxes, one showing the current arrangement of boxbugs and the other showing the arrangement from the previous time step for comparison.  

## HOW TO USE IT, part 1

Start by selecting Species 1 and imposing the time limit.  Press 'setup' to populate the bugbox with a predetermined number of individuals.  It should be easy from the pictures to see which stage is larvae, which is pupae, and which is adults.  When you hit 'go once', the picture of the current population will be replaced by a picture of the population at the next time step, but only after the old picture has been reproduced on the left side of the view.  Each time you hit 'go once', the same updating will occur.

Your job is to build a mathematical model for Species 1 by carefully observing the changes made at each time step.  Your model will consist of formulas that predict the populations of larvae, pupae, and adults at time t+1 from the population present at time t.  To do so, you need to look at the individuals in the bugbox rather than just the counts of individuals.  For example, you will see that every pupa in the current time step was a larva in the previous time step and that every larva from the previous step became a pupa; thus, P_{t+1}=L_t.  You will not be able to find an exact formula for the larva population because there is some stochasticity (randomness) built into the model.  This is a complicating factor, but it just means that your model will need a parameter, say 'f', to represent the average number of larvae born to each adult.  You should be able to find another exact equation for the new population of adults.  

It is difficult to estimate the fecundity parameter f by observation.  The best way to estimate f is to determine the long-term growth rate for the model and then obtain f by calculation.  To do this, use 'go' rather than 'go once' to run the simulation for 20 consecutive time steps.  Then keep the start and end times for the calculation at 0 and 20 and hit 'plot model'.  Record the growth rate that appears in the output window.  Do this ten times with Species 1 to get ten different results, which you can average to get a best estimate for the growth rate, lambda.  This average growth rate can be determined from the model in terms of the values of the parameters.  To find the algebraic formula that relates lambda and f, you will need to study matrix population models.  Once you know the formula, you can use it to estimate f from lambda.  Note that "growth rate" is a biological term; in mathematical terms, lambda is the dominant eigenvalue of the matrix that represents the model.

Once you have got a model that you think is correct, you can use a spreadsheet to predict the populations at each time step from the previous one.  Start the simulation over and see how well your model performs.  Of course you cannot expect it to give the correct numbers of larvae because of the randomness, but if you choose a reasonable estimate of f, your model should give results that are sometimes too large and sometimes too small.  

Once you have finished Species 1, move on to Species 2.  This species requires a model with 2 parameters rather than 1.  Either there is a new pathway, such as a stage that no longer dies at every time step, or something that used to be guaranteed, like maturation from larva to pupa, is no longer guaranteed, which requires a probability parameter.  Keep in mind that what matters is the observation of the individuals, not the total counts.  The total count of larvae, for example, could include some that are newly born and others that were born earlier and didn't mature.  A mechanistic model has to account for these processes separately, with the predicted total determined by the sum of the predictions for each relevant process. You will have to estimate new parameters by observation.  This should not be difficult for probability parameters.  You may need to restart the simulation several times to keep the populations low so that you can get enough data (using 'go once') to get a reliable estimate.

## THINGS TO NOTICE

You may notice some odd systematic behavior with Species 1 and 2.  These species have life histories that lack an essential feature for realistic populations.  For this reason, the graph of population fractions, shown in the upper plot, will not be meaningful.  You do not need to recalculate f, but can use the value you got for Species 1.

## HOW TO USE IT, part 2

Continue with Species 3 and 4.  These should give you a meaningful graph of population fractions with dots of three colors that begin to separate out into layers, although you will need more than 20 time steps to see this clearly.  Predictions for population structure tend to be more accurate than predictions for population counts because discrepancies between theory and reality for structure tend to run counter to those of earlier time steps while those for population total tend to increase over time.  If your model is mechanistically correct and your parameter estimates are close, the population fractions you see should be fairly close to what you can predict from the model.  Note that the probability parameters can change from one species to the next, so you should always estimate them from data for each new species.  The fecundity parameter f should be the same for each species, so you do not need to recalculate it.

## EXTENDING THE MODEL

The simulations run for only 20 time steps because the effects of limited space become apparent at about that time.  Stage-structured linear models are only useful for this early phase of population growth.  You can make the model more realistic by assuming that the birth rate coefficient f for Species 4 is actually a function of the total population.  You can remove the time limit and let the simulation run until the population is relatively constant.  This should not take more than 150 time steps.  If you do several runs and average the results, you can get estimated measurements of the model "final" population total and fractions.  This information can be used to estimate parameters for a coefficient formula with f as a linear function of the total population N.  This adds a minimal degree of nonlinearity to the model.  Computer simulations run with a reasonable nonlinear model should be able to approximate the results you get from the bugbox simulation.

## NETLOGO FEATURES

The creation of cells in a hexagonal grid was copied from the Hex Cells example packaged with Netlogo.  Since the boxbugs don't move, the code identifies them simply by choosing an animal image for a cell to replace the standard hex image, rather than defining turtles of a different breed to represent the boxbugs.  Aside from that, the code for the simulation is very simple.  The code for calculating the growth rate is somewhat complicated owing to the fact that Netlogo is not as well designed for scientific computation as it is for simulation; however, it is simple enough to serve as a good template for doing computation with lists and using reporters as functions to do calculations.

## CREDITS AND REFERENCES

The original BUGBOX software was written in python and converted to windows executable.  It became dated when python was updated and some of the specialized packages needed for BUGBOX were not.  Netlogo is a much better platform for agent-based modeling.  

The use of BUGBOX-population to teach mathematical modeling is described in Ledder, An Experimental Approach to Mathematical Modeling in Biology, published online by PRIMUS in 2008 and available at https://www.tandfonline.com/doi/abs/10.1080/10511970701753423.  Stage-structured linear population models can be found in many books on matrix algebra and books on mathematical biology.  It is described in both intuitive language and formal mathematical language in Ledder, Mathematical Modeling in Epidemiology and Ecology, Springer 2022, Chapter 5.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

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

bug-2
true
0
Circle -6459832 true false 62 109 172
Circle -16777216 true false 102 34 96
Line -16777216 false 135 60 93 10
Line -16777216 false 165 62 218 8
Circle -1184463 true false 135 50 10
Circle -1184463 true false 156 50 10
Circle -1184463 true false 90 150 30
Circle -1184463 true false 180 150 30
Circle -1184463 true false 90 225 30
Circle -1184463 true false 180 225 30
Circle -1184463 true false 135 180 30

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

larva
true
0
Circle -13840069 true false 96 182 108
Circle -13840069 true false 96 113 108
Circle -13840069 true false 101 67 96
Line -16777216 false 150 75 80 30
Line -16777216 false 150 75 220 30
Circle -16777216 true false 128 89 10
Circle -16777216 true false 162 89 10
Line -16777216 false 105 135 118 139
Line -16777216 false 108 201 121 205
Line -16777216 false 191 201 178 205
Line -16777216 false 192 135 179 139
Line -16777216 false 119 140 143 143
Line -16777216 false 122 205 146 208
Line -16777216 false 178 205 154 208
Line -16777216 false 181 138 160 143
Line -16777216 false 144 143 164 143
Line -16777216 false 143 208 163 208

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

pupa
true
0
Circle -13345367 true false 74 153 150
Circle -13345367 true false 84 75 132
Circle -13345367 true false 98 22 102
Line -1184463 false 104 94 112 100
Line -1184463 false 114 101 129 104
Line -1184463 false 136 105 160 105
Line -1184463 false 129 105 137 106
Line -1184463 false 162 105 170 103
Line -1184463 false 195 94 184 100
Line -1184463 false 184 101 171 104
Line -1184463 false 94 178 111 183
Line -1184463 false 203 177 185 184
Line -1184463 false 113 185 138 188
Line -1184463 false 183 185 166 188
Line -1184463 false 140 188 162 188

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
setup1
repeat 20 [ go ]
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
