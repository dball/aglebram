import gleam/dict.{type Dict}
import gleam/option.{type Option, None, Some}
import gleam/set.{type Set}
import poly.{type Poly}

/// Graphs are simple, finite, undirected, unweighted graphs of generic
/// vertices.
pub type Graph(v) {
  /// Materialized graphs store vertices and edges in a dictionary.
  ///
  /// There is an implicit invariant that every vertex in united set
  /// of values has an entry for which it is the key, and that no vertex
  /// is its own neighbor.
  Materialized(vertices: Dict(v, Set(v)))
  /// Functional graphs store vertices in a set and use an edger
  /// function to compute the edges of a given vertex.
  ///
  /// There is an implicit invariant the every vertex in the united
  /// set of return values from the edger function on the vertices
  /// is a member of the set of vertices, and that no vertex is its
  /// own neighbor.
  Functional(vertices: Set(v), edger: fn(v) -> Set(v))
}

pub fn new_materialized(vertices: Dict(v, Set(v))) -> Graph(v) {
  // TODO enforce invariants
  Materialized(vertices)
}

pub fn new_functional(vertices: Set(v), edger: fn(v) -> Set(v)) -> Graph(v) {
  // TODO enforce invariants
  Functional(vertices, edger)
}

/// Converts the given graph into a materialized form.
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

/// Returns the set of vertexes of the graph.
pub fn get_vertices(graph: Graph(v)) -> Set(v) {
  case graph {
    Materialized(vertices) -> dict.keys(vertices) |> set.from_list
    Functional(vertices, _) -> vertices
  }
}

/// Returns true if the given graph has no edges.
pub fn is_null(graph: Graph(v)) -> Bool {
  let vertices = get_vertices(graph)
  set.fold(vertices, True, fn(null, vertex) {
    case null {
      False -> False
      True -> degree(graph, vertex) == Some(0)
    }
  })
}

/// Returns true if the given graph has an edge between every pair of distinct vertices.
pub fn is_complete(graph: Graph(v)) -> Bool {
  let vertices = get_vertices(graph)
  let n = set.size(vertices)
  set.fold(vertices, True, fn(complete, vertex) {
    case complete {
      False -> False
      True -> degree(graph, vertex) == Some(n - 1)
    }
  })
}

/// Returns the number of vertices directly connected to the given vertex by an edge.
pub fn degree(graph: Graph(v), vertex: v) -> Option(Int) {
  case graph {
    Materialized(vertices) -> {
      case dict.get(vertices, vertex) {
        Ok(neighbors) -> Some(set.size(neighbors))
        Error(_) -> None
      }
    }
    Functional(vertices, edger) -> {
      case set.contains(vertices, vertex) {
        True -> Some(edger(vertex) |> set.size)
        False -> None
      }
    }
  }
}

pub fn chromatic_polynomial(graph: Graph(v)) -> Poly(Int) {
  todo
}
