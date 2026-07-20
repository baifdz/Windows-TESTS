function Invoke-AbsoluteHardwareCeiling {
    # 1. Detect hardware threads to ensure all CPU cores hit 100% instantly
    $LogicalCores = [int]$env:NUMBER_OF_PROCESSORS

    Write-Host "--- CRITICAL HARDWARE SATURATION ---" -ForegroundColor Red
    Write-Host "Cores Saturation Engine Active: $LogicalCores Cores Linked." -ForegroundColor Gray
    Write-Host "Allocating ALL available physical memory addresses globally..." -ForegroundColor Yellow
    Write-Host "WARNING: System lockup or crash will occur within seconds." -ForegroundColor White

    # 2. Initialize an infinite, unbounded storage collection for RAM blocks
    $GlobalHardwareMatrix = [System.Collections.Generic.List[byte[]]]::new()
    
    # 256 Megabytes per allocation block (optimal size for high-speed hardware caching)
    $ChunkSize = 268435456 

    # 3. HIGH-SPEED KERNEL THROTTLE PAYLOAD
    $HardwarePayload = {
        param($MatrixRef)
        $Rand = [Random]::new()

        while ($true) {
            # CPU SATURATION: Force continuous AVX/FPU calculations to lock the processing registers
            $CalcValue = [Math]::Pow([Math]::Sin($Rand.NextDouble()), [Math]::Cos($Rand.NextDouble()))
            $ByteValue = [byte]($CalcValue * 255)

            # MEMORY BUS SATURATION: Constantly read and rewrite the existing global arrays
            # to maximize motherboard data transfer bandwidth
            foreach ($Block in $MatrixRef) {
                $Length = $Block.Length
                for ($i = 0; $i -lt $Length; $i += 4096) {
                    $Block[$i] = $ByteValue
                }
            }
        }
    }

    # 4. Spin up the Runspace background pool to continuously lock the CPU cores at 100%
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1, $LogicalCores)
    $RunspacePool.Open()
    $ActiveThreads = [System.Collections.Generic.List[System.Management.Automation.PowerShell]]::new()

    for ($i = 0; $i -lt $LogicalCores; $i++) {
        $Thread = [powershell]::Create().AddScript($HardwarePayload).AddArgument($GlobalHardwareMatrix)
        $Thread.RunspacePool = $RunspacePool
        $null = $Thread.BeginInvoke()
        $ActiveThreads.Add($Thread)
    }

    # 5. UNBOUNDED RAM FLOOD LOOP: Keep grabbing 256MB blocks until the system physically can't hold anymore
    try {
        while ($true) {
            # Allocate a 256MB chunk
            $BufferChunk = [byte[]]::new($ChunkSize)
            
            # Instantly populate the block to force the OS to map it to physical RAM sticks
            for ($j = 0; $j -lt $BufferChunk.Length; $j += 4096) {
                $BufferChunk[$j] = 255
            }
            
            # Lock it into our global reference so the Garbage Collector cannot clean it up
            $GlobalHardwareMatrix.Add($BufferChunk)
            
            # Minimal pause (1 millisecond) to allow the thread pool to grab the memory handle before the next chunk expands
            [System.Threading.Thread]::Sleep(1)
        }
    }
    catch {
        # This triggers the millisecond the system hits absolute 100% RAM capacity
        Write-Warning "Absolute hardware memory limits breached. Enforcing active lock..."
        
        # ACTIVE LOCK: Endlessly iterate through the captured memory blocks.
        # This constant read/write action forces Windows to keep the data locked 
        # on the physical RAM sticks, preventing the usage graph from dropping down.
        while ($true) {
            foreach ($Block in $GlobalHardwareMatrix) {
                # Touch each block to keep it "Hot" in physical RAM
                if ($Block.Length -gt 0) {
                    $Block[0] = 255
                }
            }
            # Maximize CPU usage on the main thread alongside the background runspaces
            $null = [Math]::Sqrt([Random]::new().Next())
        }
    }
}

Invoke-AbsoluteHardwareCeiling
