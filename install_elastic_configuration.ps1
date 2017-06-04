$config_file = "install_elasticsearch.json"
$current_path = (Resolve-Path .\).Path

#Configuration par défaut

$install_option ="default"
$output_path = $current_path
$language = "en"

#Récuperation des données de traduction

function setTranslateConfiguration (){
    try {
        MyDscConfiguration -ConfigurationData 
    } catch {
        if ($language -eq "fr") {
            throw "Fichier de traduction introuvable ou érroné"
        }
        throw "Cannot find translation file or the file is invalid"
    }
}

echo $message_fr.install.install_as_service

function setLanguage($language){
    if ($language -eq "fr") {
        $message = $message_fr
    } else {
        $message = $message_en
    }
}
 
function getConfig($path) {
    try {
        Get-Content -Raw -Path $path | ConvertFrom-Json
    } catch {
        throw "Impossible d'ouvrir le fichier de configuration"
    }
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip($zip_file, $path_to_extract){
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zip_file, $path_to_extract)
}



function displayInstall($type, $message){
    Write-Output "------------------------------"
    if ($type -eq "INIT" ) {
        Write-Output "-----Install ElasticSearch----"
    } ElseIf ($type -eq "DOWNLOAD") {
        Write-Output "Download ElasticSearch ---> $message"
    } ElseIf ($type -eq "UNZIP") {
        Write-Output "UNZIPPING Elastic compress file ---> $message"
    } Elseif ($type -eq "SERVICE") {
        Write-Output "Install Elastic as the service ---> $message"
    }ElseIf ($type -eq "CONFIGURATION") {
        Write-Output "Configuration ---> $message"
    } ElseIf ($type -eq "ERROR") {
        Write-Output "Erreur ---> $message"
    }
    Write-Output "------------------------------"
}

function InstallAsService($service_name, $service_path){

    try {
        Invoke-Command | Join-Path -path $service_path -ChildPath $service_name
    } catch {
        throw "Install service failed"
    }
}

function downloadElasticSearch($option, $configuration){
    
        try {
            $url = $configuration.download_url + "elasticsearch-" + $configuration.version + ".zip"

            if ($option -eq "custom_directory"){
                $output_path = $configuration.custom_directory    
            }
    
            $output_file = Join-Path -Path $output_path -ChildPath "elasticsearch-$($configuration.version).zip"
            displayInstall -type "DOWNLOAD" -message "It can take between 2-10 min --- Begin To -> $output_file"

            #(New-Object Net.WebClient).DownloadFile($url, $output_file)

            displayInstall -type "DOWNLOAD" -message "Finished"
    
        } catch {
              throw "Vérifier le fichier de configuration
                     1 - Mettre la version de elasticsearch
                     2 - Mettre le lien de téléchargement
                     3 - Vérifier vôtre connexion"
        }


    
}

function InstallManager($config){
    if ($config.elasticsearch){
        if ($config.elasticsearch.install) {

            if ($config.elasticsearch.install.custom_directory) {
                $install_option = "custom_directory"   
            }

            downloadElasticSearch -option $install_option $config.elasticsearch.install
                
        } ElseIf ($config.elasticsearch.configuration) {
        
        }
            
    }
}


function RunConfig(){
}


function RunInstall(){

    displayInstall -type "INIT"

    $config_path = Join-Path -path  $current_path -ChildPath $config_file

    $configuration = getConfig -path $config_path

    
    echo $configuration.elasticsearch.install.version


    InstallManager -config $configuration



    #$file = Join-Path -Path $current_path -ChildPath $elastic_zip

    #displayInstall -type "UNZIP" -message "Path to extract $current_path"

    #Unzip -zip_file $file -path_to_extract $current_path

    #displayInstall -type "CONFIG" 

    #elasticsearch-service install


}

RunInstall




