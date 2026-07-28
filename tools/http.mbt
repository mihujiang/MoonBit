///|
/// HttpTool lets an Agent make HTTP GET and POST requests.
///
/// The actual HTTP call is injected via a `fetch` callback so the tool
/// works on all targets (native, JS, wasm-gc) without depending on a
/// specific HTTP library. On JS targets, you can use the platform
/// `fetch`; on native, use `oboard/mio` or `@async/http`.
///
/// The callback receives url, method ("GET" or "POST"), optional
/// headers (JSON string or ""), and optional body. It returns the
/// response body as a string.
///
/// Example:
/// ```moonbit nocheck
/// let http = HttpTool::new(fn(url, method, headers, body) {
///   // delegate to oboard/mio or JS fetch
/// })
/// ```
struct HttpTool {
  fetch : (String, String, String, String) -> String
}

///|
pub fn HttpTool::new(
  fetch : (String, String, String, String) -> String,
) -> HttpTool {
  { fetch, }
}

///|
pub impl Tool for HttpTool with fn name(_self : HttpTool) -> String {
  "http_request"
}

///|
pub impl Tool for HttpTool with fn description(_self : HttpTool) -> String {
  "Make an HTTP request to a URL. Input must be a JSON object with fields: url (required), method (GET or POST, default GET), headers (optional JSON object), body (optional request body string for POST). Returns the response body as text."
}

///|
pub impl Tool for HttpTool with fn args_schema(_self : HttpTool) -> Json {
  let props : Map[String, Json] = Map([])
  props["url"] = param(
    "string", "The URL to request, e.g. https://api.example.com/data",
  )
  props["method"] = param("string", "HTTP method: GET or POST (default: GET)")
  props["headers"] = param("string", "Optional JSON object of request headers")
  props["body"] = param("string", "Optional request body (for POST)")
  object_schema(props, ["url"])
}

///|
pub impl Tool for HttpTool with fn run(self : HttpTool, input : Json) -> String {
  match input {
    Json::Object(map) => {
      let url = match map.get("url") {
        Some(Json::String(s)) => s
        _ => return "Error: missing 'url' field"
      }
      let method = match map.get("method") {
        Some(Json::String(s)) => s
        _ => "GET"
      }
      let headers = match map.get("headers") {
        Some(Json::String(s)) => s
        _ => ""
      }
      let body = match map.get("body") {
        Some(Json::String(s)) => s
        _ => ""
      }
      (self.fetch)(url, method, headers, body)
    }
    _ => "Error: input is not a JSON object"
  }
}

///|
pub extend HttpTool with Tool::{name, description, args_schema, run}
