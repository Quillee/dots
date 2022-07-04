$home = $env:LOCALAPPDATA
$nvim_plugin_folder = 'C:\tools\neovim\nvim-win64\share\nvim\runtime\plugin'
$nvim_config_folder = '${home}\nvim'
$nvim_lua_folder = 'C:\tools\neovim\nvim-win64\bin\lua\'
$folders =  @($nvim_plugin_folder, $nvim_config_folder, $nvim_lua_folder)

foreach ($n in $folders) {
    if (Test-Path -Path $n){
        "Folder exists: $n"
    } else {
        mkdir -p $n
    }
}

cp -r -Force plugins/*.vim $nvim_plugin_folder
cp -r -Force plugins/*.lua  $nvim_lua_folder
cp -r -Force init.lua $nvim_config_folder