import gleam/list
import gleam/string

import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

import color

const github_url = "https://github.com/cyclimse/climate-timeline"

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
          footer(),
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
        [inner, footer()],
      ),
    ],
  )
}

// TODO: Host these locally
fn flygja_css(subpackage: String) -> Element(msg) {
  html.link([
    attribute.rel("stylesheet"),
    attribute.href(
      "https://cdn.jsdelivr.net/npm/@fylgja/" <> subpackage <> "/index.min.css",
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
        "@media (max-width: 500px) { .month-label { display: none !important; } .month-grid { grid-template-columns: 1fr !important; } } @media (max-width: 1200px) { .year-events { display: none !important; } } .event-card:hover { transform: scale(1.02); transition: transform 0.2s ease; box-shadow: 0 4px 12px rgba(255,0,255,0.2); }",
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

fn footer() -> Element(msg) {
  html.footer(
    [
      attribute.styles([
        #("padding", "2rem"),
        #("margin-top", "4rem"),
        #("text-align", "center"),
        #("border-top", "2px solid " <> color.highlight),
        #("color", "#666"),
      ]),
    ],
    [
      html.p(
        [
          attribute.styles([
            #("margin", "0"),
            #("font-size", "1rem"),
          ]),
        ],
        [html.text("Climate Timeline")],
      ),
      html.p(
        [
          attribute.styles([
            #("margin", "0.5rem 0 0 0"),
            #("font-size", "0.875rem"),
            #("opacity", "0.8"),
          ]),
        ],
        [
          github_link(github_url),
        ],
      ),
    ],
  )
}

fn github_link(url: String) -> Element(msg) {
  html.a(
    [
      attribute.href(url),
      attribute.styles([
        #("color", "#888"),
        #("text-decoration", "none"),
        #("display", "inline-flex"),
        #("align-items", "center"),
        #("gap", "0.25rem"),
        #("margin-top", "0.5rem"),
      ]),
    ],
    [
      github_svg(),
      html.span([], [html.text("View on GitHub")]),
    ],
  )
}

fn github_svg() -> Element(msg) {
  element.namespaced(
    "http://www.w3.org/2000/svg",
    "svg",
    [
      attribute.attribute("xmlns", "http://www.w3.org/2000/svg"),
      attribute.attribute("width", "16"),
      attribute.attribute("height", "16"),
      attribute.attribute("fill", "currentColor"),
      attribute.attribute("class", "bi bi-github"),
      attribute.attribute("viewBox", "0 0 16 16"),
    ],
    [
      element.element(
        "path",
        [
          attribute.attribute(
            "d",
            // In conformance with GitHub's trademark guidelines
            // See: https://github.com/logos
            // Copied from: https://icons.getbootstrap.com/icons/github/
            "M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27s1.36.09 2 .27c1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8",
          ),
        ],
        [],
      ),
    ],
  )
}
