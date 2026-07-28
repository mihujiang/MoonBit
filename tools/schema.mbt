///|
/// Schema helpers for building Tool JSON schemas.
///
/// Building raw `Map[String, Json]` by hand is verbose and error-prone.
/// This module provides convenience constructors for the common cases.

///|
/// Build a JSON schema for a single-param tool with one required
/// string field. This covers ~80% of simple tools.
pub fn tool_schema(name : String, typ : String, description : String) -> Json {
  let props : Map[String, Json] = Map([])
  props[name] = param(typ, description)
  object_schema(props, [name])
}

///|
/// Build a JSON schema for a parameterless tool.
pub fn tool_schema_no_params() -> Json {
  let props : Map[String, Json] = Map([])
  object_schema(props, [])
}

///|
/// Create a single JSON Schema parameter definition.
pub fn param(typ : String, description : String) -> Json {
  let p : Map[String, Json] = Map([])
  p["type"] = Json::string(typ)
  p["description"] = Json::string(description)
  Json::object(p)
}

///|
/// Build a full `{ type: object, properties, required }` schema.
fn object_schema(
  properties : Map[String, Json],
  required : Array[String],
) -> Json {
  let req : Array[Json] = []
  for r in required {
    req.push(Json::string(r))
  }
  let schema : Map[String, Json] = Map([])
  schema["type"] = Json::string("object")
  schema["properties"] = Json::object(properties)
  schema["required"] = Json::array(req)
  Json::object(schema)
}
