import nake, browsers, strutils
import os, ospaths


task defaultTask, "Build example app":
    for oldfilepath in walkDirRec("example"):
        if oldfilepath.endsWith(".html") or oldfilepath.endsWith(".css") or oldfilepath.endsWith(".js"):
            let newfilepath = oldfilepath.replace("example", "build")
            let newparent = newfilepath.parentDir()
            if not existsDir(newparent):
                createDir(newparent)
            copyFile(oldfilepath, newfilepath)
        elif oldfilepath.endsWith("app.nim"):
            let newfilepath = oldfilepath.replace("example", "build")
            let newparent = newfilepath.parentDir()
            if not existsDir(newparent):
                createDir(newparent)

            direShell nimExe, "js", "--warning[LockLevel]:off", "--nimcache:nimcache", oldfilepath
            
            let jsfilename = oldfilepath.extractFilename().replace(".nim", ".js")
            copyFile("nimcache" / jsfilename, newparent / jsfilename)

    openDefaultBrowser("file://" & (getCurrentDir() / "build" / "index.html"))