patches-own [
  occupied                   ;; whether patch is (occupied by) an agent
  language                   ;; the language vector
  probability-of-entering    ;; used for border patches
]

globals [
 language-left               ;; base language vectors for each population
 language-right
]

to setup
  clear-all

  set language-left []
  set language-right []
  ;; set the base languages to random vectors of the specified size
  repeat number-of-words [
    set language-left lput (create-random-vector word-length) language-left
    set language-right lput (create-random-vector word-length) language-right
  ]

  ask patches [ clear-patch ]
  ask patches [ initialize ]
  set-colors

  reset-ticks
end

to initialize
  (ifelse pxcor = 0 [      ;; border patches are created down the middle of the world in a straight line
    set probability-of-entering 1 - border-difficulty
  ] pxcor < 0 [            ;; for agent population left of the border
    set probability-of-entering 1
    ifelse random-float 1 < population-density [                ;; agents are spawned according to the population density
      set language (add-variation-to-language language-left)    ;; agent's language is a variant of the base language of its population
      set occupied true
    ] [
      set occupied false
    ]
  ] [ ;; for agent population right of the border, same initialization except base language is different
     set probability-of-entering 1
     ifelse random-float 1 < population-density [
      set language (add-variation-to-language language-right)
      set occupied true
    ] [
      set occupied false
    ]
  ])
end

to go
  talk
  move
  set-colors
  tick
end

to talk
  ask patches with [occupied] [
    let new-lang language
    let orig-lang new-lang
    ;; talk to a random neighbor
    ask one-of neighbors [
      if occupied [
        ;; get the adapted language, based on own language but slightly more similar to the neighbor's now
        let word-index one-of range number-of-words
        let new-word weighted-average item word-index new-lang item word-index language learning-rate
        set new-lang replace-item word-index new-lang new-word
      ]
    ]
    ;; update own language with the adapted one
    set language new-lang
  ]
end

to move
 ask patches with [occupied] [
    let new-x pxcor
    let new-y pycor

    ;; decide randomly on the direction to move
    let direction one-of ["up" "down" "left" "right"]

    ;; update new coordinates based on the chosen direction
    if direction = "up" [
      set new-y new-y + 1
    ]
    if direction = "down" [
      set new-y new-y - 1
    ]
    if direction = "left" [
      set new-x new-x - 1
    ]
    if direction = "right" [
      set new-x new-x + 1
    ]

    let original-lang language
    let moved false
    ;; check if the new patch is valid (within world bounds)
    ifelse (abs new-x <= max-pxcor and abs new-y <= max-pycor and new-x >= min-pxcor and new-y >= min-pycor) [
      ask patch new-x new-y [
        if not occupied [   ;; a patch can be occupied by only one agent
          if random-float 1 < probability-of-entering [
            set occupied true
            set language original-lang
            set moved true
          ]
        ]
      ]
      if moved [set occupied false]
    ] [
      ;; if the new patch is outside world bounds, do nothing
    ]
  ]
end

to set-colors
ask patches [
    (ifelse occupied [
     set pcolor lang-to-color language
    ] probability-of-entering = 1 [
       set pcolor green
    ] [
       set pcolor blue
     ])
]
end

to clear-patch ;; patch procedure
  set pcolor black
  set occupied false
  set language []
end

;; compute the mean language of two agents, element-wise
to-report calc-avg-language
  let avg-language map [i -> n-values word-length [0]] range number-of-words
  let total-agents count patches with [occupied]
  ask patches with [occupied] [
    foreach range number-of-words [i ->
      foreach range word-length [j ->
        let old-avg-element item j item i avg-language
        let new-avg-element old-avg-element + ((item j item i language) / total-agents)
        let updated-word replace-item j (item i avg-language) new-avg-element
        set avg-language replace-item i avg-language updated-word
      ]
    ]
  ]

  report avg-language
end

;; find the mean variance across words in all languages
to-report mean-variation-of-words
  let avg-language calc-avg-language

  let total-agents count patches with [occupied]
  let word-lengths length (first avg-language)

  ;; list to hold the squared differences for each word and each language
  let squared-diffs-sum 0

  ask patches with [occupied] [
    foreach range number-of-words [i ->
      let avg-word item i avg-language
      let patch-word item i language

      let sq-diff squared-difference avg-word patch-word

      set squared-diffs-sum squared-diffs-sum + sum sq-diff
    ]
  ]

  ;; calculate the mean variance across all languages and words
  report squared-diffs-sum / total-agents / number-of-words / word-length
end

to-report squared-difference [v1 v2]
  let diffs []
  let len length v1

  foreach range len [i ->
    let e1 item i v1
    let e2 item i v2
   set diffs lput ((e1 - e2) * (e1 - e2)) diffs
  ]

  report diffs
end

;; create a random float vector
to-report create-random-vector [len]
  let vector []
  repeat len [
    set vector lput (random-float 2 - 1) vector
  ]
  report vector
end

;; computes w * v1 + (1 - w) * v2
;; it is used with the learning rate as the weight and
;; two language vectors from conversation partners
to-report weighted-average [v1 v2 w]
  let result []

  ;; calculate the weighted average for each component of the vectors
  foreach range word-length [i -> set result lput ((1 - w) * (item i v1) + w * (item i v2)) result]

  report reverse result
end

;; variates words in a language
to-report add-variation-to-language [vec-list]
  report map [vec -> add-variation-to-word vec] vec-list
end

;; adds a variation to a word
to-report add-variation-to-word [vec-list]
  report map [i -> i + random-normal 0 intra-language-variation] vec-list
end

to-report lang-to-color [lang]
  let c []
  foreach [0 1 2] [i -> set c lput (round mean item i lang * 100 + 127) c]
  report c
end
@#$#@#$#@
GRAPHICS-WINDOW
330
10
707
388
-1
-1
9.0
1
10
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

BUTTON
75
18
144
51
setup
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
181
18
250
51
go
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

SLIDER
67
95
239
128
population-density
population-density
0
1
0.13
0.01
1
NIL
HORIZONTAL

SLIDER
67
139
273
172
intra-language-variation
intra-language-variation
0
1
0.08
0.01
1
NIL
HORIZONTAL

SLIDER
68
184
240
217
number-of-words
number-of-words
3
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
69
231
241
264
word-length
word-length
1
5
2.0
1
1
NIL
HORIZONTAL

SLIDER
70
278
242
311
border-difficulty
border-difficulty
0
1
0.68
0.01
1
NIL
HORIZONTAL

SLIDER
69
321
241
354
learning-rate
learning-rate
0
1
0.05
0.01
1
NIL
HORIZONTAL

MONITOR
721
11
1189
56
Mean Language
map [l -> map [v -> precision v 2] l] calc-avg-language
3
1
11

PLOT
734
77
1188
350
Language Variation
NIL
NIL
0.0
1.0
0.0
0.2
true
false
"" ""
PENS
"Language Variance" 1.0 0 -16777216 true "" "plot mean-variation-of-words"

@#$#@#$#@
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

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

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
NetLogo 6.4.0
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
