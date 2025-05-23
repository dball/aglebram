import field
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
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

/// Builds a new materialized graph from the given dictionary of vertices and neighbors.
/// All edges are assumed to be bidirectional; it is only necessary to declare one side.
/// All neighbors not found in the keys will be populated as vertices in the graph.
/// This will error if the vertices contains any self-references.
pub fn new_materialized(vertices: Dict(v, Set(v))) -> Result(Graph(v), Nil) {
  let vertices =
    list.fold_until(dict.to_list(vertices), Ok(vertices), fn(accum, entry) {
      let #(key, value) = entry
      case set.contains(value, key) {
        True -> list.Stop(Error(Nil))
        False -> {
          let assert Ok(accum) = accum
          list.Continue(
            Ok(
              set.fold(value, accum, fn(accum, neighbor) {
                dict.upsert(accum, neighbor, fn(them) {
                  case them {
                    None -> set.new() |> set.insert(key)
                    Some(them) -> set.insert(them, key)
                  }
                })
              }),
            ),
          )
        }
      }
    })
  case vertices {
    Ok(vertices) -> Ok(Materialized(vertices))
    Error(Nil) -> Error(Nil)
  }
}

pub fn new_functional(vertices: Set(v), edger: fn(v) -> Set(v)) -> Graph(v) {
  // TODO enforce invariants
  // TODO or maybe just an edger fn that accepts Option(v) and returns the vertices
  // on None
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
  case neighbors(graph, vertex) {
    None -> None
    Some(neighbors) -> Some(set.size(neighbors))
  }
}

/// Returns the set of vertices directly connected to the given vertex by an edge.
pub fn neighbors(graph: Graph(v), vertex: v) -> Option(Set(v)) {
  case graph {
    Materialized(vertices) -> {
      case dict.get(vertices, vertex) {
        Ok(neighbors) -> Some(neighbors)
        Error(_) -> None
      }
    }
    Functional(vertices, edger) -> {
      case set.contains(vertices, vertex) {
        True -> Some(edger(vertex))
        False -> None
      }
    }
  }
}

/// Folds the graph via a breath-first search starting at the given root node,
/// calling the accumulator fn with the accumulation and the path from the root
/// to the current node, where the current node is the head and the root is the
/// tail.
///
/// This will not emit cycles, and will visit all vertices accessible from the
/// root.
pub fn fold_bfs_from(
  graph: Graph(v),
  root: v,
  init: u,
  with: fn(u, List(v)) -> u,
) -> u {
  fold_bfs_loop(graph, init, with, set.new(), [[root]])
}

fn fold_bfs_loop(
  graph: Graph(v),
  accum: u,
  with: fn(u, List(v)) -> u,
  visited: Set(v),
  to_visit: List(List(v)),
) -> u {
  case to_visit {
    [] -> accum
    [path, ..to_visit_next] -> {
      let accum = with(accum, path)
      let assert [head, ..] = path
      let assert Some(neighbors) = neighbors(graph, head)
      let next = set.difference(neighbors, visited)
      let next_paths =
        set.to_list(next) |> list.map(fn(neighbor) { [neighbor, ..path] })
      fold_bfs_loop(
        graph,
        accum,
        with,
        set.insert(visited, head),
        list.flatten([to_visit_next, next_paths]),
      )
    }
  }
}

pub type Kind(v) {
  /// An empty graph.
  Empty
  /// A single vertex.
  Vertex(vertex: v)
  /// A path graph has a head and tail connected by a sequences of vertices.
  Path(vertices: Set(v), ends: Set(v))
  /// A cycle is a list of vertices in a loop.
  Cycle(vertices: Set(v))
  /// A tree is a graph with no cycles.
  Tree(vertices: Set(v))
  /// A component is a part of a graph disconnected from the remainder.
  Components(components: Set(Kind(v)))
  /// A general graph does not fall into any of the other categories; it has at
  /// least one cycle and does not consist entirely of a cycle, and is entirely
  /// connected.
  General(vertices: Set(v))
}

pub fn characterize(graph: Graph(v)) -> Kind(v) {
  let components = characterize_loop(graph, get_vertices(graph), [])
  case components {
    [] -> Empty
    [component] -> component
    _ -> Components(components |> set.from_list)
  }
}

fn characterize_loop(
  graph: Graph(v),
  to_visit: Set(v),
  components: List(Kind(v)),
) -> List(Kind(v)) {
  case set.to_list(to_visit) {
    [] -> components
    [vertex, ..to_visit_next] -> {
      let #(component, visited) = characterize_component(graph, vertex)
      characterize_loop(
        graph,
        set.difference(to_visit_next |> set.from_list, visited),
        [component, ..components],
      )
    }
  }
}

/// Walk the graph starting at v, returning the kind of the component and all
/// vertices visited.
fn characterize_component(graph: Graph(v), vertex: v) -> #(Kind(v), Set(v)) {
  characterize_component_loop(graph, dict.new(), False, [vertex])
}

fn characterize_component_loop(
  graph: Graph(v),
  edge_counts: Dict(v, Int),
  cycles: Bool,
  to_visit: List(v),
) {
  case to_visit {
    [] -> {
      let visited = dict.keys(edge_counts)
      let vertices = set.from_list(visited)
      case visited {
        [vertex] -> #(Vertex(vertex), vertices)
        _ -> {
          let edges_freqs = dict.values(edge_counts) |> list.sort(int.compare)
          case edges_freqs {
            [1, 1, ..rest] -> {
              case list.all(rest, fn(n) { n == 2 }) {
                True -> {
                  let ends =
                    dict.fold(edge_counts, set.new(), fn(accum, vertex, count) {
                      case count {
                        1 -> accum |> set.insert(vertex)
                        _ -> accum
                      }
                    })
                  #(Path(vertices, ends), vertices)
                }
                False -> {
                  case cycles {
                    True -> #(General(vertices), vertices)
                    False -> #(Tree(vertices), vertices)
                  }
                }
              }
            }
            [2, ..rest] -> {
              case list.all(rest, fn(n) { n == 2 }) {
                True -> #(Cycle(vertices), vertices)
                False -> todo
              }
            }
            _ -> todo
          }
        }
      }
    }
    [vertex, ..to_visit_next] -> {
      let assert Some(neighbors) = neighbors(graph, vertex)
      let visited = dict.keys(edge_counts) |> set.from_list
      let neighbors_to_visit_next = set.difference(neighbors, visited)
      let cycles = case cycles {
        True -> True
        False -> {
          case dict.is_empty(edge_counts) {
            True -> False
            False ->
              set.size(neighbors) != set.size(neighbors_to_visit_next) + 1
          }
        }
      }
      let edge_counts = dict.insert(edge_counts, vertex, set.size(neighbors))
      let to_visit =
        list.flatten([to_visit_next, neighbors_to_visit_next |> set.to_list])
      characterize_component_loop(graph, edge_counts, cycles, to_visit)
    }
  }
}

pub fn chromatic_polynomial(graph: Graph(v)) -> Poly(Int) {
  chromatic_polynomial_kind(characterize(graph))
}

fn chromatic_polynomial_kind(kind: Kind(v)) -> Poly(Int) {
  let p = poly.new(field.int(), _)
  case kind {
    Vertex(_) -> p([0, 1])
    Path(vertices, _) -> {
      let n = set.size(vertices)
      let terms = [[0, 1], ..list.repeat([-1, 1], n - 1)]
      terms |> list.map(p) |> list.reduce(poly.multiply) |> result.unwrap(p([]))
    }
    Tree(vertices) -> {
      let n = set.size(vertices)
      let terms = [[0, 1], ..list.repeat([-1, 1], n - 1)]
      terms |> list.map(p) |> list.reduce(poly.multiply) |> result.unwrap(p([]))
    }
    Cycle(vertices) -> {
      let n = set.size(vertices)
      let most =
        list.repeat(p([-1, 1]), n)
        |> list.reduce(poly.multiply)
        |> result.unwrap(p([]))
      let last =
        [p([-1, 1]), ..list.repeat(p([-1]), n)]
        |> list.reduce(poly.multiply)
        |> result.unwrap(p([]))
      poly.add(most, last)
    }
    Components(components) ->
      components
      |> set.to_list
      |> list.map(chromatic_polynomial_kind)
      |> list.reduce(poly.multiply)
      |> result.unwrap(p([]))
    _ -> todo
  }
}
