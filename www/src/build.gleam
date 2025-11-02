import gleam/string

import lustre/element.{type Element}
import simplifile
import temporary

import infographic
import model
import page

const root_dir = ".."

const output_dir = root_dir <> "/dist"

pub fn main() {
  let city_name = "Berlin"
  let samples = read_samples_for_city(city_name)

  let assert Ok(Nil) = {
    use directory <- temporary.create(temporary.directory())

    let index_page = infographic.from(samples)
    must_write_page(
      directory <> "/index.html",
      "Climate Infographic - " <> city_name,
      index_page,
    )

    let assert Ok(_) = simplifile.delete(output_dir) as "cleaning dist"
    let assert Ok(_) = simplifile.create_directory(output_dir)
      as "creating dist"
    let assert Ok(_) = simplifile.copy_directory(directory, output_dir)
      as "copying to dist"

    Nil
  }
}

fn must_write_page(path: String, title: String, content: Element(msg)) -> Nil {
  let assert Ok(Nil) =
    content
    |> page.from(title, _)
    |> element.to_document_string
    |> simplifile.write(to: path)
  Nil
}

fn read_samples_for_city(city_name: String) -> List(model.Sample) {
  let file_name =
    root_dir <> "/climate_data_" <> string.lowercase(city_name) <> ".json"
  let assert Ok(data) = model.read_samples_from_file(file_name)
  data
}
