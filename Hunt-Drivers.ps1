FUNCTION Hunt-Drivers {
    <#
    .Synopsis 
        Gets a list of drivers for the given computer(s).

    .Description 
        Gets a list of drivers for the given computer(s).

    .Parameter Computer  
        Computer can be a single hostname, FQDN, or IP address.

    .Parameter Fails  
        Provide a path to save failed systems to.

    .Example 
        Hunt-Drivers 
        Hunt-Drivers SomeHostName.domain.com
        Get-Content C:\hosts.csv | Hunt-Drivers
        Hunt-Drivers -Computer $env:computername
        Get-ADComputer -filter * | Select -ExpandProperty Name | Hunt-Drivers

    .Notes 
        Updated: 2017-08-31
        LEGAL: Copyright (C) 2017  Jeremy Arnold
        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.

        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <http://www.gnu.org/licenses/>.
    #>

    PARAM(
    	[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        $Computer = $env:COMPUTERNAME,
        [Parameter()]
        $Fails
    );

	BEGIN{

        $datetime = Get-Date -Format "yyyy-MM-dd_hh.mm.ss.ff";
        Write-Information -MessageData "Started at $datetime" -InformationAction Continue;

        $stopwatch = New-Object System.Diagnostics.Stopwatch;
        $stopwatch.Start();
        $total = 0;

        class Drivers
        {
            [Datetime] $DateScanned
            [string] $Computer
            [string] $Provider
            [string] $Driver
            [String] $Version
            [datetime] $date
            [String] $Class
            [string] $DriverSigned
            [string] $OrginalFileName
        };

    };

    PROCESS{
            
        $Computer = $Computer.Replace('"', '');  # get rid of quotes, if present
        $OutputArray = @();
        $drivers = $null;
        $drivers = Invoke-Command -ScriptBlock {Get-WindowsDriver -Online -ErrorAction SilentlyContinue}; # get list of drivers
       
        if ($drivers) { 
          
            foreach ($driver in $drivers) {#loop through each DNS record and build outputArray
             
                $output = $null;
                $output = [Drivers]::new();
                
                $output.DateScanned = Get-Date -Format u;
                $output.Computer = $Computer;
                $output.Provider = $driver.ProviderName;
                $output.Driver = $driver.Driver;
                $output.Version = $driver.Version;
                $output.date = $driver.Date;
                $output.Class = $driver.ClassDescription;
                $output.DriverSigned = $driver.DriverSignature;
                $output.OrginalFileName = $driver.OriginalFileName;

                $OutputArray += $output;
            
            };

        Return $OutputArray | Sort-Object -Property date -Descending;

        }Else{# System not reachable
        
            if ($Fails) {

                # -Fails switch was used
                Add-Content -Path $Fails -Value ("$Computer");
            
            }else{ 

                # -Fails switch not used            
                $output = $null;
                $output = [Drivers]::new();
                $output.Computer = $Computer;
                $output.DateScanned = Get-Date -Format u;

            return $output;

            };

        };

    };

    END{
        $elapsed = $stopwatch.Elapsed;
        $total = $total+1;

        Write-Information -MessageData "Total Systems: $total `t Total time elapsed: $elapsed" -InformationAction Continue;

	};

};