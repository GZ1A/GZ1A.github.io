@echo off
REM dont commit if DEBUG = 1
set debug=0

REM Const
set build=.\public
set dst=..\..\site
set repo=git@github.com:GZ1A/GZ1A.github.io.git

REM Var
set default=1

if exist %build% (
    echo "clean public directory"
    rd /S /Q %build%
    echo "Hugo again for new site"
    hugo
) else (
    echo "can not find public directory"
    echo "Hugo again for new site"
    set default=1
    hugo
)

REM delete old build
echo "delete old build"
pushd "%dst%"
for %%i in ("*.*") do (
    if not "%%i"==".gitignore" (
    if not "%%i"=="CNAME" (
        del /q "%%i"
    )
    )
)
for /d %%i in ("*.*") do (
    if not "%%i"==".src" (
    if not "%%i"==".git" (
        rd /q /s "%%i"
    )
    )
)
popd

xcopy "%build%" "%dst%" /s /q /f /h /y

setlocal enabledelayedexpansion
if exist !build! (
    cd !build!
    if !debug! neq 1 (

        REM Code for first time
        REM git init
        REM git remote add origin %repo%
        REM git push -f origin master

        echo "git pull"
        git pull origin master
        REM another remote repo
        git pull coding_repo master

        echo "git commit"
        git add -A
        echo.
        set /p commitMessage=Commit Message:
        if "!commitMessage!"=="" (
            set commitMessage=update site
        )
        git commit -m "!commitMessage!"

        echo "git push"
        git push origin master
        REM another remote repo
        git push coding_repo master
    )

) else (
    echo "can not find public directory, hugo fail!"
    set default=0
)
endlocal

if %default% neq 1 (
    pause
)
if %debug% neq 0 (
    pause
)