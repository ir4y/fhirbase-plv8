search = require('../../src/fhir/search_string')
test = require('../helpers.coffee')

assert = require('assert')

resource =
  resourceType: 'Patient'
  name: [
    {
      given: ['Niccolò', 'Great']
      family: ['Paganini']
      middle: ['Music']
    }
    {
      given: ['Niky']
      family: ['Pogy']
    }
  ]
  address: [
    {
      use: 'home'
      type: 'both'
      line: ["534 Erewhon St"]
      city: 'PleasantVille'
      district: 'Rainbow'
      state: 'Vic'
      postalCode: '3999'
    }
    {
      use: 'work'
      type: 'both'
      line: ["432 Hill Bvd"]
      city: 'Xtown'
      state: 'CA'
      postalCode: '9993'
    }
  ]

specs = [
  {
    path: ['Patient', 'name']
    elementType: 'HumanName'
    result: ['^^Niccolo$$', '^^Great$$', '^^Music$$', '^^Paganini$$', '^^Niky$$', '^^Pogy$$']
    order: 'paganini0niccolò0great0music0'
  }
  {
    path: ['Patient', 'address', 'city']
    elementType: 'string'
    result: ['^^PleasantVille$$','^^Xtown$$']
    order: 'pleasantville'
  }
  {
    path: ['Patient', 'address']
    elementType: 'Address'
    result: ['^^Vic$$', '^^PleasantVille$$', '^^Rainbow$$', '^^534 Erewhon St$$']
    order: '0pleasantville0vic0rainbow0534 erewhon st039990'
  }
]

describe "extract_as_string", ->
  specs.forEach (spec)->
    it JSON.stringify(spec.path), ->
      res = search.fhir_extract_as_string({}, resource, spec.path, spec.elementType)
      for str in spec.result
        assert(res.indexOf(str) > -1, "#{str} not in #{res}")
      order = search.fhir_sort_as_string({}, resource, spec.path, spec.elementType)
      assert.deepEqual(order, spec.order)
