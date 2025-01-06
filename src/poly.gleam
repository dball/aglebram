import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/string

pub type Poly {
  /// Poly coefficients are ordered by increasing exponent starting with 0
  Poly(coefficients: List(Float))
}

fn zerofy(p: Poly, length: Int) -> Poly {
  case length {
    0 -> p
    _ ->
      Poly(coefficients: list.append(p.coefficients, list.repeat(0.0, length)))
  }
}

fn simplify(p: Poly) -> Poly {
  p.coefficients
  |> list.reverse
  |> list.drop_while(fn(c) { c == 0.0 })
  |> list.reverse
  |> Poly
}

fn normalize(p1: Poly, p2: Poly) -> #(Poly, Poly) {
  let l1 = list.length(p1.coefficients)
  let l2 = list.length(p2.coefficients)
  case int.compare(l1, l2) {
    order.Eq -> #(p1, p2)
    order.Lt -> #(zerofy(p1, l2), p2)
    order.Gt -> #(p1, zerofy(p2, l1))
  }
}

pub fn add(p1: Poly, p2: Poly) -> Poly {
  let #(p1, p2) = normalize(p1, p2)
  Poly(list.map2(p1.coefficients, p2.coefficients, float.add))
}

pub fn multiply(p1: Poly, p2: Poly) -> Poly {
  list.index_fold(p2.coefficients, Poly([]), fn(accum, scalar, degree) {
    let p = p1.coefficients |> list.map(float.multiply(_, scalar))
    let prefix = list.repeat(0.0, degree)
    add(accum, Poly(list.append(prefix, p)))
  })
  |> simplify
}

fn exp_to_string(exp: Int, x: String) -> Option(String) {
  case exp {
    0 -> None
    1 -> Some(x)
    _ -> Some(x <> "^" <> int.to_string(exp))
  }
}

fn term_to_string(c: Float, exp: Int, x: String) -> Option(String) {
  case c {
    0.0 -> None
    _ ->
      Some(case exp_to_string(exp, x) {
        None -> float.to_string(c)
        Some(exp_string) ->
          case c {
            1.0 -> exp_string
            _ -> float.to_string(c) <> " * " <> exp_string
          }
      })
  }
}

pub fn to_string(p: Poly, x: String) -> String {
  let degree = list.length(p.coefficients)
  case degree {
    0 -> float.to_string(0.0)
    _ ->
      p.coefficients
      |> list.index_fold([], fn(accum, c, i) {
        case term_to_string(c, i, x) {
          None -> accum
          Some(term_string) -> [term_string, ..accum]
        }
      })
      |> string.join(" + ")
  }
}

pub fn eval(p: Poly, x: Float) -> Float {
  list.index_fold(p.coefficients, 0.0, fn(accum, c, i) {
    case float.power(x, int.to_float(i)) {
      Ok(value) -> accum +. { c *. value }
      Error(_) -> accum
    }
  })
}
