//! JSONRPC message types
//! See https://www.jsonrpc.org/specification

use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};

pub const VERSION: &str = "2.0";

#[derive(Serialize, Deserialize, Debug)]
pub struct Message {
    jsonrpc: String,
    #[serde(flatten)]
    type_: Type,
}

impl Message {
    pub fn make_request(method: &str, params: Option<Params>, id: Option<Value>) -> Self {
        Message { jsonrpc: VERSION.to_string(), type_: Type::Request(Request { method: method.to_string(), params, id }) }
    }

    pub fn make_error_response(error: Error, id: Value) -> Self {
        Message { jsonrpc: VERSION.to_string(), type_: Type::Response(Response { result: None, error: Some(error), id }) }
    }

    pub fn make_response(result: Option<Value>, id: Value) -> Self {
        Message { jsonrpc: VERSION.to_string(), type_: Type::Response(Response { result, error: None, id }) }
    }

    pub fn version(&self) -> &str {
        self.jsonrpc.as_str()
    }

    pub fn is_request(&self) -> bool {
        matches!(self.type_, Type::Request(_))
    }

    pub fn is_response(&self) -> bool {
        matches!(self.type_, Type::Response(_))
    }

    pub fn request(self) -> Option<Request> {
        match self.type_ {
            Type::Request(req) => Some(req),
            _ => None,
        }
    }

    pub fn response(self) -> Option<Response> {
        match self.type_ {
            Type::Response(resp) => Some(resp),
            _ => None,
        }
    }
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(untagged)]
pub enum Type {
    Request(Request),
    Response(Response),
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Request {
    pub method: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub params: Option<Params>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub id: Option<Value>
}

#[derive(Serialize, Deserialize, Clone, Debug)]
#[serde(untagged)]
pub enum Params {
    ByPosition(Vec<Value>),
    ByName(Map<String, Value>)
}

impl Into<Value> for Params {
    fn into(self) -> Value {
        match self {
            Params::ByPosition(array) => Value::Array(array),
            Params::ByName(map) => Value::Object(map),
        }
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Response {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub result: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub error: Option<Error>,
    pub id: Value
}

impl Response {
    pub fn is_error(&self) -> bool {
        self.error.is_some()
    }
}

#[derive(Serialize, Deserialize, Debug)]
pub struct Error {
    code: i64,
    message: String,
    data: Option<Value>,
}

impl Error {
    pub fn parse_error() -> Self {
        Error { code: -32700, message: String::from("Parse error"), data: None }
    }

    pub fn invalid_request() -> Self {
        Error { code: -32600, message: String::from("Invalid Request"), data: None }
    }

    pub fn method_not_found() -> Self {
        Error { code: -32601, message: String::from("Method not found"), data: None }
    }

    pub fn invalid_params() -> Self {
        Error { code: -32602, message: String::from("Invalid params"), data: None }
    }

    pub fn internal_error() -> Self {
        Error { code: -32603, message: String::from("Internal error"), data: None }
    }
}
