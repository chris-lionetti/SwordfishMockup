---
DocTitle:  Catfish Mockup
---
# Catfish Mockup:
  *  A simple, minimal RedfishSwordfish Service and mockup creator.

# Top Level Description:
This set of powershell commands when used in conjunction with the HPE Nimble Storage PowerShell toolkit will allow you to create a local repository which represents a complete Swordfish model for a Nimble Storage Array. 
When you load the HPE Nimble PowerShell Toolkit, connect to the array, and then use the Create command included in this module, It will in tern examine the Nimble Array and gather a list of all of the chassis metrics, and then it will create on the local filesytem a stucture that matches the swordfish expectation. i.e. It will create a folder called C:\SwordfishMockup\Redfish\v1\etc.
The command is broken into subcommands that are stored in difference files to make troubleshooting and expanding more easy. The command will currently query all of the chassis information, the Storage Pools, the Volumes, The Endpoints (both Initiator and Target),Endpoint Groups, as well as Storage Groups. 
Additionally. included in this code base is a Listener.ps1 which can be pointed to the freshly downloaded mockup (either generated from a live array, or downloaded from this repository). This will let you test a Swordfish consumer against a Simulator that can be very easily populated. It also allows for testing of your mapping process from your custom API to a Swordfish API.

--Provides basic management features aligned with Swordfish Management Spec 1.10:

# What it does NOT have -- that the Swordfish 1.10 model supports
   * No support for Class of Service
   * No Support for DataProtectionLines of service (yet)
   * No Support for Events (yet)
   * No Support for Replication (yet)

# Outstanding bugs.
   * Currently if a volume name or snapshot name contains a ':' or '\' the file cannot be saved since it is reserved in file systems to denote drives and folders.

# Additional information
   * I have also added the output from an exisiting Nimble Array as sample data since it will allow the listener service to be run without having to connect to a Nimble Array first which leads to faster development cycles.

# Why the project name CatFish?
Well, it needed to be tied to RedFish, Swordfish, *fish scheme. It also needed to represent a PowerShell module gathering real information from an actual Array, and re-representing that data in a Swordfish compatible way back to clients looking for actual Swordfish implementations. This kind of sounds like the internet dating phenomenon called 'catfishing'.
