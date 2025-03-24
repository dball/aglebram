import field.{type Field}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/string
import point.{type Point, Point}

pub type Poly(x) {
  /// Poly coefficients are ordered by increasing exponent starting with 0
  Poly(field: Field(x), coefficients: List(x))
}

pub fn new(field: Field(x), coefficients: List(x)) {
  Poly(field, coefficients)
}

/// Appends the specified number of zero coefficients to the polynomial,
/// e.g. to make it easier to compute binary operations.
fn zerofy(p: Poly(x), length: Int) -> Poly(x) {
  case length {
    0 -> p
    _ ->
      Poly(
        ..p,
        coefficients: list.append(
          p.coefficients,
          list.repeat(p.field.zero, length),
        ),
      )
  }
}

/// Removes all trailing zero coefficients from the polynomial.
fn simplify(p: Poly(x)) -> Poly(x) {
  let coefficients =
    p.coefficients
    |> list.reverse
    |> list.drop_while(fn(c) { c == p.field.zero })
    |> list.reverse
  Poly(..p, coefficients: coefficients)
}

/// Returns versions of both polynomials that are the same length.
fn normalize(p1: Poly(x), p2: Poly(x)) -> #(Poly(x), Poly(x)) {
  let l1 = list.length(p1.coefficients)
  let l2 = list.length(p2.coefficients)
  case int.compare(l1, l2) {
    order.Eq -> #(p1, p2)
    order.Lt -> #(zerofy(p1, l2), p2)
    order.Gt -> #(p1, zerofy(p2, l1))
  }
}

/// Returns the sum of both polynomials.
pub fn add(p1: Poly(x), p2: Poly(x)) -> Poly(x) {
  let #(p1, p2) = normalize(p1, p2)
  Poly(
    ..p1,
    coefficients: list.map2(p1.coefficients, p2.coefficients, p1.field.add),
  )
  |> simplify
}

/// Returns the product of both polynomials.
pub fn multiply(p1: Poly(x), p2: Poly(x)) -> Poly(x) {
  list.index_fold(
    p2.coefficients,
    Poly(..p1, coefficients: []),
    fn(accum, scalar, degree) {
      let p = p1.coefficients |> list.map(p1.field.multiply(_, scalar))
      let prefix = list.repeat(p1.field.zero, degree)
      add(accum, Poly(..p1, coefficients: list.append(prefix, p)))
    },
  )
  |> simplify
}

fn exp_to_string(exp: Int, v: String) -> Option(String) {
  case exp {
    0 -> None
    1 -> Some(v)
    _ -> Some(v <> "^" <> int.to_string(exp))
  }
}

fn term_to_string(c: x, field: Field(x), exp: Int, v: String) -> Option(String) {
  case c == field.zero {
    True -> None
    False ->
      Some(case exp_to_string(exp, v) {
        None -> field.to_string(c)
        Some(exp_string) -> {
          case c == field.one {
            True -> exp_string
            _ -> field.to_string(c) <> " * " <> exp_string
          }
        }
      })
  }
}

/// Returns the polynomial as a human-readable string, using the
/// given x value as the variable identifier.
pub fn to_string(p: Poly(x), v: String) -> String {
  let degree = list.length(p.coefficients)
  case degree {
    0 -> p.field.to_string(p.field.zero)
    _ ->
      p.coefficients
      |> list.index_fold([], fn(accum, c, i) {
        case term_to_string(c, p.field, i, v) {
          None -> accum
          Some(term_string) -> [term_string, ..accum]
        }
      })
      |> string.join(" + ")
  }
}

/// Evaluates the polynomial with the given x value as the variable.
pub fn eval(p: Poly(x), v: x) -> x {
  list.index_fold(p.coefficients, p.field.zero, fn(accum, c, i) {
    case p.field.int_power(v, i) {
      Ok(value) -> p.field.add(accum, p.field.multiply(c, value))
      Error(_) -> accum
    }
  })
}

pub type InterpolationError {
  InsufficientPoints
  NonFunctionalPoints
}

fn single_term(points: List(Point), point: Point) -> Poly(Float) {
  list.fold(points, Poly(field.float(), [1.0]), fn(accum, p) {
    case p == point {
      True -> accum
      False ->
        multiply(
          accum,
          Poly(..accum, coefficients: [
            { 0.0 -. p.x } /. { point.x -. p.x },
            1.0 /. { point.x -. p.x },
          ]),
        )
    }
  })
  |> multiply(Poly(field.float(), [point.y]))
}

pub fn interpolate(
  points: List(Point),
) -> Result(Poly(Float), InterpolationError) {
  let np = list.length(points)
  let xs = list.map(points, fn(point) { point.x }) |> list.unique |> list.length
  case xs {
    0 -> Error(InsufficientPoints)
    n if n < np -> Error(NonFunctionalPoints)
    _ -> {
      Ok(
        list.fold(points, Poly(field.float(), []), fn(accum, point) {
          add(accum, single_term(points, point))
        }),
      )
    }
  }
}
