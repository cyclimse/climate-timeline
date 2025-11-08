import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/time/calendar

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import color
import model
import svg

// Visual layout constants
const square_size = 12

const gap = 3

const cell_radius = 2

const highlight_stroke_width = 3

const legend_height = 20

const max_days_in_month = 31

// Temperature scale constants
const temp_min = -10.0

const temp_max = 35.0

const temp_range = 45.0

const hue_min = 0.0

const hue_max = 180.0

// Color intensity constants
const max_deviation_threshold = 5.0

const saturation_base = 50.0

const saturation_range = 50.0

const lightness_base = 70.0

const lightness_range = 30.0

const default_saturation = 60.0

const default_lightness = 55.0

const calendar_months = [
  calendar.January,
  calendar.February,
  calendar.March,
  calendar.April,
  calendar.May,
  calendar.June,
  calendar.July,
  calendar.August,
  calendar.September,
  calendar.October,
  calendar.November,
  calendar.December,
]

pub fn from(samples: List(model.Sample)) -> Element(msg) {
  let years =
    samples
    |> list.map(fn(sample) { sample.date.year })
    |> list.unique
    |> list.sort(int.compare)
  let years_as_string =
    list.first(years)
    |> result.unwrap(0)
    |> int.to_string
    <> "-"
    <> list.last(years)
    |> result.unwrap(0)
    |> int.to_string

  html.div(
    [
      attribute.styles([
        #("display", "flex"),
        #("flex-direction", "column"),
      ]),
    ],
    [
      html.p(
        [
          attribute.styles([
            #("font-size", "1rem"),
            #("color", "#444"),
          ]),
        ],
        [
          html.text(
            "This infographic visualizes daily temperature data with respect to historical averages. Each square represents a day, colored by how the temperature deviated from the historical average for that date.",
          ),
          html.text(
            " The data covers the years "
            <> years_as_string
            <> ". All credits to Open-Meteo for the data.",
          ),
        ],
      ),
      html.div([], [
        html.h3([], [html.text("Temperature Heatmap")]),
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
      ]),
    ],
  )
}

fn render_temperature_legend() -> Element(msg) {
  html.div(
    [
      attribute.styles([
        #("margin", "1.5rem 0"),
        #("display", "flex"),
        #("flex-direction", "column"),
        #("gap", "0.5rem"),
        #("width", "100%"),
        #("max-width", "800px"),
      ]),
    ],
    [
      // SVG gradient bar
      element.namespaced(
        "http://www.w3.org/2000/svg",
        "svg",
        [
          attribute.attribute(
            "viewBox",
            "0 0 400 " <> int.to_string(legend_height),
          ),
          attribute.attribute("preserveAspectRatio", "none"),
          attribute.styles([
            #("border-radius", "4px"),
            #("border", "1px solid #ddd"),
            #("width", "100%"),
            #("height", int.to_string(legend_height) <> "px"),
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
              attribute.attribute("width", "400"),
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
            #("width", "100%"),
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
      attribute.class("heatmap-container"),
      attribute.styles([
        #("position", "relative"),
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
  let cell_size = square_size + gap

  // Group samples by month
  let samples_by_month =
    samples
    |> list.group(fn(sample) { sample.date.month })

  // Get all events for this year
  let year_events =
    samples
    |> list.filter_map(fn(sample) {
      case sample.event {
        option.Some(event) if event.date.year == year -> Ok(event)
        _ -> Error(Nil)
      }
    })
    |> list.unique

  // Group events by month
  let events_by_month =
    year_events
    |> list.group(fn(event) { event.date.month })

  // Generate month labels
  let months =
    calendar_months
    |> list.map(fn(month) { #(month, month_short_name(month)) })

  // Calculate max days in any month (31) for consistent width
  let svg_width = max_days_in_month * cell_size

  html.div(
    [
      attribute.styles([
        #("display", "flex"),
        #("flex-direction", "column"),
        #("gap", "0.5rem"),
        #("position", "relative"),
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
      // Wrapper for grid and event cards
      html.div(
        [
          attribute.styles([
            #("position", "relative"),
          ]),
        ],
        [
          // Container for month rows (stacked vertically)
          html.div(
            [
              attribute.class("month-grid"),
              attribute.styles([
                #("display", "flex"),
                #("flex-direction", "column"),
                #("gap", "0"),
                #("width", "100%"),
              ]),
            ],
            // Each month is a single row with 4 columns
            list.map(months, fn(month_info) {
              let #(month, label) = month_info
              let month_samples =
                dict.get(samples_by_month, month)
                |> option.from_result
                |> option.unwrap([])

              let month_events =
                dict.get(events_by_month, month)
                |> option.from_result
                |> option.unwrap([])

              let max_temp_sample =
                list.find(month_samples, fn(sample) { sample.is_maximum })

              // Each month row is a grid with 4 columns
              html.div(
                [
                  attribute.class("month-row"),
                  attribute.styles([
                    #("display", "grid"),
                    #("grid-template-columns", "0 2.5rem 1fr 0"),
                    #("gap", "0"),
                    #("width", "100%"),
                  ]),
                ],
                [
                  // First column (left) - temp indicators
                  html.div(
                    [
                      attribute.class("temp-indicator-col"),
                      attribute.styles([
                        #("position", "relative"),
                        #("overflow", "visible"),
                      ]),
                    ],
                    case max_temp_sample {
                      Ok(sample) -> [
                        html.div(
                          [
                            attribute.styles([
                              #("position", "absolute"),
                              #("right", "0"),
                              #("top", "50%"),
                              #("transform", "translateY(-50%)"),
                              #("display", "flex"),
                              #("align-items", "center"),
                              #("justify-content", "flex-end"),
                            ]),
                          ],
                          [render_max_temp_indicator_left(sample)],
                        ),
                      ]
                      Error(_) -> []
                    },
                  ),
                  // Month label (second column)
                  html.div(
                    [
                      attribute.class("month-label"),
                      attribute.styles([
                        #("font-size", "0.75rem"),
                        #("color", "#666"),
                        #("text-align", "right"),
                        #("padding-right", "0.5rem"),
                        #("display", "flex"),
                        #("align-items", "center"),
                        #("justify-content", "flex-end"),
                      ]),
                    ],
                    [html.text(label)],
                  ),
                  // SVG for this month's row (third column)
                  element.namespaced(
                    "http://www.w3.org/2000/svg",
                    "svg",
                    [
                      attribute.attribute(
                        "viewBox",
                        "0 0 "
                          <> int.to_string(svg_width)
                          <> " "
                          <> int.to_string(cell_size),
                      ),
                      attribute.styles([
                        #("display", "block"),
                        #("width", "100%"),
                        #("height", "100%"),
                        #("overflow", "visible"),
                      ]),
                    ],
                    list.flatten([
                      render_month_paths_single_row(
                        month_samples,
                        0,
                        square_size,
                        gap,
                      ),
                      render_month_event_highlights(
                        month_samples,
                        0,
                        square_size,
                        gap,
                      ),
                      render_max_temp_highlight(
                        month_samples,
                        0,
                        square_size,
                        gap,
                      ),
                    ]),
                  ),
                  // Fourth column (right) - event cards
                  html.div(
                    [
                      attribute.class("event-card-col"),
                      attribute.styles([
                        #("position", "relative"),
                        #("overflow", "visible"),
                      ]),
                    ],
                    case list.first(month_events) {
                      Ok(event) -> [
                        html.div(
                          [
                            attribute.styles([
                              #("position", "absolute"),
                              #("left", "1rem"),
                              #("top", "0"),
                              #("display", "flex"),
                              #("align-items", "center"),
                              #("min-height", int.to_string(cell_size) <> "px"),
                              #("width", "280px"),
                            ]),
                          ],
                          [render_event_card_inline(event)],
                        ),
                      ]
                      Error(_) -> []
                    },
                  ),
                ],
              )
            }),
          ),
        ],
      ),
    ],
  )
}

fn render_max_temp_highlight(
  samples: List(model.Sample),
  month_index: Int,
  square_size: Int,
  gap: Int,
) -> List(Element(msg)) {
  list.filter_map(samples, fn(sample) {
    case sample.is_maximum {
      True ->
        Ok(render_highlight(
          sample,
          color.max_temp_highlight,
          month_index,
          square_size,
          gap,
        ))
      False -> Error(Nil)
    }
  })
}

fn render_month_paths_single_row(
  samples: List(model.Sample),
  month_index: Int,
  square_size: Int,
  gap: Int,
) -> List(Element(msg)) {
  // Group samples by color
  let grouped_by_color =
    samples
    |> list.sort(fn(a, b) { int.compare(a.date.day, b.date.day) })
    |> list.index_map(fn(sample, _idx) { sample })
    |> list.group(fn(sample) { temperature_to_color(sample) })
    |> dict.to_list

  // Render one path per color for this month
  list.map(grouped_by_color, fn(group) {
    let #(color, month_samples) = group
    render_month_color_path(color, month_samples, month_index, square_size, gap)
  })
}

fn render_month_event_highlights(
  samples: List(model.Sample),
  month_index: Int,
  square_size: Int,
  gap: Int,
) -> List(Element(msg)) {
  // Filter samples that have events
  let samples_with_events =
    samples
    |> list.filter(fn(sample) {
      case sample.event {
        option.Some(_) -> True
        option.None -> False
      }
    })

  // Render highlight border for each event day
  list.map(samples_with_events, fn(sample) {
    render_event_highlight(sample, month_index, square_size, gap)
  })
}

/// Calculate the position of a cell in the heatmap
fn calculate_cell_position(
  day: Int,
  month_index: Int,
  square_size: Int,
  gap: Int,
) -> #(Int, Int) {
  let cell_size = square_size + gap
  let x = { day - 1 } * cell_size
  let y = month_index * cell_size
  #(x, y)
}

fn render_event_highlight(
  sample: model.Sample,
  month_index: Int,
  square_size: Int,
  gap: Int,
) -> Element(msg) {
  render_highlight(sample, color.event_highlight, month_index, square_size, gap)
}

fn render_highlight(
  sample: model.Sample,
  color: String,
  month_index: Int,
  square_size: Int,
  gap: Int,
) -> Element(msg) {
  let #(x, y) =
    calculate_cell_position(sample.date.day, month_index, square_size, gap)
  let path_data =
    svg.rounded_rect_path(x, y, square_size, square_size, cell_radius)

  svg.path_stroked(path_data, color, highlight_stroke_width)
}

fn render_month_color_path(
  color: String,
  samples: List(model.Sample),
  month_index: Int,
  square_size: Int,
  gap: Int,
) -> Element(msg) {
  // Build path data for all rectangles of this color in this month
  let path_data =
    samples
    |> list.map(fn(sample) {
      let #(x, y) =
        calculate_cell_position(sample.date.day, month_index, square_size, gap)
      svg.rounded_rect_path(x, y, square_size, square_size, cell_radius)
    })
    |> svg.join_paths

  svg.path_filled(path_data, color)
}

fn temperature_to_color(sample: model.Sample) -> String {
  let temp = sample.temperature_celsius

  // Calculate hue: teal (180) at -10°C to red (0) at 35°C
  // Linear interpolation
  let hue = case temp <=. temp_min {
    True -> hue_max
    False ->
      case temp >=. temp_max {
        True -> hue_min
        False -> {
          let normalized =
            { temp +. float.absolute_value(temp_min) } /. temp_range
          hue_max -. { normalized *. hue_max }
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
      let intensity = case deviation >=. max_deviation_threshold {
        True -> 1.0
        False -> deviation /. max_deviation_threshold
      }

      let saturation = saturation_base +. { intensity *. saturation_range }
      let lightness = lightness_base -. { intensity *. lightness_range }

      #(saturation, lightness)
    }
    option.None -> {
      // No historical data - use medium intensity
      #(default_saturation, default_lightness)
    }
  }

  // Quantize colors to reduce number of unique colors
  // This creates a palette of ~32 colors by rounding to nearest steps
  let quantized_hue = color.quantize_value(hue, color.hue_quantize_step)
  let quantized_saturation =
    color.quantize_value(saturation, color.saturation_quantize_step)
  let quantized_lightness =
    color.quantize_value(lightness, color.lightness_quantize_step)

  "hsl("
  <> float.to_string(quantized_hue)
  <> ", "
  <> float.to_string(quantized_saturation)
  <> "%, "
  <> float.to_string(quantized_lightness)
  <> "%)"
}

fn render_max_temp_indicator_left(sample: model.Sample) -> Element(msg) {
  html.div(
    [
      attribute.class("max-temp-indicator"),
      attribute.styles([
        #("display", "flex"),
        #("align-items", "center"),
        #("gap", "0.5rem"),
        #("justify-content", "flex-end"),
      ]),
    ],
    [
      // Temperature info box
      html.div(
        [
          attribute.styles([
            #("background", "white"),
            #("border", "2px solid " <> color.max_temp_highlight),
            #("border-radius", "6px"),
            #("padding", "0.4rem 0.6rem"),
            #("box-shadow", "0 2px 4px rgba(0,0,0,0.1)"),
            #("font-size", "0.75rem"),
            #("white-space", "nowrap"),
          ]),
        ],
        [
          html.div(
            [
              attribute.styles([
                #("font-weight", "bold"),
                #("color", color.max_temp_highlight),
                #("font-size", "0.85rem"),
              ]),
            ],
            [
              html.text(
                float.to_precision(sample.max_temperature_celsius, 1)
                |> float.to_string
                <> "°C",
              ),
            ],
          ),
          html.div(
            [
              attribute.styles([
                #("color", "#666"),
                #("font-size", "0.65rem"),
                #("margin-top", "0.1rem"),
              ]),
            ],
            [
              html.text(
                "Record high "
                <> month_short_name(sample.date.month)
                <> " "
                <> int.to_string(sample.date.day),
              ),
            ],
          ),
        ],
      ),
      // Arrow pointing to the right (toward the heatmap)
      element.namespaced(
        "http://www.w3.org/2000/svg",
        "svg",
        [
          attribute.attribute("width", "40"),
          attribute.attribute("height", "20"),
          attribute.attribute("viewBox", "0 0 40 20"),
          attribute.styles([
            #("flex-shrink", "0"),
          ]),
        ],
        [
          element.namespaced(
            "http://www.w3.org/2000/svg",
            "path",
            [
              attribute.attribute("d", "M0,10 L35,10 L25,5 M35,10 L25,15"),
              attribute.attribute("stroke", color.max_temp_highlight),
              attribute.attribute("stroke-width", "2"),
              attribute.attribute("fill", "none"),
              attribute.attribute("stroke-linecap", "round"),
              attribute.attribute("stroke-linejoin", "round"),
            ],
            [],
          ),
        ],
      ),
    ],
  )
}

fn render_event_card_inline(event: model.Event) -> Element(msg) {
  html.div(
    [
      attribute.class("event-card"),
      attribute.styles([
        #("background", "white"),
        #("border", "2px solid " <> color.event_highlight),
        #("border-radius", "8px"),
        #("padding", "0.75rem"),
        #("box-shadow", "0 2px 8px rgba(0,0,0,0.1)"),
        #("font-size", "0.8rem"),
      ]),
    ],
    [
      html.h4(
        [
          attribute.styles([
            #("margin", "0 0 0.25rem 0"),
            #("font-size", "0.85rem"),
            #("color", color.event_highlight),
          ]),
        ],
        [html.text(event.display_name)],
      ),
      html.p(
        [
          attribute.styles([
            #("margin", "0 0 0.25rem 0"),
            #("font-size", "0.7rem"),
            #("color", "#666"),
          ]),
        ],
        [
          html.text(
            month_short_name(event.date.month)
            <> " "
            <> int.to_string(event.date.day)
            <> ", "
            <> int.to_string(event.date.year),
          ),
        ],
      ),
      html.p(
        [
          attribute.styles([
            #("margin", "0 0 0.25rem 0"),
            #("font-size", "0.75rem"),
            #("line-height", "1.3"),
          ]),
        ],
        [html.text(event.description)],
      ),
      html.a(
        [
          attribute.href(event.wiki_link),
          attribute.target("_blank"),
          attribute.styles([
            #("font-size", "0.7rem"),
            #("color", color.event_highlight),
            #("text-decoration", "none"),
          ]),
        ],
        [html.text("Learn more →")],
      ),
    ],
  )
}

fn month_short_name(month: calendar.Month) -> String {
  case month {
    calendar.January -> "Jan"
    calendar.February -> "Feb"
    calendar.March -> "Mar"
    calendar.April -> "Apr"
    calendar.May -> "May"
    calendar.June -> "Jun"
    calendar.July -> "Jul"
    calendar.August -> "Aug"
    calendar.September -> "Sep"
    calendar.October -> "Oct"
    calendar.November -> "Nov"
    calendar.December -> "Dec"
  }
}
