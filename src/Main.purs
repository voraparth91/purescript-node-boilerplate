module Main where

import Data.Array
import Data.Traversable
import Prelude hiding (apply)

import Control.Monad.Except (ExceptT(..), lift, runExceptT)
import Control.Monad.Reader (ReaderT(..), ask, runReaderT)
import Control.Monad.State (StateT(..), runStateT)
import Control.Monad.State (get) as State
import Data.Either (Either(..))
import Data.Generic.Rep (class Generic)
import Data.Generic.Rep.Show (genericShow)
import Data.Interval.Duration.Iso (Error)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Tuple (Tuple(..))
import Database.Redis (Connection, connect, defaultConfig, set)
import Database.Redis as Redis
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Aff.Class (liftAff)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Effect.Ref (new, Ref, read)
import Foreign.Generic (defaultOptions, genericEncodeJSON)
import Node.Express.App (App, listenHttp, get)
import Node.Express.Handler (Handler, HandlerM(..))
import Node.Express.Request (getRouteParam)
import Node.Express.Response (send)
import Node.HTTP (Server)
import Utils (sToBS)

foreign import getTime :: Unit -> Effect String

type GlobalState = { redisConn :: Connection }

newtype MyRecord = MyRecord { a :: String }
derive instance genericMyRecord :: Generic MyRecord _
instance showMyRecord :: Show MyRecord where show = genericShow

opts = defaultOptions { unwrapSingleConstructors = true }

myhandler :: Ref GlobalState -> Handler
myhandler globalST = do
    reqData <- getRouteParam "reqdata"
    s <- liftEffect $ read globalST
    _ <- liftAff $ (Redis.set s.redisConn (sToBS "key") (sToBS $ fromMaybe "{}" reqData) Nothing Nothing)
    resp <- liftAff $ (Redis.get s.redisConn (sToBS "key"))
    send $ fromMaybe (sToBS "Nothing Received") resp

perfHandler :: Ref GlobalState -> Handler
perfHandler globalST = do
    arr <- pur sreplicate 1000000 "Hi")
    a <- liftEffect $ getTime unit
    _ <- for arr \n -> do
        pure $ (genericEncodeJSON opts (MyRecord { a: "Hello World" }))
    b <- liftEffect $ getTime unit
    send (a <> " -- " <> b)

timeHandler :: Ref GlobalState -> Handler
timeHandler globalST = do
    a <- liftEffect $ getTime unit
    send a

redisConnect :: Aff Connection
redisConnect = connect defaultConfig

upHandler :: Ref GlobalState -> Handler
upHandler globalST = do
    s <- liftAff (runExceptT (runReaderT (runStateT (myMonadRunner "UP") { valS : "state"}) { valR : "reader"}))
    send "UP"

myMonadRunner:: String -> StateT { valS::String } (ReaderT { valR:: String} (ExceptT Error Aff)) String
myMonadRunner str = do
    _ <- State.get
    _ <- lift $ ask
    pure $ "UP"

myRandomAff :: String -> Aff String
myRandomAff str = do
    pure $ str

randomReaderT :: String -> ReaderT { val:: String } HandlerM String
randomReaderT str = do
    _ <- ask
    pure $ str

randomState :: String -> StateT { val:: String } HandlerM String
randomState str = do
    _ <- State.get
    pure $ str

randomEither :: String -> ExceptT Error HandlerM String
randomEither str = do
    pure $ str

app :: Ref GlobalState -> App
app globalST = do
    --get "/:reqdata" (myhandler globalST)
    get "/encode" $ send (genericEncodeJSON opts (MyRecord { a: "Hello World" }))
    get "/perf" $ (perfHandler globalST)
    get "/hello" $ send "Hello World"
    get "/time" $ (timeHandler globalST)
    get "/up" $ (upHandler globalST)

main :: Effect Unit
main = do
    launchAff_ initApp

initApp :: Aff Server
initApp = do
    conn        <- redisConnect
    globalST    <- liftEffect $ new { redisConn : conn}
    liftEffect $ listenHttp (app globalST) 8080 \_ ->
        log $ "Listening on " <> show 8080