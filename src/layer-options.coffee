# all the available types of gerber layers
module.exports = [
  {
    val: 'tcu'
    desc: 'top copper'
    match: /\.(gtl)|(cmp)$/i
    side: 'top'
    mult: false
  }
  {
    val: 'tsm'
    desc: 'top soldermask'
    match: /\.(gts)|(stc)$/i
    side: 'top'
    mult: false
  }
  {
    val: 'tss'
    desc: 'top silkscreen'
    match: /\.(gto)|(plc)$/i
    side: 'top'
    mult: false
  }
  {
    val: 'tsp',
    desc: 'top solderpaste'
    match: /\.(gtp)|(crc)$/i
    side: 'top'
    mult: false
  }
  {
    val: 'bcu'
    desc: 'bottom copper'
    match: /\.(gbl)|(sol)$/i
    side: 'bottom'
    mult: false
  }
  {
    val: 'bsm'
    desc: 'bottom soldermask'
    match: /\.(gbs)|(sts)$/i
    side: 'bottom'
    mult: false
  }
  {
    val: 'bss',
    desc: 'bottom silkscreen'
    match: /\.(gbo)|(pls)$/i
    side: 'bottom'
    mult: false
  }
  {
    val: 'bsp'
    desc: 'bottom solderpaste'
    match: /\.(gbp)|(crs)$/i
    side: 'bottom'
    mult: false
  }
  {
    val: 'icu'
    desc: 'inner copper'
    match: /\.(gp\d+)|(g\d+l)$/i
    side: 'none'
    mult: false
  }
  {
    val: 'out'
    desc: 'board outline'
    match: /(\.(gko)|(mil)$)|edge/i
    side: 'both'
    mult: false
  }
  {
    val: 'drw'
    desc: 'gerber drawing'
    match: /\.gbr$/i
    side: 'none'
    mult: true
  }
  {
    val: 'drl'
    desc: 'drill hits'
    match: /(\.xln$)|(\.drl$)|(\.txt$)|(\.drd$)/i
    side: 'both'
    mult: true
  }
]
