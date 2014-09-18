# all the available types of gerber layers
module.exports = [
  {
    val: 'tcu'
    desc: 'top copper'
    match: /\.(gtl)|(cmp)$/i
    mult: false
  }
  {
    val: 'tsm'
    desc: 'top soldermask'
    match: /\.(gts)|(stc)$/i
    mult: false
  }
  {
    val: 'tss'
    desc: 'top silkscreen'
    match: /\.(gto)|(plc)$/i
    mult: false
  }
  {
    val: 'tsp',
    desc: 'top solderpaste'
    match: /\.(gtp)|(crc)$/i
    mult: false   
  }
  {
    val: 'bcu'
    desc: 'bottom copper'
    match: /\.(gbl)|(sol)$/i
    mult: false
  }
  {
    val: 'bsm'
    desc: 'bottom soldermask'
    match: /\.(gbs)|(sts)$/i
    mult: false
  }
  {
    val: 'bss',
    desc: 'bottom silkscreen'
    match: /\.(gbo)|(pls)$/i
    mult: false
  }
  {
    val: 'bsp'
    desc: 'bottom solderpaste'
    match: /\.(gbp)|(crs)$/i
    mult: false
  }
  {
    val: 'icu'
    desc: 'inner copper'
    match: /\.(gp\d+)|(g\d+l)$/i
    mult: false
  }
  {
    val: 'out'
    desc: 'board outline'
    match: /(\.(gko)|(mil)$)|edge/i
    mult: false
  }
  {
    val: 'drw'
    desc: 'gerber drawing'
    match: /\.gbr$/i
    mult: true
  }
  {
    val: 'drl'
    desc: 'drill hits'
    match: /(\.xln$)|(\.drl$)|(\.txt$)|(\.drd$)/i
    mult: true
  }
]
