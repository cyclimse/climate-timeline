import gleam/list
import gleam/string

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn from(cities: List(String)) -> Element(msg) {
  html.div(
    [
      attribute.styles([
        #("display", "flex"),
        #("flex-direction", "column"),
        #("gap", "2rem"),
        #("padding", "2rem 0"),
      ]),
    ],
    [
      html.div([], [
        html.h1(
          [
            attribute.styles([
              #("font-size", "2.5rem"),
              #("margin-bottom", "0.5rem"),
            ]),
          ],
          [html.text("Climate Timeline")],
        ),
        html.p(
          [
            attribute.styles([
              #("font-size", "1.2rem"),
              #("color", "#666"),
              #("margin-bottom", "0.5rem"),
            ]),
          ],
          [
            html.text(
              "Explore daily temperature data visualizations for major European cities.",
            ),
          ],
        ),
        html.p(
          [
            attribute.styles([
              #("font-size", "0.95rem"),
              #("color", "#888"),
              #("margin-top", "0.5rem"),
            ]),
          ],
          [
            html.text(
              "Data provided by Open-Meteo. Visualizations show daily temperature deviations from historical averages.",
            ),
          ],
        ),
      ]),
      html.div(
        [
          attribute.styles([
            #("display", "grid"),
            #("grid-template-columns", "repeat(auto-fill, minmax(250px, 1fr))"),
            #("gap", "1.5rem"),
            #("margin-top", "1rem"),
          ]),
        ],
        list.map(cities, fn(city) { city_card(city) }),
      ),
    ],
  )
}

fn city_card(city: String) -> Element(msg) {
  html.a(
    [
      attribute.href(city <> ".html"),
      attribute.class("card"),
      attribute.styles([
        #("padding", "1.5rem"),
        #("text-decoration", "none"),
      ]),
    ],
    [
      html.h3(
        [
          attribute.styles([
            #("margin", "0 0 0.5rem 0"),
            #("font-size", "1.5rem"),
          ]),
        ],
        [html.text(string.capitalise(city))],
      ),
      html.p(
        [
          attribute.styles([
            #("margin", "0"),
            #("color", "#666"),
            #("font-size", "0.9rem"),
          ]),
        ],
        [html.text("View climate data →")],
      ),
    ],
  )
}
