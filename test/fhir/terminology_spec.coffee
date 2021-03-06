term = require('../../src/fhir/terminology')
crud = require('../../src/fhir/crud')
test = require('../helpers.coffee')
plv8 = require('../../plpl/src/plv8')

assert = require('assert')
log = (x)->
  console.log(JSON.stringify(x, null, " "))

expand = (q)-> term.fhir_expand_valueset(plv8, q)


TEST_VS = {
  id: 'mytestvs'
  resourceType: 'ValueSet'
  codeSystem:
    system: 'mysystem1'
    concept: [
      {
        code: 'a1'
        display: 'A1'
        concept: [{code: 'nested', display: 'display'}]
      }
    ]
  compose:
    include: [
      {
        system: 'mysystem2'
        concept: [
         {code: 'a21', display: 'A21'}
         {code: 'a22', display: 'A22'}]
      }
      {
        system: 'mysystem2'
        concept: [
         {code: 'a31', display: 'A31'}
         {code: 'a32', display: 'A32'}]
      }
    ]
}

describe "terminology", ->

  before ->
    crud.fhir_terminate_resource(plv8, {resourceType: 'ValueSet', id: TEST_VS.id})
    crud.fhir_create_resource(plv8, {resourceType: 'ValueSet', resource: TEST_VS})

  it "expand", ->
    vs =  expand(id: "administrative-gender")
    res = vs.expansion.contains
    assert.equal(res.length, 4)

    vs =  expand(id: "administrative-gender", filter: 'fe')
    res = vs.expansion.contains
    assert.equal(res.length, 1)

  it "custom vs", ->
    vs =  expand(id: "mytestvs")
    res = vs.expansion.contains.map((x)-> x.code).sort()
    assert.deepEqual([ 'a1', 'a21', 'a22', 'a31', 'a32', 'nested' ], res)

    vs =  expand(id: "mytestvs", filter: '32')
    res = vs.expansion.contains
    assert.equal(res.length, 1)

    vs =  expand(id: "mytestvs", filter: 'nested')
    res = vs.expansion.contains
    assert.equal(res.length, 1)

    vs =  expand(id: "mytestvs", filter: 'display')
    res = vs.expansion.contains
    assert.equal(res.length, 1)

    crud.fhir_delete_resource(plv8, {resourceType: 'ValueSet', id: TEST_VS.id})

    res = expand(id: "mytestvs")
    assert.equal(res.resourceType, 'OperationOutcome')
