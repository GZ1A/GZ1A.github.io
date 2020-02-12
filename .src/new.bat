@echo off
pushd ..\..\
echo.
set /p name=  new article title:
hugo new post\\"%name%".md
popd
"%name%.md"