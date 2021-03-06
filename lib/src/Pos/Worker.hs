{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE RankNTypes          #-}
{-# LANGUAGE RecordWildCards     #-}

-- | High level workers.

module Pos.Worker
       ( allWorkers
       ) where

import           Universum

import           Pos.Worker.Block (blkWorkers)
-- Message instances.
import           Pos.Chain.Txp (TxpConfiguration)
import           Pos.Context (NodeContext (..))
import           Pos.Core as Core (Config, configBlkSecurityParam,
                     configEpochSlots)
import           Pos.Infra.Diffusion.Types (Diffusion)
import           Pos.Infra.Network.CLI (launchStaticConfigMonitoring)
import           Pos.Infra.Network.Types (NetworkConfig (..))
import           Pos.Infra.Slotting (logNewSlotWorker)
import           Pos.Launcher.Resource (NodeResources (..))
import           Pos.Worker.Delegation (dlgWorkers)
import           Pos.Worker.Ssc (sscWorkers)
import           Pos.Worker.Update (usWorkers)
import           Pos.WorkMode (WorkMode)

-- | All, but in reality not all, workers used by full node.
allWorkers
    :: forall ext ctx m . WorkMode ctx m
    => Core.Config
    -> TxpConfiguration
    -> NodeResources ext
    -> [Diffusion m -> m ()]
allWorkers coreConfig txpConfig NodeResources {..} = mconcat
    [ sscWorkers coreConfig
    , usWorkers (configBlkSecurityParam coreConfig)
    , blkWorkers coreConfig txpConfig
    , dlgWorkers
    , [properSlottingWorker, staticConfigMonitoringWorker]
    ]
  where
    topology = ncTopology ncNetworkConfig
    NodeContext {..} = nrContext
    properSlottingWorker =
        const $ logNewSlotWorker $ configEpochSlots coreConfig
    staticConfigMonitoringWorker = const (launchStaticConfigMonitoring topology)
