module Polysemy.Log.Colog.Test.ConcTest where

import Colog (LogAction(LogAction), defCapacity)
import Polysemy.Test (UnitTest, assertEq, runTestAuto)

import Polysemy.Log.Colog.Colog (interpretLogColog')
import Polysemy.Log.Colog.Conc (interpretCologConcNativeWith)
import qualified Polysemy.Log.Effect.Log as Log
import Polysemy.Log.Effect.Log (Log)
import qualified Polysemy.Log.Data.LogEntry as LogEntry
import Polysemy.Log.Data.LogEntry (LogEntry)
import Polysemy.Log.Data.LogMessage (LogMessage(LogMessage))
import qualified Polysemy.Log.Data.Severity as Severity
import Control.Concurrent.STM (newTVarIO, atomically, modifyTVar', readTVarIO)

prog ::
  Member Log r =>
  Sem r ()
prog = do
  Log.debug "debug"
  Log.warn "warn"

target :: [LogMessage]
target =
  [LogMessage Severity.Warn "warn", LogMessage Severity.Debug "debug"]

test_concColog :: UnitTest
test_concColog =
  runTestAuto do
    tv <- embed (newTVarIO [])
    let action msg = atomically (modifyTVar' tv (msg :))
    interpretCologConcNativeWith @(LogEntry LogMessage) defCapacity (LogAction action) (interpretLogColog' prog)
    msgs <- embed (readTVarIO tv)
    assertEq @_ @IO target (LogEntry.message <$> msgs)
