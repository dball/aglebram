import field
import gleeunit/should
import point.{Point}
import poly

pub fn add_test() {
  let new = poly.new(field.float(), _)
  let p1 = new([1.0, 1.0, 1.0])
  let p2 = new([2.0, 3.0, 4.0])
  let p3 = new([5.0])

  poly.add(p1, p2)
  |> should.equal(new([3.0, 4.0, 5.0]))

  poly.add(p1, p3)
  |> should.equal(new([6.0, 1.0, 1.0]))
}

pub fn multiply_test() {
  let new = poly.new(field.float(), _)
  let p = new([1.0, 1.0, 1.0])
  let p0 = new([0.0])
  let p1 = new([1.0])
  let p2 = new([2.0])
  let px = new([0.0, 1.0])
  let p2x = new([2.0, 1.0])

  poly.multiply(p, p0) |> should.equal(new([]))
  poly.multiply(p, p1)
  |> should.equal(new([1.0, 1.0, 1.0]))
  poly.multiply(p, p2)
  |> should.equal(new([2.0, 2.0, 2.0]))
  poly.multiply(p, px)
  |> should.equal(new([0.0, 1.0, 1.0, 1.0]))
  poly.multiply(p, p2x)
  |> should.equal(new([2.0, 3.0, 3.0, 1.0]))
}

pub fn to_string_test() {
  let new = poly.new(field.float(), _)
  let p = new([-1.0, 0.0, 2.0, 1.0])
  poly.to_string(p, "x")
  |> should.equal("x^3 + 2.0 * x^2 + -1.0")
}

pub fn eval_test() {
  let new = poly.new(field.float(), _)
  let p = new([2.0, 0.0, 1.0])
  poly.eval(p, 3.0) |> should.equal(11.0)
}

pub fn interpolate_test() {
  let points = [Point(1.0, 1.0), Point(2.0, 4.0), Point(7.0, 9.0)]
  let assert Ok(p) = poly.interpolate(points)
  poly.eval(p, 1.0) |> should.equal(1.0)
  // TODO equals with epsilon
  //poly.eval(p, 2.0) |> should.equal(4.0)
  //poly.eval(p, 7.0) |> should.equal(9.0)
}
