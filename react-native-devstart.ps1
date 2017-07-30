<#

	REACT-NATIVE-DEVSTART
	
	ABOUT
		This PowerShell script sets up a React Native Android development environment by
		starting processes and repositions the windows on the screen.
	
	HOW IT WORKS
		The script starts an Android Emulator and moves its to a specified location on the screen.
		Then, the PowerShell terminal windows are created and relocated as well.
		Finally, the script starts your favorite IDE.
	
	PREREQUISITES
		- React Native
		- Android Virtual Device (AVD)
		- Some IDE
	
	SETUP
		Change the variables to suit your needs.
	
	NOTES
		Version: 0.1
		Date: August 1, 2017
		Author: Jarkko Vallius
		
		
	Happy devving!
	
#>


### Change at least the following variables

# React Native project location, ie. C:\projects\my-react-native-project
$REACT_NATIVE_PROJECT_ROOT = "C:\projects\my-react-native-project" ;

# Android SDK location, ie. C:\apps\android-sdk
$ANDROID_SDK_FOLDER = "C:\apps\android-sdk";

# Android Virtual Device (AVD) name, ie. NEXUS_5_API_19
$ANDROID_EMULATOR_AVD_NAME = "NEXUS_5_API_19";

# Your favorite IDE filepath, ie. C:\Program Files (x86)\Microsoft VS Code\Code.exe
$IDE_FILEPATH = "C:\Program Files (x86)\Microsoft VS Code\Code.exe" ;


# Using dual or single monitor
# - change to $false for single monitor
$DUAL_MONITORS = $true ; 

# Main monitor's screen width
$MONITOR_ONE_WIDTH = 1680 ;

# Seconds monitor's screen width
$MONITOR_TWO_WIDTH = 1680 ;





### Optional variables

# PowerShell windows' width
$POWERSHELL_WINDOW_WIDTH = 800 ;

# Android Emulator X position on the screen
$ANDROID_EMULATOR_X_POSITION = If ($DUAL_MONITORS) {$MONITOR_ONE_WIDTH} Else {0} ;

# Android Emulator Y position on the screen
$ANDROID_EMULATOR_Y_POSITION = 0;

# PowerShell windows' starting Y position on the screen
$POWERSHELL_WINDOW_START_Y_POSITION = 0 ;


<#
PowerShell terminal windows

Parameters: 
 	ArgumentList:
		'-noexit' argument prevents terminal screen from closing itself
		
	TerminalWindowHeight
#>
$POWERSHELL_TERMINALS = (
	( ('-noexit', 'react-native start'), 		200 ), # packager, window height 200
	( ('-noexit', 'react-native run-android'), 	300 ), # runs android emulator, window height 300
	( ('-noexit', 'react-native log-android'), 	500 )  # android logger, window height 500
) ;


<#
PowerShell terminal windows' positions 
- For dual monitors: terminal windows are on the right side of the second screen
- For single monitor: terminal windows are on the right side of the screen
#>
$secondScreenWidth = If ($DUAL_MONITORS) {$MONITOR_TWO_WIDTH} Else {0}  ;
$POWERSHELL_WINDOW_X_POSITION = $MONITOR_ONE_WIDTH + $secondScreenWidth - $POWERSHELL_WINDOW_WIDTH ;






Function Set-Window {
    <#
        .SYNOPSIS
            Sets the window size (height,width) and coordinates (x,y) of
            a process window.

        .DESCRIPTION
            Sets the window size (height,width) and coordinates (x,y) of
            a process window.
			

        .PARAMETER ProcessName
            Name of the process to determine the window characteristics

        .PARAMETER X
            Set the position of the window in pixels from the top.

        .PARAMETER Y
            Set the position of the window in pixels from the left.

        .PARAMETER Width
            Set the width of the window.

        .PARAMETER Height
            Set the height of the window.

        .PARAMETER Passthru
            Display the output object of the window.

        .NOTES
            Name: Set-Window
            Author: Boe Prox
            Version History
                1.0//Boe Prox - 11/24/2015
                    - Initial build

        .OUTPUT
            System.Automation.WindowInfo

        .EXAMPLE
            Get-Process powershell | Set-Window -X 2040 -Y 142 -Passthru

            ProcessName Size     TopLeft  BottomRight
            ----------- ----     -------  -----------
            powershell  1262,642 2040,142 3302,784   

            Description
            -----------
            Set the coordinates on the window for the process PowerShell.exe
        
    #>
    [OutputType('System.Automation.WindowInfo')]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipelineByPropertyName=$True)]
        $Id,
		#$ProcessName,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height,
        [switch]$Passthru
    )
    Begin {
        Try{
            [void][Window]
        } Catch {
        Add-Type @"
              using System;
              using System.Runtime.InteropServices;
              public class Window {
                [DllImport("user32.dll")]
                [return: MarshalAs(UnmanagedType.Bool)]
                public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

                [DllImport("User32.dll")]
                public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);
              }
              public struct RECT
              {
                public int Left;        // x position of upper-left corner
                public int Top;         // y position of upper-left corner
                public int Right;       // x position of lower-right corner
                public int Bottom;      // y position of lower-right corner
              }
"@
        }
    }
    Process {
        $Rectangle = New-Object RECT
        #$Handle = (Get-Process -Name $ProcessName).MainWindowHandle
		$Handle = (Get-Process -Id $Id).MainWindowHandle
        $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
        If (-NOT $PSBoundParameters.ContainsKey('Width')) {            
            $Width = $Rectangle.Right - $Rectangle.Left            
        }
        If (-NOT $PSBoundParameters.ContainsKey('Height')) {
            $Height = $Rectangle.Bottom - $Rectangle.Top
        }
        If ($Return) {
            $Return = [Window]::MoveWindow($Handle, $x, $y, $Width, $Height,$True)
        }
        If ($PSBoundParameters.ContainsKey('Passthru')) {
            $Rectangle = New-Object RECT
            $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
            If ($Return) {
                $Height = $Rectangle.Bottom - $Rectangle.Top
                $Width = $Rectangle.Right - $Rectangle.Left
                $Size = New-Object System.Management.Automation.Host.Size -ArgumentList $Width, $Height
                $TopLeft = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Left, $Rectangle.Top
                $BottomRight = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Right, $Rectangle.Bottom
                If ($Rectangle.Top -lt 0 -AND $Rectangle.LEft -lt 0) {
                    Write-Warning "Window is minimized! Coordinates will not be accurate."
                }
                $Object = [pscustomobject]@{
                    #ProcessName = $ProcessName
					Id = $Id
                    Size = $Size
                    TopLeft = $TopLeft
                    BottomRight = $BottomRight
                }
                $Object.PSTypeNames.insert(0,'System.Automation.WindowInfo')
                $Object            
            }
        }
    }
}






<#

	SCRIPT BEGINS HERE
	
#>
Set-Location -Path $REACT_NATIVE_PROJECT_ROOT ;


#
# ANDROID EMULATOR
#
Start-Process -FilePath ($ANDROID_SDK_FOLDER + "\tools\emulator.exe") -ArgumentList ("-avd " + $ANDROID_EMULATOR_AVD_NAME) ;  
Start-Sleep 5 ;
# note: android emulator process is named as qemu-system-i386
Get-Process qemu-system-i386 | Set-Window -X $ANDROID_EMULATOR_X_POSITION -Y $ANDROID_EMULATOR_Y_POSITION ;

# Sleep 10 seconds so emulator has enough time to get up before starting powershell terminals and deploying apk
Start-Sleep 10



#
# POWERSHELL TERMINALS
#
$ScreenY = $POWERSHELL_WINDOW_START_Y_POSITION ;
foreach ($window in $POWERSHELL_TERMINALS) {
	$ArgumentList = $window[0] ;
	$WindowHeight = $window[1] ;
	
	# start powershell process
	$process = Start-Process -FilePath powershell -Passthru -ArgumentList $ArgumentList
	
	# by sleeping a bit we make sure that process' id is available for relocating
	Start-Sleep -m 500 ;
	
	# relocate and resize the terminal window
	Get-Process -Id $process.Id | Set-Window -X $POWERSHELL_WINDOW_X_POSITION -Y $ScreenY -Width $POWERSHELL_WINDOW_WIDTH -Height $WindowHeight ;
	
	$ScreenY += $WindowHeight ;
}


#
# IDE
#
Start-Process $IDE_FILEPATH ;



