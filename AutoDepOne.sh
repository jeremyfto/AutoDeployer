MYDIR="$(dirname "$(readlink -f "$0")")"
source "$MYDIR"/config.cfg
#echo $IPDASH $IPDOT $KEYNAME $GITURL $PROJNAME $REPONAME
chmod 400 $KEYNAME.pem
ssh -T -i "$KEYNAME.pem" ubuntu@ec2-$IPDASH.us-east-2.compute.amazonaws.com <<EOF
    sudo apt-get update;
    yes | sudo apt-get install python-pip python-dev nginx git
    sudo apt-get update;
    sudo pip install virtualenv;
    git clone $GITURL.git;
    cd $REPONAME;
    virtualenv venv;
    source venv/bin/activate;
    cat requirements.txt | xargs -n 1 pip install
    pip install django bcrypt django-extensions
    pip install gunicorn
    cd $PROJNAME
    perl -pi -e 's/DEBUG = True/DEBUG = False/g' settings.py
    perl -pi -e "s/ALLOWED_HOSTS = \Q[]\E/ALLOWED_HOSTS = ['$IPDOT']/g" settings.py
    echo 'STATIC_ROOT = os.path.join(BASE_DIR, "static/")' | sudo tee --append settings.py
    cd ..
    python manage.py makemigrations
    python manage.py migrate
    yes| python manage.py collectstatic
    gunicorn --bind 0.0.0.0:8000 $PROJNAME.wsgi:application
EOF
