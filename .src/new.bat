@echo off
set siteSrcPath=.\
pushd %siteSrcPath%
echo.
set /p name="  new article title:"
hugo new post\\"%name%.md"
popd
"content\post\%name%.md"