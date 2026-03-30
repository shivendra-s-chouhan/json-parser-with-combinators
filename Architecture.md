# Architecture

## Overview

`json-parser-with-combinators` is a small Haskell project that parses JSON values using hand-written parser combinators. The core parsing logic lives in `src/JsonParser.hs`, while the executable entrypoint is in `app/Main.hs` and a thin IO wrapper is provided in `src/Lib.hs`.

## Project Structure

- `src/JsonParser.hs`
  - Implements a custom `Parser` type and parser combinator library.
  - Defines JSON AST types in `JsonValue`.
  - Exposes parsers for JSON values: `jsonValue`, `jsonString`, `jsonNumber`, `jsonBool`, `jsonObject`, `jsonArray`, and helpers like `char`, `string`, `spaces`, `symbol`, `between`, and `try`.
- `src/Lib.hs`
  - Provides `jsonParserIO`, which runs `jsonValue` against input text and returns an `Either ParseError JsonValue` result.
  - Wraps parsed results into a simple IO-friendly interface.
- `app/Main.hs`
  - Reads input from standard input.
  - Calls `jsonParserIO`.
  - Prints the resulting parse success or error.
- `test/Spec.hs`
  - Contains Hspec test cases for parser behavior.

## Parser Architecture

### Parser type

The parser is defined as:

```haskell
newtype Parser a = Parser { runParser :: String -> (String, Either ParseError a) }
```

A parser consumes a `String` and returns the remaining input plus either a `ParseError` or a parsed value.

### Core typeclasses

`Parser` supports:

- `Functor` for mapping parsed results,
- `Applicative` for sequencing parsers,
- `Monad` for dependent parsing logic,
- `Alternative` for choice and backtracking.

This combination allows building complex parsers from small reusable building blocks.

### Primitive combinators

Key primitive combinators include:

- `any_` — consumes one character,
- `satisfy` — consumes a character if it matches a predicate,
- `char` / `string` — match exact text,
- `spaces` / `symbol` — consume whitespace and tokens,
- `between` — parse a value between two delimiters,
- `sepBy` / `sepBy1` — parse comma-separated lists,
- `try` — allow backtracking when an alternative fails after consuming no input.

### JSON parsers

`JsonParser` composes specific JSON parsers:

- `jsonString` — parses quoted strings with escape sequences,
- `jsonNumber` — parses numeric values as `Double`,
- `jsonBool` — parses `true` or `false`,
- `jsonNull` — parses the literal `null`,
- `jsonArray` — parses arrays of `JsonValue`,
- `jsonObject` — parses objects as `HashMap String JsonValue`,
- `jsonValue` — top-level choice between all JSON value types.

### JSON AST

The parsed result is represented by the `JsonValue` type:

```haskell
data JsonValue
  = JsonString String
  | JsonNumber Double
  | JsonObject (HashMap String JsonValue)
  | JsonArray [JsonValue]
  | JsonBool Bool
  | JsonNull
```

## Runtime flow

1. `app/Main.hs` reads input from stdin.
2. `jsonParserIO` runs `runParser jsonValue` on the input.
3. If parsing succeeds and consumes all input, the parsed `JsonValue` is returned.
4. If parsing fails, a `ParseError` with message and remaining input is returned.

## Build and test

The project uses Stack and defines:

- library source in `src`,
- executable source in `app`,
- tests in `test`.

Run the project with:

```bash
stack build
stack exec json-parser-with-combinators-exe
```

Run tests with:

```bash
stack test --fast
```
