## Accessing Felix and Biowulf 

### Before you begin
* Apply for NIH Biowulf HPC accounts: https://hpc.nih.gov/docs/accounts.html 
* Sign up to GitHub https://github.com/
* Contact the SCNI admin and requets to be added to:
    1) the NIF group's Helix directory
    2) the NIF GitHub user group: https://github.com/nimh-nif


### Using NoMachine

* Install NoMachine from the web: https://www.nomachine.com/
* Setup an SSH connection to host: felix.nimh.nih.gov, port 22 (https://hpc.nih.gov/docs/connect.html)
* Connect to Felix
* In Felix, open a terminal window: Applications > System Tools > Terminal
* Navigate to the NIF group's directory, create a folder for yourself and clone the github repository 'SortSpikes'

::

    cd /data/NIF/projects
    mkdir leathersml
    chmod 755 -R /leathersml
    cd leathersml
    git clone https://github.com/nimh-nif/SortSpikes.git

* Open Matlab

::

    module load matlab
    matlab &

### Using OSX

* Open an OSX Finder window. From the menu at the top of the screen select Go > Connect to Server
* Enter the server address: smb://helixdrive.nih.gov/NIF and click connect
* Enter your NIH username and password
* The NIF group's Helix directory is now mapped to your local Mac as a volume.

* Open an OSX Terminal window (e.g. click the magnifying glass in the top right corner of the desktop and type 'terminal')
* Open an SSH connection to Felix:

::

    ssh murphyap@felix.nimh.nih.gov
    

### Modifying SortSpikes Matlab code

* Copy BatchNeuroScript_APM.m and rename with own initials
* Copy set_waveclus_handles_APM.m and rename with own initials
* Add new user to PreprocessNeuroData.m

