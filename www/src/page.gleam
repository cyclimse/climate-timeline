import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub fn from(title: String, inner: Element(msg)) -> Element(msg) {
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
          navbar(),
          inner,
        ],
      ),
    ],
  )
}

fn head(title: String) -> Element(msg) {
  html.head([], [
    html.meta([attribute.charset("utf-8")]),
    html.meta([
      attribute.name("viewport"),
      attribute.content("width=device-width, initial-scale=1"),
    ]),
    // TODO: host these locally
    html.link([
      attribute.rel("stylesheet"),
      attribute.href("https://cdn.jsdelivr.net/npm/@fylgja/base/index.min.css"),
    ]),
    html.link([
      attribute.rel("stylesheet"),
      attribute.href(
        "https://cdn.jsdelivr.net/npm/@fylgja/tokens/css/index.min.css",
      ),
    ]),
    html.link([
      attribute.rel("stylesheet"),
      attribute.href(
        "https://cdn.jsdelivr.net/npm/@fylgja/utilities/index.min.css",
      ),
    ]),
    element.element("style", [], [
      element.text(
        "@media (max-width: 500px) { .month-label { display: none !important; } .month-grid { grid-template-columns: 1fr !important; } }",
      ),
    ]),
    html.title([], title),
  ])
}

fn navbar() -> Element(msg) {
  html.header(
    [
      attribute.class("page-header"),
      attribute.class("sticky"),
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
          html.div([], [html.text("My Blog")]),
          html.nav(
            [
              attribute.class("flex"),
              attribute.class("gap"),
            ],
            [
              html.a([attribute.href("/")], [html.text("Home")]),
              html.a([attribute.href("/about.html")], [html.text("About")]),
            ],
          ),
        ],
      ),
    ],
  )
}
