module Lib
    ( jsonParserIO
    ) where
import JsonParser (runParser, jsonString, jsonValue, JsonValue(..), ParseError(..))


jsonParserIO :: String -> IO (Either ParseError JsonValue)
jsonParserIO input = case runParser jsonValue input of
    ("", Right value) -> return $ Right value
    (remaining, Left err) -> return $ Left $ ParseError $ "Parsing error: " ++ show (case err of ParseError msg -> msg) ++ ", remaining input: " ++ remaining
    
