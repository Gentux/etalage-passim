#!/bin/bash

python etalagepassim/scripts/update_db_change_field_name.py -v -s "Offre de transport"      -i "select"         -l "Couverture territoriale"    -nl "Niveau"            $1
python etalagepassim/scripts/update_db_change_field_name.py -v -s "Application mobile"      -i "url"            -l "URL Web mobile"             -nl "Web mobile"        $1
python etalagepassim/scripts/update_db_change_field_name.py -v -s "Application mobile"      -i "url"            -l "URL système Android"        -nl "Android"           $1
python etalagepassim/scripts/update_db_change_field_name.py -v -s "Application mobile"      -i "url"            -l "URL système Blackberry"     -nl "Blackberry"        $1
python etalagepassim/scripts/update_db_change_field_name.py -v -s "Application mobile"      -i "url"            -l "URL système Symbian"        -nl "Symbian"           $1
python etalagepassim/scripts/update_db_change_field_name.py -v -s "Application mobile"      -i "url"            -l "URL système Windows mobile" -nl "Windows mobile"    $1
python etalagepassim/scripts/update_db_change_field_name.py -v -s "Application mobile"      -i "url"            -l "URL système iPhone"         -nl "iPhone"            $1
python etalagepassim/scripts/update_db_change_field_name.py -v -s "Service d'information"   -i "territories"    -l "Territoire couvert"         -nl "Territoires"       $1
