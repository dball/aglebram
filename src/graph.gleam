import gleam/dict.{type Dict}
import gleam/set.{type Set}
import poly.{type Poly}

/// Graphs are finite, undirected, unweighted graphs of generic vertices.
pub type Graph(v) {
  /// Materialized graphs store vertices and edges in a dictionary.
  ///
  /// There is an implicit invariant that every vertex in united set
  /// of values has an entry for which it is the key.
  Materialized(vertices: Dict(v, Set(v)))
  /// Functional graphs store vertices in a set and use an edger
  /// function to compute the edges of a given vertex.
  ///
  /// There is an implicit invariant the every vertex in the united
  /// set of return values from the edger function on the vertices
  /// is a member of the set of vertices.
  Functional(vertices: Set(v), edger: fn(v) -> Set(v))
}

pub fn build_materialized_graph(vertices: Dict(v, Set(v))) -> Graph(v) {
  Materialized(vertices)
}

pub fn build_functional_graph(
  vertices: Set(v),
  edger: fn(v) -> Set(v),
) -> Graph(v) {
  Functional(vertices, edger)
}

pub fn materialize(graph: Graph(v)) -> Graph(v) {
  case graph {
    Materialized(_) -> graph
    Functional(vertices, edger) ->
      Materialized(
        set.fold(vertices, dict.new(), fn(accum, vertex) {
          dict.insert(accum, vertex, edger(vertex))
        }),
      )
  }
}

pub fn chromatic_polynomial(graph: Graph(v)) -> Poly(Int) {
  todo
}
