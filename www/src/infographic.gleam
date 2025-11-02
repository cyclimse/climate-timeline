import gleam/int
import gleam/string
import gleam/list

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import model

pub fn from(samples: List(model.Sample)) -> Element(msg) {
  let years =
    samples
    |> list.map(fn(sample) { sample.date.year })
    |> list.unique
    |> list.sort(int.compare)

  html.div(
    [
      attribute.styles([
        #("display", "flex"),
        #("flex-direction", "column"),
        #("gap", "2rem"),
      ]),
    ],
    [
      html.h1([], [html.text("Climate Infographic")]),
      html.p([], [
        html.text("Data spanning the years: "),
        html.text(string.join(list.map(years, int.to_string), ", ")),
      ]),
      // Further infographic elements would go here
    ],
  )
}
