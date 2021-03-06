module Main where

import Debug.Trace
import Data.Either
import Data.Maybe
import Data.Foldable (for_)
import Control.Monad.Eff
import Node.Express.Internal.QueryString


type Test a b = { input :: a, output :: b }

doTest :: forall a b e. (Show b, Eq b)
       => (Test a b -> b) -> Test a b -> Eff ( trace :: Trace | e) Unit
doTest testFn test =
    let result = testFn test
        printPassed = trace "✔︎"
        printFailed =
            trace ("✗\n\tExpected: \""
                  ++ show test.output
                  ++ "\"\n\tGot: \""
                  ++ show result
                  ++ "\"")
    in if result /= test.output then printFailed else printPassed

queryParserTests =
    [ {input: "a=b",        output: Right [Param "a" "b"]}
    , {input: "a=b&b=c",    output: Right [Param "a" "b", Param "b" "c"]}
    , {input: "a[123]=&b=", output: Right [Param "a[123]" "", Param "b" ""]}
    , {input: "",           output: Right []}
    , {input: "a=b%20c",    output: Right [Param "a" "b c"]}
    , {input: "a=b+c",      output: Right [Param "a" "b c"]}
    , {input: "a=b=c",      output: Right [Param "a" "b=c"]}
    , {input: "a%3Db=c",    output: Right [Param "a=b" "c"]}
    ]

-- TODO: find out why this type is not inferring
queryGetOneTests :: [Test [Param] (Maybe String)]
queryGetOneTests =
    [ {input: [Param "b" "c"],                  output: Nothing}
    , {input: [],                               output: Nothing}
    , {input: [Param "a" "b"],                  output: Just "b"}
    , {input: [Param "a" "b", Param "a" "c"],   output: Just "b"}
    ]

queryGetAllTests =
    [ {input: [Param "b" "c"],                  output: []}
    , {input: [],                               output: []}
    , {input: [Param "a" "b"],                  output: ["b"]}
    , {input: [Param "a" "b", Param "a" "c"],   output: ["b", "c"]}
    ]


main = do
    trace "Testing parser"
    for_ queryParserTests $ doTest (\t -> parse t.input)
    trace "Testing getters (one value)"
    for_ queryGetOneTests $ doTest (\t -> getOne t.input "a")
    trace "Testing getters (all values)"
    for_ queryGetAllTests $ doTest (\t -> getAll t.input "a")
