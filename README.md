# json-parser-with-combinators

A small Haskell JSON parser implemented with parser combinators.

## Running the project

Use Stack to build and run the project:

```bash
stack build
stack exec json-parser-with-combinators-exe
```

Then enter input for parsing when prompted.

Example Windows input:

```text
{ "key" : -1.23, "flag" : true, "items" : [1, 2, 3], "name" : "Alice", "data" : null }
```

On Windows, press Enter and then Ctrl+Z to submit EOF.

Example output:

```text
Parsed JSON value: Right (JsonObject (fromList [("key",JsonNumber (-1.23)),("items",JsonArray [JsonNumber 1.0,JsonNumber 2.0,JsonNumber 3.0]),("name",JsonString "Alice"),("data",JsonNull),("flag",JsonBool True)]))
```

To run tests:

```bash
stack test --fast
```

## Sample input

The parser supports JSON values such as objects, arrays, strings, numbers, booleans, and null.

Example:

```haskell
runParser jsonValue "{ \"key\" : -1.23, \"flag\" : true, \"items\" : [1, 2, 3], \"name\" : \"Alice\", \"data\" : null }"
```

Expected output:

```haskell
("",Right (JsonObject (fromList [("key",JsonNumber (-1.23)), ("flag",JsonBool True), ("items",JsonArray [JsonNumber 1.0,JsonNumber 2.0,JsonNumber 3.0]), ("name",JsonString "Alice"), ("data",JsonNull)])))
```