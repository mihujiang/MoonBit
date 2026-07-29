///|
/// config — unified configuration loader for moon-agent executables.
///
/// Provides `ChatConfig` struct and `load_config()` to read API settings
/// from `.env` / `config.json` at project root, with env var fallback.
///
/// Lookup order:
/// 1. `./.env` (simple KEY=VALUE format, recommended)
/// 2. `./config.json`
/// 3. `../.env` (parent directory, for executables in subdirs like `cmd/chat`)
/// 4. `../config.json`
/// 5. Environment variables: `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`
///
/// Example `.env`:
/// ```
/// OPENAI_API_KEY=sk-...
/// OPENAI_BASE_URL=https://api.deepseek.com
/// OPENAI_MODEL=deepseek-chat
/// ```
///
/// Example `config.json`:
/// ```json
/// {
///   "api_key": "sk-...",
///   "base_url": "https://api.deepseek.com",
///   "model": "deepseek-chat",
///   "max_tokens": 4096,
///   "system_prompt": ""
/// }
/// ```

///|
/// Configuration for connecting to an OpenAI-compatible LLM endpoint.
pub struct ChatConfig {
  api_key : String
  base_url : String
  model : String
  max_tokens : Int
  system_prompt : String
}

///|
/// Default config points to OpenAI's public endpoint with `gpt-4o`.
/// `api_key` is empty — caller must set it before use.
pub fn ChatConfig::default() -> ChatConfig {
  {
    api_key: "",
    base_url: "https://api.openai.com",
    model: "gpt-4o",
    max_tokens: 4096,
    system_prompt: "",
  }
}

///|
/// Load config from a JSON file at the given path.
/// Returns `None` if the file cannot be read, parsed, or lacks `api_key`.
pub fn load_config_from_file(path : String) -> ChatConfig? {
  let content = read_file_to_string(path)
  if content == "" {
    return None
  }
  let json = @json.parse(content) catch { _ => return None }
  match json {
    Json::Object(map) => {
      let api_key = get_str(map, "api_key", "")
      if api_key == "" {
        return None
      }
      let base_url = get_str(map, "base_url", "https://api.openai.com")
      let model = get_str(map, "model", "gpt-4o")
      let max_tokens = get_int(map, "max_tokens", 4096)
      let system_prompt = get_str(map, "system_prompt", "")
      Some({ api_key, base_url, model, max_tokens, system_prompt })
    }
    _ => None
  }
}

///|
/// Parse a `.env` format string into a `ChatConfig`.
/// Format: one `KEY=VALUE` per line, `#` lines are comments, blank lines ignored.
/// Supported keys: `OPENAI_API_KEY`, `OPENAI_BASE_URL`, `OPENAI_MODEL`.
fn load_config_from_dotenv_content(content : String) -> ChatConfig? {
  let mut api_key = ""
  let mut base_url = "https://api.openai.com"
  let mut model = "gpt-4o"
  let lines = content.split("\n")
  for line in lines {
    let trimmed = line.trim()
    // skip blank lines and comments
    if trimmed == "" || trimmed.has_prefix("#") {
      continue
    }
    let eq_pos = trimmed.find("=")
    match eq_pos {
      Some(pos) => {
        let key = trimmed[0:pos].to_owned().trim()
        let val = trimmed[pos + 1:trimmed.length()].to_owned().trim()
        match key {
          "OPENAI_API_KEY" => api_key = val.to_owned()
          "OPENAI_BASE_URL" => base_url = val.to_owned()
          "OPENAI_MODEL" => model = val.to_owned()
          _ => ()
        }
      }
      None => ()
    }
  }
  if api_key == "" {
    return None
  }
  Some({ api_key, base_url, model, max_tokens: 4096, system_prompt: "" })
}

///|
/// Load config from a `.env` file at the given path.
/// Returns `None` if the file cannot be read or lacks `OPENAI_API_KEY`.
pub fn load_config_from_env_file(path : String) -> ChatConfig? {
  let content = read_file_to_string(path)
  if content == "" {
    return None
  }
  load_config_from_dotenv_content(content)
}

///|
/// Load config from default locations, falling back to env vars.
///
/// Lookup order:
/// 1. `./.env`
/// 2. `./config.json`
/// 3. `../.env`
/// 4. `../config.json`
/// 5. Env vars: `OPENAI_API_KEY` (required), `OPENAI_BASE_URL`, `OPENAI_MODEL`
///
/// Returns `None` if no valid config found.
pub fn load_config() -> ChatConfig? {
  match load_config_from_env_file(".env") {
    Some(c) => return Some(c)
    None => ()
  }
  match load_config_from_file("config.json") {
    Some(c) => return Some(c)
    None => ()
  }
  match load_config_from_env_file("../.env") {
    Some(c) => return Some(c)
    None => ()
  }
  match load_config_from_file("../config.json") {
    Some(c) => return Some(c)
    None => ()
  }
  match @env.get_env_var("OPENAI_API_KEY") {
    Some(key) =>
      if key == "" {
        None
      } else {
        let base_url = match @env.get_env_var("OPENAI_BASE_URL") {
          Some(u) => u
          None => "https://api.openai.com"
        }
        let model = match @env.get_env_var("OPENAI_MODEL") {
          Some(m) => m
          None => "gpt-4o"
        }
        Some({
          api_key: key,
          base_url,
          model,
          max_tokens: 4096,
          system_prompt: "",
        })
      }
    None => None
  }
}

///|
/// Load config or abort with a helpful error message.
/// Use this in executables that always need API access.
pub fn load_config_or_abort() -> ChatConfig {
  match load_config() {
    Some(c) => c
    None => {
      println("Error: No API configuration found.")
      println("")
      println("To configure, create `.env` at project root:")
      println("  OPENAI_API_KEY=sk-...")
      println("  OPENAI_BASE_URL=https://api.deepseek.com")
      println("  OPENAI_MODEL=deepseek-chat")
      println("")
      println("Or create `config.json`:")
      println(
        "  { \"api_key\": \"sk-...\", \"base_url\": \"https://api.deepseek.com\", \"model\": \"deepseek-chat\" }",
      )
      println("")
      println(
        "Or set env vars: OPENAI_API_KEY, OPENAI_BASE_URL (optional), OPENAI_MODEL (optional)",
      )
      abort("No API configuration found")
    }
  }
}

///|
fn get_str(map : Map[String, Json], key : String, default : String) -> String {
  match map.get(key) {
    Some(Json::String(s)) => s
    _ => default
  }
}

///|
fn get_int(map : Map[String, Json], key : String, default : Int) -> Int {
  match map.get(key) {
    Some(Json::Number(n, ..)) => n.to_int()
    _ => default
  }
}
