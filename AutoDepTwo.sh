MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR"/config.cfg
#echo $IPDASH $IPDOT $KEYNAME $GITURL $PROJNAME $REPONAME
chmod 400 $KEYNAME.pem
ssh -T -i "$KEYNAME.pem" ubuntu@ec2-$IPDASH.us-east-2.compute.amazonaws.com <<EOF
    echo "[Unit]" | sudo tee --append /etc/systemd/system/gunicorn.service
    echo "Description=gunicorn daemon" | sudo tee --append /etc/systemd/system/gunicorn.service
    echo "After=network.target" | sudo tee --append /etc/systemd/system/gunicorn.service
    echo "[Service]" | sudo tee --append /etc/systemd/system/gunicorn.service
    echo "User=ubuntu" | sudo tee --append /etc/systemd/system/gunicorn.service
    echo "Group=www-data" | sudo tee --append /etc/systemd/system/gunicorn.service
    echo "WorkingDirectory=/home/ubuntu/$REPONAME" | sudo tee --append /etc/systemd/system/gunicorn.service
    echo "ExecStart=/home/ubuntu/$REPONAME/venv/bin/gunicorn --workers 3 --bind unix:/home/ubuntu/$REPONAME/$PROJNAME.sock $PROJNAME.wsgi:application" | sudo tee --append /etc/systemd/system/gunicorn.service
    echo "[Install]" | sudo tee --append /etc/systemd/system/gunicorn.service
    echo "WantedBy=multi-user.target" | sudo tee --append /etc/systemd/system/gunicorn.service
    sudo systemctl daemon-reload
    sudo systemctl start gunicorn
    sudo systemctl enable gunicorn
    echo -e "server {" | sudo tee --append /etc/nginx/sites-available/$PROJNAME;
    echo -e "    listen 80;" | sudo tee --append /etc/nginx/sites-available/$PROJNAME;
    echo -e "    server_name $IPDOT;" | sudo tee --append /etc/nginx/sites-available/$PROJNAME;
    echo -e "    location = /favicon.ico { access_log off; log_not_found off; }" | sudo tee --append /etc/nginx/sites-available/$PROJNAME;
    echo -e "    location /static/ {" | sudo tee --append /etc/nginx/sites-available/$PROJNAME;
    echo -e "        root /home/ubuntu/$REPONAME;" | sudo tee --append /etc/nginx/sites-available/$PROJNAME;
    echo -e "    }" | sudo tee --append /etc/nginx/sites-available/$PROJNAME;
    echo -e "    location / {" | sudo tee --append /etc/nginx/sites-available/$PROJNAME;
    echo -e "        include proxy_params;" | sudo tee --append /etc/nginx/sites-available/$PROJNAME;
    echo -e "        proxy_pass http://unix:/home/ubuntu/$REPONAME/$PROJNAME.sock;" | sudo tee --append /etc/nginx/sites-available/$PROJNAME;
    echo -e "    }" | sudo tee --append /etc/nginx/sites-available/$PROJNAME;
    echo -e "}" | sudo tee --append /etc/nginx/sites-available/$PROJNAME;
    sudo ln -s /etc/nginx/sites-available/$PROJNAME /etc/nginx/sites-enabled
    sudo nginx -t
    sudo rm /etc/nginx/sites-enabled/default
    sudo service nginx restart
EOF
