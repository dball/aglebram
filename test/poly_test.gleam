import gleeunit/should
import poly.{Poly}

pub fn add_test() {
  let p1 = Poly([1.0, 1.0, 1.0])
  let p2 = Poly([2.0, 3.0, 4.0])
  let p3 = Poly([5.0])

  poly.add(p1, p2)
  |> should.equal(Poly([3.0, 4.0, 5.0]))

  poly.add(p1, p3)
  |> should.equal(Poly([6.0, 1.0, 1.0]))
}

pub fn multiply_test() {
  let p = Poly([1.0, 1.0, 1.0])
  let p0 = Poly([0.0])
  let p1 = Poly([1.0])
  let p2 = Poly([2.0])
  let px = Poly([0.0, 1.0])
  let p2x = Poly([2.0, 1.0])

  poly.multiply(p, p0) |> should.equal(Poly([]))
  poly.multiply(p, p1)
  |> should.equal(Poly([1.0, 1.0, 1.0]))
  poly.multiply(p, p2)
  |> should.equal(Poly([2.0, 2.0, 2.0]))
  poly.multiply(p, px)
  |> should.equal(Poly([0.0, 1.0, 1.0, 1.0]))
  poly.multiply(p, p2x)
  |> should.equal(Poly([2.0, 3.0, 3.0, 1.0]))
}

pub fn to_string_test() {
  let p = Poly([-1.0, 0.0, 2.0, 1.0])
  poly.to_string(p, "x")
  |> should.equal("x^3 + 2.0 * x^2 + -1.0")
}

pub fn eval_test() {
  let p = Poly([2.0, 0.0, 1.0])
  poly.eval(p, 3.0) |> should.equal(11.0)
}
