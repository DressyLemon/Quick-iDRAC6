# Quick-iDRAC6
Used to quickly connect to iDRAC 6 with one command. Ensure that the environment is configured in a predefined, the library will be automatically extracted from your iDRAC Environment. Please download the JRE Server 7u80 and extract ensure that you extract the folders into a folder titled "JRE", You can download JRE at https://edelivery.oracle.com/akam/otn/java/jdk/7u80-b15/server-jre-7u80-windows-x64.tar.gz - This will require you to have an account created.

# Installation Guide

First of all you will need to quickly create a predified environment. Please ensure that you are located at a easily accessable location

Use this command line switches to run the quickly connection to your iDRAC6
```
Define the LocalPath using the "-d" command switch to define your path which contains your "JRE" Installation and Library Folder
Define the iDRAC-Host using the -h command switch to define your hostname or IP that your iDRAC6 is run on
Define the iDRAC-User using the "-u" command switch to define your iDRAC6 Username
Define the Web-UI Port using the "-w" command switch to define the port that the iDRAC6 Web-Interface is listening on
Define the KVM Port using the "-k" command switch to define your KVM Access Port 
```
## How to run the command
Ensure that you change the iDRAC command line switches
```cmd
mkdir Quick-iDRAC6
cd Quick-iDRAC6
powershell -c "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/DressyLemon/Quick-iDRAC6/main/run.bat' -OutFile 'run.bat'"
run.bat -d="%cd%" -h="idrac6.example.com" -w=44 -k=900 -u=root
```
### Single Command Example
Ensure that you change the iDRAC command line switches, ENSURE YOU CHANGE YOUR "LocalPath" SWITCH WITH THE FOLDER!
```cmd
mkdir Quick-iDRAC6 & cd Quick-iDRAC6 & powershell -c "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/DressyLemon/Quick-iDRAC6/main/run.bat' -OutFile 'run.bat'" & run.bat -d="%cd%\Quick-iDRAC6" -h="idrac6.example.com" -w=443 -k=5900 -u root
```
