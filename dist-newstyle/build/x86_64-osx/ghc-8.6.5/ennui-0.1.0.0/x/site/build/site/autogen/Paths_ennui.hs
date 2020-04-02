{-# LANGUAGE CPP #-}
{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
module Paths_ennui (
    version,
    getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir,
    getDataFileName, getSysconfDir
  ) where

import qualified Control.Exception as Exception
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude

#if defined(VERSION_base)

#if MIN_VERSION_base(4,0,0)
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#else
catchIO :: IO a -> (Exception.Exception -> IO a) -> IO a
#endif

#else
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#endif
catchIO = Exception.catch

version :: Version
version = Version [0,1,0,0] []
bindir, libdir, dynlibdir, datadir, libexecdir, sysconfdir :: FilePath

bindir     = "/Users/eben/.cabal/bin"
libdir     = "/Users/eben/.cabal/lib/x86_64-osx-ghc-8.6.5/ennui-0.1.0.0-inplace-site"
dynlibdir  = "/Users/eben/.cabal/lib/x86_64-osx-ghc-8.6.5"
datadir    = "/Users/eben/.cabal/share/x86_64-osx-ghc-8.6.5/ennui-0.1.0.0"
libexecdir = "/Users/eben/.cabal/libexec/x86_64-osx-ghc-8.6.5/ennui-0.1.0.0"
sysconfdir = "/Users/eben/.cabal/etc"

getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir, getSysconfDir :: IO FilePath
getBinDir = catchIO (getEnv "ennui_bindir") (\_ -> return bindir)
getLibDir = catchIO (getEnv "ennui_libdir") (\_ -> return libdir)
getDynLibDir = catchIO (getEnv "ennui_dynlibdir") (\_ -> return dynlibdir)
getDataDir = catchIO (getEnv "ennui_datadir") (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "ennui_libexecdir") (\_ -> return libexecdir)
getSysconfDir = catchIO (getEnv "ennui_sysconfdir") (\_ -> return sysconfdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
