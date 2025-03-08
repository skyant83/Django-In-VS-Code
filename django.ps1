$global:cwd = Get-Location
$global:is_venv_enabled

if (Test-Path '.\.venv'){
	Write-Host "g"
	$venv = ".\.venv\Scripts\Activate.ps1"
}
elseif (Test-Path "$env:TEMP\sky_django\venv.xml") {
	Write-Host "h"
	$venv = Import-Clixml -Path "$env:TEMP\sky_django\venv.xml"
}
if (Test-Path "$env:TEMP\sky_django\django_manage.xml") {
	Write-Host "i"
	$manage = Import-Clixml -Path "$env:TEMP\sky_django\django_manage.xml"
}

# $location = Get-ChildItem -Path .\ -Filter README.md -Recurse | ForEach-Object{$_.DirectoryName}

# Write-Output ("loc = {0}" -f $location)

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
				if (-not ([string]::IsNullOrEmpty($venv))) {
					Invoke-Expression "$venv\Scripts\Activate.ps1"
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
	$venv_loc = Get-ChildItem -Path .\ -Filter .venv -Recurse | ForEach-Object{$_.FullName}
	if ( $venv_loc -eq "$cwd\.venv") {
		$title = @{ Object = "A Virtual Environment (.venv) Exists"; ForegroundColor = 'Yellow'}
		$msg = "Confirm the creation of a new virtual environment (existing will be deleted)"
		$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Deletes the existing .venv to create a new one"
		$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Cancels the whole process"
		$options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)

		$choice = $Host.UI.PromptForChoice($title, $message, $options, 1)
		Remove-Item "$cwd\.venv" -f $cwd -Force -Recurse
		Write-Host "Deleted old .venv folder"
		Pause
	}

	Write-Host "Creating .venv folder..." -ForegroundColor Green
	py -m venv .venv
	$venv = ".\.venv\Scripts\Activate.ps1"
	Save-Venv $venv
	Write-Host "Activating .venv..."
	Enable-Venv
	Write-Host "Upgrading pip..." -ForegroundColor Green
	py -m pip install --upgrade pip
	Write-Host "Installing Django Project modules..." -ForegroundColor Green
	pip install python-dotenv
	Write-Host "Python-dotenv Installed" -ForegroundColor Green
	pip install Django
	Write-Host "Django Installed" -ForegroundColor Green
	Disable-Venv

	# Write-Host ($venv_loc -eq ('{0}\.venv' -f $cwd))
	# Write-Host ('{0}\.venv' -f $cwd)
	Write-Host "Finished creating virtual environment" -ForegroundColor Green
	Pause
}

function Enable-Venv {
	if (-not ([string]::IsNullOrEmpty($venv))) {
		Invoke-Expression $venv
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
	if (-not ([string]::IsNullOrEmpty($manage))) {
		do {
			Write-Host "A Django Project Already exits"
			Write-Host $manage
			$continue = Read-Host "Are you sure you want to continue? (y|N)"
			$continue = $continue.ToLower()
			Clear-Host
			switch ($continue) {
				'y' {
				}
				'n' {
					Show-Menu
					return
				}
				Default {}
			}
		} until (
			$continue -eq 'y' -or $continue -eq 'n'
		)
	}
	if (-not ([string]::IsNullOrEmpty($venv))) {
		Invoke-Expression "$venv"
	} else {
		Test-Venv
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
	django-admin startproject $proj_name
	Set-Manage
	Disable-Venv
	Clear-Host
	Write-Host "Django Project $proj_name has been successfully created" -ForegroundColor Green
	Pause
	# Write-Host $cwd
}

function Test-Venv {
	do {
		Write-Host "Does the virtual environment already exit?"
		$choice = Read-Host "(y|N)"
		Clear-Host
		$choice = $choice.ToLower()
		switch ($choice) {
			'y' {
				Request-ForFile
			}
			'n' {
				Write-Host "Please create a virtual environment before creating a Django Project"
				Pause
				Clear-Host
				Show-Menu
			}
		}

	} until (
		$choice -eq 'y' -OR $choice -eq 'n'
	)
}

function Request-ForFile {
	do {
		Write-Host "Enter .venv absolute path"
		$path = Read-Host "(C:\Documents\...\{virtual environment})"
		$path_exists = Test-Path "$path\Scripts\Activate.ps1"
		# Clear-Host
		if ($path_exists) {
			$venv = $path
			Save-Venv $venv
			return
		}

	} until ($path_exists)
}

function Set-Manage {

}

function Save-Venv {
	param (
		[string] $venv_path
	)
	if (Test-Path "$env:TEMP\sky_django\") {
		$venv_path | Export-Clixml -path "$env:TEMP\sky_django\venv.xml"
	} else {
		mkdir -Path $env:TEMP\sky_django\
		$venv_path | Export-Clixml -path "$env:TEMP\sky_django\venv.xml"
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
		Remove-Item "$cwd\$proj_path"
		Remove-Item "$env:TEMP\sky_django\django_manage.xml"
	}
}

# $Host.UI.PromptForChoice("test", "test1", @('&Yes', '&No'),1)

Show-Menu