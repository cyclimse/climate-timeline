import gleam/io
import gleam/list
import gleam/string

import lustre/element.{type Element}
import simplifile
import taskle
import temporary

import infographic
import model
import page

const root_dir = ".."

const data_dir = root_dir <> "/data"

const output_dir = root_dir <> "/dist"

pub fn main() {
  let assert Ok(climate_data_files) = simplifile.read_directory(data_dir)
    as "listing data directory"

  let cities =
    climate_data_files
    |> list.filter(fn(file) {
      string.starts_with(file, "climate_data_")
      && string.ends_with(file, ".json")
    })
    |> list.map(fn(file) {
      string.drop_start(
        string.drop_end(file, string.length(".json")),
        string.length("climate_data_"),
      )
    })

  let assert Ok(samples) =
    taskle.parallel_map(
      cities,
      fn(city_name) {
        let file_path =
          data_dir
          <> "/"
          <> "climate_data_"
          <> string.lowercase(city_name)
          <> ".json"

        io.println(
          "Reading data for "
          <> string.capitalise(city_name)
          <> " from "
          <> file_path,
        )

        let assert Ok(samples) = model.read_samples_from_file(file_path)
        #(city_name, samples)
      },
      5000,
    )

  let city_names = list.map(cities, string.lowercase)

  let assert Ok(Nil) = {
    use directory <- temporary.create(temporary.directory())

    // Generate pages for each city
    let assert Ok(_) =
      taskle.parallel_map(
        samples,
        fn(pair) {
          let #(city_name, samples) = pair
          let city_name_lower = string.lowercase(city_name)
          let title = "Climate Data for " <> string.capitalise(city_name)

          io.println("Generating page for " <> string.capitalise(city_name))

          // This is the slowest part:
          let content = infographic.from(samples)

          let path = directory <> "/" <> city_name_lower <> ".html"
          must_write_page(path, title, city_names, city_name_lower, content)
          Nil
        },
        5000,
      )
      as "generating pages"

    let assert Ok(_) = simplifile.delete(output_dir) as "cleaning dist"
    let assert Ok(_) = simplifile.create_directory(output_dir)
      as "creating dist"
    let assert Ok(_) = simplifile.copy_directory(directory, output_dir)
      as "copying to dist"

    Nil
  }
}

fn must_write_page(
  path: String,
  title: String,
  cities: List(String),
  current_city: String,
  content: Element(msg),
) -> Nil {
  let assert Ok(Nil) =
    content
    |> page.from(title, cities, current_city, _)
    |> element.to_document_string
    |> simplifile.write(to: path)
  Nil
}
