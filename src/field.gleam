import gleam/float
import gleam/int
import gleam/order

pub type Field(x) {
  Field(
    add: fn(x, x) -> x,
    subtract: fn(x, x) -> x,
    multiply: fn(x, x) -> x,
    divide: fn(x, x) -> Result(x, Nil),
    zero: x,
    one: x,
    to_string: fn(x) -> String,
    int_power: fn(x, Int) -> Result(x, Nil),
  )
}

fn int_power(base: Int, exp: Int) -> Result(Int, Nil) {
  case int.compare(exp, 0) {
    order.Lt -> Error(Nil)
    order.Eq -> Ok(1)
    order.Gt -> {
      let assert Ok(dec) = int_power(base, exp - 1)
      Ok(base * dec)
    }
  }
}

pub fn int() -> Field(Int) {
  Field(
    add: int.add,
    subtract: int.subtract,
    multiply: int.multiply,
    divide: int.divide,
    zero: 0,
    one: 1,
    to_string: int.to_string,
    int_power: int_power,
  )
}

pub fn float() -> Field(Float) {
  Field(
    add: float.add,
    subtract: float.subtract,
    multiply: float.multiply,
    divide: float.divide,
    zero: 0.0,
    one: 1.0,
    to_string: float.to_string,
    int_power: fn(base, exp) { float.power(base, int.to_float(exp)) },
  )
}
