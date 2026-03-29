module Main (main) where

import Test.Hspec
import Data.HashMap.Strict (fromList)
import JsonParser (runParser, jsonString, jsonValue, JsonValue(..))

main :: IO ()
main = hspec $ describe "JsonParser" $ do
  describe "jsonString" $ do
    it "parses a simple JSON string" $ do
      runParser jsonString "\"hello\"" `shouldBe` ("", Right "hello")

    it "parses a JSON string with trailing whitespace" $ do
      runParser jsonString "\"hello\"   " `shouldBe` ("", Right "hello")

    it "parses escaped newline characters" $ do
      runParser jsonString "\"line1\\nline2\"" `shouldBe` ("", Right "line1\nline2")

  describe "jsonValue" $ do
    it "parses a JSON string value into JsonString" $ do
      runParser jsonValue "\"hello world\"" `shouldBe` ("", Right (JsonString "hello world"))

    it "parses a JSON object with string, number, object, array, and null values" $ do
      let input = "{ \"name\" : \"Alice\", \"age\" : 30, \"address\" : { \"city\" : \"NY\" }, \"tags\" : [ \"x\", \"y\" ], \"spouse\" : null }"
      runParser jsonValue input `shouldBe`
        ("", Right (JsonObject (fromList
          [ ("name", JsonString "Alice")
          , ("age", JsonNumber 30)
          , ("address", JsonObject (fromList [("city", JsonString "NY")]))
          , ("tags", JsonArray [JsonString "x", JsonString "y"])
          , ("spouse", JsonNull)
          ])))
