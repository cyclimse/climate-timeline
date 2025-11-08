import gleam/float
import gleam/int

pub const highlight = "#0000FF"

pub const event_highlight = highlight

pub const max_temp_highlight = "#FF4500"

// Color quantization steps
pub const hue_quantize_step = 15.0

pub const saturation_quantize_step = 10.0

pub const lightness_quantize_step = 5.0

/// Quantize a float value to the nearest multiple of a step size.
/// Used to reduce the number of unique colors in the palette.
pub fn quantize_value(value: Float, step: Float) -> Float {
  let rounded = value /. step
  let rounded_int = float.round(rounded)
  int.to_float(rounded_int) *. step
}
