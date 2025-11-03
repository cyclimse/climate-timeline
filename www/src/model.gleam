import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleam/time/calendar

import simplifile
import snag.{type Result}

pub type Sample {
  Sample(
    date: calendar.Date,
    temperature_celsius: Float,
    historical_average_temperature_celsius: Option(Float),
    event: Option(Event),
  )
}

fn decode_date() -> decode.Decoder(calendar.Date) {
  decode.map(decode.string, fn(date_str) {
    // Assuming date is in "YYYY-MM-DD" format
    let assert [year_str, month_str, day_str] = string.split(date_str, "-")
    let assert Ok(year) = int.parse(year_str)
    let assert Ok(month) = int.parse(month_str)
    let assert Ok(month) = calendar.month_from_int(month)
    let assert Ok(day) = int.parse(day_str)
    calendar.Date(year, month, day)
  })
}

fn sample_decoder() -> decode.Decoder(Sample) {
  use date <- decode.field("date", decode_date())
  use temperature_celsius <- decode.field("temperature_celsius", decode.float)
  use historical_average_temperature_celsius <- decode.field(
    "historical_average_temperature_celsius",
    decode.optional(decode.float),
  )
  decode.success(Sample(
    date:,
    temperature_celsius:,
    historical_average_temperature_celsius:,
    event: option.None,
  ))
}

pub fn read_samples_from_file(file_path: String) -> Result(List(Sample)) {
  use data <- result.try(
    simplifile.read(file_path) |> snag.map_error(simplifile.describe_error),
  )
  use samples <- result.try(
    json.parse(data, decode.list(sample_decoder()))
    |> snag.map_error(fn(e) {
      "decoding samples from " <> file_path <> ": " <> string.inspect(e)
    }),
  )
  Ok(samples)
}

pub type Event {
  Event(
    id: String,
    display_name: String,
    date: calendar.Date,
    description: String,
    wiki_link: String,
  )
}

fn event_decoder() -> decode.Decoder(Event) {
  use id <- decode.field("id", decode.string)
  use display_name <- decode.field("display_name", decode.string)
  use date <- decode.field("date", decode_date())
  use description <- decode.field("description", decode.string)
  use wiki_link <- decode.field("wiki_link", decode.string)
  decode.success(Event(id:, display_name:, date:, description:, wiki_link:))
}

pub fn read_events_from_file(file_path: String) -> Result(List(Event)) {
  use data <- result.try(
    simplifile.read(file_path) |> snag.map_error(simplifile.describe_error),
  )

  use events <- result.try(
    json.parse(data, decode.list(event_decoder()))
    |> snag.map_error(fn(e) {
      "decoding events from " <> file_path <> ": " <> string.inspect(e)
    }),
  )

  Ok(events)
}
