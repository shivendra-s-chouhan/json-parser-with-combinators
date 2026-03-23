module JsonParser ()
   where

import Control.Applicative(Alternative(..))
import Control.Applicative (Applicative(..))




newtype Parser a = Parser { runParser :: String -> (String, Either ParseError a) }  -- a is the type of the value that the parser will produce e.g. JsonValue

data ParseError = ParseError String
                deriving (Show, Eq)

instance Functor Parser where
  fmap f (Parser p) = Parser $ \input ->     -- (Parser p) is unwrapping the Parser to get the function p
    let (rest, result) = p input
    in (rest, case result of 
        Left err -> Left err
        Right value -> Right (f value))

-- since Parser a must wrap a function of type String -> (String, Either ParseError a), any will take a String input and return a tuple of the remaining String and either a ParseError or a Char (the next character in the input). 
any_ :: Parser Char 
any_ = Parser $ \input -> case input of   -- Parser is a constructor to which we are passing a function (\input -> case input of ...)
    [] -> ([], Left (ParseError "Unexpected end of input"))
    (x:xs) -> (xs, Right x)


eof :: Parser ()
eof = Parser $ \input -> case input of
    [] -> ([], Right ())
    _  -> (input, Left (ParseError "Expected end of input"))

-- pure injects a value into the Parser context

-- <*> is the applicative operator that takes a Parser that produces a function (Parser pf) and another Parser that produces a value (Parser pa), and returns a new Parser that applies the function produced by pf to the value produced by pa. 

--p1 = pure (+1)        :: Parser (Int -> Int)
--p2 = pure 5           :: Parser Int
--runParser (p1 <*> p2) "input"   this will run p1 on input to get a function (in this case, the function (+1)), and then run p2 on the remaining input to get a value (in this case, 5). The result will be the application of the function to the value, which is 6. 

-- <*> = “run left parser, then right parser, then combine results”
instance Applicative Parser where 
  pure x = Parser $ \input -> (input, Right x) -- pure takes a value x and returns a Parser that does not consume any input and simply returns x as the result. The function \input -> (input, Right x) is a lambda function that takes the input string and returns a tuple where the first element is the unchanged input (since pure does not consume anything) and the second element is Right x, indicating a successful parse with the value x.
  Parser pf <*> Parser pa = Parser $ \input -> 
    let (rest1, resultF) = pf input
    in case resultF of 
        Left err -> (rest1, Left err) -- If the first parser fails, we return the error immediately without trying to parse with the second parser.
        Right f -> 
          let (rest2, resultA) = pa rest1
           in case resultA of
                Left err -> (rest2, Left err) -- If the second parser fails, we return that error.
                Right a -> (rest2, Right (f a)) 
  Parser a *> Parser b = Parser $ \input ->
    let (rest1, resultB) = b input
    in case resultB of
        Left err -> (rest1, Left err) -- If the second parser fails, we return that error.
        Right x -> (rest1, Right x) -- If the second parser succeeds, we return its result, ignoring the result of the first parser.
  Parser a <* Parser b = Parser $ \input ->
    let (rest1, resultA) = a input
    in case resultA of
        Left err -> (rest1, Left err) -- If the first parser fails, we return that error. 
        Right a -> (rest1, Right a) -- If the first parser succeeds, we return its result, ignoring the result of the second parser.
  
 {-- 
  a <$ Parser b = Parser $ \input -> 
    let (rest1, resultB) = b input
    in case resultB of
        Left err -> (rest1, Left err) -- If the second parser fails, we return that error.
        Right _ -> (rest1, Right a) -- If the second parser succeeds, we return the value a, ignoring the result of the second parser.
--}

-- >>= = “run a parser, take its result, and use it to decide what parser to run next”
instance Monad Parser where
  return x = Parser $ \input -> (input, Right x) -- return is the same as pure, it takes a value and returns a Parser that produces that value without consuming any input. 

  (>>=) (Parser p) f = Parser $ \input -> 
    let (rest, result) = p input 
    in case result of 
        Left err -> (rest, Left err) -- if the first parse fails, return the error immediately 
        Right value -> runParser (f value) rest -- if the first parse succeeds, we take the resulting value and pass it to the function f, which returns a new Parser. We then run that Parser on the remaining input (rest) to get the final result. The "runParser" function is used to extract the function from the Parser returned by f

-- try is a combinator that allows us to attempt a parser and, if it fails, to backtrack and try another parser without consuming any input. This is useful for handling alternatives in our grammar. For example, if we have a parser that tries to parse a number but fails, we can use try to backtrack and attempt to parse a string instead.
try :: Parser a -> Parser a
try (Parser p) = Parser $ \input -> case p input of
    (rest, Left err) -> (input, Left err) -- If the parser fails, we return the original input and the error
    success -> success -- If the parser succeeds, we return its result as is.


-- <|> is a combinator that allows us to try one parser, and if it fails, to try another parser as an alternative. It is often used to handle different possible inputs in a grammar. For example, if we want to parse either a number or a string, we can use the <|> operator to try parsing a number first, and if that fails, to try parsing a string.
instance Alternative Parser where
  empty = Parser $ \input -> (input, Left (ParseError "No alternative")) -- empty represents a parser that always fails. It takes the input and returns it unchanged, along with a ParseError indicating that there are no alternatives.

-- <|> :: Parser a -> Parser a -> Parser a
  Parser p1 <|> Parser p2 = Parser $ \input -> case p1 input of 
    (rest, Left err)
      | rest == input -> p2 input -- if the first parser fails without consuming any input, we try the second parser
      | otherwise -> (rest, Left err)
    success -> success -- if the first parser succeeds, we return its result without trying the second parser

-- this is a helper function that takes a name for the expected input and a list of parsers, and tries each parser in the list until one succeeds. If all parsers fail, it returns a ParseError with a message indicating what was expected.
choice :: String -> [Parser a] -> Parser a
choice name = foldr (<|>) noMatch
  where noMatch = Parser $ \input -> (input, Left (ParseError $ "Expected " ++ name)) 

satisfy :: String -> (Char -> Bool) -> Parser Char
satisfy name predicate = try $ do
    c <- any_
    if predicate c
        then return c
        else Parser $ \input -> (input, Left (ParseError $ "Expected " ++ name ++ ", but got '" ++ [c] ++ "'"))


many :: Parser a -> Parser [a]
many p = many1 p <|> pure [] -- many tries to apply the parser p one or more times, and if it fails, it returns an empty list.
many1 :: Parser a -> Parser [a]
many1 p = do 
    first <- p 
    rest <- many p 
    return (first : rest) -- many1 requires at least one successful parse of p. It first parses one instance of p to get the "first" value, and then it uses many to parse zero or more additional instances of p to get the "rest" of the list. Finally, it combines the first value with the rest of the list and returns it as a single list.

sepBy :: Parser a -> Parser sep -> Parser [a]
sepBy p sep = sepBy1 p sep <|> pure [] -- sepBy tries to parse one or more instances of p separated by sep. If it fails, it returns an empty list.
sepBy1 :: Parser a -> Parser sep -> Parser [a]
sepBy1 p sep = do
    first <- p
    rest <- many (sep *> p) -- sepBy1 requires at least one successful parse of p. It first parses one instance of p to get the "first" value, and then it uses many to parse zero or more additional instances of p, each preceded by the separator sep. The expression (sep *> p) means that we first parse the separator and then parse another instance of p, but we ignore the result of the separator and only keep the result of p.
    return (first : rest) -- Finally, it combines the first value with the rest of the list and returns it as a single list.

  
data JsonValue = JsonString String
               | JsonNumber Double
               | JsonObject HashMap String JsonValue
               | JsonArray [JsonValue]
               | JsonBool Bool
               | JsonNull
               deriving (Show, Eq)

char c = satisfy [c] (== c) -- char is a parser that takes a character c and returns a parser that succeeds if the next character in the input is c, and fails otherwise. It uses the satisfy function to check if the next character matches c.

space = satisfy "whitespace" isSpace -- space is a parser that succeeds if the next character in the input is a whitespace character (such as space, tab, or newline), and fails otherwise. It uses the satisfy function with the isSpace predicate to check for whitespace characters.

digit = satisfy "digit" isDigit -- digit is a parser that succeeds if the next character in the input is a digit (0-9), and fails otherwise. It uses the satisfy function with the isDigit predicate to check for digit characters.

string = traverse char -- string is a parser that takes a string as input and returns a parser that succeeds if the next characters in the input match the given string, and fails otherwise. It uses the traverse function to apply the char parser to each character in the input string, effectively checking for a sequence of characters.
  
spaces = many space -- spaces is a parser that succeeds if the next characters in the input are zero or more whitespace characters, and fails otherwise. It uses the many combinator to apply the space parser repeatedly until it fails, effectively consuming all leading whitespace characters.

symbol s = string s <* spaces -- symbol is a parser that takes a string s and returns a parser that succeeds if the next characters in the input match s, followed by zero or more whitespace characters. It uses the string parser to check for the exact sequence of characters in s, and then it uses the <* operator to consume any trailing whitespace after successfully matching s.

between open close value = open *> value <* close -- between is a combinator that takes three parsers: open, close, and value. It returns a parser that succeeds if the input starts with the open parser, followed by the value parser, and ends with the close parser. The *> operator is used to ignore the result of the open parser, and the <* operator is used to ignore the result of the close parser, so that only the result of the value parser is returned. This is useful for parsing structures that are enclosed by specific characters, such as parentheses or quotes.


brackets = between (symbol "[") (symbol "]") 

braces = betwee (symbol "{") (symbol "}")

jsonNumber = read <$> many1 digit -- jsonNumber is a parser that parses a sequence of digits and converts it into a Double. 

jsonBool = choice "JSON boolean"
  [True <$ symbol "true",
   False <$ symbol "false"] -- jsonBool is a parser that recognizes the literals "true" and "false" and returns the corresponding Boolean values. 

jsonNull = JsonNull <$ symbol "null" -- jsonNull is a parser that recognizes the literal "null" and returns the JsonNull value.

jsonString = between (char '"') (char '"') (many jsonChar) <* spaces 
  where 
      jsonChar = choice "JSON string character"
        [try $ '\n' <$ string "\\n",
         try $ '\t' <$ string "\\t",
         try $ '\\' <$ string "\\\\",
         try $ '"'  <$ string "\\\"",
         stisfy "non-quote, non-backslash character" (\c -> c /= '"' && c /= '\\')] 


jsonObject = do 
  assocList <- braces  $ jsonEntry `sepBy` symbol ","
  return $ fromList assocList
  where 
    jsonEntry = do 
      key <- jsonString
      symbol ":"
      value <- jsonValue
      return (key, value)

jsonArray = brackets $ jsonValue `sepBy` symbol "," 


jsonValue = choice "JSON value"
  [JsonString <$> jsonString,
   JsonNumber <$> jsonNumber,
   JsonObject <$> jsonObject,
   JsonArray <$> jsonArray,
   JsonBool <$> jsonBool,
   JsonNull <$> jsonNull
  ]