import gleam/int
import gleam/string

import lustre/attribute
import lustre/element.{type Element}

/// Build an SVG path for a rounded rectangle at position (x, y) with given width and height
pub fn rounded_rect_path(
  x: Int,
  y: Int,
  width: Int,
  height: Int,
  radius: Int,
) -> String {
  let x_str = int.to_string(x)
  let y_str = int.to_string(y)
  let x_r_str = int.to_string(x + radius)
  let y_r_str = int.to_string(y + radius)
  let x_w_str = int.to_string(x + width)
  let y_h_str = int.to_string(y + height)
  let x_w_r_str = int.to_string(x + width - radius)
  let y_h_r_str = int.to_string(y + height - radius)

  "M"
  <> x_r_str
  <> ","
  <> y_str
  <> " L"
  <> x_w_r_str
  <> ","
  <> y_str
  <> " Q"
  <> x_w_str
  <> ","
  <> y_str
  <> " "
  <> x_w_str
  <> ","
  <> y_r_str
  <> " L"
  <> x_w_str
  <> ","
  <> y_h_r_str
  <> " Q"
  <> x_w_str
  <> ","
  <> y_h_str
  <> " "
  <> x_w_r_str
  <> ","
  <> y_h_str
  <> " L"
  <> x_r_str
  <> ","
  <> y_h_str
  <> " Q"
  <> x_str
  <> ","
  <> y_h_str
  <> " "
  <> x_str
  <> ","
  <> y_h_r_str
  <> " L"
  <> x_str
  <> ","
  <> y_r_str
  <> " Q"
  <> x_str
  <> ","
  <> y_str
  <> " "
  <> x_r_str
  <> ","
  <> y_str
  <> " Z"
}

/// Create an SVG path element with a fill color
pub fn path_filled(path_data: String, fill: String) -> Element(msg) {
  element.namespaced(
    "http://www.w3.org/2000/svg",
    "path",
    [
      attribute.attribute("d", path_data),
      attribute.attribute("fill", fill),
      attribute.styles([#("cursor", "pointer")]),
    ],
    [],
  )
}

/// Create an SVG path element with a stroke (outline) only
pub fn path_stroked(
  path_data: String,
  stroke: String,
  stroke_width: Int,
) -> Element(msg) {
  element.namespaced(
    "http://www.w3.org/2000/svg",
    "path",
    [
      attribute.attribute("d", path_data),
      attribute.attribute("fill", "none"),
      attribute.attribute("stroke", stroke),
      attribute.attribute("stroke-width", int.to_string(stroke_width)),
      attribute.attribute("class", "event-highlight"),
      attribute.styles([#("pointer-events", "none")]),
    ],
    [],
  )
}

/// Join multiple path data strings into a single compound path
pub fn join_paths(paths: List(String)) -> String {
  paths |> string.join(" ")
}
