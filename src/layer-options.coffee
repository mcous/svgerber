# all the available types of gerber layers
module.exports = [
  { val: 'tcu', desc: 'top copper',         match: /\.(gtl)|(cmp)$/i        }
  { val: 'tsm', desc: 'top soldermask',     match: /\.(gts)|(stc)$/i        }
  { val: 'tss', desc: 'top silkscreen',     match: /\.(gto)|(plc)$/i        }
  { val: 'tsp', desc: 'top solderpaste',    match: /\.(gtp)|(crc)$/i        }
  { val: 'bcu', desc: 'bottom copper',      match: /\.(gbl)|(sol)$/i        }
  { val: 'bsm', desc: 'bottom soldermask',  match: /\.(gbs)|(sts)$/i        }
  { val: 'bss', desc: 'bottom silkscreen',  match: /\.(gbo)|(pls)$/i        }
  { val: 'bsp', desc: 'bottom solderpaste', match: /\.(gbp)|(crs)$/i        }
  { val: 'icu', desc: 'inner copper',       match: /\.(gp\d+)|(g\d+l)$/i    }
  { val: 'out', desc: 'board outline',      match: /(\.(gko)|(mil)$)|edge/i }
  { val: 'drw', desc: 'gerber drawing',     match: /\.gbr$/i                }
  {
    val: 'drl'
    desc: 'drill hits'
    match: /(\.xln$)|(\.drl$)|(\.txt$)|(\.drd$)/i
  }
]
