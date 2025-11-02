import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import gleam/time/calendar

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
              ]),
            ],
            [
              html.text(
                "Color intensity shows deviation from historical average. Hue indicates temperature (teal=cold, red=hot).",
              ),
            ],
          ),
          render_heatmap(samples),
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
        list.index_map(samples, fn(sample, index) {
          render_day_rect(sample, index, square_size, gap)
        }),
      ),
    ],
  )
}

fn render_day_rect(
  sample: model.Sample,
  index: Int,
  square_size: Int,
  gap: Int,
) -> Element(msg) {
  let color = temperature_to_color(sample)
  let tooltip = make_tooltip(sample)

  let cell_size = square_size + gap
  let cols = 53

  let col = index % cols
  let row = index / cols

  let x = col * cell_size
  let y = row * cell_size

  element.namespaced(
    "http://www.w3.org/2000/svg",
    "rect",
    [
      attribute.attribute("x", int.to_string(x)),
      attribute.attribute("y", int.to_string(y)),
      attribute.attribute("width", int.to_string(square_size)),
      attribute.attribute("height", int.to_string(square_size)),
      attribute.attribute("fill", color),
      attribute.attribute("rx", "2"),
      // Rounded corners
      attribute.attribute("ry", "2"),
      attribute.styles([#("cursor", "pointer")]),
    ],
    [
      // SVG title element for tooltip
      element.namespaced("http://www.w3.org/2000/svg", "title", [], [
        html.text(tooltip),
      ]),
    ],
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

  "hsl("
  <> float.to_string(hue)
  <> ", "
  <> float.to_string(saturation)
  <> "%, "
  <> float.to_string(lightness)
  <> "%)"
}

fn make_tooltip(sample: model.Sample) -> String {
  let date_str =
    int.to_string(sample.date.year)
    <> "-"
    <> int.to_string(sample.date.month |> calendar.month_to_int)
    <> "-"
    <> int.to_string(sample.date.day)

  let temp_str = float.to_string(sample.temperature_celsius) <> "°C"

  let hist_str = case sample.historical_average_temperature_celsius {
    option.Some(hist) -> " (historical avg: " <> float.to_string(hist) <> "°C)"
    option.None -> ""
  }

  date_str <> ": " <> temp_str <> hist_str
}
