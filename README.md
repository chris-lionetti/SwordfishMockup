
# How to Use
From a Windows Machine, download using the PSGallery the HPENimblePowerShellToolkit, Then download this package and place it anywhere.  Modify the 'Listener.ps1' script with your Nimble Array IP Address, username, and passowrd. Open a PowerShell window (Administrator window) and execute the script called 'Listener.ps1'. Leave this PowerShell window alone and open a webbrowser (CHROME) to the address HTTP://localhost:5000/redfish/v1 and you should see the basic folder to start exploring Swordfish. Any errors should appear in the PowerShell window. To cease using the software open a web browser to the following location HTTP://Localhost:5000/end and the powershell code will terminate.# Catfish:
  *  A simple, minimal Redfish/Swordfish Service responder.
  *  A simple, single command to pull a Mockup from a live array and save to file.

# Top Level Description:
This set of powershell commands when used in conjunction with the HPE Nimble Storage PowerShell toolkit will allow you to nativly respond to Swordfish RestAPI requests which are translated and executed on a live Nimble Storage Array. 
You must modify the file called 'listener.ps1' to insert your username, password, and array IP address, it will in turn use the Nimble PowerShell Toolkit (downloadable from the PSGallery) to communcate directly with the array.
The command is broken into subcommands that are stored in difference files to make troubleshooting and expanding more easy. The command will currently query all of the chassis information, the Storage Pools, the Volumes, The Endpoints (both Initiator and Target),Endpoint Groups, Consistency Groups, Storage Groups, and Data Protection Lines of Service. 

--Provides basic management features aligned with Swordfish Management Spec 1.10:

# What it does NOT have -- that the Swordfish 1.10 model supports
   * No support for Class of Service
   * No Support for Replication (yet)
   
# To create a Mockup.
Modify the first few lines of the MockupCreator.ps1 file to set your Mockup folder root, as well as your array IP Address and password.
Once set, you can issue the .\MockupCreator.ps1 command
# Outstanding bugs.
 
# Why the project name CatFish?
Well, it needed to be tied to RedFish, Swordfish, *fish scheme. It also needed to represent a PowerShell module gathering real information from an actual Array, and re-representing that data in a Swordfish compatible way back to clients looking for actual Swordfish implementations. This kind of sounds like the internet dating phenomenon called 'catfishing'.
