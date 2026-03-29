module Main (main) where

import Lib

main :: IO ()
main = 
  do 
      putStrLn "Enter input for parsing: "
      input <- getContents
      parseResult <- jsonParserIO input
      putStrLn $ "Parsed JSON value: " ++ show parseResult
