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
