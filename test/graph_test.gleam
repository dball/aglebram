import gleam/dict
import gleam/list
import gleam/set
import gleeunit/should
import graph

pub fn bfs_fold_test() {
  let g =
    graph.new_materialized(
      dict.from_list([
        #("a", set.from_list(["b", "c"])),
        #("b", set.from_list(["a", "d", "e"])),
        #("c", set.from_list(["a", "f", "g"])),
        #("d", set.from_list(["b"])),
        #("e", set.from_list(["b"])),
        #("f", set.from_list(["d"])),
        #("g", set.from_list(["d"])),
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
    ["g", "d"],
    ["g", "d", "b"],
    ["g", "d", "b", "a"],
    ["g", "d", "b", "e"],
    ["g", "d", "b", "a", "c"],
    ["g", "d", "b", "a", "c", "f"],
  ])
}
