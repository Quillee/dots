$home_appdata = $env:LOCALAPPDATA
$nvim_plugin_folder = 'C:\tools\neovim\nvim-win64\share\nvim\runtime\plugin'
$nvim_config_folder = '${home_appdata}\nvim'
$nvim_lua_folder = 'C:\tools\neovim\nvim-win64\bin\lua\'
$folders =  @($nvim_plugin_folder, $nvim_config_folder, $nvim_lua_folder)

foreach ($n in $folders) {
    if (Test-Path -Path $n){
        "Folder exists: $n"
    } else {
        mkdir -p $n
    }
}

""
"Copying files"
cp -r -Force lua/*.vim $nvim_plugin_folder
cp -r -Force lua/*.lua  $nvim_lua_folder
cp -r -Force init.lua $nvim_config_folder
"Done"

