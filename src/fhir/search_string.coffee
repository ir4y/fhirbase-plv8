lang = require('../lang')
sql = require('../honey')
xpath = require('./xpath')
search_common = require('./search_common')

UNACCENT_MAP =
  'é': 'e'
  'á': 'a'
  'ű': 'u'
  'ő': 'o'
  'ú': 'u'
  'ö': 'o'
  'ü': 'u'
  'ó': 'o'
  'í': 'i'
  'É': 'E'
  'Á': 'A'
  'Ű': 'U'
  'Ő': 'O'
  'Ú': 'U'
  'Ö': 'O'
  'Ü': 'U'
  'Ó': 'O'
  'Í': 'I'
  'ò': 'o'

UNACCENT_RE = new RegExp("[" + (k for k,_ of UNACCENT_MAP).join('') + "]" , 'g');
unaccent_fn = (match) -> UNACCENT_MAP[match]

unaccent = (s) -> s.toString().replace(UNACCENT_RE, unaccent_fn)
exports.unaccent = unaccent

TODO = -> throw new Error("TODO")

EMPTY_VALUE = "$NULL"

exports.fhir_extract_as_string = (plv8, resource, path, element_type)->
  obj = xpath.get_in(resource, [path])
  vals = lang.values(obj).filter((x)-> x && x.toString().trim())
  if vals.length == 0
    EMPTY_VALUE
  else
    ("^^#{unaccent(v)}$$" for v in vals).join(" ")

exports.fhir_extract_as_string.plv8_signature =
  arguments: ['json', 'json', 'text']
  returns: 'text'
  immutable: true

exports.fhir_sort_as_string = (plv8, resource, path, element_type)->
  obj = xpath.get_in(resource, [path])[0]
  return null unless obj
  res = switch element_type
    when 'string'
      obj.toString().toLowerCase()
    when 'HumanName'
      lang.values(obj).filter((x)-> x && x.toString().trim().toLowerCase()).join('0')
      [[].concat(obj.family || []).join('0'),[].concat(obj.given || []).join('0'),[].concat(obj.middle || []).join('0'), obj.text].join('0')
    when 'Coding'
      [obj.system, obj.code, obj.display].join('0')
    when 'Address'
      [obj.country, obj.city, obj.state, obj.district, [].concat(obj.line || []).join('0'), obj.postalCode, obj.text].join('0')
    when 'ContactPoint'
      [obj.system, obj.value].join('0')
    when 'CodeableConcept'
      coding = obj.coding && obj.coding[0]
      if coding
        [coding.system, coding.code, coding.display, obj.text].join('0')
      else
        obj.text
    else
      lang.values(obj).filter((x)-> x && x.toString().trim()).join('0')

  res && res.toLowerCase()

exports.fhir_sort_as_string.plv8_signature =
  arguments: ['json', 'json', 'text']
  returns: 'text'
  immutable: true

normalize_string_value = (x)->
  x && x.trim().toLowerCase()

SUPPORTED_TYPES = [
  'Address'
  'ContactPoint'
  'HumanName'
  'string'
]

sf = search_common.get_search_functions({extract:'fhir_extract_as_string', sort:'fhir_sort_as_string',SUPPORTED_TYPES:SUPPORTED_TYPES})
extract_expr = sf.extract_expr

exports.order_expression = sf.order_expression
exports.index_order = sf.index_order

OPERATORS =
  eq: (tbl, meta, value)->
    ["$ilike", extract_expr(meta, tbl), "%^^#{normalize_string_value(value.value)}$$%"]
  sw: (tbl, meta, value)->
    ["$ilike", extract_expr(meta, tbl), "%^^#{normalize_string_value(value.value)}%"]
  ew: (tbl, meta, value)->
    ["$ilike", extract_expr(meta, tbl), "%#{normalize_string_value(value.value)}$$%"]
  co: (tbl, meta, value)->
    ["$ilike", extract_expr(meta, tbl), "%#{normalize_string_value(value.value)}%"]
  missing: (tbl, meta, value)->
    if value.value == 'false'
      ["$ne", extract_expr(meta, tbl), EMPTY_VALUE]
    else
      ["$ilike", extract_expr(meta, tbl), EMPTY_VALUE]




OPERATORS_ALIASES =
  exact: 'eq'
  contains: 'co'
  sw: 'sw'
  ew: 'ew'
  startwith: 'sw'
  endwith: 'ew'
  missing: 'missing'

exports.normalize_operator = (meta, value)->
  return 'sw' if not meta.modifier and not value.prefix
  op = OPERATORS_ALIASES[meta.modifier]
  return op if op
  throw new Error("Not supported operator #{JSON.stringify(meta)} #{JSON.stringify(value)}")

handle = (tbl, meta, value)->
  unless SUPPORTED_TYPES.indexOf(meta.elementType) > -1
    throw new Error("String Search: unsupported type #{JSON.stringify(meta)}")

  op = OPERATORS[meta.operator]

  unless op
    throw new Error("String Search: Unsupported operator #{JSON.stringify(meta)}")

  op(tbl, meta, value)

exports.handle = handle

exports.index = (plv8, metas)->
  meta = metas[0]
  idx_name = "#{meta.resourceType.toLowerCase()}_#{meta.name.replace('-','_')}_string"

  exprs = metas.map((x)-> extract_expr(x))

  [
    name: idx_name
    ddl:
      create: 'index'
      name:  idx_name
      using: ':GIN'
      on: meta.resourceType.toLowerCase()
      opclass: ':gin_trgm_ops'
      expression: exprs
  ]
