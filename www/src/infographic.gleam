import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/string

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
      html.div(
        [
          attribute.styles([
            #("margin-top", "2rem"),
          ]),
        ],
        [
          html.h2([], [html.text("Temperature Heatmap")]),
          html.p(
            [
              attribute.styles([
                #("font-size", "0.9rem"),
                #("color", "#666"),
                #("margin-bottom", "1rem"),
              ]),
            ],
            [
              html.text(
                "Color intensity shows deviation from historical average.",
              ),
            ],
          ),
          render_temperature_legend(),
          render_heatmap(samples),
        ],
      ),
    ],
  )
}

fn render_temperature_legend() -> Element(msg) {
  let legend_width = 400
  let legend_height = 20

  html.div(
    [
      attribute.styles([
        #("margin", "1.5rem 0"),
        #("display", "flex"),
        #("flex-direction", "column"),
        #("align-items", "center"),
        #("gap", "0.5rem"),
      ]),
    ],
    [
      // SVG gradient bar
      element.namespaced(
        "http://www.w3.org/2000/svg",
        "svg",
        [
          attribute.attribute("width", int.to_string(legend_width)),
          attribute.attribute("height", int.to_string(legend_height)),
          attribute.styles([
            #("border-radius", "4px"),
            #("border", "1px solid #ddd"),
          ]),
        ],
        [
          // Define the gradient
          element.namespaced("http://www.w3.org/2000/svg", "defs", [], [
            element.namespaced(
              "http://www.w3.org/2000/svg",
              "linearGradient",
              [
                attribute.attribute("id", "temp-gradient"),
                attribute.attribute("x1", "0%"),
                attribute.attribute("y1", "0%"),
                attribute.attribute("x2", "100%"),
                attribute.attribute("y2", "0%"),
              ],
              [
                element.namespaced(
                  "http://www.w3.org/2000/svg",
                  "stop",
                  [
                    attribute.attribute("offset", "0%"),
                    attribute.attribute("stop-color", "hsl(180, 60%, 55%)"),
                  ],
                  [],
                ),
                element.namespaced(
                  "http://www.w3.org/2000/svg",
                  "stop",
                  [
                    attribute.attribute("offset", "25%"),
                    attribute.attribute("stop-color", "hsl(135, 60%, 55%)"),
                  ],
                  [],
                ),
                element.namespaced(
                  "http://www.w3.org/2000/svg",
                  "stop",
                  [
                    attribute.attribute("offset", "50%"),
                    attribute.attribute("stop-color", "hsl(90, 60%, 55%)"),
                  ],
                  [],
                ),
                element.namespaced(
                  "http://www.w3.org/2000/svg",
                  "stop",
                  [
                    attribute.attribute("offset", "75%"),
                    attribute.attribute("stop-color", "hsl(45, 60%, 55%)"),
                  ],
                  [],
                ),
                element.namespaced(
                  "http://www.w3.org/2000/svg",
                  "stop",
                  [
                    attribute.attribute("offset", "100%"),
                    attribute.attribute("stop-color", "hsl(0, 60%, 55%)"),
                  ],
                  [],
                ),
              ],
            ),
          ]),
          // Rectangle filled with gradient
          element.namespaced(
            "http://www.w3.org/2000/svg",
            "rect",
            [
              attribute.attribute("width", int.to_string(legend_width)),
              attribute.attribute("height", int.to_string(legend_height)),
              attribute.attribute("fill", "url(#temp-gradient)"),
            ],
            [],
          ),
        ],
      ),
      // Temperature labels
      html.div(
        [
          attribute.styles([
            #("display", "flex"),
            #("justify-content", "space-between"),
            #("width", int.to_string(legend_width) <> "px"),
            #("font-size", "0.75rem"),
            #("color", "#666"),
          ]),
        ],
        [
          html.span([], [html.text("-10°C")]),
          html.span([], [html.text("0°C")]),
          html.span([], [html.text("15°C")]),
          html.span([], [html.text("25°C")]),
          html.span([], [html.text("35°C+")]),
        ],
      ),
    ],
  )
}

fn render_heatmap(samples: List(model.Sample)) -> Element(msg) {
  // Group samples by year
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
        #("gap", "3rem"),
      ]),
    ],
    list.map(years, fn(year) {
      let year_samples =
        list.filter(samples, fn(sample) { sample.date.year == year })
      render_year_heatmap(year, year_samples)
    }),
  )
}

fn render_year_heatmap(year: Int, samples: List(model.Sample)) -> Element(msg) {
  // Calculate SVG dimensions based on samples
  let num_days = list.length(samples)
  let square_size = 12
  let gap = 3
  let cell_size = square_size + gap

  // Arrange in 53 columns (weeks) like GitHub
  let cols = 53
  let rows = { num_days + cols - 1 } / cols
  // Ceiling division

  let svg_width = cols * cell_size
  let svg_height = rows * cell_size

  // Group samples by color to minimize path elements
  let grouped_by_color =
    samples
    |> list.index_map(fn(sample, index) { #(sample, index) })
    |> list.group(fn(pair) {
      let #(sample, _index) = pair
      temperature_to_color(sample)
    })
    |> dict.to_list

  html.div(
    [
      attribute.styles([
        #("display", "flex"),
        #("flex-direction", "column"),
        #("gap", "0.5rem"),
      ]),
    ],
    [
      html.h3(
        [
          attribute.styles([
            #("font-size", "1.2rem"),
            #("margin", "0"),
          ]),
        ],
        [html.text(int.to_string(year))],
      ),
      element.namespaced(
        "http://www.w3.org/2000/svg",
        "svg",
        [
          attribute.attribute("width", int.to_string(svg_width)),
          attribute.attribute("height", int.to_string(svg_height)),
          attribute.attribute(
            "viewBox",
            "0 0 "
              <> int.to_string(svg_width)
              <> " "
              <> int.to_string(svg_height),
          ),
          attribute.styles([
            #("display", "block"),
            #("overflow", "visible"),
          ]),
        ],
        // Render one path per color
        list.map(grouped_by_color, fn(group) {
          let #(color, samples_with_index) = group
          render_color_group_path(color, samples_with_index, square_size, gap)
        }),
      ),
    ],
  )
}

fn render_color_group_path(
  color: String,
  samples_with_index: List(#(model.Sample, Int)),
  square_size: Int,
  gap: Int,
) -> Element(msg) {
  let cell_size = square_size + gap
  let cols = 53
  let radius = 2

  // Build path data for all rectangles of this color
  let path_data =
    samples_with_index
    |> list.map(fn(pair) {
      let #(_sample, index) = pair
      let col = index % cols
      let row = index / cols
      let x = col * cell_size
      let y = row * cell_size

      // Create a rounded rectangle path for this cell
      // M x,y+r means: move to (x, y+radius)
      // Then draw the rounded rectangle using arcs and lines
      let x_str = int.to_string(x)
      let y_str = int.to_string(y)
      let x_r_str = int.to_string(x + radius)
      let y_r_str = int.to_string(y + radius)
      let x_w_str = int.to_string(x + square_size)
      let y_h_str = int.to_string(y + square_size)
      let x_w_r_str = int.to_string(x + square_size - radius)
      let y_h_r_str = int.to_string(y + square_size - radius)

      // Draw rounded rectangle path
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
    })
    |> string.join(" ")

  element.namespaced(
    "http://www.w3.org/2000/svg",
    "path",
    [
      attribute.attribute("d", path_data),
      attribute.attribute("fill", color),
      attribute.styles([#("cursor", "pointer")]),
    ],
    [],
  )
}

fn temperature_to_color(sample: model.Sample) -> String {
  let temp = sample.temperature_celsius

  // Calculate hue: teal (180) at -10°C to red (0) at 35°C
  // Linear interpolation
  let hue = case temp <=. -10.0 {
    True -> 180.0
    False ->
      case temp >=. 35.0 {
        True -> 0.0
        False -> {
          let normalized = { temp +. 10.0 } /. 45.0
          180.0 -. { normalized *. 180.0 }
        }
      }
  }

  // Calculate saturation and lightness based on deviation from historical average
  let #(saturation, lightness) = case
    sample.historical_average_temperature_celsius
  {
    option.Some(hist_avg) -> {
      let deviation = float.absolute_value(temp -. hist_avg)

      // More deviation = more intense color (higher saturation, lower lightness)
      // Deviation of 0°C -> lighter, 5°C+ -> most intense
      let intensity = case deviation >=. 5.0 {
        True -> 1.0
        False -> deviation /. 5.0
      }

      let saturation = 50.0 +. { intensity *. 50.0 }
      let lightness = 70.0 -. { intensity *. 30.0 }

      #(saturation, lightness)
    }
    option.None -> {
      // No historical data - use medium intensity
      #(60.0, 55.0)
    }
  }

  // Quantize colors to reduce number of unique colors
  // This creates a palette of ~32 colors by rounding to nearest steps
  let quantized_hue = quantize_value(hue, 15.0)
  // Round to nearest 15 degrees
  let quantized_saturation = quantize_value(saturation, 10.0)
  // Round to nearest 10%
  let quantized_lightness = quantize_value(lightness, 5.0)
  // Round to nearest 5%

  "hsl("
  <> float.to_string(quantized_hue)
  <> ", "
  <> float.to_string(quantized_saturation)
  <> "%, "
  <> float.to_string(quantized_lightness)
  <> "%)"
}

fn quantize_value(value: Float, step: Float) -> Float {
  let rounded = {
    value /. step
  }
  let rounded_int = float.round(rounded)
  int.to_float(rounded_int) *. step
}
