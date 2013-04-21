window.Utils = {}
Utils.current_time = (t) ->
  t = new Date() if not t
  if not t.getHours
    t2 = new Date()
    t2.setTime(t)
    t = t2
  return Utils.pad(t.getHours(), 2, 0) + ':' + Utils.pad(t.getMinutes(), 2, 0)

Utils.normalize_time = (t) ->
  return Utils.current_time() if not t
  return Utils.current_time(parseInt(t) * 1000) if t.toString().match(/^\d+$/)

Utils.pad = (x, n, y) ->
  zeros = Utils.repeat(y, n)
  return String(zeros + x).slice(-1 * n)

Utils.repeat = (str, i) ->
  return "" if isNaN(i) or i <= 0
  return str + Utils.repeat(str, i-1)
