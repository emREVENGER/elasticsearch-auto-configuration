#Author YILMAZ EMRAH

$config_file = "install_elasticsearch.json"
$current_path = (Resolve-Path .\).Path

#Configuration par défaut
$current_task = "Download"
$install_option ="default"
$output_path = $current_path
$translation_file = "translation_data.psd1"
$language = "en"

#Récupération de la configuration elastic
$config_path = Join-Path -path  $current_path -ChildPath $config_file
$configuration = getConfig -path $config_path

#Récuperation des données de traduction

$translation_data = InitTranslateConfiguration

# Fonction d'initialisation de traduction
function InitTranslateConfiguration (){
    $translation_data = Import-LocalizedData -BaseDirectory $current_path -FileName $translation_file
    
    if ($configuration.elasticsearch.lang -eq "fr") {
        $message = $translation_data.message_fr
    } else {
        $message = $translation_data.message_en
    }
    return $message
}

# Fonction de récupération de config
function getConfig($path) {
    try {
        Get-Content -Raw -Path $path | ConvertFrom-Json
    } catch {
        Write-Error $translation_data.error.cannot_open_file + " $($path)" 
    }
}

# Fonction de décompression
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip($zip_file, $path_to_extract){
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip_file, $path_to_extract)
}

# Fonction d'affichage
function displayInstall($type, $message){
    Write-Host "---------------------------------------------------------------" -ForegroundColor Yellow -BackgroundColor Cyan
    if ($type -eq "INIT" ) {
        Write-Host "---------------- $($translation_data.install.install_message) ----------------" -ForegroundColor Cyan
    } ElseIf ($type -eq "DOWNLOAD") {
        Write-Host "-   $($translation_data.install.download_message)   - `n$message" -ForegroundColor White -BackgroundColor Blue
    } ElseIf ($type -eq "UNZIP") {
        Write-Host "$($translation_data.install.unzip_elastic) - $message"
    } Elseif ($type -eq "SERVICE") {
        Write-Host "$($translation_data.install.install_as_service) - $message"
    } ElseIf ($type -eq "CONFIGURATION") {
        Write-Host "$($translation_data.configuration.title) - $message"
    }
    Write-Host "---------------------------------------------------------------" -ForegroundColor Black -BackgroundColor Green
}

# Installation du service
function InstallAsService($service_name, $service_path){
    try {
        Invoke-Command | Join-Path -path $service_path -ChildPath $service_name
    } catch {
        Write-Error "Install service failed"
    }
}

# Téléchargement de ElasticSearch
function downloadElasticSearch($option, $configuration)
{
    try {
        $url = $configuration.download_url + "elasticsearch-" + $configuration.version + ".zip"

        if ($option -eq "custom_directory"){
            $output_path = $configuration.custom_directory    
        }
    
        $output_file = Join-Path -Path $output_path -ChildPath "elasticsearch-$($configuration.version).zip"
        displayInstall -type "DOWNLOAD" -message "$($translation_data.general.take_time) ---> $output_file"
    
        (New-Object Net.WebClient).DownloadFile($url, $output_file)

        Write-Host $translation_data.general.download_finished -ForegroundColor Green

        return $output_path

    } catch {
            Write-Error  "$($translation_data.error.check_configuration_file) - $($config_file) 
                    1 - $($translation_data.error.put_elastic_link)
                    2 - $($translation_data.error.put_elastic_version)
                    3 - $($translation_data.error.check_your_network)"  
    }
}

# Gère l'installation de elasticsearch
function InstallManager($config){
    if ($config.elasticsearch){
        if ($config.elasticsearch.install) {

            if ($config.elasticsearch.install.custom_directory) {
                $install_option = "custom_directory"   
            }

            #Telechargement
            $output_path = downloadElasticSearch -option $install_option $config.elasticsearch.install
            $download_status = "done"

            #Decompression
            if ($download_status -eq "done") {
                $elastic_file = Join-Path -Path $output_path -ChildPath "elasticsearch-$($config.elasticsearch.install.version).zip"
                displayInstall -type "UNZIP" -message "$($elastic_file) $($translation.general.to) $extract_path"
                Unzip -zip_file $elastic_file -path_to_extract $output_path
            }
        } 
    }
}

# Fonction de lancement de l'installation
function RunInstall(){
    displayInstall -type "INIT"
    InstallManager -config $configuration
}

RunInstall




