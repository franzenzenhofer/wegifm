
#flags
_DEBUG_ = true

#the very ugly state
_video_is_playing_ = false
_global_drawing_loop_id_ = 0
_start_time_ = 0
_video_chunk_duration_ms_ = 10000
_end_time_ = 0
_loop_ = true
_keep_ratio_ = true
_framerate_ = 10
_current_frame_ = 0

_GIF_ = {}
_make_gif_now_ = false

_WEBM_ = {}
_make_webm_now_ = false

_crop_left_ = 0
_crop_top_ = 0
_crop_right_ = 0
_crop_bottom_ = 0

_text_ = 
  topstring: "TOP"
  bottomstring: "BOTTOM"
  fontsize: 34


#DOM helper
$$ = (id) -> document.getElementById(id)
$e = (id, eventname, func) -> 
  log('hiho')
  $$(id).addEventListener(eventname, (evt) -> 
    func(evt)
  )
$d = (id) -> $$(id).setAttribute('disabled', 'disabled')
$dd = (id) -> $$(id).removeAttribute('disabled')

$_ = (selector) -> document.querySelectorAll(selector)
$n = (name) -> document.getElementsByName(name)
$_e = (selector, eventnames, func) ->
  elements = $_(selector)
  d(elements)
  if not Array.isArray(eventnames)
    eventnames = [eventnames]
  for eventname in eventnames 
    for elem in elements
      do (elem) ->
        #log(elem)
        elem.addEventListener(eventname, ((e)->func(e)))

#helper 
d = (msg) -> console.log(msg) if _DEBUG_; return msg

log = (msg) ->
  li = document.createElement('li')
  li.innerHTML = msg
  $$('loglist').appendChild(li)
  $$('loglist').scrollTop = $$('loglist').scrollHeight

now = window.performance?.now?.bind(window.performance) or Date.now


#shortcuts
v = $$('input_video')#document.createElement('video')

#helper objects
tc = document.createElement('canvas')
tcc = tc.getContext('2d')

oc = $$('out_canvas');
occ = oc.getContext('2d')

#font canvas
ec = document.createElement('canvas')
ecc = ec.getContext('2d')



drawingLoop = (i, o) ->
  _global_drawing_loop_id_ = window.setInterval(
    (
      ()->
        tempDrawing(i,o)
        fontDraw()
        outDraw()
        if v.currentTime >= v.duration
          #d('end check in drawing loop is true')
          customEnded()

    )
  , 1000/_framerate_)

fontDraw = () ->
  ec.width = oc.width
  ec.height = oc.height
  ecc.textAlign = "center"
  ecc.strokeStyle = "black"
  ecc.fillStyle = "white"

  ecc.font = _text_.fontsize+"pt Impact"
  ecc.lineWidth = 2
  ecc.drawImage(tc,0,0,oc.width, oc.height)

  ecc.fillText(_text_.topstring, oc.width/2, _text_.fontsize+5)
  ecc.strokeText(_text_.topstring, oc.width/2, _text_.fontsize+5)

  ecc.fillText(_text_.bottomstring, oc.width/2, oc.height-5)
  ecc.strokeText(_text_.bottomstring, oc.width/2, oc.height-5)

tempDrawing = (i, o) ->
  o.canvas.width = i.width - cropWidthOffset(_crop_left_) - cropWidthOffset(_crop_right_)
  o.canvas.height = i.height - cropHeightOffset(_crop_top_) - cropWidthOffset(_crop_bottom_)
  o.drawImage(i, cropWidthOffset(_crop_left_), cropHeightOffset(_crop_top_), i.width, i.height, 0, 0, i.width, i.height)
  #o.drawImage(fc,0,0)

cropWidthOffset = (crop_value, video = v) ->
  Math.floor(video.width * (crop_value/100))

cropHeightOffset = (crop_value, video = v) ->
  Math.floor(video.height * (crop_value/100))


#TODO clean this array later
vtc_array = []

cleanVtcArray = () ->
  vtc_array = []

createVeryTemporaryCanvas = (i) ->
    vtc = document.createElement('canvas')
    vtc.width = i.width
    vtc.height = i.height
    vtcc = vtc.getContext('2d')
    vtcc.drawImage(i,0,0,i.width,i.height)
    return vtc

outDraw = () ->
  _current_frame_ = _current_frame_ + 1
  $$('frame_counter').innerHTML = _current_frame_
  occ.drawImage(ec,0,0,oc.width, oc.height)
  #occ.fillText("Figure 1", 88, 88)
  if _make_gif_now_ is true or _make_webm_now_ is true
    delayi = 1000/_framerate_
    vtc_array.push(createVeryTemporaryCanvas(oc))
  if _make_gif_now_ is true
    _GIF_.addFrame(vtc_array[vtc_array.length - 1], {delay: delayi})
    log('gif add frame '+_current_frame_+' '+'delay '+delayi)
  if _make_webm_now_ is true
    _WEBM_.add(vtc_array[vtc_array.length - 1], delayi)
    log('webm add frame '+_current_frame_+' '+'delay '+delayi)

setEndTime = (s = _start_time_, du = _video_chunk_duration_ms_) ->
  d('start_time '+_start_time_)
  d('duration time '+du)
  _end_time_ = s+(du/1000)
  d('end_time '+_end_time_)

initVideosAndCanvas = (src, force_reset = false) ->
  if src?
    v.src = src

  if _end_time_ is 0 or force_reset is true
    _end_time_ = setEndTime()
    if _end_time_ > v.duration
      _end_time_ = v.duration
  #$$('video_end').value = 100



  if force_reset is true
    _start_time_ = 0
    $$('video_start').value = 0
  
  #d(_end_time_)
  v.width = tc.width = v.videoWidth
  v.height = tc.height = v.videoHeight
  display_width = parseInt(window.getComputedStyle($$('display')).getPropertyValue('width'))
  if display_width > 400 then display_width = 400
  resize_factor_width = display_width / v.width
  #d('resize_factor_width:'+resize_factor_width)
  if resize_factor_width > 1 then resize_factor_width = 1
  [w,h] = setCanvasWidthAndHeightByFraction(resize_factor_width, resize_factor_width, false)
  $$('vc').style.height = oc.height
  $$('display').style.height = oc.height

v.addEventListener('loadedmetadata', () ->
  log('metadata of video loaded')
  initVideosAndCanvas()
)

v.addEventListener('playing', () -> 
  _video_is_playing_ = true
  drawingLoop(v, tcc)
)

customPlay = (restart = true) ->
  #d('_video_is_playing_:'+_video_is_playing_)
  if restart 
    stopVideo()
    #d('restart the video')
    d('_start_time_:'+_start_time_)
    #customEnded()
    v.currentTime = _start_time_
    d('v.currentTime:'+v.currentTime)
    _video_is_playing_ = true
    _current_frame_ = 0
    v.play()
  else
    if _video_is_playing_ is false
      customPlay(true)

stopVideo = () ->
  v.pause()
  clearInterval(_global_drawing_loop_id_)

customEnded = () ->
  #d('custom ended')
  _video_is_playing_ = false
  stopVideo()
  if _loop_ is true
    customPlay()
  if _make_gif_now_ is true
    _make_gif_now_ = false
    _GIF_.render()
    #cleanVtcArray()
  if _make_webm_now_ is true
    _make_webm_now_ = false
    finishWebM()

v.addEventListener('ended', () -> 
  #d('ended event')
  customEnded()
)

v.addEventListener('timeupdate', () ->
  #d('timeupdate')
  #d(v.currentTime)
  if v.currentTime > _end_time_
    #d('timeupdate end event')
    customEnded() 
)

qaVideoStartAndEnd = () ->
  setEndTime()
  $$('video_start').value = (_start_time_ / v.duration) * 100
  $$('video_duration').value = _video_chunk_duration_ms_
  
  #ev = parseFloat($$('video_end').value)
  sv = parseFloat($$('video_start').value)
  if _end_time_ < _start_time_
    console.log('end time is smaller than start time')
    _end_time_ = _start_time_
  #if ev < sv
  #  $$('video_end').value = sv #$$('video_start').value
  if sv < 0
    $$('video_start').value = 0
    _start_time_ = 0
  if sv >= 100
    $$('video_start').value = 99


$$('video_start').addEventListener('input', () ->
  _start_time_ = v.duration*(parseFloat($$('video_start').value)/100)
  qaVideoStartAndEnd()
  customPlay(true)
)

$_e('.start_plus_minus', 'click', (e)->
    d(e)
    p_m_ms = parseInt(e.target.value)
    _start_time_ = _start_time_ + (p_m_ms/1000)
    qaVideoStartAndEnd()
    customPlay(true)
  )

$_e('.test_start', 'click', (e)->
  qaVideoStartAndEnd()
  customPlay(true)
)

#$$('video_end').addEventListener('input', () ->
#  _end_time_ = v.duration*(parseFloat($$('video_end').value)/100)
#  qaVideoStartAndEnd()
#)

#$$('loop_on').addEventListener('click', () -> _loop_ = true; customPlay(false))
#$$('loop_off').addEventListener('click', () -> _loop_ = false )

#$$('someid').addEventListener('click', () ->
# 
#)

#setCanvasWidthAndHeightByTotal = (w,h) ->

setCanvasWidthAndHeight = (w, h) ->
  oc.width =  w
  oc.height = h
  [w,h]


setCanvasWidthAndHeightByFraction = (wp, hp, ratio = _keep_ratio_) ->
  if wp? then $$('video_width').value = wp*100
  if hp? then $$('video_height').value = hp*100
  w_h_ratio = Math.floor((oc.width/oc.height)*100)/100
  h_w_ratio = Math.floor((oc.height/oc.width)*100)/100 

  w = oc.width
  h = oc.height 

  if wp?
    w = parseInt(wp*tc.width)

  if hp?
    h = parseInt(hp*tc.height)

  if wp isnt null and wp isnt undefined and ratio is true
    #d(wp)
    #d('keep ratio by width')
    #d(w_h_ratio)
    h = parseInt(w / w_h_ratio)
    $$('video_height').value = (h / tc.height)*100
  
  else if hp isnt null and hp isnt undefined and ratio is true
    w = parseInt(h / h_w_ratio)
    d($$('video_width').value)
    $$('video_width').value = (w / tc.width)*100

  setCanvasWidthAndHeight(w,h)

$$('video_width').addEventListener('input', () ->
  setCanvasWidthAndHeightByFraction(parseInt($$('video_width').value)/100)
)

$$('video_height').addEventListener('input', () ->
  vh_percentage = parseInt($$('video_height').value)/100
  setCanvasWidthAndHeightByFraction(null, vh_percentage)
)

$$('ratio_yes').addEventListener('click', () -> _keep_ratio_ = true)
$$('ratio_no').addEventListener('click', () -> _keep_ratio_ = false)

$$('crop_left').addEventListener('input', () -> 
  _crop_left_ = parseInt($$('crop_left').value)
  setCanvasWidthAndHeightByFraction(parseInt($$('video_width').value)/100, null, false)
)

$$('crop_right').addEventListener('input', () -> 
  _crop_right_ = parseInt($$('crop_right').value)
  setCanvasWidthAndHeightByFraction(parseInt($$('video_width').value)/100, null, false)
)

$$('crop_top').addEventListener('input', () -> 
  _crop_top_ = parseInt($$('crop_top').value)
  setCanvasWidthAndHeightByFraction(null,parseInt($$('video_height').value)/100, false)
)

$$('crop_bottom').addEventListener('input', () -> 
  _crop_bottom_ = parseInt($$('crop_bottom').value)
  setCanvasWidthAndHeightByFraction(null,parseInt($$('video_height').value)/100, false)
)

setFramerate = (fr) ->
  old_fr_value = _framerate_
  fr = parseInt(fr)
  #if isNaN(fr) then d('is NAN')
  if fr < 1 or fr > 30 or isNaN(fr)
    d('out of bounds')
    $$('framerate').value = _framerate_ = old_fr_value
  else
    _framerate_ = fr
  $$('fps').innerHTML = _framerate_
  d(fr)

$_e('#framerate', 'blur', (e)->
  setFramerate($$('framerate').value)
)

$$('set_framerate').addEventListener('click', () ->
  setFramerate($$('framerate').value)
)



makeGif = () ->
  if _make_gif_now_ is true then log('gif creation already in progress'); return false;
  d('init gif creation')
  $d('make_gif')
  _GIF_ = new GIF(
    workerScript: './bower_components/gif.js/dist/gif.worker.js'
    width: oc.width
    height: oc.height
    workers: 2
    quality: 20
  )
  _GIF_.on('start', ()->
    log('gif creation started')
  )


  _GIF_.on 'progress', (p) ->
    log("rendering: #{ Math.round(p * 100) }% "+p)

  _GIF_.on('finished', (blob) -> 
    #alert('finished')
    log("gif finished")
    url = URL.createObjectURL(blob)
    log("<a href='"+url+"' target='blank' >open gif in new tab</a>")
    log("<a href='"+url+"' target='blank' download='gifmachine.gif' >download gif</a>")
    log("size #{ (blob.size / 1000).toFixed 2 }kb")
    $dd('make_gif')
    cleanVtcArray()
  )
  _make_gif_now_ = true
  customPlay(true)
  

makeWebM = () ->
  if _make_webm_now_ is true then log('webm creation already in progress'); return false;
  log('init webM creation')
  $d('make_webm')
  _WEBM_ = new Whammy.Video()
  _make_webm_now_ = true
  customPlay(true)

finishWebM = () ->
  log('compile webm')
  blob = _WEBM_.compile()
  log("webm finished")
  url = URL.createObjectURL(blob)
  log("<a href='"+url+"' target='blank' >open webm in new tab</a>")
  log("<a href='"+url+"' target='blank' download='gifmachine.webm' >download webm</a>")
  log("size #{ (blob.size / 1000).toFixed 2 }kb")
  _make_webm_now_ = false
  $dd('make_webm')
  cleanVtcArray()


$$('make_gif').addEventListener('click', () ->
  makeGif()
)

$e('make_webm', 'click', ()->
  makeWebM()
)

fileSelect = (event, action_per_file, finish_callback) ->
  files = event.target.files
  r = []
  for f in files
    do (f) ->
      r = action_per_file(f)
  finish_callback(r)

$$('video_files').addEventListener('change', (evt) ->
  file = evt.target.files[0]
  log(file.name+' ('+file.type+') selected')
  if not file.type.match('video')
    log('Error: '+escape(file.name)+' is not a video!')
  else
    log(file.name+' is a video')
    reader =  new FileReader()
    reader.onload = (reader_event) -> 
      d(reader_event)
      log(reader_event)
      if reader_event.target.readyState is FileReader.DONE
        log('file successfully loaded')
        url =  window.URL.createObjectURL(new Blob([reader_event.target.result], {type: file.type}))
        log(url)
        initVideosAndCanvas(url, true)
    reader.readAsArrayBuffer(file)

)

setVideoDuration = (v) ->
  v = parseInt(v)
  if v < 0 then v = 1
  if v > 20000 then v = 20000
  if not v? then v = 10000
  _video_chunk_duration_ms_ = v
  setEndTime()
  customPlay(true)
  log(_end_time_)
  qaVideoStartAndEnd()

$_e('#video_duration', 'blur', (e)->
  setVideoDuration($$('video_duration').value)
)

$_e('#video_duration_set', 'click', (e)->
  setVideoDuration($$('video_duration').value)
)

$_e('.video_duration_plus_minus', 'click', (e)->
    d(e)
    p_m_ms = parseInt(e.target.value)
    setVideoDuration(parseInt($$('video_duration').value)+p_m_ms)
    qaVideoStartAndEnd()
    customPlay(true)
  )

$_e('#text_top', ['keydown', 'change', 'keyup'], (e)->
  _text_.topstring = $$('text_top').value.trim().toUpperCase()
)

$_e('#text_bottom', ['keydown', 'change', 'keyup'], (e)->
  _text_.bottomstring = $$('text_bottom').value.trim().toUpperCase()
)

setFontSize = (s) ->
  s = parseInt(s)
  if not s? then s = _text_.fontsize
  if s < 0 then s = _text_.fontsize
  if s > 250 then s = _text_.fontsize
  _text_.fontsize = s
  $$('fontsize').value = s

$_e('#fontsize', 'blur', (e)->
  setFontSize($$('fontsize').value)
)

$$('set_fontsize').addEventListener('click', () ->
  setFontSize($$('fontsize').value)
)




