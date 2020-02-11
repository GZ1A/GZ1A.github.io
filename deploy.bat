@echo off
set pan=.\public\
set repo=https://github.com/GZ1A/GZ1A.github.io.git
set branch=master
set default=1

if exist %pan% (
    
    echo "clean public directory"
    rd /S /Q %pan%
    echo "Hugo again for new site"
    hugo
) else (
    echo "can not find public directory"
    echo "Hugo again for new site"
    set default=1
    hugo
)

setlocal enabledelayedexpansion
if exist %pan% (
    cd %pan%
    echo "git commit"
    git add -A
    echo.
    set /p commitMessage=Commit Message:
    if "!commitMessage!"=="" (
        set commitMessage=update site
    )
    git commit -m "%commitMessage% at %time%"
    echo "set remote repository and push forcely"
    git remote add origin %repo%
    git push origin master
    REM git init
    REM git push -f origin master
) else (
    echo "can not find public directory, hugo fail!"
    set default=0
)
endlocal

if %default% neq 1 (
    pause
)