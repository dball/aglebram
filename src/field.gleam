import gleam/float
import gleam/int

pub type Field(x) {
  Field(
    add: fn(x, x) -> x,
    subtract: fn(x, x) -> x,
    multiply: fn(x, x) -> x,
    divide: fn(x, x) -> Result(x, Nil),
    zero: x,
    one: x,
    to_string: fn(x) -> String,
  )
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
  )
}
