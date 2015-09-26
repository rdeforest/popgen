# Remove when popular browsers catch up
AudioContext = AudioContext or webkitAudioContext

console.clear()
console.log 'And so it starts...'

HALF_STEP = Math.pow 2, 1/12
WHOLE_STEP = Math.pow 2, 1/6

STEPS_FROM_A_DOWN_TO_C = 9
LOWEST_OCTAVE = 4

concertTuning = 440 # The A above mildle C in Hz

keyNames = "C C#/Db D D#/Eb E F F#/Gb G G#/Ab A A#/Bb B".split ' '
keyPitch = (name) ->
  note = keyNames.indexOf name
  concertTuning * Math.pow HALF_STEP, LOWEST_OCTAVE * -12 - STEPS_FROM_A_DOWN_TO_C + note

keys = {}

for name in keyNames
  keys[name] = keyPitch name

chordProg = [
    [0, 2, 4],
    [4, 6, 8],
    [5, 7, 9],
    [3, 5, 7]
  ]

waveforms = 'sine square sawtooth triangle'.split ' '

# Ugh, global variables


selections =
  key: keys["A"]
  octave: 3
  range: 16
  waveform: 'sawtooth'

notesPerMeasure = 4
qtrNote = 600
eigthNote = qtrNote / 2
minNote = eigthNote
context = new AudioContext

chord = base = chordType = melodyType = time = melodyInt = undefined
chor1 = chor2 = chor3 = melody = undefined

isRunning = false

notes = undefined

chordGain  = context.createGain();  chordGain.gain.value = 0.05
melodyGain = context.createGain(); melodyGain.gain.value = 0.1

init = ->
  updateBase()
  updateWaveformType()
  buildMajorScale()

  [chor1, chor2, chor3, melody] = (context.createOscillator() for [1..4])

  [chor1, chor2, chor3].forEach (voice, i) ->
    voice.connect chordGain
    voice.type = chordType
    voice.frequency.value = notes[chordProg[0][i]]

  melody.connect melodyGain
  melody.type = melodyType
  melody.frequency.value = base
  
  channel.connect context.destination for channel in [chordGain, melodyGain]

beginFunc = ->
  console.log 'starting music...'
  endFunc()
  init()
  chord = step = time = 0
  melodyInt = setInterval melodyFun, minNote
  voice.start 0 for voice in [chor1, chor2, chor3, melody]
  isRunning = true

endFunc = ->
  if isRunning
    voice.stop 0 for voice in [chor1, chor2, chor3, melody]
    clearInterval melodyInt
    isRunning = false

buildScale = (steps...) ->
  notes = [freq = base]

  for step in steps
    freq *= step
    notes.push freq

  notes

majorScale = [
    WHOLE_STEP, WHOLE_STEP, HALF_STEP
    WHOLE_STEP, WHOLE_STEP, WHOLE_STEP, HALF_STEP
  ]

buildMajorScale = ->
  s = buildScale majorScale...
  notes = []
  notes = notes.concat s for [1 .. selections.range]

melodyFun = ->
  time++

  if time % (notesPerMeasure * (qtrNote / minNote)) is 0 and not (time is 0)
    chord++
    chord %= 4
    chor1.frequency.value = notes[chordProg[chord][0]]
    chor2.frequency.value = notes[chordProg[chord][1]]
    chor3.frequency.value = notes[chordProg[chord][2]]

  if (time % (Math.floor Math.random() * qtrNote / minNote) is 0)
    note = Math.floor Math.random() * (notes.length - 1)
    melody.frequency.value = notes[note]

beginButtonInfo =
  value: 'start'
  onclick: beginFunc
  className: 'button'

endButtonInfo =
  value: 'end'
  onclick: endFunc
  className: 'button_end'

makeButton = (info) ->
  {value, onclick, className} = info
  b = $('<input>')
    .on('click', onclick)
    .attr
      type: 'button'
      value: value
    .addClass className

makeButtonDiv = ->
  $('<div>')
    .addClass('buttonDiv')
    .append(makeButton beginButtonInfo)
    .append(makeButton endButtonInfo)

capitalize = (s) -> s[0].toUpperCase() + s.substr 1

makeSelector = (name, selected, options) ->
  cname = capitalize name
  sel = $('<select>')
      .append((new Option o[0], o[1]) for o in options)
      .addClass('selector')
      .attr('name', cname + "Selector")
      .on('change', -> restart selections[name] = @value)
      .prop('selectedIndex', selected)
      .append 'foo'

  [cname + ': ', sel]

makeControlDiv = (context) ->
  $('<div>')
    .addClass('ddDiv')
    .append((makeSelector('key',      9, ([k, f]     for k, f of keys)))...)
    .append((makeSelector('octave',   3, ([o, o]     for o in [0 .. 6])))...)
    .append((makeSelector('range',    1, ([i, i * 8] for i in [1 .. 5])))...)
    .append((makeSelector('waveform', 2, ([w, w]     for w in waveforms)))...)
    .append('BPM: ', ($('<input>')
      .attr('name', 'BPMInput')
      .addClass('textInput')
      .attr('type', 'text')
      .on('change', ->
        checkBpmInput this
        qtrNote = Math.floor Math.pow bpmdd.value / 60 / 1000, -1
        minNote = eightNote = qtrNote / 2
        restart())
      .attr('value', 100)))

updateBase = -> base = selections.key * Math.pow(2, selections.octave)

updateWaveformType = -> chordType = melodyType = selections.waveform

checkBpmInput = (ob) ->
  console.log 'bpm: ', ob
  invalidChars = /[^0-9]/g
  ob.value = ob.value.replace invalidChars, ''
  ob.value = Math.min 40, Math.max 300, ob.value

restart = -> beginFunc() if isRunning

$(->
  $("body").append(makeButtonDiv)
  $("body").append(makeControlDiv)
)

