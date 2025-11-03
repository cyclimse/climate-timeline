import gleam/list
import gleam/string

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn from(
  title: String,
  cities: List(String),
  current_city: String,
  inner: Element(msg),
) -> Element(msg) {
  html.html(
    [
      attribute.styles([
        #("--hue", "var(--hue-violet)"),
        #("font-size", "var(--font-size-4)"),
        #("line-height", "var(--line-height-2)"),
      ]),
    ],
    [
      head(title),
      html.body(
        [
          attribute.styles([
            #("max-width", "40rem"),
            #("margin", "3rem auto"),
          ]),
        ],
        [
          navbar(cities, current_city),
          inner,
        ],
      ),
    ],
  )
}

pub fn from_simple(title: String, inner: Element(msg)) -> Element(msg) {
  html.html(
    [
      attribute.styles([
        #("--hue", "var(--hue-violet)"),
        #("font-size", "var(--font-size-4)"),
        #("line-height", "var(--line-height-2)"),
      ]),
    ],
    [
      head(title),
      html.body(
        [
          attribute.styles([
            #("max-width", "50rem"),
            #("margin", "3rem auto"),
            #("padding", "0 1rem"),
          ]),
        ],
        [inner],
      ),
    ],
  )
}

// TODO: Host these locally
fn flygja_css(subpackage: String) -> Element(msg) {
  html.link([
    attribute.rel("stylesheet"),
    attribute.href(
      "https://cdn.jsdelivr.net/npm/@fylgja/"
      <> subpackage
      <> "/index.min.css",
    ),
  ])
}

fn head(title: String) -> Element(msg) {
  html.head([], [
    html.meta([attribute.charset("utf-8")]),
    html.meta([
      attribute.name("viewport"),
      attribute.content("width=device-width, initial-scale=1"),
    ]),
    flygja_css("base"),
    flygja_css("tokens/css"),
    flygja_css("utilities"),
    flygja_css("card"),
    element.element("style", [], [
      element.text(
        "@media (max-width: 500px) { .month-label { display: none !important; } .month-grid { grid-template-columns: 1fr !important; } }",
      ),
    ]),
    html.title([], title),
  ])
}

fn navbar(cities: List(String), current_city: String) -> Element(msg) {
  html.header(
    [
      attribute.class("page-header"),
      attribute.styles([
        #("margin-bottom", "2rem"),
      ]),
    ],
    [
      html.div(
        [
          attribute.class("container"),
          attribute.class("flex"),
          attribute.class("align"),
          attribute.class("gap"),
        ],
        [
          html.div(
            [
              attribute.styles([
                #("font-size", "1.5rem"),
                #("font-weight", "600"),
              ]),
            ],
            [
              html.text(
                "Climate Infographic for " <> string.capitalise(current_city),
              ),
            ],
          ),
          html.nav(
            [
              attribute.class("flex"),
              attribute.class("gap"),
              attribute.class("align"),
            ],
            [
              html.label(
                [
                  attribute.styles([
                    #("display", "flex"),
                    #("align-items", "center"),
                    #("gap", "0.5rem"),
                  ]),
                ],
                [
                  html.text("City: "),
                  html.select(
                    [
                      attribute.attribute(
                        "onchange",
                        "location.href = this.value",
                      ),
                      attribute.styles([
                        #("padding", "0.25rem 0.5rem"),
                        #("border-radius", "4px"),
                        #("border", "1px solid #ccc"),
                      ]),
                    ],
                    list.map(cities, fn(city) {
                      let is_current = city == current_city
                      element.element(
                        "option",
                        [
                          attribute.value(city <> ".html"),
                          case is_current {
                            True -> attribute.selected(True)
                            False -> attribute.none()
                          },
                        ],
                        [html.text(string.capitalise(city))],
                      )
                    }),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
