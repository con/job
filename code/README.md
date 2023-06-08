ATM we are running the beast as 

    for j in openneuro-annotations/ds00*json; do ds=$(basename ${j%.json}); [ -e "$ds" ] && {echo "$ds skip - exists"} || { chronic ../CON/job/code/prototype-neurobagel.sh $ds && echo "$ds done"; }; done

while taking annotions from https://github.com/neurobagel/openneuro-annotations
