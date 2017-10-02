## Accessing Felix and Biowulf 

* Install NoMachine from the web: https://www.nomachine.com/
* Setup an SSH connection to host: felix.nimh.nih.gov, port 22 (https://hpc.nih.gov/docs/connect.html)
* Connect to Felix



* In Felix, open a terminal window: Applications > System Tools > Terminal
* Navigate to the NIF group's directory, create a folder for yourself and clone the github repository 'SortSpikes'

::

    cd /data/NIF/projects
    mkdir 
    cd 
    git clone https://github.com/nimh-nif/SortSpikes.git

* Open Matlab

::

    module load matlab
    matlab &
