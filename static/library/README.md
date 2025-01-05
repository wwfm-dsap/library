# WWFM-DSAP Library

## Welcome to the WWFM-DSAP Library

Here each administrative divisions licensee can find all the account profiles and contracts for their region   

### Updating the library

For collaboration in refining the data, particularly for non technical personel, we host the data on Google Sheets. 
'sudo bash ./1.sh` grabs the data from Google Sheets (as an xlsx file)  
'sudo bash ./2.sh temp[timestamp].xlsx` will generate json files  
e.g. data.json to map the country jsons, then the country jsons themselves e.g. uk.json, us,json etc
'sudo bash ./3.sh` will update the heatmap 
