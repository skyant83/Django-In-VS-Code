$global:cwd = Get-Location
$global:is_venv_enabled
$global:venv

if (Test-Path "$cwd\.venv"){
	Write-Host "Found Default venv"
	$global:venv = ".\.venv\Scripts\Activate.ps1"
}
elseif (Test-Path "$env:TEMP\sky_django\venv.xml") {
	Write-Host "Checking Saved venv"
	$global:venv = Import-Clixml -Path "$env:TEMP\sky_django\venv.xml"
	if (-not (Test-Path $global:venv)) {
		Remove-Item "$env:TEMP\sky_django\venv.xml"
		Write-Host "Saved venv Location Invalid"
	} else {
		Write-Host "Found Saved venv"
	}
}

function Show-Menu {
	do {
		Clear-Host
		Write-Host "================ " -NoNewline
		Write-Host "My Basic Django" -NoNewline -ForegroundColor Magenta
		Write-Host " ================"

		Write-Host "1: Create a new Django .venv"
		Write-Host "2: Create a new Django Project"
		Write-Host "3: Delete a Django Project"
		Write-Host "Q: Exit" -ForegroundColor Red
		$choice = Read-Host "Select an option"
		Clear-Host
		switch ($choice) {
			'1' {
				New-VirtualEnvironment
			}
			'2' {
				New-DjangoProject
			}
			'3' {
				Remove-DjangoProject
			}
			'q' {
				if (-not ([string]::IsNullOrEmpty($global:venv))) {
					Disable-Venv
				}
				exit
			}
		}
	} until (
		$choice -eq 'q'
	)
}
function New-VirtualEnvironment {
	$global:venv_loc = Get-ChildItem -Path .\ -Filter .venv -Recurse | ForEach-Object{$_.FullName}
	if ( $global:venv_loc -eq "$cwd\.venv") {
		$title = "$([char]0x1b)[33mA Virtual Environment (.venv) Exists"
		$msg = "Confirm the creation of a new virtual environment (existing will be deleted)"
		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Deletes the existing .venv to create a new one"
		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Cancels the whole process"
		$options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

		Clear-Host
		$choice = $Host.UI.PromptForChoice($title, $msg, $options, 0)
		switch ($choice) {
			0 {
				Clear-Host
				Remove-Item "$cwd\.venv" -f $cwd -Force -Recurse
				Write-Host "Deleted old .venv folder" -ForegroundColor Yellow
			}
			1 {
				Return
			}
		}
	}

	Write-Host "Creating .venv folder..." -ForegroundColor Green
	py -m venv .venv
	$global:venv = ".\.venv\Scripts\Activate.ps1"
	Save-Venv $global:venv

	Write-Host "Activating .venv..." -ForegroundColor Yellow
	Enable-Venv

	Write-Host "Upgrading pip..." -ForegroundColor Green
	py -m pip install --upgrade pip

	Write-Host "Installing Django Project modules..." -ForegroundColor Green
	pip install python-dotenv

	Write-Host "Python-dotenv Installed" -ForegroundColor Green
	pip install Django

	Write-Host "Django Installed" -ForegroundColor Green
	Disable-Venv
	Write-Host "Finished creating virtual environment" -ForegroundColor Green
	Pause
}

function Enable-Venv {
	if (-not ([string]::IsNullOrEmpty($global:venv))) {
		Invoke-Expression $global:venv
		$global:is_venv_enabled = $true
	}
}

function Disable-Venv {
	if ($global:is_venv_enabled) {
		deactivate
		$global:is_venv_enabled = $false
	}
}

function New-DjangoProject {
	if (-not ([string]::IsNullOrEmpty($global:venv))) {
		Enable-Venv
	} elseif (-not (Assert-Venv)) {
		Return
	}
	Clear-Host
	do {
		Write-Host "Create a new Django Project"
		$proj_name = Read-Host "Enter Project Name"
		Clear-Host
	} until (
		-not ([string]::IsNullOrEmpty($proj_name))
	)
	Write-Host "Creating a new Django Project..." -ForegroundColor Green
	try {
		$ErrorOut = django-admin startproject $proj_name 2>&1
	} catch {
		$ErrorOut = $_.Exception.Message
	}
	if ($ErrorOut -Match "valid project name"){
		Write-Host "CommandError: '$proj_name' is not a valid project name. Please make sure the name is a valid identifier" -ForegroundColor Red
		Pause
		Return
	}
	if ($ErrorOut -Match "already exists"){
		Write-Host "CommandError: '$cwd\$proj_name' already exists" -ForegroundColor Red
		Pause
		Return
	}
	Disable-Venv
	Clear-Host
	Write-Host "Django Project $proj_name has been successfully created" -ForegroundColor Green
	Pause
}

function Assert-Venv {
	$title = "$([char]0x1b)[33mChecking virtual environment existence"
	$msg = "Does a virtual environment already exist?"
	$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "A virtual environment already exists in this directory"
	$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "There is no virtual enviroment in this directory"
	$options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

	Clear-Host
	$choice = $Host.UI.PromptForChoice($title, $msg, $options, 0)
	switch ($choice) {
		0 {
			Request-ForFile
			Return $true
		}
		1 {
			Write-Host "Please create a virtual environment before creating a Django Project"
			Pause
			Return $False
		}
	}
}

function Request-ForFile {
	do {
		Write-Host "Enter .venv absolute path"
		$path = Read-Host "(C:\Documents\...\{virtual environment})"
		$path_exists = Test-Path "$path\Scripts\Activate.ps1"
		if ($path_exists) {
			$global:venv = $path
			Save-Venv $global:venv
			return
		}

	} until ($path_exists)
}

function Save-Venv {
	param (
		[string] $global:venv_path
	)
	if (Test-Path "$env:TEMP\sky_django\") {
		$global:venv_path | Export-Clixml -path "$env:TEMP\sky_django\venv.xml"
	} else {
		mkdir -Path $env:TEMP\sky_django\ | Out-Null
		$global:venv_path | Export-Clixml -path "$env:TEMP\sky_django\venv.xml"
	}
}

function Remove-DjangoProject {
	do {
		Write-Host "Delete an exist Django Project"
		$proj_path = Read-Host "Enter project name (-q to cancel)"
		$valid_path = Test-Path "$cwd\$proj_path"
		Clear-Host
		switch ($p) {
			'-q' {
				Show-Menu
			}
		}
	} until (
		$proj_path -eq '-q' -or $valid_path
	)
	if ($valid_path) {
		if ($proj_path -eq ".venv") {
			Write-Host "The selected folder is the virutal environment" -ForegroundColor Yellow
			Write-Host "You cannot delete this folder via this script"
			Write-Host "If you want to delete the virtual environment, you must delete it " -NoNewline
			Write-Host "$([char]0x1b)[1mmanually$([char]0x1b)[22m" -ForegroundColor Red
			Pause
			Return
		}
		Remove-Item "$cwd\$proj_path"
	}
}

Show-Menu