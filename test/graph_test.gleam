import gleam/dict
import gleam/list
import gleam/set
import gleeunit/should
import graph

pub fn bfs_fold_test() {
  let assert Ok(g) =
    graph.new_materialized(
      dict.from_list([
        #("a", set.from_list(["b", "c"])),
        #("b", set.from_list(["d", "e"])),
        #("c", set.from_list(["f", "g"])),
      ]),
    )
  graph.fold_bfs_from(g, "a", [], fn(accum, path) {
    [list.reverse(path), ..accum]
  })
  |> list.reverse
  |> should.equal([
    ["a"],
    ["a", "b"],
    ["a", "c"],
    ["a", "b", "d"],
    ["a", "b", "e"],
    ["a", "c", "f"],
    ["a", "c", "g"],
  ])

  graph.fold_bfs_from(g, "g", [], fn(accum, path) {
    [list.reverse(path), ..accum]
  })
  |> list.reverse
  |> should.equal([
    ["g"],
    ["g", "c"],
    ["g", "c", "a"],
    ["g", "c", "f"],
    ["g", "c", "a", "b"],
    ["g", "c", "a", "b", "d"],
    ["g", "c", "a", "b", "e"],
  ])
}

pub fn characterize_test() {
  let t = fn(vs: List(#(String, List(String))), kind: graph.Kind(String)) {
    let vs = list.map(vs, fn(v) { #(v.0, set.from_list(v.1)) })
    let assert Ok(g) = graph.new_materialized(dict.from_list(vs))
    graph.characterize(g) |> should.equal(kind)
  }
  t([], graph.Empty)
  t([#("a", [])], graph.Vertex("a"))
  t(
    [#("a", []), #("b", [])],
    graph.Components(components: {
      [graph.Vertex("a"), graph.Vertex("b")] |> set.from_list
    }),
  )
  t(
    [#("a", ["b"]), #("b", ["c"])],
    graph.Path(["a", "b", "c"] |> set.from_list, ["a", "c"] |> set.from_list),
  )
  t(
    [#("a", ["b"]), #("b", ["c"]), #("c", ["a"])],
    graph.Cycle(["a", "b", "c"] |> set.from_list),
  )
  t(
    [#("a", ["b", "c"]), #("b", ["d", "e"]), #("c", ["f", "g"])],
    graph.Tree(vertices: ["a", "b", "c", "d", "e", "f", "g"] |> set.from_list),
  )
  t(
    [#("a", ["b", "c"]), #("b", ["d", "e"]), #("c", ["f", "g"]), #("g", ["a"])],
    graph.General(
      vertices: ["a", "b", "c", "d", "e", "f", "g"] |> set.from_list,
    ),
  )
  t(
    [
      #("a", ["b", "c"]),
      #("b", ["d", "e"]),
      #("c", ["f", "g"]),
      #("x", ["y"]),
      #("y", ["z"]),
      #("z", ["x"]),
      #("h", []),
    ],
    graph.Components(components: {
      [
        graph.Tree(
          vertices: ["a", "b", "c", "d", "e", "f", "g"] |> set.from_list,
        ),
        graph.Cycle(vertices: ["x", "y", "z"] |> set.from_list),
        graph.Vertex("h"),
      ]
      |> set.from_list
    }),
  )
}
